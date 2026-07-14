import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OCR 任务状态
enum OcrTaskStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// OCR 任务
class OcrTask {
  final String id;
  final String imagePath;
  final String language;
  OcrTaskStatus status;
  String? result;
  String? error;
  DateTime createdAt;
  DateTime? completedAt;
  int retryCount;

  OcrTask({
    required this.id,
    required this.imagePath,
    required this.language,
    this.status = OcrTaskStatus.pending,
    this.result,
    this.error,
    DateTime? createdAt,
    this.completedAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'language': language,
    'status': status.index,
    'result': result,
    'error': error,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OcrTask.fromJson(Map<String, dynamic> json) => OcrTask(
    id: json['id'],
    imagePath: json['imagePath'],
    language: json['language'],
    status: OcrTaskStatus.values[json['status']],
    result: json['result'],
    error: json['error'],
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt']) 
        : null,
    retryCount: json['retryCount'] ?? 0,
  );
}

/// OCR 队列服务 - 支持离线批量处理和持久化
class OcrQueueService {
  static final OcrQueueService _instance = OcrQueueService._internal();
  factory OcrQueueService() => _instance;
  OcrQueueService._internal() {
    _loadTaskQueue();
  }

  final List<OcrTask> _taskQueue = [];
  bool _isProcessing = false;
  Timer? _progressTimer;
  
  // 任务队列变更监听
  final _taskController = StreamController<List<OcrTask>>.broadcast();
  Stream<List<OcrTask>> get taskStream => _taskController.stream;
  
  // 进度更新监听
  final _progressController = StreamController<BatchOcrProgress>.broadcast();
  Stream<BatchOcrProgress> get progressStream => _progressController.stream;

  static const int maxRetryCount = 3;
  static const String taskQueueKey = 'ocr_task_queue';

  /// 添加单个任务
  Future<OcrTask> addTask({
    required String imagePath,
    required String language,
  }) async {
    final task = OcrTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      language: language,
    );

    _taskQueue.add(task);
    await _saveTaskQueue();
    _emitTaskUpdate();

    if (!_isProcessing) {
      _processQueue();
    }

    return task;
  }

  /// 添加批量任务
  Future<List<OcrTask>> addBatchTasks({
    required List<String> imagePaths,
    required String language,
  }) async {
    final tasks = <OcrTask>[];

    for (final path in imagePaths) {
      final task = OcrTask(
        id: '${DateTime.now().millisecondsSinceEpoch}_${tasks.length}',
        imagePath: path,
        language: language,
      );
      _taskQueue.add(task);
      tasks.add(task);
    }

    await _saveTaskQueue();
    _emitTaskUpdate();
    _emitProgressUpdate();

    if (!_isProcessing) {
      _processQueue();
    }

    return tasks;
  }

  /// 处理任务队列
  Future<void> _processQueue() async {
    if (_isProcessing || _taskQueue.isEmpty) return;

    _isProcessing = true;
    final textRecognizer = TextRecognizer();

    try {
      final pendingTasks = _taskQueue
          .where((task) => 
              task.status == OcrTaskStatus.pending)
          .toList();

      for (final task in pendingTasks) {
        if (task.status == OcrTaskStatus.cancelled) continue;

        task.status = OcrTaskStatus.processing;
        _emitTaskUpdate();
        _emitProgressUpdate();

        try {
          final image = InputImage.fromFile(File(task.imagePath));
          final recognizedText = await textRecognizer.processImage(image);

          task.result = recognizedText.text;
          task.status = OcrTaskStatus.completed;
          task.completedAt = DateTime.now();
        } catch (e) {
          task.retryCount++;
          if (task.retryCount >= maxRetryCount) {
            task.status = OcrTaskStatus.failed;
            task.error = e.toString();
            task.completedAt = DateTime.now();
          } else {
            task.status = OcrTaskStatus.pending;
          }
        }

        await _saveTaskQueue();
        _emitTaskUpdate();
        _emitProgressUpdate();
      }
    } finally {
      await textRecognizer.close();
      _isProcessing = false;
    }
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final index = _taskQueue.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _taskQueue[index];
      if (task.status == OcrTaskStatus.pending || 
          task.status == OcrTaskStatus.processing) {
        task.status = OcrTaskStatus.cancelled;
        await _saveTaskQueue();
        _emitTaskUpdate();
        _emitProgressUpdate();
      }
    }
  }

  /// 重试失败的任务
  Future<void> retryTask(String taskId) async {
    final index = _taskQueue.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _taskQueue[index];
      if (task.status == OcrTaskStatus.failed) {
        task.status = OcrTaskStatus.pending;
        task.error = null;
        task.retryCount = 0;
        await _saveTaskQueue();
        _emitTaskUpdate();

        if (!_isProcessing) {
          _processQueue();
        }
      }
    }
  }

  /// 清除已完成的任务
  Future<void> clearCompletedTasks() async {
    _taskQueue.removeWhere((task) => 
        task.status == OcrTaskStatus.completed || 
        task.status == OcrTaskStatus.failed ||
        task.status == OcrTaskStatus.cancelled);
    await _saveTaskQueue();
    _emitTaskUpdate();
  }

  /// 获取所有任务
  List<OcrTask> getAllTasks() => List.unmodifiable(_taskQueue);

  /// 获取任务统计
  Map<OcrTaskStatus, int> getTaskStats() {
    final stats = <OcrTaskStatus, int>{};
    for (final status in OcrTaskStatus.values) {
      stats[status] = _taskQueue
          .where((task) => task.status == status)
          .length;
    }
    return stats;
  }

  /// 获取当前进度
  BatchOcrProgress getCurrentProgress() {
    final total = _taskQueue.length;
    final completed = _taskQueue
        .where((task) => task.status == OcrTaskStatus.completed)
        .length;
    final failed = _taskQueue
        .where((task) => task.status == OcrTaskStatus.failed)
        .length;
    final processing = _taskQueue
        .where((task) => task.status == OcrTaskStatus.processing)
        .length;

    return BatchOcrProgress(
      total: total,
      completed: completed,
      failed: failed,
      processing: processing,
      isRunning: _isProcessing,
    );
  }

  /// 加载任务队列
  Future<void> _loadTaskQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(taskQueueKey);

      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _taskQueue.clear();
        _taskQueue.addAll(
          jsonList.map((json) => OcrTask.fromJson(json)).toList()
        );
        _emitTaskUpdate();
      }
    } catch (e) {
      debugPrint('Error loading OCR task queue: $e');
    }
  }

  /// 保存任务队列
  Future<void> _saveTaskQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _taskQueue.map((task) => task.toJson()).toList();
      final jsonStr = json.encode(jsonList);
      await prefs.setString(taskQueueKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving OCR task queue: $e');
    }
  }

  /// 发送任务更新
  void _emitTaskUpdate() {
    _taskController.add(List.unmodifiable(_taskQueue));
  }

  /// 发送进度更新
  void _emitProgressUpdate() {
    _progressController.add(getCurrentProgress());
  }

  /// 释放资源
  void dispose() {
    _progressTimer?.cancel();
    _taskController.close();
    _progressController.close();
  }
}

/// 批量 OCR 进度
class BatchOcrProgress {
  final int total;
  final int completed;
  final int failed;
  final int processing;
  final bool isRunning;

  BatchOcrProgress({
    required this.total,
    required this.completed,
    required this.failed,
    required this.processing,
    required this.isRunning,
  });

  double get progress => total == 0 ? 0 : (completed + failed) / total;
  bool get isCompleted => completed + failed >= total;
  int get remaining => total - completed - failed;
}
