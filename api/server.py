from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from datetime import date, datetime, time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Callable, Mapping
from urllib.parse import parse_qs, urlparse


ALLOWED_TASK_STATUSES = {"todo", "doing", "done", "cancelled"}
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def current_timestamp_text() -> str:
    return datetime.now().replace(microsecond=0).isoformat(sep=" ")


@dataclass(frozen=True)
class TaskSearchFilters:
    q: str | None = None
    status: str | None = None
    date_from: str | None = None
    date_to: str | None = None
    tag: str | None = None


@dataclass(frozen=True)
class ActivitySearchFilters:
    q: str | None = None
    category: str | None = None
    date_from: str | None = None
    date_to: str | None = None
    tag: str | None = None


class ValidationError(ValueError):
    pass


class NotFoundError(LookupError):
    pass


def json_default(value: Any) -> str:
    if isinstance(value, (date, datetime, time)):
        return value.isoformat()
    return str(value)


def parse_json_body(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    content_length = int(handler.headers.get("Content-Length", "0"))
    if content_length == 0:
        return {}
    raw_body = handler.rfile.read(content_length).decode("utf-8")
    try:
        data = json.loads(raw_body)
    except json.JSONDecodeError as error:
        raise ValidationError("Request body must be valid JSON") from error
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a JSON object")
    return data


def require_text(data: Mapping[str, Any], key: str) -> str:
    value = data.get(key)
    if value is None:
        raise ValidationError(f"{key} is required")
    text = str(value).strip()
    if not text:
        raise ValidationError(f"{key} must not be empty")
    return text


def optional_text(data: Mapping[str, Any], key: str) -> str | None:
    value = data.get(key)
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def optional_int(data: Mapping[str, Any], key: str) -> int | None:
    value = data.get(key)
    if value is None or value == "":
        return None
    try:
        parsed_value = int(value)
    except (TypeError, ValueError) as error:
        raise ValidationError(f"{key} must be an integer") from error
    if parsed_value < 0:
        raise ValidationError(f"{key} must be greater than or equal to 0")
    return parsed_value


def validate_date_text(value: str) -> str:
    if not DATE_PATTERN.match(value):
        raise ValidationError("Date must use YYYY-MM-DD format")
    try:
        date.fromisoformat(value)
    except ValueError as error:
        raise ValidationError("Date must be a valid calendar date") from error
    return value


def query_value(query: Mapping[str, list[str]], key: str) -> str | None:
    value = query.get(key, [None])[0]
    if value is None:
        return None
    text = value.strip()
    return text or None


def optional_query_date(query: Mapping[str, list[str]], key: str) -> str | None:
    value = query_value(query, key)
    if value is None:
        return None
    return validate_date_text(value)


def parse_task_search_filters(query: Mapping[str, list[str]]) -> TaskSearchFilters:
    status = query_value(query, "status")
    if status is not None and status not in ALLOWED_TASK_STATUSES:
        raise ValidationError("status must be one of todo, doing, done, cancelled")
    tag = query_value(query, "tag")
    return TaskSearchFilters(
        q=query_value(query, "q"),
        status=status,
        date_from=optional_query_date(query, "date_from"),
        date_to=optional_query_date(query, "date_to"),
        tag=normalize_tag_name(tag) if tag is not None else None,
    )


def parse_activity_search_filters(query: Mapping[str, list[str]]) -> ActivitySearchFilters:
    tag = query_value(query, "tag")
    return ActivitySearchFilters(
        q=query_value(query, "q"),
        category=query_value(query, "category"),
        date_from=optional_query_date(query, "date_from"),
        date_to=optional_query_date(query, "date_to"),
        tag=normalize_tag_name(tag) if tag is not None else None,
    )


def normalize_tag_name(value: Any) -> str:
    text = str(value).strip().lstrip("#").strip().lower()
    text = re.sub(r"\s+", " ", text)
    if not text:
        raise ValidationError("tag name must not be empty")
    if len(text) > 50:
        raise ValidationError("tag name must be 50 characters or fewer")
    return text


def normalize_tag_list(value: Any) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise ValidationError("tags must be a list")
    tags: list[str] = []
    seen_tags: set[str] = set()
    for raw_tag in value:
        tag = normalize_tag_name(raw_tag)
        if tag not in seen_tags:
            tags.append(tag)
            seen_tags.add(tag)
    return tags


def normalize_task_payload(data: Mapping[str, Any], partial: bool = False) -> dict[str, Any]:
    payload: dict[str, Any] = {}
    if not partial or "title" in data:
        payload["title"] = require_text(data, "title")
    if "detail" in data:
        payload["detail"] = optional_text(data, "detail")
    if "status" in data:
        status = require_text(data, "status")
        if status not in ALLOWED_TASK_STATUSES:
            raise ValidationError("status must be one of todo, doing, done, cancelled")
        payload["status"] = status
    elif not partial:
        payload["status"] = "todo"
    if "due_date" in data:
        payload["due_date"] = optional_text(data, "due_date")
    if "completed_at" in data:
        payload["completed_at"] = optional_text(data, "completed_at")
    if "sort_order" in data:
        payload["sort_order"] = optional_int(data, "sort_order")
    if "tags" in data:
        payload["tags"] = normalize_tag_list(data["tags"])
    if "status" in payload:
        if payload["status"] == "done":
            payload["completed_at"] = payload.get("completed_at") or current_timestamp_text()
        else:
            payload["completed_at"] = None
    if not payload:
        raise ValidationError("At least one field is required")
    return payload


def normalize_subtask_payload(data: Mapping[str, Any], partial: bool = False) -> dict[str, Any]:
    payload: dict[str, Any] = {}
    if not partial or "title" in data:
        payload["title"] = require_text(data, "title")
    if "is_done" in data:
        payload["is_done"] = bool(data["is_done"])
    elif not partial:
        payload["is_done"] = False
    if "sort_order" in data:
        payload["sort_order"] = optional_int(data, "sort_order") or 0
    if not payload:
        raise ValidationError("At least one field is required")
    return payload


def normalize_reorder_payload(data: Mapping[str, Any]) -> list[int]:
    raw_task_ids = data.get("task_ids")
    if not isinstance(raw_task_ids, list) or not raw_task_ids:
        raise ValidationError("task_ids must be a non-empty list")
    task_ids: list[int] = []
    for raw_task_id in raw_task_ids:
        try:
            task_id = int(raw_task_id)
        except (TypeError, ValueError) as error:
            raise ValidationError("task_ids must contain integers") from error
        if task_id <= 0:
            raise ValidationError("task_ids must contain positive integers")
        task_ids.append(task_id)
    if len(task_ids) != len(set(task_ids)):
        raise ValidationError("task_ids must not contain duplicates")
    return task_ids


def normalize_subtask_reorder_payload(data: Mapping[str, Any]) -> list[int]:
    raw_subtask_ids = data.get("subtask_ids")
    if not isinstance(raw_subtask_ids, list) or not raw_subtask_ids:
        raise ValidationError("subtask_ids must be a non-empty list")
    subtask_ids: list[int] = []
    for raw_subtask_id in raw_subtask_ids:
        try:
            subtask_id = int(raw_subtask_id)
        except (TypeError, ValueError) as error:
            raise ValidationError("subtask_ids must contain integers") from error
        if subtask_id <= 0:
            raise ValidationError("subtask_ids must contain positive integers")
        subtask_ids.append(subtask_id)
    if len(subtask_ids) != len(set(subtask_ids)):
        raise ValidationError("subtask_ids must not contain duplicates")
    return subtask_ids


def normalize_activity_payload(data: Mapping[str, Any], partial: bool = False) -> dict[str, Any]:
    payload: dict[str, Any] = {}
    if not partial or "title" in data:
        payload["title"] = require_text(data, "title")
    if "category" in data:
        payload["category"] = optional_text(data, "category")
    if not partial or "activity_date" in data:
        payload["activity_date"] = require_text(data, "activity_date")
    if "started_at" in data:
        payload["started_at"] = optional_text(data, "started_at")
    if "duration_minutes" in data:
        payload["duration_minutes"] = optional_int(data, "duration_minutes")
    if "memo" in data:
        payload["memo"] = optional_text(data, "memo")
    if "tags" in data:
        payload["tags"] = normalize_tag_list(data["tags"])
    if not payload:
        raise ValidationError("At least one field is required")
    return payload


@dataclass(frozen=True)
class DatabaseConfig:
    host: str
    port: int
    database: str
    user: str
    password: str

    @classmethod
    def from_env(cls) -> "DatabaseConfig":
        return cls(
            host=os.getenv("MYSQL_HOST", "127.0.0.1"),
            port=int(os.getenv("MYSQL_PORT", "3306")),
            database=os.getenv("MYSQL_DATABASE", "alarmapp"),
            user=os.getenv("MYSQL_USER", "alarmapp"),
            password=os.getenv("MYSQL_PASSWORD", "alarmapp_password"),
        )


class MysqlRepository:
    def __init__(self, config: DatabaseConfig):
        self.config = config

    def _connect(self) -> Any:
        import pymysql
        import pymysql.cursors

        return pymysql.connect(
            host=self.config.host,
            port=self.config.port,
            user=self.config.user,
            password=self.config.password,
            database=self.config.database,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
        )

    def _column_exists(self, cursor: Any, table_name: str, column_name: str) -> bool:
        cursor.execute(
            """
            SELECT COUNT(*) AS column_count
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s
            """,
            (self.config.database, table_name, column_name),
        )
        row = cursor.fetchone()
        return bool(row and row.get("column_count", 0) > 0)

    def _index_exists(self, cursor: Any, table_name: str, index_name: str) -> bool:
        cursor.execute(
            """
            SELECT COUNT(*) AS index_count
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND INDEX_NAME = %s
            """,
            (self.config.database, table_name, index_name),
        )
        row = cursor.fetchone()
        return bool(row and row.get("index_count", 0) > 0)

    def ensure_schema(self) -> None:
        with self._connect() as connection:
            with connection.cursor() as cursor:
                # MySQL RDS는 "ADD COLUMN IF NOT EXISTS" 문법을 지원하지 않는다.
                if not self._column_exists(cursor, "tasks", "sort_order"):
                    cursor.execute(
                        "ALTER TABLE tasks ADD COLUMN sort_order INT NOT NULL DEFAULT 0",
                    )
                if not self._column_exists(cursor, "tasks", "completed_at"):
                    cursor.execute(
                        "ALTER TABLE tasks ADD COLUMN completed_at DATETIME NULL",
                    )
                if not self._index_exists(cursor, "tasks", "idx_tasks_sort_order"):
                    cursor.execute(
                        "ALTER TABLE tasks ADD INDEX idx_tasks_sort_order (sort_order)",
                    )
                if not self._index_exists(cursor, "tasks", "idx_tasks_completed_at"):
                    cursor.execute(
                        "ALTER TABLE tasks ADD INDEX idx_tasks_completed_at (completed_at)",
                    )
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS tags (
                      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                      name VARCHAR(50) NOT NULL,
                      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                      PRIMARY KEY (id),
                      UNIQUE KEY uq_tags_name (name)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                    """,
                )
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS task_tags (
                      task_id BIGINT UNSIGNED NOT NULL,
                      tag_id BIGINT UNSIGNED NOT NULL,
                      PRIMARY KEY (task_id, tag_id),
                      KEY idx_task_tags_tag_id (tag_id),
                      CONSTRAINT fk_task_tags_task_id FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
                      CONSTRAINT fk_task_tags_tag_id FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                    """,
                )
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS task_subtasks (
                      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                      task_id BIGINT UNSIGNED NOT NULL,
                      title VARCHAR(255) NOT NULL,
                      is_done BOOLEAN NOT NULL DEFAULT FALSE,
                      sort_order INT NOT NULL DEFAULT 0,
                      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                      PRIMARY KEY (id),
                      KEY idx_task_subtasks_task_id (task_id),
                      KEY idx_task_subtasks_sort_order (sort_order),
                      CONSTRAINT fk_task_subtasks_task_id FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                    """,
                )
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS activity_tags (
                      activity_id BIGINT UNSIGNED NOT NULL,
                      tag_id BIGINT UNSIGNED NOT NULL,
                      PRIMARY KEY (activity_id, tag_id),
                      KEY idx_activity_tags_tag_id (tag_id),
                      CONSTRAINT fk_activity_tags_activity_id FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE,
                      CONSTRAINT fk_activity_tags_tag_id FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                    """,
                )
                self._migrate_activity_categories_to_tags(cursor)

    def list_tasks(
        self,
        due_date: str | None = None,
        filters: TaskSearchFilters | None = None,
    ) -> list[dict[str, Any]]:
        query = "SELECT * FROM tasks"
        where_clauses: list[str] = []
        params: list[Any] = []
        if due_date:
            where_clauses.append("due_date = %s")
            params.append(due_date)
        if filters is not None:
            if filters.q:
                where_clauses.append("(title LIKE %s OR detail LIKE %s)")
                search_text = f"%{filters.q}%"
                params.extend([search_text, search_text])
            if filters.status:
                where_clauses.append("status = %s")
                params.append(filters.status)
            if filters.date_from:
                where_clauses.append("COALESCE(due_date, DATE(created_at)) >= %s")
                params.append(filters.date_from)
            if filters.date_to:
                where_clauses.append("COALESCE(due_date, DATE(created_at)) <= %s")
                params.append(filters.date_to)
            if filters.tag:
                where_clauses.append(
                    """
                    EXISTS (
                      SELECT 1
                      FROM task_tags
                      INNER JOIN tags ON tags.id = task_tags.tag_id
                      WHERE task_tags.task_id = tasks.id AND tags.name = %s
                    )
                    """,
                )
                params.append(filters.tag)
        if where_clauses:
            query += " WHERE " + " AND ".join(where_clauses)
        query += " ORDER BY sort_order ASC, created_at DESC, id DESC"
        return self._attach_task_subtasks(self._attach_task_tags(self._fetch_all(query, tuple(params))))

    def list_tasks_for_dailynote(self, note_date: str) -> list[dict[str, Any]]:
        return self._attach_task_subtasks(self._attach_task_tags(self._fetch_all(
            """
            SELECT * FROM tasks
            WHERE due_date = %s OR (due_date IS NULL AND DATE(created_at) = %s)
            ORDER BY status = 'done', sort_order ASC, created_at ASC, id ASC
            """,
            (note_date, note_date),
        )))

    def create_task(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        tags = payload.get("tags", [])
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO tasks (title, detail, status, due_date, completed_at, sort_order)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        payload["title"],
                        payload.get("detail"),
                        payload.get("status", "todo"),
                        payload.get("due_date"),
                        payload.get("completed_at"),
                        payload.get("sort_order", 0),
                    ),
                )
                task_id = int(cursor.lastrowid)
                self._replace_task_tags(cursor, task_id, tags)
                return self.get_task(task_id)

    def get_task(self, task_id: int) -> dict[str, Any]:
        rows = self._attach_task_subtasks(self._attach_task_tags(self._fetch_all("SELECT * FROM tasks WHERE id = %s", (task_id,))))
        if not rows:
            raise NotFoundError("Task not found")
        return rows[0]

    def update_task(self, task_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        payload_data = dict(payload)
        has_tags = "tags" in payload_data
        tags = payload_data.pop("tags", [])
        if payload_data:
            self._update_record("tasks", task_id, payload_data)
        else:
            self.get_task(task_id)
        if has_tags:
            with self._connect() as connection:
                with connection.cursor() as cursor:
                    self._replace_task_tags(cursor, task_id, tags)
        return self.get_task(task_id)

    def delete_task(self, task_id: int) -> None:
        self._delete_record("tasks", task_id)

    def reorder_tasks(self, task_ids: list[int]) -> list[dict[str, Any]]:
        with self._connect() as connection:
            with connection.cursor() as cursor:
                placeholders = ", ".join(["%s"] * len(task_ids))
                cursor.execute(f"SELECT id FROM tasks WHERE id IN ({placeholders})", tuple(task_ids))
                existing_task_ids = {int(row["id"]) for row in cursor.fetchall()}
                if existing_task_ids != set(task_ids):
                    raise NotFoundError("Task not found")
                for index, task_id in enumerate(task_ids):
                    cursor.execute("UPDATE tasks SET sort_order = %s WHERE id = %s", (index * 1000, task_id))
        return self.list_tasks()

    def _next_subtask_sort_order(self, task_id: int) -> int:
        rows = self._fetch_all(
            """
            SELECT sort_order
            FROM task_subtasks
            WHERE task_id = %s
            ORDER BY sort_order DESC, id DESC
            LIMIT 1
            """,
            (task_id,),
        )
        if not rows:
            return 0
        return int(rows[0]["sort_order"]) + 1000

    def create_subtask(self, task_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        self.get_task(task_id)
        sort_order = (
            payload["sort_order"]
            if "sort_order" in payload
            else self._next_subtask_sort_order(task_id)
        )
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO task_subtasks (task_id, title, is_done, sort_order)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        task_id,
                        payload["title"],
                        payload.get("is_done", False),
                        sort_order,
                    ),
                )
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def update_subtask(self, task_id: int, subtask_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        self.get_task(task_id)
        assignments = ", ".join(f"{field_name} = %s" for field_name in payload)
        values = tuple(payload.values()) + (task_id, subtask_id)
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    f"UPDATE task_subtasks SET {assignments} WHERE task_id = %s AND id = %s",
                    values,
                )
                if cursor.rowcount == 0:
                    cursor.execute("SELECT id FROM task_subtasks WHERE task_id = %s AND id = %s", (task_id, subtask_id))
                    if cursor.fetchone() is None:
                        raise NotFoundError("Subtask not found")
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def delete_subtask(self, task_id: int, subtask_id: int) -> dict[str, Any]:
        self.get_task(task_id)
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM task_subtasks WHERE task_id = %s AND id = %s", (task_id, subtask_id))
                if cursor.rowcount == 0:
                    raise NotFoundError("Subtask not found")
        self._sync_task_completion_from_subtasks(task_id)
        return self.get_task(task_id)

    def reorder_subtasks(self, task_id: int, subtask_ids: list[int]) -> dict[str, Any]:
        self.get_task(task_id)
        with self._connect() as connection:
            with connection.cursor() as cursor:
                placeholders = ", ".join(["%s"] * len(subtask_ids))
                cursor.execute(
                    f"SELECT id FROM task_subtasks WHERE task_id = %s AND id IN ({placeholders})",
                    (task_id, *subtask_ids),
                )
                existing_subtask_ids = {int(row["id"]) for row in cursor.fetchall()}
                if existing_subtask_ids != set(subtask_ids):
                    raise NotFoundError("Subtask not found")
                for index, subtask_id in enumerate(subtask_ids):
                    cursor.execute(
                        "UPDATE task_subtasks SET sort_order = %s WHERE task_id = %s AND id = %s",
                        (index * 1000, task_id, subtask_id),
                    )
        return self.get_task(task_id)

    def _attach_task_tags(self, tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not tasks:
            return tasks
        task_ids = [int(task["id"]) for task in tasks]
        placeholders = ", ".join(["%s"] * len(task_ids))
        rows = self._fetch_all(
            f"""
            SELECT task_tags.task_id, tags.name
            FROM task_tags
            INNER JOIN tags ON tags.id = task_tags.tag_id
            WHERE task_tags.task_id IN ({placeholders})
            ORDER BY tags.name ASC
            """,
            tuple(task_ids),
        )
        tags_by_task_id: dict[int, list[str]] = {task_id: [] for task_id in task_ids}
        for row in rows:
            tags_by_task_id[int(row["task_id"])].append(str(row["name"]))
        for task in tasks:
            task["tags"] = tags_by_task_id.get(int(task["id"]), [])
        return tasks

    def _attach_task_subtasks(self, tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not tasks:
            return tasks
        task_ids = [int(task["id"]) for task in tasks]
        placeholders = ", ".join(["%s"] * len(task_ids))
        rows = self._fetch_all(
            f"""
            SELECT id, task_id, title, is_done, sort_order, created_at, updated_at
            FROM task_subtasks
            WHERE task_id IN ({placeholders})
            ORDER BY sort_order ASC, created_at ASC, id ASC
            """,
            tuple(task_ids),
        )
        subtasks_by_task_id: dict[int, list[dict[str, Any]]] = {task_id: [] for task_id in task_ids}
        for row in rows:
            row["is_done"] = bool(row["is_done"])
            subtasks_by_task_id[int(row["task_id"])].append(row)
        for task in tasks:
            task["subtasks"] = subtasks_by_task_id.get(int(task["id"]), [])
        return tasks

    def _sync_task_completion_from_subtasks(self, task_id: int) -> None:
        rows = self._fetch_all(
            """
            SELECT COUNT(*) AS total_count, SUM(is_done = TRUE) AS done_count
            FROM task_subtasks
            WHERE task_id = %s
            """,
            (task_id,),
        )
        total_count = int(rows[0]["total_count"]) if rows else 0
        done_count = int(rows[0]["done_count"] or 0) if rows else 0
        if total_count == 0:
            return
        if done_count == total_count:
            self._update_record("tasks", task_id, {"status": "done", "completed_at": current_timestamp_text()})
        else:
            self._update_record("tasks", task_id, {"status": "todo", "completed_at": None})

    def _replace_task_tags(self, cursor: Any, task_id: int, tags: list[str]) -> None:
        cursor.execute("DELETE FROM task_tags WHERE task_id = %s", (task_id,))
        for tag in tags:
            cursor.execute("INSERT IGNORE INTO tags (name) VALUES (%s)", (tag,))
            cursor.execute("SELECT id FROM tags WHERE name = %s", (tag,))
            row = cursor.fetchone()
            if row is None:
                raise ValidationError(f"Tag not found after insert: {tag}")
            cursor.execute("INSERT IGNORE INTO task_tags (task_id, tag_id) VALUES (%s, %s)", (task_id, row["id"]))

    def list_activities(
        self,
        activity_date: str | None = None,
        filters: ActivitySearchFilters | None = None,
    ) -> list[dict[str, Any]]:
        query = "SELECT * FROM activities"
        where_clauses: list[str] = []
        params: list[Any] = []
        if activity_date:
            where_clauses.append("activity_date = %s")
            params.append(activity_date)
        if filters is not None:
            if filters.q:
                where_clauses.append(
                    """
                    (
                      title LIKE %s
                      OR category LIKE %s
                      OR memo LIKE %s
                      OR EXISTS (
                        SELECT 1
                        FROM activity_tags
                        INNER JOIN tags ON tags.id = activity_tags.tag_id
                        WHERE activity_tags.activity_id = activities.id AND tags.name LIKE %s
                      )
                    )
                    """,
                )
                search_text = f"%{filters.q}%"
                params.extend([search_text, search_text, search_text, search_text])
            if filters.category:
                where_clauses.append("category = %s")
                params.append(filters.category)
            if filters.date_from:
                where_clauses.append("activity_date >= %s")
                params.append(filters.date_from)
            if filters.date_to:
                where_clauses.append("activity_date <= %s")
                params.append(filters.date_to)
            if filters.tag:
                where_clauses.append(
                    """
                    EXISTS (
                      SELECT 1
                      FROM activity_tags
                      INNER JOIN tags ON tags.id = activity_tags.tag_id
                      WHERE activity_tags.activity_id = activities.id AND tags.name = %s
                    )
                    """,
                )
                params.append(filters.tag)
        if where_clauses:
            query += " WHERE " + " AND ".join(where_clauses)
        query += " ORDER BY activity_date DESC, started_at DESC, id DESC"
        return self._attach_activity_tags(self._fetch_all(query, tuple(params)))

    def create_activity(self, payload: Mapping[str, Any]) -> dict[str, Any]:
        tags = self._activity_tags_from_payload(payload)
        category = tags[0] if tags else payload.get("category")
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO activities
                      (title, category, activity_date, started_at, duration_minutes, memo)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        payload["title"],
                        category,
                        payload["activity_date"],
                        payload.get("started_at"),
                        payload.get("duration_minutes"),
                        payload.get("memo"),
                    ),
                )
                activity_id = int(cursor.lastrowid)
                self._replace_activity_tags(cursor, activity_id, tags)
                return self.get_activity(activity_id)

    def get_activity(self, activity_id: int) -> dict[str, Any]:
        rows = self._attach_activity_tags(self._fetch_all("SELECT * FROM activities WHERE id = %s", (activity_id,)))
        if not rows:
            raise NotFoundError("Activity not found")
        return rows[0]

    def update_activity(self, activity_id: int, payload: Mapping[str, Any]) -> dict[str, Any]:
        payload_data = dict(payload)
        has_tags = "tags" in payload_data
        tags = self._activity_tags_from_payload(payload_data) if has_tags else []
        payload_data.pop("tags", None)
        if has_tags:
            payload_data["category"] = tags[0] if tags else None
        if payload_data:
            self._update_record("activities", activity_id, payload_data)
        else:
            self.get_activity(activity_id)
        if has_tags:
            with self._connect() as connection:
                with connection.cursor() as cursor:
                    self._replace_activity_tags(cursor, activity_id, tags)
        return self.get_activity(activity_id)

    def delete_activity(self, activity_id: int) -> None:
        self._delete_record("activities", activity_id)

    def _fetch_all(self, query: str, params: tuple[Any, ...]) -> list[dict[str, Any]]:
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, params)
                return list(cursor.fetchall())

    def _attach_activity_tags(self, activities: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not activities:
            return activities
        activity_ids = [int(activity["id"]) for activity in activities]
        placeholders = ", ".join(["%s"] * len(activity_ids))
        rows = self._fetch_all(
            f"""
            SELECT activity_tags.activity_id, tags.name
            FROM activity_tags
            INNER JOIN tags ON tags.id = activity_tags.tag_id
            WHERE activity_tags.activity_id IN ({placeholders})
            ORDER BY tags.name ASC
            """,
            tuple(activity_ids),
        )
        tags_by_activity_id: dict[int, list[str]] = {activity_id: [] for activity_id in activity_ids}
        for row in rows:
            tags_by_activity_id[int(row["activity_id"])].append(str(row["name"]))
        for activity in activities:
            activity["tags"] = tags_by_activity_id.get(int(activity["id"]), [])
        return activities

    def _replace_activity_tags(self, cursor: Any, activity_id: int, tags: list[str]) -> None:
        cursor.execute("DELETE FROM activity_tags WHERE activity_id = %s", (activity_id,))
        for tag in tags:
            cursor.execute("INSERT IGNORE INTO tags (name) VALUES (%s)", (tag,))
            cursor.execute("SELECT id FROM tags WHERE name = %s", (tag,))
            row = cursor.fetchone()
            if row is None:
                raise ValidationError(f"Tag not found after insert: {tag}")
            cursor.execute("INSERT IGNORE INTO activity_tags (activity_id, tag_id) VALUES (%s, %s)", (activity_id, row["id"]))

    def _activity_tags_from_payload(self, payload: Mapping[str, Any]) -> list[str]:
        if "tags" in payload:
            return list(payload["tags"])
        category = payload.get("category")
        return [normalize_tag_name(category)] if category else []

    def _migrate_activity_categories_to_tags(self, cursor: Any) -> None:
        cursor.execute(
            """
            INSERT IGNORE INTO tags (name)
            SELECT DISTINCT LOWER(TRIM(LEADING '#' FROM TRIM(category)))
            FROM activities
            WHERE category IS NOT NULL AND TRIM(category) <> ''
            """,
        )
        cursor.execute(
            """
            INSERT IGNORE INTO activity_tags (activity_id, tag_id)
            SELECT activities.id, tags.id
            FROM activities
            INNER JOIN tags
              ON tags.name = LOWER(TRIM(LEADING '#' FROM TRIM(activities.category)))
            WHERE activities.category IS NOT NULL AND TRIM(activities.category) <> ''
            """,
        )

    def _update_record(self, table_name: str, record_id: int, payload: Mapping[str, Any]) -> None:
        if table_name not in {"tasks", "activities"}:
            raise ValidationError("Unsupported table")
        assignments = ", ".join(f"{field_name} = %s" for field_name in payload)
        values = tuple(payload.values()) + (record_id,)
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(f"UPDATE {table_name} SET {assignments} WHERE id = %s", values)
                if cursor.rowcount == 0:
                    cursor.execute(f"SELECT id FROM {table_name} WHERE id = %s", (record_id,))
                    if cursor.fetchone() is None:
                        raise NotFoundError(f"{table_name[:-1].title()} not found")

    def _delete_record(self, table_name: str, record_id: int) -> None:
        if table_name not in {"tasks", "activities"}:
            raise ValidationError("Unsupported table")
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(f"DELETE FROM {table_name} WHERE id = %s", (record_id,))
                if cursor.rowcount == 0:
                    raise NotFoundError(f"{table_name[:-1].title()} not found")


def build_daily_note_markdown(
    note_date: str,
    activities: list[Mapping[str, Any]],
    tasks: list[Mapping[str, Any]],
) -> str:
    lines = [
        f"# {note_date} Daily Note",
        "",
        "## Activities",
        "",
    ]
    if activities:
        for activity in activities:
            lines.append(format_activity_line(activity))
    else:
        lines.append("- No activities recorded.")

    lines.extend(["", "## Tasks", ""])
    if tasks:
        for task in tasks:
            lines.append(format_task_line(task))
            for subtask in task.get("subtasks", []):
                lines.append(format_subtask_line(subtask))
    else:
        lines.append("- No tasks recorded.")

    lines.append("")
    return "\n".join(lines)


def format_activity_line(activity: Mapping[str, Any]) -> str:
    details = []
    if activity.get("started_at"):
        details.append(str(activity["started_at"]))
    if activity.get("duration_minutes") is not None:
        details.append(f"{activity['duration_minutes']}m")
    if activity.get("tags"):
        details.append(" ".join(f"#{tag}" for tag in activity["tags"]))
    suffix = f" ({', '.join(details)})" if details else ""
    memo = f" - {activity['memo']}" if activity.get("memo") else ""
    return f"- {activity['title']}{suffix}{memo}"


def format_task_line(task: Mapping[str, Any]) -> str:
    checkbox = "x" if task.get("status") == "done" else " "
    tags = " ".join(f"#{tag}" for tag in task.get("tags", []))
    tag_text = f" {tags}" if tags else ""
    detail = f" - {task['detail']}" if task.get("detail") else ""
    return f"- [{checkbox}] {task['title']}{tag_text}{detail}"


def format_subtask_line(subtask: Mapping[str, Any]) -> str:
    checkbox = "x" if subtask.get("is_done") else " "
    return f"  - [{checkbox}] {subtask['title']}"


def write_daily_note(
    repository: Any,
    note_date: str,
    daily_note_dir: Path,
) -> dict[str, Any]:
    validated_date = validate_date_text(note_date)
    activities = repository.list_activities(validated_date)
    if hasattr(repository, "list_tasks_for_dailynote"):
        tasks = repository.list_tasks_for_dailynote(validated_date)
    else:
        tasks = repository.list_tasks(validated_date)

    daily_note_dir.mkdir(parents=True, exist_ok=True)
    file_path = daily_note_dir / f"{validated_date}.md"
    file_path.write_text(
        build_daily_note_markdown(validated_date, activities, tasks),
        encoding="utf-8",
    )
    return {
        "date": validated_date,
        "path": str(file_path),
        "activity_count": len(activities),
        "task_count": len(tasks),
    }


def parse_record_id(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except ValueError as error:
        raise NotFoundError("Route not found") from error


class AlarmappRequestHandler(BaseHTTPRequestHandler):
    repository_factory: Callable[[], MysqlRepository]
    daily_note_dir: Path

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self) -> None:
        self._handle_request("GET")

    def do_POST(self) -> None:
        self._handle_request("POST")

    def do_PUT(self) -> None:
        self._handle_request("PUT")

    def do_DELETE(self) -> None:
        self._handle_request("DELETE")

    def _handle_request(self, method: str) -> None:
        try:
            parsed_url = urlparse(self.path)
            path_parts = [part for part in parsed_url.path.split("/") if part]
            query = parse_qs(parsed_url.query)
            result, status = self._dispatch(method, path_parts, query)
            self._write_json(result, status)
        except ValidationError as error:
            self._write_json({"error": str(error)}, HTTPStatus.BAD_REQUEST)
        except NotFoundError as error:
            self._write_json({"error": str(error)}, HTTPStatus.NOT_FOUND)
        except Exception as error:
            self._write_json({"error": f"Internal server error: {error}"}, HTTPStatus.INTERNAL_SERVER_ERROR)

    def _dispatch(
        self,
        method: str,
        path_parts: list[str],
        query: Mapping[str, list[str]],
    ) -> tuple[Any, HTTPStatus]:
        repository = self.repository_factory()
        if path_parts == ["health"] and method == "GET":
            return {"status": "ok"}, HTTPStatus.OK
        if len(path_parts) < 2 or path_parts[0] != "api":
            raise NotFoundError("Route not found")
        resource_name = path_parts[1]
        record_id_text = path_parts[2] if len(path_parts) >= 3 else None
        if resource_name == "tasks":
            if record_id_text == "reorder":
                return self._dispatch_task_reorder(repository, method)
            if len(path_parts) >= 4 and path_parts[3] == "subtasks":
                if len(path_parts) > 5:
                    raise NotFoundError("Subtask route not found")
                if len(path_parts) == 5 and path_parts[4] == "reorder":
                    return self._dispatch_subtask_reorder(
                        repository,
                        method,
                        parse_record_id(record_id_text),
                    )
                return self._dispatch_task_subtasks(
                    repository,
                    method,
                    parse_record_id(record_id_text),
                    parse_record_id(path_parts[4] if len(path_parts) == 5 else None),
                )
            if len(path_parts) > 3:
                raise NotFoundError("Task route not found")
            return self._dispatch_tasks(repository, method, parse_record_id(record_id_text), query)
        if resource_name == "activities":
            return self._dispatch_activities(repository, method, parse_record_id(record_id_text), query)
        if resource_name == "dailynotes":
            return self._dispatch_dailynotes(repository, method, record_id_text)
        raise NotFoundError("Route not found")

    def _dispatch_tasks(
        self,
        repository: MysqlRepository,
        method: str,
        task_id: int | None,
        query: Mapping[str, list[str]],
    ) -> tuple[Any, HTTPStatus]:
        if method == "GET" and task_id is None:
            due_date = optional_query_date(query, "due_date")
            filters = parse_task_search_filters(query)
            return {"items": repository.list_tasks(due_date, filters)}, HTTPStatus.OK
        if method == "POST" and task_id is None:
            return repository.create_task(normalize_task_payload(parse_json_body(self))), HTTPStatus.CREATED
        if task_id is None:
            raise NotFoundError("Task route not found")
        if method == "GET":
            return repository.get_task(task_id), HTTPStatus.OK
        if method == "PUT":
            return repository.update_task(task_id, normalize_task_payload(parse_json_body(self), partial=True)), HTTPStatus.OK
        if method == "DELETE":
            repository.delete_task(task_id)
            return {"deleted": True}, HTTPStatus.OK
        raise NotFoundError("Task route not found")

    def _dispatch_task_reorder(
        self,
        repository: MysqlRepository,
        method: str,
    ) -> tuple[Any, HTTPStatus]:
        if method != "POST":
            raise NotFoundError("Task reorder route not found")
        task_ids = normalize_reorder_payload(parse_json_body(self))
        return {"items": repository.reorder_tasks(task_ids)}, HTTPStatus.OK

    def _dispatch_subtask_reorder(
        self,
        repository: MysqlRepository,
        method: str,
        task_id: int | None,
    ) -> tuple[Any, HTTPStatus]:
        if method != "POST" or task_id is None:
            raise NotFoundError("Subtask reorder route not found")
        subtask_ids = normalize_subtask_reorder_payload(parse_json_body(self))
        return repository.reorder_subtasks(task_id, subtask_ids), HTTPStatus.OK

    def _dispatch_task_subtasks(
        self,
        repository: MysqlRepository,
        method: str,
        task_id: int | None,
        subtask_id: int | None,
    ) -> tuple[Any, HTTPStatus]:
        if task_id is None:
            raise NotFoundError("Task route not found")
        if method == "POST" and subtask_id is None:
            return repository.create_subtask(
                task_id,
                normalize_subtask_payload(parse_json_body(self)),
            ), HTTPStatus.CREATED
        if subtask_id is None:
            raise NotFoundError("Subtask route not found")
        if method == "PUT":
            return repository.update_subtask(
                task_id,
                subtask_id,
                normalize_subtask_payload(parse_json_body(self), partial=True),
            ), HTTPStatus.OK
        if method == "DELETE":
            return repository.delete_subtask(task_id, subtask_id), HTTPStatus.OK
        raise NotFoundError("Subtask route not found")

    def _dispatch_activities(
        self,
        repository: MysqlRepository,
        method: str,
        activity_id: int | None,
        query: Mapping[str, list[str]],
    ) -> tuple[Any, HTTPStatus]:
        if method == "GET" and activity_id is None:
            activity_date = optional_query_date(query, "activity_date")
            filters = parse_activity_search_filters(query)
            return {"items": repository.list_activities(activity_date, filters)}, HTTPStatus.OK
        if method == "POST" and activity_id is None:
            return repository.create_activity(normalize_activity_payload(parse_json_body(self))), HTTPStatus.CREATED
        if activity_id is None:
            raise NotFoundError("Activity route not found")
        if method == "GET":
            return repository.get_activity(activity_id), HTTPStatus.OK
        if method == "PUT":
            return repository.update_activity(
                activity_id,
                normalize_activity_payload(parse_json_body(self), partial=True),
            ), HTTPStatus.OK
        if method == "DELETE":
            repository.delete_activity(activity_id)
            return {"deleted": True}, HTTPStatus.OK
        raise NotFoundError("Activity route not found")

    def _dispatch_dailynotes(
        self,
        repository: MysqlRepository,
        method: str,
        note_date: str | None,
    ) -> tuple[Any, HTTPStatus]:
        if method != "POST" or note_date is None:
            raise NotFoundError("Daily note route not found")
        return write_daily_note(repository, note_date, self.daily_note_dir), HTTPStatus.OK

    def _write_json(self, payload: Any, status: HTTPStatus) -> None:
        body = json.dumps(payload, ensure_ascii=False, default=json_default).encode("utf-8")
        self.send_response(status)
        self._send_cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def log_message(self, format: str, *args: Any) -> None:
        return


def create_handler(
    repository_factory: Callable[[], MysqlRepository],
    daily_note_dir: Path | None = None,
) -> type[AlarmappRequestHandler]:
    class ConfiguredAlarmappRequestHandler(AlarmappRequestHandler):
        pass

    ConfiguredAlarmappRequestHandler.repository_factory = staticmethod(repository_factory)
    ConfiguredAlarmappRequestHandler.daily_note_dir = daily_note_dir or Path(
        os.getenv("DAILYNOTE_DIR", "/dailynote"),
    )
    return ConfiguredAlarmappRequestHandler


def run() -> None:
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    config = DatabaseConfig.from_env()
    repository = MysqlRepository(config)
    repository.ensure_schema()
    handler = create_handler(lambda: MysqlRepository(config))
    server = ThreadingHTTPServer((host, port), handler)
    print(f"alarmapp API listening on http://{host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    run()
