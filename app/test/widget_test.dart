import 'package:alarmapp_local/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAlarmApiClient extends AlarmApiClient {
  const FakeAlarmApiClient() : super(baseUrl: 'http://test.local');

  @override
  Future<List<TaskItem>> fetchTasks() async {
    final today = _todayDateText();
    return [
      TaskItem(
        id: 1,
        title: '테스트 할일',
        status: 'todo',
        createdAt: '${today}T00:00:00Z',
        sortOrder: 0,
        tags: const ['dev'],
      ),
      TaskItem(
        id: 2,
        title: '완료한 테스트 할일',
        status: 'done',
        completedAt: '${today}T12:30:00Z',
        createdAt: '${today}T00:00:00Z',
        sortOrder: 1000,
        tags: const ['done'],
      ),
    ];
  }

  @override
  Future<List<TaskItem>> searchTasks({
    String? keyword,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    return fetchTasks();
  }

  @override
  Future<List<TaskItem>> reorderTasks(List<int> taskIds) async {
    return fetchTasks();
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    if (task.status == 'done') {
      return task.copyWith(completedAt: '${_todayDateText()}T12:30:00Z');
    }
    return task;
  }

  @override
  Future<List<ActivityRecord>> fetchActivities() async {
    return [
      ActivityRecord(
        id: 1,
        title: '테스트 활동',
        activityDate: _todayDateText(),
        durationMinutes: 25,
        tags: ['dev'],
      ),
    ];
  }

  @override
  Future<List<ActivityRecord>> searchActivities({
    String? keyword,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    return fetchActivities();
  }
}

class MutableFakeAlarmApiClient extends AlarmApiClient {
  MutableFakeAlarmApiClient(this.tasks) : super(baseUrl: 'http://test.local');

  List<TaskItem> tasks;
  int nextSubtaskId = 1;

  @override
  Future<List<TaskItem>> fetchTasks() async {
    return tasks;
  }

  @override
  Future<List<ActivityRecord>> fetchActivities() async {
    return const [];
  }

  @override
  Future<List<TaskItem>> searchTasks({
    String? keyword,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    return tasks;
  }

  @override
  Future<List<ActivityRecord>> searchActivities({
    String? keyword,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    return const [];
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    final updatedTask = task.status == 'done'
        ? task.copyWith(completedAt: '${_todayDateText()}T13:00:00Z')
        : task.copyWith(clearCompletedAt: true);
    tasks = tasks
        .map((item) => item.id == updatedTask.id ? updatedTask : item)
        .toList();
    return updatedTask;
  }

  @override
  Future<TaskItem> createSubtask(int taskId, String title) async {
    final task = tasks.singleWhere((item) => item.id == taskId);
    final subtask = TaskSubtask(
      id: nextSubtaskId,
      taskId: taskId,
      title: title,
      isDone: false,
      sortOrder: task.subtasks.length * 1000,
    );
    nextSubtaskId += 1;
    return _saveTask(task.copyWith(subtasks: [...task.subtasks, subtask]));
  }

  @override
  Future<TaskItem> updateSubtask(
    int taskId,
    TaskSubtask subtask, {
    String? title,
    bool? isDone,
  }) async {
    final task = tasks.singleWhere((item) => item.id == taskId);
    final updatedSubtasks = [
      for (final item in task.subtasks)
        item.id == subtask.id
            ? item.copyWith(title: title, isDone: isDone)
            : item,
    ];
    final completedCount = updatedSubtasks.where((item) => item.isDone).length;
    final isComplete =
        updatedSubtasks.isNotEmpty && completedCount == updatedSubtasks.length;
    return _saveTask(
      task.copyWith(
        status: isComplete ? 'done' : 'todo',
        completedAt: isComplete ? '${_todayDateText()}T13:00:00Z' : null,
        clearCompletedAt: !isComplete,
        subtasks: updatedSubtasks,
      ),
    );
  }

  @override
  Future<TaskItem> deleteSubtask(int taskId, int subtaskId) async {
    final task = tasks.singleWhere((item) => item.id == taskId);
    final updatedSubtasks =
        task.subtasks.where((item) => item.id != subtaskId).toList();
    return _saveTask(task.copyWith(subtasks: updatedSubtasks));
  }

  @override
  Future<TaskItem> reorderSubtasks(int taskId, List<int> subtaskIds) async {
    final task = tasks.singleWhere((item) => item.id == taskId);
    final subtasksById = {
      for (final subtask in task.subtasks) subtask.id: subtask,
    };
    final reorderedSubtasks = [
      for (var index = 0; index < subtaskIds.length; index++)
        subtasksById[subtaskIds[index]]!.copyWith(sortOrder: index * 1000),
    ];
    return _saveTask(task.copyWith(subtasks: reorderedSubtasks));
  }

  TaskItem _saveTask(TaskItem updatedTask) {
    tasks = tasks
        .map((item) => item.id == updatedTask.id ? updatedTask : item)
        .toList();
    return updatedTask;
  }

  @override
  Future<List<TaskItem>> reorderTasks(List<int> taskIds) async {
    return tasks;
  }
}

String _todayDateText() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

void main() {
  testWidgets('renders timer and stored records', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlarmHomePage(apiClient: FakeAlarmApiClient()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '알림 사운드 활성화'));
    await tester.pumpAndSettle();

    expect(find.text('지금뭐해'), findsOneWidget);
    expect(find.text('테스트 할일'), findsOneWidget);
    expect(find.text('오늘 먼저 할 일'), findsOneWidget);
    expect(find.text('인박스 / 나중에 할 일'), findsOneWidget);
    expect(find.text('인박스가 비어 있습니다.'), findsOneWidget);
    expect(find.text('#dev'), findsWidgets);
    expect(find.byIcon(Icons.drag_handle), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmHomePage(
          key: UniqueKey(),
          apiClient: const FakeAlarmApiClient(),
          initialTabIndex: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final audioButton = find.widgetWithText(FilledButton, '알림 사운드 활성화');
    if (audioButton.evaluate().isNotEmpty) {
      await tester.tap(audioButton);
    }
    await tester.pumpAndSettle();

    expect(find.text('검색 / 고급 필터'), findsOneWidget);
    expect(find.text('고급 필터'), findsOneWidget);
    expect(find.text(DateTime.now().day.toString()), findsWidgets);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('고급 필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기간 보기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('이번 달 기록'),
      300,
      scrollable: find
          .byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down)
          .last,
    );
    expect(find.textContaining('이번 달 기록'), findsOneWidget);
    expect(find.textContaining('${_todayDateText()} '), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('테스트 활동'),
      500,
      scrollable: find
          .byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down)
          .last,
    );
    expect(find.text('테스트 활동'), findsOneWidget);
  });

  testWidgets('checked task moves into completed panel', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = _todayDateText();
    final apiClient = MutableFakeAlarmApiClient([
      TaskItem(
        id: 1,
        title: '패널 이동 테스트',
        status: 'todo',
        createdAt: '${today}T00:00:00Z',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmHomePage(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();
    final audioButton = find.widgetWithText(FilledButton, '알림 사운드 활성화');
    if (audioButton.evaluate().isNotEmpty) {
      await tester.tap(audioButton);
    }
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('패널 이동 테스트'));
    final taskTile = find.ancestor(
      of: find.text('패널 이동 테스트'),
      matching: find.byType(ListTile),
    );
    await tester
        .tap(find.descendant(of: taskTile, matching: find.byType(Checkbox)));
    await tester.pump();

    expect(apiClient.tasks.single.status, 'done');
    expect(apiClient.tasks.single.completedAt, isNotNull);
    expect(find.text('패널 이동 테스트'), findsNothing);

    await tester.tap(find.text('완료한 일'));
    await tester.pumpAndSettle();

    expect(find.text('패널 이동 테스트'), findsOneWidget);
    expect(find.textContaining('$today · 1개'), findsOneWidget);
  });

  testWidgets('subtasks show progress and complete parent task',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = _todayDateText();
    final apiClient = MutableFakeAlarmApiClient([
      TaskItem(
        id: 1,
        title: '상위 작업',
        status: 'todo',
        createdAt: '${today}T00:00:00Z',
        subtasks: const [
          TaskSubtask(
            id: 1,
            taskId: 1,
            title: '첫 단계',
            isDone: false,
            sortOrder: 0,
          ),
          TaskSubtask(
            id: 2,
            taskId: 1,
            title: '둘째 단계',
            isDone: false,
            sortOrder: 1000,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmHomePage(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();
    final audioButton = find.widgetWithText(FilledButton, '알림 사운드 활성화');
    if (audioButton.evaluate().isNotEmpty) {
      await tester.tap(audioButton);
    }
    await tester.pumpAndSettle();

    expect(find.text('상위 작업'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.byTooltip('서브태스크 펼치기').first);
    await tester.pumpAndSettle();

    expect(find.text('서브태스크 0/2개 완료'), findsOneWidget);
    expect(find.text('첫 단계'), findsOneWidget);
    expect(find.text('둘째 단계'), findsOneWidget);
    expect(find.byTooltip('서브태스크 수정'), findsNWidgets(2));
    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

    final editableSubtaskTile = find.ancestor(
      of: find.text('첫 단계'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(
        of: editableSubtaskTile,
        matching: find.byTooltip('서브태스크 수정'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '첫 단계 수정');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(apiClient.tasks.single.subtasks.first.title, '첫 단계 수정');
    expect(find.text('첫 단계 수정'), findsOneWidget);

    final reorderedTask = await apiClient.reorderSubtasks(1, [2, 1]);
    expect(
      reorderedTask.subtasks.map((subtask) => subtask.title).toList(),
      ['둘째 단계', '첫 단계 수정'],
    );
    expect(
      reorderedTask.subtasks.map((subtask) => subtask.sortOrder).toList(),
      [0, 1000],
    );

    final firstSubtaskTile = find.ancestor(
      of: find.text('첫 단계 수정'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: firstSubtaskTile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();

    expect(apiClient.tasks.single.completedSubtaskCount, 1);
    expect(apiClient.tasks.single.status, 'todo');
    expect(find.text('50%'), findsOneWidget);

    final secondSubtaskTile = find.ancestor(
      of: find.text('둘째 단계'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: secondSubtaskTile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();

    expect(apiClient.tasks.single.status, 'done');
    expect(apiClient.tasks.single.completedAt, isNotNull);
    expect(find.text('상위 작업'), findsNothing);

    await tester.tap(find.text('완료한 일'));
    await tester.pumpAndSettle();

    expect(find.text('상위 작업'), findsOneWidget);

    await tester.tap(find.text('상위 작업'));
    await tester.pumpAndSettle();
    expect(find.text('첫 단계 수정'), findsOneWidget);

    final completedFirstSubtaskTile = find.ancestor(
      of: find.text('첫 단계 수정'),
      matching: find.byType(CheckboxListTile),
    );
    await tester.tap(
      find.descendant(
        of: completedFirstSubtaskTile,
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    expect(apiClient.tasks.single.status, 'todo');
    expect(apiClient.tasks.single.completedAt, isNull);
    expect(apiClient.tasks.single.completedSubtaskCount, 1);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('phone layout keeps task cards compact until expanded',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = _todayDateText();
    final apiClient = MutableFakeAlarmApiClient([
      TaskItem(
        id: 1,
        title: '긴 제목의 모바일 확인용 할일',
        status: 'todo',
        detail: '상세 설명은 접힌 카드에서 한 줄 요약으로만 보여야 합니다.',
        createdAt: '${today}T00:00:00Z',
        tags: const ['dev', 'mobile'],
        subtasks: const [
          TaskSubtask(
            id: 1,
            taskId: 1,
            title: '첫 모바일 단계',
            isDone: false,
            sortOrder: 0,
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmHomePage(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();
    final audioButton = find.widgetWithText(FilledButton, '알림 사운드 활성화');
    if (audioButton.evaluate().isNotEmpty) {
      await tester.tap(audioButton);
    }
    await tester.pumpAndSettle();

    expect(find.text('위 3개만 오늘 실행 목록입니다.'), findsOneWidget);
    expect(find.text('긴 제목의 모바일 확인용 할일'), findsOneWidget);
    expect(
      find.textContaining('#dev 외 1개 · 서브태스크 0/1'),
      findsOneWidget,
    );
    expect(find.byTooltip('할일 더보기'), findsOneWidget);
    expect(find.text('서브태스크 추가'), findsNothing);

    await tester.tap(find.textContaining('#dev 외 1개 · 서브태스크 0/1'));
    await tester.pumpAndSettle();
    expect(find.text('할일 요약'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('상세 설명은 접힌 카드에서 한 줄 요약으로만 보여야 합니다.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SelectableText),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('서브태스크 펼치기').first);
    await tester.pumpAndSettle();

    expect(find.text('서브태스크 0/1개 완료'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '서브태스크 추가'), findsOneWidget);
    expect(find.text('작게 쪼갠 다음 행동을 입력'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(TextButton, '서브태스크 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '서브태스크 추가'));
    await tester.pumpAndSettle();

    expect(find.text('작게 쪼갠 다음 행동을 입력'), findsOneWidget);
  });
}
