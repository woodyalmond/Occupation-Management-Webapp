import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'alarm_audio.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  runApp(const AlarmApp(apiBaseUrl: apiBaseUrl));
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({required this.apiBaseUrl, super.key});

  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지금뭐해',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: AlarmHomePage(apiClient: AlarmApiClient(baseUrl: apiBaseUrl)),
    );
  }
}

class AlarmApiClient {
  const AlarmApiClient({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<List<TaskItem>> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tasks'));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TaskItem>> searchTasks({
    String? keyword,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    final response = await http.get(
      _buildUri('/api/tasks', {
        'q': keyword,
        'status': status,
        'date_from': dateFrom,
        'date_to': dateTo,
        'tag': tag,
      }),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TaskItem> createTask(String title,
      {List<String> tags = const []}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'status': 'todo', 'tags': tags}),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': task.title,
        'detail': task.detail,
        'status': task.status,
        'due_date': task.dueDate,
        'completed_at': task.completedAt,
        'sort_order': task.sortOrder,
        'tags': task.tags,
      }),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TaskItem> createSubtask(int taskId, String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks/$taskId/subtasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TaskItem> updateSubtask(
    int taskId,
    TaskSubtask subtask, {
    String? title,
    bool? isDone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/tasks/$taskId/subtasks/${subtask.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title ?? subtask.title,
        'is_done': isDone ?? subtask.isDone,
        'sort_order': subtask.sortOrder,
      }),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TaskItem> deleteSubtask(int taskId, int subtaskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tasks/$taskId/subtasks/$subtaskId'),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TaskItem> reorderSubtasks(int taskId, List<int> subtaskIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks/$taskId/subtasks/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subtask_ids': subtaskIds}),
    );
    _ensureSuccess(response);
    return TaskItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<TaskItem>> reorderTasks(List<int> taskIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tasks/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'task_ids': taskIds}),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/tasks/$id'));
    _ensureSuccess(response);
  }

  Future<List<ActivityRecord>> fetchActivities() async {
    final response = await http.get(Uri.parse('$baseUrl/api/activities'));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => ActivityRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityRecord>> searchActivities({
    String? keyword,
    String? dateFrom,
    String? dateTo,
    String? tag,
  }) async {
    final response = await http.get(
      _buildUri('/api/activities', {
        'q': keyword,
        'date_from': dateFrom,
        'date_to': dateTo,
        'tag': tag,
      }),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => ActivityRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityRecord> createActivity({
    required String title,
    required int durationMinutes,
    List<String> tags = const [],
    String? memo,
  }) async {
    final now = DateTime.now();
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': tags.isEmpty ? null : tags.first,
        'tags': tags,
        'activity_date': _formatDate(now),
        'started_at': _formatTime(now),
        'duration_minutes': durationMinutes,
        'memo': memo,
      }),
    );
    _ensureSuccess(response);
    return ActivityRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ActivityRecord> updateActivity(ActivityRecord activity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/activities/${activity.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': activity.title,
        'category': activity.tags.isEmpty ? null : activity.tags.first,
        'tags': activity.tags,
        'activity_date': activity.activityDate,
        'started_at': activity.startedAt,
        'duration_minutes': activity.durationMinutes,
        'memo': activity.memo,
      }),
    );
    _ensureSuccess(response);
    return ActivityRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteActivity(int id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/api/activities/$id'));
    _ensureSuccess(response);
  }

  Future<DailyNoteExportResult> exportDailyNote(String dateText) async {
    final response =
        await http.post(Uri.parse('$baseUrl/api/dailynotes/$dateText'));
    _ensureSuccess(response);
    return DailyNoteExportResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final preview = response.body.length > 300
          ? '${response.body.substring(0, 300)}…'
          : response.body;
      throw ApiException('API 요청 실패: ${response.statusCode} $preview');
    }
  }

  Uri _buildUri(String path, Map<String, String?> query) {
    final queryParameters = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty && value != 'all') {
        queryParameters[entry.key] = value;
      }
    }
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DailyNoteExportResult {
  const DailyNoteExportResult({
    required this.date,
    required this.path,
    required this.activityCount,
    required this.taskCount,
  });

  final String date;
  final String path;
  final int activityCount;
  final int taskCount;

  factory DailyNoteExportResult.fromJson(Map<String, dynamic> json) {
    return DailyNoteExportResult(
      date: json['date'] as String,
      path: json['path'] as String,
      activityCount: json['activity_count'] as int,
      taskCount: json['task_count'] as int,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.status,
    this.detail,
    this.dueDate,
    this.completedAt,
    this.createdAt,
    this.sortOrder = 0,
    this.tags = const [],
    this.subtasks = const [],
  });

  final int id;
  final String title;
  final String status;
  final String? detail;
  final String? dueDate;
  final String? completedAt;
  final String? createdAt;
  final int sortOrder;
  final List<String> tags;
  final List<TaskSubtask> subtasks;

  bool get isDone => status == 'done';
  bool get hasSubtasks => subtasks.isNotEmpty;
  int get completedSubtaskCount =>
      subtasks.where((subtask) => subtask.isDone).length;
  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : completedSubtaskCount / subtasks.length;

  TaskItem copyWith({
    String? title,
    String? status,
    String? detail,
    String? dueDate,
    String? completedAt,
    bool clearCompletedAt = false,
    String? createdAt,
    int? sortOrder,
    List<String>? tags,
    List<TaskSubtask>? subtasks,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      dueDate: dueDate ?? this.dueDate,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String? ?? 'todo',
      detail: json['detail'] as String?,
      dueDate: json['due_date'] as String?,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      tags: ((json['tags'] as List<dynamic>?) ?? const [])
          .map((tag) => tag as String)
          .toList(),
      subtasks: ((json['subtasks'] as List<dynamic>?) ?? const [])
          .map((subtask) =>
              TaskSubtask.fromJson(subtask as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TaskSubtask {
  const TaskSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int taskId;
  final String title;
  final bool isDone;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  TaskSubtask copyWith({
    String? title,
    bool? isDone,
    int? sortOrder,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskSubtask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskSubtask.fromJson(Map<String, dynamic> json) {
    return TaskSubtask(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      title: json['title'] as String,
      isDone: json['is_done'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.title,
    required this.activityDate,
    this.category,
    this.startedAt,
    this.durationMinutes,
    this.memo,
    this.tags = const [],
  });

  final int id;
  final String title;
  final String activityDate;
  final String? category;
  final String? startedAt;
  final int? durationMinutes;
  final String? memo;
  final List<String> tags;

  ActivityRecord copyWith({
    String? title,
    String? category,
    String? activityDate,
    String? startedAt,
    int? durationMinutes,
    String? memo,
    List<String>? tags,
  }) {
    return ActivityRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      activityDate: activityDate ?? this.activityDate,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memo: memo ?? this.memo,
      tags: tags ?? this.tags,
    );
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String?,
      activityDate: json['activity_date'] as String,
      startedAt: json['started_at'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      memo: json['memo'] as String?,
      tags: ((json['tags'] as List<dynamic>?) ?? const [])
          .map((tag) => tag as String)
          .toList(),
    );
  }
}

class _RecordDateGroup {
  const _RecordDateGroup({
    required this.date,
    required this.activities,
    required this.tasks,
  });

  final String date;
  final List<ActivityRecord> activities;
  final List<TaskItem> tasks;

  int get totalCount => activities.length + tasks.length;
}

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({
    required this.apiClient,
    this.initialTabIndex = 0,
    super.key,
  });

  final AlarmApiClient apiClient;
  final int initialTabIndex;

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  final AlarmAudioService _alarmAudioService = const AlarmAudioService();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _recordSearchController = TextEditingController();
  final Map<int, TextEditingController> _subtaskControllers = {};
  final Set<int> _expandedTaskIds = {};
  final Set<int> _addingSubtaskIds = {};
  List<TaskItem> _tasks = [];
  List<ActivityRecord> _activities = [];
  List<TaskItem> _recordTasks = [];
  List<ActivityRecord> _recordActivities = [];
  Timer? _timer;
  int _durationSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  DateTime _selectedRecordDate = DateTime.now();
  DateTime _calendarCenterDate = DateTime.now();
  DateTime? _recordStartDate;
  DateTime? _recordEndDate;
  bool _isRunning = false;
  bool _isLoading = true;
  bool _isFilteringRecords = false;
  bool _isAudioActivated = false;
  bool _isAdvancedRecordFilterExpanded = false;
  bool _useSelectedDateFilter = true;
  String _recordPeriodPreset = 'month';
  String _recordStatusFilter = 'all';
  String? _selectedTaskTagFilter;
  String? _recordTagFilter;
  String? _errorMessage;

  double get _progress {
    if (_durationSeconds == 0) {
      return 0;
    }
    return 1 - (_remainingSeconds / _durationSeconds);
  }

  List<String> get _availableTags {
    final tags = <String>{};
    for (final task in _tasks) {
      tags.addAll(task.tags);
    }
    for (final activity in _activities) {
      tags.addAll(activity.tags);
    }
    return tags.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAudioActivationDialog();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _recordSearchController.dispose();
    for (final controller in _subtaskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.apiClient.fetchTasks(),
        widget.apiClient.fetchActivities(),
      ]);
      setState(() {
        _tasks = results[0] as List<TaskItem>;
        _activities = results[1] as List<ActivityRecord>;
        _recordTasks = _tasks;
        _recordActivities = _activities;
      });
    } catch (error) {
      setState(() {
        final baseUrl = widget.apiClient.baseUrl;
        final detail = error is ApiException ? error.message : error.toString();
        _errorMessage = '로컬 API에 연결할 수 없습니다.\n'
            'API 주소: $baseUrl\n'
            '원인: $detail\n'
            '확인: docker-compose up -d mariadb api 후 curl $baseUrl/health';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRecordFilters() async {
    setState(() {
      _isFilteringRecords = true;
    });
    final selectedDateText = _formatDate(_selectedRecordDate);
    final dateFrom = _useSelectedDateFilter
        ? selectedDateText
        : _formatNullableDate(_recordStartDate);
    final dateTo = _useSelectedDateFilter
        ? selectedDateText
        : _formatNullableDate(_recordEndDate);
    try {
      final results = await Future.wait([
        widget.apiClient.searchTasks(
          keyword: _recordSearchController.text,
          status: _recordStatusFilter,
          dateFrom: dateFrom,
          dateTo: dateTo,
          tag: _recordTagFilter,
        ),
        widget.apiClient.searchActivities(
          keyword: _recordSearchController.text,
          dateFrom: dateFrom,
          dateTo: dateTo,
          tag: _recordTagFilter,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _recordTasks = results[0] as List<TaskItem>;
        _recordActivities = results[1] as List<ActivityRecord>;
      });
    } catch (error) {
      if (mounted) {
        _showError('검색/필터 적용에 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFilteringRecords = false;
        });
      }
    }
  }

  void _clearRecordFilters() {
    _recordSearchController.clear();
    setState(() {
      _recordStatusFilter = 'all';
      _recordStartDate = null;
      _recordEndDate = null;
      _useSelectedDateFilter = true;
      _recordPeriodPreset = 'month';
      _recordTagFilter = null;
    });
    unawaited(_applyRecordFilters());
  }

  void _setRecordDayMode() {
    setState(() {
      _useSelectedDateFilter = true;
    });
    unawaited(_applyRecordFilters());
  }

  void _setRecordPeriodPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _useSelectedDateFilter = false;
      _recordPeriodPreset = preset;
      if (preset == 'week') {
        _recordStartDate = now.subtract(Duration(days: now.weekday - 1));
        _recordEndDate = now;
      } else if (preset == 'month') {
        _recordStartDate = DateTime(now.year, now.month);
        _recordEndDate = now;
      } else if (preset == 'all') {
        _recordStartDate = null;
        _recordEndDate = null;
      }
    });
    unawaited(_applyRecordFilters());
  }

  Future<void> _pickRecordStartDate() async {
    final picked = await _pickDate(_recordStartDate ?? _selectedRecordDate);
    if (picked == null) {
      return;
    }
    setState(() {
      _useSelectedDateFilter = false;
      _recordPeriodPreset = 'custom';
      _recordStartDate = picked;
    });
  }

  Future<void> _pickRecordEndDate() async {
    final picked = await _pickDate(_recordEndDate ?? _selectedRecordDate);
    if (picked == null) {
      return;
    }
    setState(() {
      _useSelectedDateFilter = false;
      _recordPeriodPreset = 'custom';
      _recordEndDate = picked;
    });
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  void _selectRecordDate(DateTime date) {
    setState(() {
      _selectedRecordDate = date;
      _calendarCenterDate = date;
    });
    if (_useSelectedDateFilter) {
      unawaited(_applyRecordFilters());
    }
  }

  Future<void> _showAudioActivationDialog() async {
    if (!mounted || _isAudioActivated) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('알림 사운드 활성화'),
          content: const Text(
            '브라우저 정책상 사용자가 한 번 버튼을 눌러야 알람 소리를 재생할 수 있습니다. '
            '타이머 종료 알림을 듣기 위해 아래 버튼을 눌러주세요.',
          ),
          actions: [
            FilledButton.icon(
              onPressed: () {
                final activated = _alarmAudioService.activate();
                if (activated) {
                  _alarmAudioService.playAlarm();
                }
                setState(() {
                  _isAudioActivated = activated;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      activated
                          ? '알림 사운드가 활성화되었습니다.'
                          : '이 브라우저는 Web Audio를 지원하지 않습니다.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('알림 사운드 활성화'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTimer() {
    final activated = _alarmAudioService.activate();
    if (activated && !_isAudioActivated) {
      setState(() {
        _isAudioActivated = true;
      });
    }
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
      return;
    }
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        _alarmAudioService.playAlarm();
        _showActivityDialog(defaultTitle: '방금 한 일');
      } else {
        setState(() {
          _remainingSeconds -= 1;
        });
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _durationSeconds;
      _isRunning = false;
    });
  }

  Future<void> _changeDuration() async {
    final activated = _alarmAudioService.activate();
    if (activated && !_isAudioActivated) {
      setState(() {
        _isAudioActivated = true;
      });
    }
    final controller =
        TextEditingController(text: (_durationSeconds ~/ 60).toString());
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('타이머 시간 설정'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '분'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(controller.text)),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (minutes == null || minutes <= 0) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _durationSeconds = minutes * 60;
      _remainingSeconds = _durationSeconds;
      _isRunning = false;
    });
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      return;
    }
    try {
      final task = await widget.apiClient.createTask(title);
      setState(() {
        _tasks = [task, ..._tasks];
        _taskController.clear();
      });
      unawaited(_exportDailyNoteForDate(_taskRecordDate(task)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('할일 저장에 실패했습니다.');
    }
  }

  Future<void> _showTaskDialog({TaskItem? task}) async {
    final titleController =
        TextEditingController(text: task?.title ?? _taskController.text.trim());
    final newTagController = TextEditingController();
    final selectedTags = <String>{...task?.tags ?? const <String>[]};
    final saved = await showDialog<TaskItem?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableTags = {..._availableTags, ...selectedTags}.toList()
              ..sort();
            return AlertDialog(
              title: Text(task == null ? '태그와 함께 할일 추가' : '할일 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '할일'),
                    ),
                    const SizedBox(height: 12),
                    Text('태그', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (availableTags.isEmpty)
                      const Text('아직 생성된 태그가 없습니다.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final tag in availableTags)
                            FilterChip(
                              label: Text('#$tag'),
                              selected: selectedTags.contains(tag),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedTags.add(tag);
                                  } else {
                                    selectedTags.remove(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newTagController,
                            decoration: const InputDecoration(
                              labelText: '새 태그',
                              hintText: '예: dev',
                            ),
                            onSubmitted: (_) {
                              _addDialogTag(newTagController, selectedTags,
                                  setDialogState);
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _addDialogTag(
                              newTagController, selectedTags, setDialogState),
                          icon: const Icon(Icons.add),
                          tooltip: '태그 추가',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소')),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      TaskItem(
                        id: task?.id ?? -1,
                        title: title,
                        status: task?.status ?? 'todo',
                        detail: task?.detail,
                        dueDate: task?.dueDate,
                        completedAt: task?.completedAt,
                        createdAt: task?.createdAt,
                        sortOrder: task?.sortOrder ?? 0,
                        tags: selectedTags.toList()..sort(),
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
    titleController.dispose();
    newTagController.dispose();
    if (saved == null) {
      return;
    }
    try {
      if (task == null) {
        final created =
            await widget.apiClient.createTask(saved.title, tags: saved.tags);
        setState(() {
          _tasks = [created, ..._tasks];
          _taskController.clear();
        });
        unawaited(_exportDailyNoteForDate(_taskRecordDate(created)));
      } else {
        final updated = await widget.apiClient
            .updateTask(task.copyWith(title: saved.title, tags: saved.tags));
        setState(() {
          _tasks = _tasks
              .map((item) => item.id == updated.id ? updated : item)
              .toList();
        });
        unawaited(_exportDailyNoteForDate(_taskRecordDate(updated)));
      }
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError(task == null ? '할일 저장에 실패했습니다.' : '할일 수정에 실패했습니다.');
    }
  }

  void _addDialogTag(
    TextEditingController controller,
    Set<String> selectedTags,
    StateSetter setDialogState,
  ) {
    final tag = _normalizeUiTag(controller.text);
    if (tag == null) {
      return;
    }
    setDialogState(() {
      selectedTags.add(tag);
      controller.clear();
    });
  }

  String? _normalizeUiTag(String value) {
    final tag =
        value.trim().replaceFirst(RegExp(r'^#+'), '').trim().toLowerCase();
    if (tag.isEmpty) {
      return null;
    }
    return tag;
  }

  Future<void> _toggleTask(TaskItem task) async {
    if (task.hasSubtasks) {
      _showError('서브태스크가 있는 할일은 하위 체크리스트를 모두 완료하면 자동 완료됩니다.');
      return;
    }
    final nextStatus = task.isDone ? 'todo' : 'done';
    try {
      final updatedTask =
          await widget.apiClient.updateTask(task.copyWith(status: nextStatus));
      setState(() {
        _replaceTaskInLists(updatedTask);
      });
      if (updatedTask.isDone && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 완료함에 저장되었습니다.')),
        );
      }
      unawaited(_exportDailyNoteForDate(_taskRecordDate(task)));
      unawaited(_exportDailyNoteForDate(_taskRecordDate(updatedTask)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('할일 수정에 실패했습니다.');
    }
  }

  Future<void> _addSubtask(TaskItem task) async {
    final controller = _subtaskControllerFor(task.id);
    final title = controller.text.trim();
    if (title.isEmpty) {
      return;
    }
    try {
      final updatedTask = await widget.apiClient.createSubtask(task.id, title);
      setState(() {
        controller.clear();
        _expandedTaskIds.add(task.id);
        _addingSubtaskIds.remove(task.id);
        _replaceTaskInLists(updatedTask);
      });
      unawaited(_exportDailyNoteForDate(_taskRecordDate(updatedTask)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('서브태스크 저장에 실패했습니다.');
    }
  }

  Future<void> _toggleSubtask(TaskItem task, TaskSubtask subtask) async {
    try {
      final updatedTask = await widget.apiClient.updateSubtask(
        task.id,
        subtask,
        isDone: !subtask.isDone,
      );
      setState(() {
        _replaceTaskInLists(updatedTask);
        if (!updatedTask.isDone) {
          _expandedTaskIds.add(updatedTask.id);
        }
      });
      if (updatedTask.isDone && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 서브태스크를 완료해 완료한 일로 이동했습니다.')),
        );
      }
      unawaited(_exportDailyNoteForDate(_taskRecordDate(updatedTask)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('서브태스크 수정에 실패했습니다.');
    }
  }

  Future<void> _showSubtaskEditDialog(
    TaskItem task,
    TaskSubtask subtask,
  ) async {
    var editedTitle = subtask.title;
    final savedTitle = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('서브태스크 수정'),
          content: TextFormField(
            initialValue: subtask.title,
            autofocus: true,
            decoration: const InputDecoration(labelText: '서브태스크'),
            onChanged: (value) {
              editedTitle = value;
            },
            onFieldSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, editedTitle.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    if (savedTitle == null ||
        savedTitle.isEmpty ||
        savedTitle == subtask.title) {
      return;
    }
    try {
      final updatedTask = await widget.apiClient.updateSubtask(
        task.id,
        subtask,
        title: savedTitle,
      );
      setState(() {
        _replaceTaskInLists(updatedTask);
        _expandedTaskIds.add(updatedTask.id);
      });
      unawaited(_exportDailyNoteForDate(_taskRecordDate(updatedTask)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('서브태스크 수정에 실패했습니다.');
    }
  }

  Future<void> _deleteSubtask(TaskItem task, TaskSubtask subtask) async {
    try {
      final updatedTask =
          await widget.apiClient.deleteSubtask(task.id, subtask.id);
      setState(() {
        _replaceTaskInLists(updatedTask);
        if (updatedTask.hasSubtasks) {
          _expandedTaskIds.add(updatedTask.id);
        }
      });
      unawaited(_exportDailyNoteForDate(_taskRecordDate(updatedTask)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('서브태스크 삭제에 실패했습니다.');
    }
  }

  Future<void> _reorderSubtasks(
    TaskItem task,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final previousTask = task;
    final reorderedSubtasks = List<TaskSubtask>.from(task.subtasks);
    final movedSubtask = reorderedSubtasks.removeAt(oldIndex);
    reorderedSubtasks.insert(newIndex, movedSubtask);
    final optimisticTask = task.copyWith(
      subtasks: _withSubtaskSortOrders(reorderedSubtasks),
    );
    setState(() {
      _replaceTaskInLists(optimisticTask);
      _expandedTaskIds.add(task.id);
    });
    try {
      final savedTask = await widget.apiClient.reorderSubtasks(
        task.id,
        optimisticTask.subtasks.map((subtask) => subtask.id).toList(),
      );
      setState(() {
        _replaceTaskInLists(savedTask);
        _expandedTaskIds.add(savedTask.id);
      });
      unawaited(_applyRecordFilters());
    } catch (error) {
      setState(() {
        _replaceTaskInLists(previousTask);
        _expandedTaskIds.add(previousTask.id);
      });
      _showError('서브태스크 순서 저장에 실패했습니다.');
    }
  }

  List<TaskSubtask> _withSubtaskSortOrders(List<TaskSubtask> subtasks) {
    return [
      for (var index = 0; index < subtasks.length; index++)
        subtasks[index].copyWith(sortOrder: index * 1000),
    ];
  }

  TextEditingController _subtaskControllerFor(int taskId) {
    return _subtaskControllers.putIfAbsent(
      taskId,
      () => TextEditingController(),
    );
  }

  void _replaceTaskInLists(TaskItem updatedTask) {
    _tasks = _tasks
        .map((item) => item.id == updatedTask.id ? updatedTask : item)
        .toList();
    _recordTasks = _recordTasks
        .map((item) => item.id == updatedTask.id ? updatedTask : item)
        .toList();
  }

  Future<void> _deleteTask(TaskItem task) async {
    try {
      await widget.apiClient.deleteTask(task.id);
      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
        _recordTasks =
            _recordTasks.where((item) => item.id != task.id).toList();
        _expandedTaskIds.remove(task.id);
        _addingSubtaskIds.remove(task.id);
        _subtaskControllers.remove(task.id)?.dispose();
      });
      unawaited(_exportDailyNoteForDate(_taskRecordDate(task)));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('할일 삭제에 실패했습니다.');
    }
  }

  Future<void> _reorderTasks(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final previousTasks = List<TaskItem>.from(_tasks);
    final visibleTasks = _filteredTimerTasks();
    final reorderedVisibleTasks = List<TaskItem>.from(visibleTasks);
    final movedTask = reorderedVisibleTasks.removeAt(oldIndex);
    reorderedVisibleTasks.insert(newIndex, movedTask);
    final visibleQueue = List<TaskItem>.from(reorderedVisibleTasks);
    final nextTasks = [
      for (final task in _tasks)
        _matchesVisibleTimerTask(task) ? visibleQueue.removeAt(0) : task,
    ];
    final reorderedTasks = _withSortOrders(nextTasks);
    setState(() {
      _tasks = reorderedTasks;
    });
    try {
      final savedTasks = await widget.apiClient
          .reorderTasks(reorderedTasks.map((task) => task.id).toList());
      setState(() {
        _tasks = savedTasks;
      });
      unawaited(_applyRecordFilters());
    } catch (error) {
      setState(() {
        _tasks = previousTasks;
      });
      _showError('할일 순서 저장에 실패했습니다.');
    }
  }

  List<TaskItem> _withSortOrders(List<TaskItem> tasks) {
    return [
      for (var index = 0; index < tasks.length; index++)
        tasks[index].copyWith(sortOrder: index * 1000),
    ];
  }

  List<TaskItem> _filteredTimerTasks() {
    return _tasks.where(_matchesVisibleTimerTask).toList();
  }

  bool _matchesVisibleTimerTask(TaskItem task) {
    return !task.isDone && _matchesTaskTagFilter(task);
  }

  bool _matchesTaskTagFilter(TaskItem task) {
    final selectedTag = _selectedTaskTagFilter;
    return selectedTag == null || task.tags.contains(selectedTag);
  }

  Future<void> _showActivityDialog(
      {String? defaultTitle, ActivityRecord? activity}) async {
    final activated = _alarmAudioService.activate();
    if (activated && !_isAudioActivated) {
      setState(() {
        _isAudioActivated = true;
      });
    }
    final titleController =
        TextEditingController(text: activity?.title ?? defaultTitle ?? '');
    final newTagController = TextEditingController();
    final minutesController = TextEditingController(
        text:
            (activity?.durationMinutes ?? (_durationSeconds ~/ 60)).toString());
    final memoController = TextEditingController(text: activity?.memo ?? '');
    final selectedTags = <String>{...activity?.tags ?? const <String>[]};
    final saved = await showDialog<ActivityRecord?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableTags = {..._availableTags, ...selectedTags}.toList()
              ..sort();
            return AlertDialog(
              title: Text(activity == null ? '활동 기록' : '활동 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: '활동 내용')),
                    TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '소요 시간(분)'),
                    ),
                    TextField(
                        controller: memoController,
                        decoration: const InputDecoration(labelText: '메모')),
                    const SizedBox(height: 12),
                    Text('태그', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (availableTags.isEmpty)
                      const Text('아직 생성된 태그가 없습니다.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final tag in availableTags)
                            FilterChip(
                              label: Text('#$tag'),
                              selected: selectedTags.contains(tag),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedTags.add(tag);
                                  } else {
                                    selectedTags.remove(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newTagController,
                            decoration: const InputDecoration(
                              labelText: '새 태그',
                              hintText: '예: report',
                            ),
                            onSubmitted: (_) {
                              _addDialogTag(newTagController, selectedTags,
                                  setDialogState);
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _addDialogTag(
                              newTagController, selectedTags, setDialogState),
                          icon: const Icon(Icons.add),
                          tooltip: '태그 추가',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소')),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final durationMinutes =
                        int.tryParse(minutesController.text) ?? 0;
                    if (title.isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      ActivityRecord(
                        id: activity?.id ?? -1,
                        title: title,
                        activityDate: activity?.activityDate ??
                            _formatDate(DateTime.now()),
                        startedAt: activity?.startedAt,
                        durationMinutes: durationMinutes,
                        memo: memoController.text.trim(),
                        tags: selectedTags.toList()..sort(),
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == null) {
      titleController.dispose();
      newTagController.dispose();
      minutesController.dispose();
      memoController.dispose();
      return;
    }
    try {
      if (activity == null) {
        final created = await widget.apiClient.createActivity(
          title: saved.title,
          durationMinutes: saved.durationMinutes ?? 0,
          tags: saved.tags,
          memo: saved.memo,
        );
        setState(() {
          _activities = [created, ..._activities];
        });
        unawaited(_exportDailyNoteForDate(created.activityDate));
        unawaited(_applyRecordFilters());
      } else {
        final updated = await widget.apiClient.updateActivity(
          activity.copyWith(
            title: saved.title,
            category: saved.tags.isEmpty ? null : saved.tags.first,
            durationMinutes: saved.durationMinutes,
            memo: saved.memo,
            tags: saved.tags,
          ),
        );
        setState(() {
          _activities = _activities
              .map((item) => item.id == updated.id ? updated : item)
              .toList();
        });
        unawaited(_exportDailyNoteForDate(activity.activityDate));
        unawaited(_exportDailyNoteForDate(updated.activityDate));
        unawaited(_applyRecordFilters());
      }
    } catch (error) {
      _showError('활동 저장에 실패했습니다.');
    } finally {
      titleController.dispose();
      newTagController.dispose();
      minutesController.dispose();
      memoController.dispose();
    }
  }

  Future<void> _deleteActivity(ActivityRecord activity) async {
    try {
      await widget.apiClient.deleteActivity(activity.id);
      setState(() {
        _activities =
            _activities.where((item) => item.id != activity.id).toList();
      });
      unawaited(_exportDailyNoteForDate(activity.activityDate));
      unawaited(_applyRecordFilters());
    } catch (error) {
      _showError('활동 삭제에 실패했습니다.');
    }
  }

  Future<void> _exportSelectedDailyNote() async {
    final result =
        await _exportDailyNoteForDate(_formatDate(_selectedRecordDate));
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.date} Daily Note 저장 완료')),
    );
  }

  Future<DailyNoteExportResult?> _exportDailyNoteForDate(
      String dateText) async {
    if (dateText.isEmpty) {
      return null;
    }
    try {
      return await widget.apiClient.exportDailyNote(dateText);
    } catch (error) {
      if (mounted) {
        _showError('Daily Note 저장에 실패했습니다.');
      }
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지금뭐해'),
          actions: [
            IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: '새로고침'),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '타이머'),
              Tab(text: '기록'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTimerTab(),
                  _buildRecordsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildTimerTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactPhone = constraints.maxWidth < 600;
        final mainContent = _buildTimerMainContent(isCompactPhone);
        if (constraints.maxWidth >= 920) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: mainContent,
                ),
              ),
              SizedBox(
                width: 360,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                  children: [
                    _buildCompletedTaskPanel(),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: EdgeInsets.all(isCompactPhone ? 12 : 20),
          children: [
            ...mainContent,
            SizedBox(height: isCompactPhone ? 8 : 12),
            _buildCompletedTaskPanel(),
          ],
        );
      },
    );
  }

  List<Widget> _buildTimerMainContent(bool isCompactPhone) {
    return [
      if (_errorMessage != null)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_errorMessage!),
          ),
        ),
      Card(
        child: Padding(
          padding: EdgeInsets.all(isCompactPhone ? 12 : 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InputChip(
                  avatar: Icon(
                      _isAudioActivated ? Icons.volume_up : Icons.volume_off),
                  label: Text(_isAudioActivated ? '사운드 활성화됨' : '사운드 미활성화'),
                  onPressed:
                      _isAudioActivated ? null : _showAudioActivationDialog,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _changeDuration,
                icon: const Icon(Icons.timer),
                label: Text(_formatRemainingTime(_remainingSeconds),
                    style: isCompactPhone
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.displaySmall),
              ),
              SizedBox(height: isCompactPhone ? 12 : 16),
              LinearProgressIndicator(value: _progress.clamp(0, 1)),
              SizedBox(height: isCompactPhone ? 12 : 16),
              Wrap(
                spacing: isCompactPhone ? 8 : 12,
                runSpacing: isCompactPhone ? 4 : 0,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? '일시정지' : '시작'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('초기화'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showActivityDialog(),
                    icon: const Icon(Icons.add_task),
                    label: const Text('활동 기록'),
                  ),
                  TextButton.icon(
                    onPressed: _alarmAudioService.playAlarm,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('사운드 테스트'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: isCompactPhone ? 12 : 20),
      Text(
        '할일',
        style: isCompactPhone
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.titleLarge,
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: const InputDecoration(hintText: '할일 입력'),
              onSubmitted: (_) => _addTask(),
            ),
          ),
          IconButton(onPressed: _addTask, icon: const Icon(Icons.add)),
          IconButton(
            onPressed: () => _showTaskDialog(),
            icon: const Icon(Icons.label),
            tooltip: '태그와 함께 추가',
          ),
        ],
      ),
      _buildTaskTagFilterChips(isCompactPhone),
      SizedBox(height: isCompactPhone ? 6 : 8),
      Text(
        isCompactPhone
            ? '위 3개만 오늘 실행 목록입니다.'
            : '위 3개가 오늘 먼저 할 일입니다. 새 할일은 아래 인박스에 쌓고, 필요한 일을 위로 끌어올리세요.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      SizedBox(height: isCompactPhone ? 6 : 8),
      _buildReorderableTaskList(isCompactPhone),
    ];
  }

  Widget _buildReorderableTaskList(bool isCompactPhone) {
    final visibleTasks = _filteredTimerTasks();
    if (visibleTasks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('조건에 맞는 할일이 없습니다.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: visibleTasks.length,
          onReorder: _reorderTasks,
          itemBuilder: (context, index) {
            final task = visibleTasks[index];
            return Column(
              key: ValueKey('task-wrapper-${task.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0)
                  _buildTaskSectionHeader(
                    '오늘 먼저 할 일',
                    '위 3개만 오늘의 실행 목록으로 봅니다.',
                    isCompactPhone,
                  ),
                if (index == 3)
                  _buildTaskSectionHeader(
                    '인박스 / 나중에 할 일',
                    '생각나는 일은 여기에 두고, 오늘 할 일만 위로 올립니다.',
                    isCompactPhone,
                  ),
                _buildTaskCard(
                  task: task,
                  index: index,
                  isCompactPhone: isCompactPhone,
                ),
              ],
            );
          },
        ),
        if (visibleTasks.length <= 3) ...[
          _buildTaskSectionHeader(
            '인박스 / 나중에 할 일',
            '새 할일은 여기에 쌓이고, 필요할 때 위로 올립니다.',
            isCompactPhone,
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('인박스가 비어 있습니다.'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedTaskPanel() {
    final completedTasks = _completedTasks();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.folder_outlined),
        title: const Text('완료한 일'),
        subtitle: Text(
          completedTasks.isEmpty
              ? '체크한 할일이 날짜별로 쌓입니다.'
              : '${completedTasks.length}개 완료됨',
        ),
        children: completedTasks.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('아직 완료한 일이 없습니다.'),
                  ),
                ),
              ]
            : _buildCompletedYearNodes(completedTasks),
      ),
    );
  }

  List<Widget> _buildCompletedYearNodes(List<TaskItem> completedTasks) {
    final tasksByDate = _completedTasksByDate(completedTasks);
    final dates = tasksByDate.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    final years = dates.map((date) => date.substring(0, 4)).toSet().toList()
      ..sort((left, right) => right.compareTo(left));

    return [
      for (final year in years)
        ExpansionTile(
          title: Text('$year년'),
          initiallyExpanded:
              year == _formatDate(DateTime.now()).substring(0, 4),
          children: _buildCompletedMonthNodes(year, dates, tasksByDate),
        ),
    ];
  }

  List<Widget> _buildCompletedMonthNodes(
    String year,
    List<String> dates,
    Map<String, List<TaskItem>> tasksByDate,
  ) {
    final months = dates
        .where((date) => date.startsWith(year))
        .map((date) => date.substring(0, 7))
        .toSet()
        .toList()
      ..sort((left, right) => right.compareTo(left));
    final currentMonth = _formatDate(DateTime.now()).substring(0, 7);

    return [
      for (final month in months)
        ExpansionTile(
          title: Text('${int.parse(month.substring(5, 7))}월'),
          initiallyExpanded: month == currentMonth,
          children: _buildCompletedDateNodes(month, dates, tasksByDate),
        ),
    ];
  }

  List<Widget> _buildCompletedDateNodes(
    String month,
    List<String> dates,
    Map<String, List<TaskItem>> tasksByDate,
  ) {
    final monthDates = dates.where((date) => date.startsWith(month)).toList();
    return [
      for (final date in monthDates)
        ExpansionTile(
          title: Text('$date · ${tasksByDate[date]!.length}개'),
          initiallyExpanded: _isRecentDateText(date),
          children: [
            for (final task in tasksByDate[date]!)
              _buildCompletedTaskTile(task),
          ],
        ),
    ];
  }

  Widget _buildCompletedTaskTile(TaskItem task) {
    final details = [
      if (_completedTaskTime(task) != null) _completedTaskTime(task),
      if (task.tags.isNotEmpty) task.tags.map((tag) => '#$tag').join(' '),
      task.detail,
    ].whereType<String>().where((text) => text.isNotEmpty).join(' · ');

    if (task.hasSubtasks) {
      return ExpansionTile(
        leading: Checkbox(
          value: true,
          onChanged: null,
        ),
        title: Text(task.title, style: _taskTextStyle(task)),
        subtitle: details.isEmpty ? null : Text(details),
        children: [
          for (final subtask in task.subtasks)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 48, right: 16),
              value: subtask.isDone,
              onChanged: (_) => _toggleSubtask(task, subtask),
              title: Text(
                subtask.title,
                style: _subtaskTextStyle(subtask),
              ),
            ),
        ],
      );
    }

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: true,
        onChanged: (_) => _toggleTask(task),
      ),
      title: Text(task.title, style: _taskTextStyle(task)),
      subtitle: details.isEmpty ? null : Text(details),
    );
  }

  List<TaskItem> _completedTasks() {
    return _tasks.where((task) => task.isDone).toList()
      ..sort((left, right) {
        final leftDate = left.completedAt ?? left.createdAt ?? '';
        final rightDate = right.completedAt ?? right.createdAt ?? '';
        return rightDate.compareTo(leftDate);
      });
  }

  Map<String, List<TaskItem>> _completedTasksByDate(
      List<TaskItem> completedTasks) {
    final tasksByDate = <String, List<TaskItem>>{};
    for (final task in completedTasks) {
      final date = _completedTaskDate(task);
      if (date == null || date.isEmpty) {
        continue;
      }
      tasksByDate.putIfAbsent(date, () => []).add(task);
    }
    return tasksByDate;
  }

  String? _completedTaskDate(TaskItem task) {
    return _dateOnly(task.completedAt) ?? _taskRecordDate(task);
  }

  String? _completedTaskTime(TaskItem task) {
    final completedAt = task.completedAt;
    if (completedAt == null || completedAt.length < 16) {
      return null;
    }
    return completedAt.substring(11, 16);
  }

  bool _isRecentDateText(String dateText) {
    final date = DateTime.tryParse(dateText);
    if (date == null) {
      return false;
    }
    return DateTime.now().difference(date).inDays <= 7;
  }

  Widget _buildTaskTagFilterChips(bool isCompactPhone) {
    final tags = _availableTags;
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: isCompactPhone ? 6 : 8),
      child: Wrap(
        spacing: isCompactPhone ? 6 : 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: const Text('전체'),
            visualDensity:
                isCompactPhone ? VisualDensity.compact : VisualDensity.standard,
            selected: _selectedTaskTagFilter == null,
            onSelected: (_) {
              setState(() {
                _selectedTaskTagFilter = null;
              });
            },
          ),
          for (final tag in tags)
            ChoiceChip(
              label: Text('#$tag'),
              visualDensity: isCompactPhone
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              selected: _selectedTaskTagFilter == tag,
              onSelected: (_) {
                setState(() {
                  _selectedTaskTagFilter = tag;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTaskSectionHeader(
    String title,
    String description,
    bool isCompactPhone,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: isCompactPhone ? 8 : 12,
        bottom: isCompactPhone ? 4 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isCompactPhone
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleMedium,
          ),
          if (!isCompactPhone) ...[
            const SizedBox(height: 2),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required TaskItem task,
    required int index,
    required bool isCompactPhone,
  }) {
    final isTodayFocus = index < 3;
    final rankLabel = isTodayFocus ? '${index + 1}' : null;
    final isExpanded = _expandedTaskIds.contains(task.id);
    return Card(
      color:
          isTodayFocus ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Column(
        children: [
          ListTile(
            dense: isCompactPhone,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompactPhone ? 8 : 16,
              vertical: isCompactPhone ? 0 : 4,
            ),
            visualDensity:
                isCompactPhone ? VisualDensity.compact : VisualDensity.standard,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rankLabel != null)
                  CircleAvatar(
                    radius: isCompactPhone ? 10 : 12,
                    child: Text(rankLabel,
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                Checkbox(
                  value: task.isDone,
                  onChanged: task.hasSubtasks ? null : (_) => _toggleTask(task),
                ),
                IconButton(
                  icon:
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  visualDensity: isCompactPhone
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  constraints: isCompactPhone
                      ? const BoxConstraints(minWidth: 32, minHeight: 32)
                      : null,
                  tooltip: isExpanded ? '서브태스크 접기' : '서브태스크 펼치기',
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedTaskIds.remove(task.id);
                      } else {
                        _expandedTaskIds.add(task.id);
                      }
                    });
                  },
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: _buildExpandableText(
                    task.title,
                    dialogTitle: '할일',
                    style: _taskTextStyle(task),
                    maxLines: isCompactPhone ? 1 : null,
                    overflow: isCompactPhone
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                  ),
                ),
                if (task.hasSubtasks)
                  _buildTaskProgressIndicator(task, isCompactPhone),
              ],
            ),
            subtitle: _buildTaskSubtitle(
              task,
              isCompactPhone: isCompactPhone,
              isExpanded: isExpanded,
            ),
            trailing: isCompactPhone
                ? _buildCompactTaskActions(task, index)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '수정',
                        onPressed: () => _showTaskDialog(task: task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: '삭제',
                        onPressed: () => _deleteTask(task),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ],
                  ),
          ),
          if (isExpanded) _buildSubtaskPanel(task, isCompactPhone),
        ],
      ),
    );
  }

  Widget _buildCompactTaskActions(TaskItem task, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          tooltip: '할일 더보기',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showTaskDialog(task: task);
            }
            if (value == 'delete') {
              _deleteTask(task);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
        ),
        ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ],
    );
  }

  Widget _buildTaskProgressIndicator(TaskItem task, bool isCompactPhone) {
    final percent = (task.subtaskProgress * 100).round();
    final size = isCompactPhone ? 36.0 : 44.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: task.subtaskProgress),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskPanel(TaskItem task, bool isCompactPhone) {
    final controller = _subtaskControllerFor(task.id);
    final isAddingSubtask =
        !isCompactPhone || _addingSubtaskIds.contains(task.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompactPhone ? 8 : 16,
        0,
        isCompactPhone ? 8 : 16,
        isCompactPhone ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.hasSubtasks)
            Padding(
              padding: EdgeInsets.only(bottom: isCompactPhone ? 4 : 8),
              child: Text(
                '서브태스크 ${task.completedSubtaskCount}/${task.subtasks.length}개 완료',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (task.hasSubtasks)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: task.subtasks.length,
              onReorder: (oldIndex, newIndex) =>
                  _reorderSubtasks(task, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final subtask = task.subtasks[index];
                return ListTile(
                  key: ValueKey('subtask-${task.id}-${subtask.id}'),
                  dense: true,
                  visualDensity: isCompactPhone
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: subtask.isDone,
                    onChanged: (_) => _toggleSubtask(task, subtask),
                  ),
                  title: _buildExpandableText(
                    subtask.title,
                    dialogTitle: '서브태스크',
                    style: _subtaskTextStyle(subtask),
                    maxLines: isCompactPhone ? 1 : null,
                    overflow: isCompactPhone
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: '서브태스크 수정',
                        onPressed: () => _showSubtaskEditDialog(task, subtask),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '서브태스크 삭제',
                        onPressed: () => _deleteSubtask(task, subtask),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (task.hasSubtasks) SizedBox(height: isCompactPhone ? 4 : 8),
          if (!isAddingSubtask)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_task),
                label: const Text('서브태스크 추가'),
                onPressed: () {
                  setState(() {
                    _addingSubtaskIds.add(task.id);
                  });
                },
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: '서브태스크 추가',
                      hintText: '작게 쪼갠 다음 행동을 입력',
                    ),
                    onSubmitted: (_) => _addSubtask(task),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_task),
                  tooltip: '서브태스크 추가',
                  onPressed: () => _addSubtask(task),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget? _buildTaskSubtitle(
    TaskItem task, {
    required bool isCompactPhone,
    required bool isExpanded,
  }) {
    if (isCompactPhone && !isExpanded) {
      final summary = _compactTaskSummary(task);
      if (summary == null) {
        return null;
      }
      return _buildExpandableText(
        summary,
        dialogTitle: '할일 요약',
        style: Theme.of(context).textTheme.labelSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final children = <Widget>[];
    if (task.detail != null && task.detail!.isNotEmpty) {
      children.add(
        Text(
          task.detail!,
          style: isCompactPhone ? Theme.of(context).textTheme.bodySmall : null,
        ),
      );
    }
    if (task.tags.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: isCompactPhone ? 2 : 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              for (final tag in task.tags)
                Chip(
                  label: Text(
                    '#$tag',
                    style: isCompactPhone
                        ? Theme.of(context).textTheme.labelSmall
                        : null,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      );
    }
    if (children.isEmpty) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String? _compactTaskSummary(TaskItem task) {
    final parts = <String>[];
    if (task.tags.isNotEmpty) {
      final extraTagCount = task.tags.length - 1;
      parts.add(extraTagCount > 0
          ? '#${task.tags.first} 외 $extraTagCount개'
          : '#${task.tags.first}');
    }
    if (task.hasSubtasks) {
      parts.add('서브태스크 ${task.completedSubtaskCount}/${task.subtasks.length}');
    }
    if (task.detail != null && task.detail!.isNotEmpty) {
      parts.add(task.detail!);
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }

  Widget _buildExpandableText(
    String text, {
    required String dialogTitle,
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final textWidget = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (overflow != TextOverflow.ellipsis) {
      return textWidget;
    }
    return InkWell(
      onTap: () => _showFullTextDialog(dialogTitle, text),
      child: textWidget,
    );
  }

  Future<void> _showFullTextDialog(String title, String content) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: SelectableText(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordCalendarRow() {
    final days = List.generate(
        7, (index) => _calendarCenterDate.add(Duration(days: index - 3)));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _calendarCenterDate =
                          _calendarCenterDate.subtract(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 주',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthLabel(_calendarCenterDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _selectRecordDate(DateTime.now());
                  },
                  child: const Text('오늘'),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _calendarCenterDate =
                          _calendarCenterDate.add(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 주',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isSelected = _isSameDate(day, _selectedRecordDate);
                  final isToday = _isSameDate(day, DateTime.now());
                  final hasActivity = _activities.any(
                      (activity) => activity.activityDate == _formatDate(day));
                  final hasTask = _tasks
                      .any((task) => _taskRecordDate(task) == _formatDate(day));
                  return ChoiceChip(
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      _selectRecordDate(day);
                    },
                    label: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${day.month}월',
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                              if (isSelected) ...[
                                const SizedBox(width: 2),
                                const Icon(Icons.check_circle, size: 12),
                              ],
                            ],
                          ),
                          Text(_weekdayLabel(day.weekday)),
                          Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            isToday
                                ? '오늘'
                                : (hasActivity || hasTask ? '기록 있음' : '없음'),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordFilterCard() {
    final activeAdvancedFilterCount = _activeAdvancedRecordFilterCount();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('검색 / 고급 필터',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_isFilteringRecords)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _recordSearchController,
                    decoration: const InputDecoration(
                      labelText: '검색어',
                      hintText: '할일 제목, 상세, 활동 제목, 메모 검색',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _applyRecordFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isFilteringRecords ? null : _applyRecordFilters,
                  icon: const Icon(Icons.search),
                  label: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: _isAdvancedRecordFilterExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isAdvancedRecordFilterExpanded = expanded;
                });
              },
              title: Text(
                activeAdvancedFilterCount == 0
                    ? '고급 필터'
                    : '고급 필터 $activeAdvancedFilterCount개 적용 중',
              ),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      selected: _useSelectedDateFilter,
                      label: Text('하루 보기: ${_formatDate(_selectedRecordDate)}'),
                      onSelected: (_) => _setRecordDayMode(),
                    ),
                    ChoiceChip(
                      selected: !_useSelectedDateFilter,
                      label: const Text('기간 보기'),
                      onSelected: (_) => _setRecordPeriodPreset('month'),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _recordTagFilter ?? 'all',
                        decoration: const InputDecoration(labelText: '태그'),
                        items: [
                          const DropdownMenuItem(
                              value: 'all', child: Text('전체')),
                          for (final tag in _availableTags)
                            DropdownMenuItem(value: tag, child: Text('#$tag')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _recordTagFilter =
                                value == null || value == 'all' ? null : value;
                            if (_recordTagFilter != null &&
                                _useSelectedDateFilter) {
                              final now = DateTime.now();
                              _useSelectedDateFilter = false;
                              _recordPeriodPreset = 'month';
                              _recordStartDate = DateTime(now.year, now.month);
                              _recordEndDate = now;
                            }
                          });
                          unawaited(_applyRecordFilters());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      selected: !_useSelectedDateFilter &&
                          _recordPeriodPreset == 'week',
                      label: const Text('이번 주'),
                      onSelected: (_) => _setRecordPeriodPreset('week'),
                    ),
                    ChoiceChip(
                      selected: !_useSelectedDateFilter &&
                          _recordPeriodPreset == 'month',
                      label: const Text('이번 달'),
                      onSelected: (_) => _setRecordPeriodPreset('month'),
                    ),
                    ChoiceChip(
                      selected: !_useSelectedDateFilter &&
                          _recordPeriodPreset == 'all',
                      label: const Text('전체'),
                      onSelected: (_) => _setRecordPeriodPreset('all'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickRecordStartDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                          '시작일: ${_formatNullableDate(_recordStartDate) ?? '없음'}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickRecordEndDate,
                      icon: const Icon(Icons.event),
                      label: Text(
                          '종료일: ${_formatNullableDate(_recordEndDate) ?? '없음'}'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          _isFilteringRecords ? null : _applyRecordFilters,
                      icon: const Icon(Icons.manage_search),
                      label: const Text('적용'),
                    ),
                    TextButton.icon(
                      onPressed: _clearRecordFilters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('초기화'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _activeAdvancedRecordFilterCount() {
    var count = 0;
    if (!_useSelectedDateFilter) {
      count += 1;
    }
    if (_recordStartDate != null) {
      count += 1;
    }
    if (_recordEndDate != null) {
      count += 1;
    }
    if (_recordTagFilter != null) {
      count += 1;
    }
    return count;
  }

  Widget _buildRecordsTab() {
    final selectedDateText = _formatDate(_selectedRecordDate);
    final selectedActivities = _useSelectedDateFilter
        ? _recordActivities
            .where((activity) => activity.activityDate == selectedDateText)
            .toList()
        : _recordActivities;
    final selectedTasks = _useSelectedDateFilter
        ? _recordTasks
            .where((task) => _taskRecordDate(task) == selectedDateText)
            .toList()
        : _recordTasks;
    final recordTitle = _useSelectedDateFilter
        ? selectedDateText
        : _periodRecordTitle(selectedActivities.length + selectedTasks.length);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('날짜 선택', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildRecordCalendarRow(),
        const SizedBox(height: 12),
        _buildRecordFilterCard(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _exportSelectedDailyNote,
            icon: const Icon(Icons.description),
            label: const Text('MD 저장'),
          ),
        ),
        const SizedBox(height: 12),
        if (_useSelectedDateFilter)
          ..._buildDailyRecordSections(
            recordTitle,
            selectedActivities,
            selectedTasks,
          )
        else
          _buildPeriodRecordTimeline(
            recordTitle,
            selectedActivities,
            selectedTasks,
          ),
      ],
    );
  }

  List<Widget> _buildDailyRecordSections(
    String recordTitle,
    List<ActivityRecord> selectedActivities,
    List<TaskItem> selectedTasks,
  ) {
    return [
      Text('$recordTitle 활동 기록 (${selectedActivities.length})',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (selectedActivities.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('조건에 맞는 활동이 없습니다.'),
          ),
        ),
      ...selectedActivities.map(_buildRecordActivityCard),
      const SizedBox(height: 20),
      Text('$recordTitle 할일 기록 (${selectedTasks.length})',
          style: Theme.of(context).textTheme.titleLarge),
      if (selectedTasks.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('조건에 맞는 할일이 없습니다.'),
          ),
        ),
      ...selectedTasks.map(_buildRecordTaskTile),
    ];
  }

  Widget _buildPeriodRecordTimeline(
    String recordTitle,
    List<ActivityRecord> selectedActivities,
    List<TaskItem> selectedTasks,
  ) {
    final groups = _groupRecordsByDate(selectedActivities, selectedTasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recordTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '총 ${selectedActivities.length + selectedTasks.length}개 · 활동 ${selectedActivities.length}개 · 할일 ${selectedTasks.length}개',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('조건에 맞는 기록이 없습니다.'),
            ),
          )
        else
          for (final group in groups)
            Card(
              child: ExpansionTile(
                initiallyExpanded: _isRecentDateText(group.date),
                title: Text(
                  '${group.date} ${_weekdayText(group.date)} · ${group.totalCount}개',
                ),
                children: [
                  for (final activity in group.activities)
                    _buildRecordActivityTile(activity),
                  for (final task in group.tasks) _buildRecordTaskTile(task),
                ],
              ),
            ),
      ],
    );
  }

  List<_RecordDateGroup> _groupRecordsByDate(
    List<ActivityRecord> activities,
    List<TaskItem> tasks,
  ) {
    final activitiesByDate = <String, List<ActivityRecord>>{};
    final tasksByDate = <String, List<TaskItem>>{};
    for (final activity in activities) {
      activitiesByDate
          .putIfAbsent(activity.activityDate, () => [])
          .add(activity);
    }
    for (final task in tasks) {
      tasksByDate.putIfAbsent(_taskRecordDate(task), () => []).add(task);
    }
    final dates = {...activitiesByDate.keys, ...tasksByDate.keys}.toList()
      ..sort((left, right) => right.compareTo(left));
    return [
      for (final date in dates)
        _RecordDateGroup(
          date: date,
          activities: activitiesByDate[date] ?? const [],
          tasks: tasksByDate[date] ?? const [],
        ),
    ];
  }

  Widget _buildRecordActivityCard(ActivityRecord activity) {
    return Card(child: _buildRecordActivityTile(activity));
  }

  Widget _buildRecordActivityTile(ActivityRecord activity) {
    return ListTile(
      leading: _buildActivityTimeBadge(activity),
      title: Text(activity.title),
      subtitle: Text(
        [
          if (activity.tags.isNotEmpty)
            activity.tags.map((tag) => '#$tag').join(' '),
          if (activity.durationMinutes != null) '${activity.durationMinutes}분',
          activity.memo,
        ].whereType<String>().where((text) => text.isNotEmpty).join(' · '),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showActivityDialog(activity: activity),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteActivity(activity),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTaskTile(TaskItem task) {
    return ListTile(
      leading: Icon(task.isDone ? Icons.check_circle : Icons.circle_outlined),
      title: Text(
        task.title,
        style: _taskTextStyle(task),
      ),
      subtitle: Text(
        [
          task.status,
          if (task.tags.isNotEmpty) task.tags.map((tag) => '#$tag').join(' '),
        ].join(' · '),
      ),
    );
  }

  String _periodRecordTitle(int resultCount) {
    final tagText = _recordTagFilter == null ? '' : ' #$_recordTagFilter';
    final periodText = switch (_recordPeriodPreset) {
      'week' => '이번 주',
      'month' => '이번 달',
      'all' => '전체',
      _ =>
        '${_formatNullableDate(_recordStartDate) ?? '처음'} ~ ${_formatNullableDate(_recordEndDate) ?? '오늘'}',
    };
    return '$periodText$tagText 기록 ($resultCount)';
  }

  String _weekdayText(String dateText) {
    final date = DateTime.tryParse(dateText);
    if (date == null) {
      return '';
    }
    return '${_weekdayLabel(date.weekday)}요일';
  }

  String _formatRemainingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainSeconds.toString().padLeft(2, '0')}';
  }

  TextStyle? _taskTextStyle(TaskItem task) {
    if (!task.isDone) {
      return null;
    }
    return const TextStyle(
      decoration: TextDecoration.lineThrough,
      color: Colors.grey,
    );
  }

  TextStyle? _subtaskTextStyle(TaskSubtask subtask) {
    if (!subtask.isDone) {
      return null;
    }
    return const TextStyle(
      decoration: TextDecoration.lineThrough,
      color: Colors.grey,
    );
  }

  Widget _buildActivityTimeBadge(ActivityRecord activity) {
    return Container(
      width: 58,
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14),
          const SizedBox(height: 2),
          Text(
            _formatActivityTime(activity.startedAt),
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(String? value) {
    if (value == null || value.isEmpty) {
      return '--:--';
    }
    if (value.length >= 5) {
      return value.substring(0, 5);
    }
    return value;
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  String? _formatNullableDate(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    return _formatDate(dateTime);
  }

  String _monthLabel(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월';
  }

  String _taskRecordDate(TaskItem task) {
    return task.dueDate ?? _dateOnly(task.createdAt) ?? '';
  }

  String? _dateOnly(String? value) {
    if (value == null || value.length < 10) {
      return null;
    }
    return value.substring(0, 10);
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => '월',
      DateTime.tuesday => '화',
      DateTime.wednesday => '수',
      DateTime.thursday => '목',
      DateTime.friday => '금',
      DateTime.saturday => '토',
      DateTime.sunday => '일',
      _ => '',
    };
  }
}
