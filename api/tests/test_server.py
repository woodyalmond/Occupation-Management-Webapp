from __future__ import annotations

import json
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from datetime import UTC, datetime
from http.server import ThreadingHTTPServer
from pathlib import Path
from typing import Any, Mapping


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from server import DatabaseConfig, MysqlRepository, NotFoundError, create_handler


class FakeNoopUpdateCursor:
    def __init__(self, record_exists: bool) -> None:
        self.record_exists = record_exists
        self.rowcount = 0

    def __enter__(self) -> "FakeNoopUpdateCursor":
        return self

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> None:
        return None

    def execute(self, query: str, params: tuple[Any, ...]) -> None:
        return None

    def fetchone(self) -> dict[str, int] | None:
        return {"id": 31} if self.record_exists else None


class FakeNoopUpdateConnection:
    def __init__(self, record_exists: bool) -> None:
        self.record_exists = record_exists

    def __enter__(self) -> "FakeNoopUpdateConnection":
        return self

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> None:
        return None

    def cursor(self) -> FakeNoopUpdateCursor:
        return FakeNoopUpdateCursor(self.record_exists)


class FakeNoopUpdateRepository(MysqlRepository):
    def __init__(self, record_exists: bool) -> None:
        super().__init__(
            DatabaseConfig(
                host="127.0.0.1",
                port=3306,
                database="alarmapp",
                user="alarmapp",
                password="alarmapp_password",
            ),
        )
        self.record_exists = record_exists

    def _connect(self) -> FakeNoopUpdateConnection:
        return FakeNoopUpdateConnection(self.record_exists)


class InMemoryRepository:
    def __init__(self) -> None:
        self.tasks: dict[int, dict[str, Any]] = {}
        self.subtasks: dict[int, dict[str, Any]] = {}
        self.activities: dict[int, dict[str, Any]] = {}
        self.next_task_id = 1
        self.next_subtask_id = 1
        self.next_activity_id = 1

    def list_tasks(self, due_date: str | None = None, filters: Any | None = None) -> list[dict[str, Any]]:
        records = list(self.tasks.values())
        if due_date:
            records = [record for record in records if record.get("due_date") == due_date]
        if filters is not None:
            if filters.q:
                records = [
                    record
                    for record in records
                    if self._contains(record.get("title"), filters.q) or self._contains(record.get("detail"), filters.q)
                ]
            if filters.status:
                records = [record for record in records if record.get("status") == filters.status]
            if filters.date_from:
                records = [record for record in records if self._task_record_date(record) >= filters.date_from]
            if filters.date_to:
                records = [record for record in records if self._task_record_date(record) <= filters.date_to]
            if filters.tag:
                records = [record for record in records if filters.tag in record.get("tags", [])]
        for record in records:
            record["subtasks"] = self._subtasks_for_task(int(record["id"]))
        return sorted(records, key=lambda record: (record.get("sort_order", 0), record.get("created_at", "")), reverse=False)

    def list_tasks_for_dailynote(self, note_date: str) -> list[dict[str, Any]]:
        records = [
            record
            for record in self.tasks.values()
            if record.get("due_date") == note_date or record.get("created_at", "").startswith(note_date)
        ]
        for record in records:
            record["subtasks"] = self._subtasks_for_task(int(record["id"]))
        return records

    def create_task(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        task = self._with_common_fields(payload, self.next_task_id)
        task.setdefault("sort_order", 0)
        task.setdefault("tags", [])
        task.setdefault("subtasks", [])
        self.tasks[self.next_task_id] = task
        self.next_task_id += 1
        return task

    def get_task(self, task_id: int) -> dict[str, Any]:
        if task_id not in self.tasks:
            raise NotFoundError("Task not found")
        self.tasks[task_id]["subtasks"] = self._subtasks_for_task(task_id)
        return self.tasks[task_id]

    def update_task(self, task_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        task = self.get_task(task_id)
        task.update(payload)
        task.setdefault("tags", [])
        return task

    def delete_task(self, task_id: int) -> None:
        if task_id not in self.tasks:
            raise NotFoundError("Task not found")
        del self.tasks[task_id]

    def reorder_tasks(self, task_ids: list[int]) -> list[dict[str, Any]]:
        for index, task_id in enumerate(task_ids):
            task = self.get_task(task_id)
            task["sort_order"] = index * 1000
        return self.list_tasks()

    def _next_subtask_sort_order(self, task_id: int) -> int:
        existing_subtasks = self._subtasks_for_task(task_id)
        if not existing_subtasks:
            return 0
        return max(int(subtask.get("sort_order", 0)) for subtask in existing_subtasks) + 1000

    def create_subtask(self, task_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        self.get_task(task_id)
        sort_order = (
            payload["sort_order"]
            if "sort_order" in payload
            else self._next_subtask_sort_order(task_id)
        )
        subtask = self._with_common_fields(
            {
                "task_id": task_id,
                "title": payload["title"],
                "is_done": payload.get("is_done", False),
                "sort_order": sort_order,
            },
            self.next_subtask_id,
        )
        self.subtasks[self.next_subtask_id] = subtask
        self.next_subtask_id += 1
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def update_subtask(self, task_id: int, subtask_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        self.get_task(task_id)
        if subtask_id not in self.subtasks or self.subtasks[subtask_id]["task_id"] != task_id:
            raise NotFoundError("Subtask not found")
        self.subtasks[subtask_id].update(payload)
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def delete_subtask(self, task_id: int, subtask_id: int) -> dict[str, Any]:
        self.get_task(task_id)
        if subtask_id not in self.subtasks or self.subtasks[subtask_id]["task_id"] != task_id:
            raise NotFoundError("Subtask not found")
        del self.subtasks[subtask_id]
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def reorder_subtasks(self, task_id: int, subtask_ids: list[int]) -> dict[str, Any]:
        self.get_task(task_id)
        existing_subtask_ids = {
            int(subtask["id"])
            for subtask in self.subtasks.values()
            if subtask["task_id"] == task_id
        }
        if existing_subtask_ids != set(subtask_ids):
            raise NotFoundError("Subtask not found")
        for index, subtask_id in enumerate(subtask_ids):
            self.subtasks[subtask_id]["sort_order"] = index * 1000
        return self.get_task(task_id)

    def _subtasks_for_task(self, task_id: int) -> list[dict[str, Any]]:
        return sorted(
            [
                subtask
                for subtask in self.subtasks.values()
                if subtask["task_id"] == task_id
            ],
            key=lambda subtask: (subtask.get("sort_order", 0), subtask.get("created_at", "")),
        )

    def _sync_task_completion_from_subtasks(self, task_id: int) -> None:
        subtasks = self._subtasks_for_task(task_id)
        if not subtasks:
            return
        task = self.get_task(task_id)
        if all(subtask.get("is_done") for subtask in subtasks):
            task["status"] = "done"
            task["completed_at"] = task.get("completed_at") or datetime.now(UTC).isoformat()
        else:
            task["status"] = "todo"
            task["completed_at"] = None

    def list_activities(self, activity_date: str | None = None, filters: Any | None = None) -> list[dict[str, Any]]:
        records = list(self.activities.values())
        if activity_date:
            records = [record for record in records if record.get("activity_date") == activity_date]
        if filters is not None:
            if filters.q:
                records = [
                    record
                    for record in records
                    if self._contains(record.get("title"), filters.q)
                    or self._contains(record.get("category"), filters.q)
                    or self._contains(record.get("memo"), filters.q)
                ]
            if filters.category:
                records = [record for record in records if record.get("category") == filters.category]
            if filters.date_from:
                records = [record for record in records if record.get("activity_date", "") >= filters.date_from]
            if filters.date_to:
                records = [record for record in records if record.get("activity_date", "") <= filters.date_to]
            if filters.tag:
                records = [record for record in records if filters.tag in record.get("tags", [])]
        return records

    def create_activity(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        activity = self._with_common_fields(payload, self.next_activity_id)
        if "tags" not in activity:
            activity["tags"] = [str(activity["category"]).strip().lstrip("#").lower()] if activity.get("category") else []
        activity["category"] = activity["tags"][0] if activity["tags"] else activity.get("category")
        self.activities[self.next_activity_id] = activity
        self.next_activity_id += 1
        return activity

    def get_activity(self, activity_id: int) -> dict[str, Any]:
        if activity_id not in self.activities:
            raise NotFoundError("Activity not found")
        return self.activities[activity_id]

    def update_activity(self, activity_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        activity = self.get_activity(activity_id)
        activity.update(payload)
        if "tags" in payload:
            activity["category"] = activity["tags"][0] if activity["tags"] else None
        activity.setdefault("tags", [])
        return activity

    def delete_activity(self, activity_id: int) -> None:
        if activity_id not in self.activities:
            raise NotFoundError("Activity not found")
        del self.activities[activity_id]

    def _with_common_fields(self, payload: Mapping[str, Any], record_id: int) -> dict[str, Any]:
        now = datetime.now(UTC).isoformat()
        return {"id": record_id, **dict(payload), "created_at": now, "updated_at": now}

    def _contains(self, value: Any, keyword: str) -> bool:
        return keyword.lower() in str(value or "").lower()

    def _task_record_date(self, task: Mapping[str, Any]) -> str:
        return str(task.get("due_date") or task.get("created_at", "")[:10])


class ApiServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repository = InMemoryRepository()
        cls.temp_dir = tempfile.TemporaryDirectory()
        cls.daily_note_dir = Path(cls.temp_dir.name)
        handler = create_handler(lambda: cls.repository, daily_note_dir=cls.daily_note_dir)
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.thread.join(timeout=2)
        cls.server.server_close()
        cls.temp_dir.cleanup()

    def setUp(self) -> None:
        self.__class__.repository = InMemoryRepository()

    def test_task_crud_flow(self) -> None:
        created = self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Write plan", "detail": "Keep it short", "due_date": "2026-04-30"},
        )
        self.assertEqual(created["title"], "Write plan")
        self.assertEqual(created["status"], "todo")
        self.assertIsNone(created["completed_at"])

        updated = self.request_json("PUT", f"/api/tasks/{created['id']}", {"status": "done"})
        self.assertEqual(updated["status"], "done")
        self.assertIsNotNone(updated["completed_at"])

        reopened = self.request_json("PUT", f"/api/tasks/{created['id']}", {"status": "todo"})
        self.assertEqual(reopened["status"], "todo")
        self.assertIsNone(reopened["completed_at"])

        listed = self.request_json("GET", "/api/tasks?due_date=2026-04-30")
        self.assertEqual(len(listed["items"]), 1)

        deleted = self.request_json("DELETE", f"/api/tasks/{created['id']}")
        self.assertTrue(deleted["deleted"])
        self.assert_http_error("GET", f"/api/tasks/{created['id']}", 404)

    def test_activity_crud_flow(self) -> None:
        created = self.request_json(
            "POST",
            "/api/activities",
            {
                "title": "Deep work",
                "category": "Study",
                "activity_date": "2026-04-30",
                "started_at": "09:00:00",
                "duration_minutes": 30,
            },
        )
        self.assertEqual(created["tags"], ["study"])

        updated = self.request_json("PUT", f"/api/activities/{created['id']}", {"memo": "Done"})
        self.assertEqual(updated["memo"], "Done")

        listed = self.request_json("GET", "/api/activities?activity_date=2026-04-30")
        self.assertEqual(len(listed["items"]), 1)

        deleted = self.request_json("DELETE", f"/api/activities/{created['id']}")
        self.assertTrue(deleted["deleted"])

    def test_invalid_task_status_returns_400(self) -> None:
        self.assert_http_error("POST", "/api/tasks", 400, {"title": "Bad", "status": "invalid"})

    def test_task_search_filters_by_keyword_status_and_date_range(self) -> None:
        self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Write backup plan", "detail": "MariaDB dump", "status": "todo", "due_date": "2026-04-30"},
        )
        self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Read docs", "detail": "Filter UI", "status": "done", "due_date": "2026-05-02"},
        )

        listed = self.request_json("GET", "/api/tasks?q=backup&status=todo&date_from=2026-04-01&date_to=2026-04-30")

        self.assertEqual(len(listed["items"]), 1)
        self.assertEqual(listed["items"][0]["title"], "Write backup plan")

    def test_task_reorder_updates_sort_order(self) -> None:
        first = self.request_json("POST", "/api/tasks", {"title": "First"})
        second = self.request_json("POST", "/api/tasks", {"title": "Second"})
        third = self.request_json("POST", "/api/tasks", {"title": "Third"})

        reordered = self.request_json("POST", "/api/tasks/reorder", {"task_ids": [third["id"], first["id"], second["id"]]})

        self.assertEqual([item["title"] for item in reordered["items"]], ["Third", "First", "Second"])
        self.assertEqual([item["sort_order"] for item in reordered["items"]], [0, 1000, 2000])

    def test_task_tags_can_be_created_updated_and_filtered(self) -> None:
        first = self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Write API tests", "tags": [" Dev ", "dev", "#urgent"]},
        )
        second = self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Clean desk", "tags": ["home"]},
        )

        self.assertEqual(first["tags"], ["dev", "urgent"])
        self.assertEqual(second["tags"], ["home"])

        updated = self.request_json("PUT", f"/api/tasks/{first['id']}", {"tags": ["study"]})
        self.assertEqual(updated["tags"], ["study"])

        listed = self.request_json("GET", "/api/tasks?tag=study")

        self.assertEqual(len(listed["items"]), 1)
        self.assertEqual(listed["items"][0]["title"], "Write API tests")

    def test_subtasks_complete_parent_task_when_all_done(self) -> None:
        task = self.request_json("POST", "/api/tasks", {"title": "Ship feature"})
        first_update = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Write API"},
        )
        first_subtask = first_update["subtasks"][0]
        second_update = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Wire UI"},
        )
        second_subtask = second_update["subtasks"][1]

        partial = self.request_json(
            "PUT",
            f"/api/tasks/{task['id']}/subtasks/{first_subtask['id']}",
            {"is_done": True},
        )
        self.assertEqual(partial["status"], "todo")
        self.assertEqual(partial["completed_at"], None)
        self.assertEqual([subtask["is_done"] for subtask in partial["subtasks"]], [True, False])

        completed = self.request_json(
            "PUT",
            f"/api/tasks/{task['id']}/subtasks/{second_subtask['id']}",
            {"is_done": True},
        )
        self.assertEqual(completed["status"], "done")
        self.assertIsNotNone(completed["completed_at"])
        self.assertEqual([subtask["is_done"] for subtask in completed["subtasks"]], [True, True])

        reopened = self.request_json(
            "PUT",
            f"/api/tasks/{task['id']}/subtasks/{first_subtask['id']}",
            {"is_done": False},
        )
        self.assertEqual(reopened["status"], "todo")
        self.assertEqual(reopened["completed_at"], None)

    def test_subtask_delete_returns_updated_parent_task(self) -> None:
        task = self.request_json("POST", "/api/tasks", {"title": "Clean queue"})
        updated = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Archive item"},
        )
        subtask_id = updated["subtasks"][0]["id"]

        deleted = self.request_json("DELETE", f"/api/tasks/{task['id']}/subtasks/{subtask_id}")

        self.assertEqual(deleted["id"], task["id"])
        self.assertEqual(deleted["subtasks"], [])

    def test_create_subtask_appends_after_existing_items(self) -> None:
        task = self.request_json("POST", "/api/tasks", {"title": "Timer task"})
        first = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "First"},
        )
        self.assertEqual(first["subtasks"][0]["title"], "First")
        self.assertEqual(first["subtasks"][0]["sort_order"], 0)

        second = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Second"},
        )
        self.assertEqual([subtask["title"] for subtask in second["subtasks"]], ["First", "Second"])
        self.assertEqual(second["subtasks"][1]["sort_order"], 1000)

        third = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Third"},
        )
        self.assertEqual(
            [subtask["title"] for subtask in third["subtasks"]],
            ["First", "Second", "Third"],
        )
        self.assertEqual(third["subtasks"][2]["sort_order"], 2000)

        reordered = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks/reorder",
            {
                "subtask_ids": [
                    third["subtasks"][2]["id"],
                    third["subtasks"][0]["id"],
                    third["subtasks"][1]["id"],
                ]
            },
        )
        fourth = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Fourth"},
        )
        self.assertEqual(fourth["subtasks"][-1]["title"], "Fourth")
        self.assertEqual(fourth["subtasks"][-1]["sort_order"], 3000)
        self.assertEqual(
            [subtask["title"] for subtask in fourth["subtasks"]],
            [subtask["title"] for subtask in reordered["subtasks"]] + ["Fourth"],
        )

    def test_subtasks_can_be_reordered(self) -> None:
        task = self.request_json("POST", "/api/tasks", {"title": "Plan release"})
        first = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "First"},
        )["subtasks"][0]
        second = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Second"},
        )["subtasks"][1]
        third = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks",
            {"title": "Third"},
        )["subtasks"][2]

        reordered = self.request_json(
            "POST",
            f"/api/tasks/{task['id']}/subtasks/reorder",
            {"subtask_ids": [third["id"], first["id"], second["id"]]},
        )

        self.assertEqual([subtask["title"] for subtask in reordered["subtasks"]], ["Third", "First", "Second"])
        self.assertEqual([subtask["sort_order"] for subtask in reordered["subtasks"]], [0, 1000, 2000])

    def test_mysql_noop_update_keeps_existing_record_valid(self) -> None:
        repository = FakeNoopUpdateRepository(record_exists=True)

        repository._update_record("tasks", 31, {"title": "Same title"})

    def test_mysql_noop_update_still_rejects_missing_record(self) -> None:
        repository = FakeNoopUpdateRepository(record_exists=False)

        with self.assertRaises(NotFoundError):
            repository._update_record("tasks", 31, {"title": "Same title"})

    def test_activity_search_filters_by_keyword_tag_and_date_range(self) -> None:
        self.request_json(
            "POST",
            "/api/activities",
            {
                "title": "Implement search",
                "tags": ["Dev"],
                "activity_date": "2026-04-30",
                "memo": "Added filters",
            },
        )
        self.request_json(
            "POST",
            "/api/activities",
            {
                "title": "Planning",
                "tags": ["admin"],
                "activity_date": "2026-05-02",
                "memo": "Roadmap",
            },
        )

        listed = self.request_json("GET", "/api/activities?q=filters&tag=dev&date_from=2026-04-01&date_to=2026-04-30")

        self.assertEqual(len(listed["items"]), 1)
        self.assertEqual(listed["items"][0]["title"], "Implement search")
        self.assertEqual(listed["items"][0]["tags"], ["dev"])

    def test_daily_note_export_writes_markdown_file(self) -> None:
        self.request_json(
            "POST",
            "/api/tasks",
            {"title": "Finish alarm app", "status": "done", "due_date": "2026-04-30"},
        )
        self.request_json(
            "POST",
            "/api/activities",
            {
                "title": "Build daily note export",
                "tags": ["dev"],
                "activity_date": "2026-04-30",
                "duration_minutes": 45,
                "memo": "Generated markdown.",
            },
        )

        result = self.request_json("POST", "/api/dailynotes/2026-04-30")

        daily_note_path = self.daily_note_dir / "2026-04-30.md"
        self.assertEqual(result["date"], "2026-04-30")
        self.assertTrue(daily_note_path.exists())
        contents = daily_note_path.read_text(encoding="utf-8")
        self.assertIn("# 2026-04-30 Daily Note", contents)
        self.assertIn("- Build daily note export (45m, #dev) - Generated markdown.", contents)
        self.assertIn("- [x] Finish alarm app", contents)

    def request_json(self, method: str, path: str, payload: Mapping[str, Any] | None = None) -> Any:
        request = self.build_request(method, path, payload)
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.loads(response.read().decode("utf-8"))

    def assert_http_error(
        self,
        method: str,
        path: str,
        status_code: int,
        payload: Mapping[str, Any] | None = None,
    ) -> None:
        request = self.build_request(method, path, payload)
        with self.assertRaises(urllib.error.HTTPError) as error_context:
            urllib.request.urlopen(request, timeout=5)
        self.assertEqual(error_context.exception.code, status_code)

    def build_request(
        self,
        method: str,
        path: str,
        payload: Mapping[str, Any] | None,
    ) -> urllib.request.Request:
        body = None
        headers = {"Content-Type": "application/json"}
        if payload is not None:
            body = json.dumps(payload).encode("utf-8")
        return urllib.request.Request(f"{self.base_url}{path}", data=body, headers=headers, method=method)


if __name__ == "__main__":
    unittest.main()
