import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';

/// 云同步服务 - 支持离线队列、冲突检测和自动同步
class SyncService {
  final NetworkService _networkService;
  final DatabaseService _databaseService;
  
  final List<SyncOperation> _syncQueue = [];
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  bool _isOnline = true;
  
  // 同步状态流
  final _syncStatusController = StreamController<SyncStatusType>.broadcast();
  Stream<SyncStatusType> get syncStatusStream => _syncStatusController.stream;
  
  SyncService({
    required NetworkService networkService,
    required DatabaseService databaseService,
  })  : _networkService = networkService,
        _databaseService = databaseService {
    _loadSyncQueue();
    _checkConnectivity();
    _startAutoSync();
  }
  
  /// 检查网络连接
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isOnline = false;
    }
    return _isOnline;
  }
  
  /// 启动自动同步定时器
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _autoSync(),
    );
  }
  
  /// 自动同步
  Future<void> _autoSync() async {
    if (!_isOnline || _isSyncing || _syncQueue.isEmpty) return;
    await syncAll();
  }
  
  /// 同步所有待同步项目
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中',
        synced: 0,
        failed: 0,
        errors: [],
      );
    }
    
    _isSyncing = true;
    _emitStatus(SyncStatusType.syncing);
    
    try {
      await _checkConnectivity();
      if (!_isOnline) {
        _emitStatus(SyncStatusType.offline);
        return SyncResult(
          success: false,
          message: '无网络连接，已加入同步队列',
          synced: 0,
          failed: 0,
          errors: [],
        );
      }
      
      int synced = 0;
      int failed = 0;
      final errors = <String>[];
      
      // 处理本地数据库中的文档同步
      final localDocs = await _databaseService.getAllDocuments();
      for (final doc in localDocs) {
        if (doc.syncStatus == SyncStatus.syncing) {
          try {
            await _syncDocument(doc);
            synced++;
          } catch (e) {
            failed++;
            errors.add('${doc.title}: $e');
          }
        }
      }
      
      // 处理同步队列中的操作
      final queueToRemove = <SyncOperation>[];
      for (final op in _syncQueue) {
        try {
          await _executeOperation(op);
          synced++;
          queueToRemove.add(op);
        } catch (e) {
          failed++;
          errors.add('${op.documentId}: $e');
          if (op.retryCount >= 3) {
            queueToRemove.add(op);
          } else {
            op.retryCount++;
          }
        }
      }
      
      _syncQueue.removeWhere((op) => queueToRemove.contains(op));
      await _saveSyncQueue();
      
      final result = SyncResult(
        success: failed == 0,
        message: '同步完成: 成功 $synced, 失败 $failed',
        synced: synced,
        failed: failed,
        errors: errors,
      );
      
      _emitStatus(SyncStatusType.synced);
      return result;
      
    } catch (e) {
      _emitStatus(SyncStatusType.error);
      return SyncResult(
        success: false,
        message: '同步失败: $e',
        synced: 0,
        failed: 0,
        errors: [e.toString()],
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  /// 同步单个文档
  Future<void> _syncDocument(Document doc) async {
    try {
      final response = await _networkService.post(
        '/documents/sync',
        data: doc.toMap(),
      );
      
      if (response.statusCode == 200) {
        final updatedDoc = doc.copyWith(syncStatus: SyncStatus.synced);
        await _databaseService.updateDocument(updatedDoc);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// 执行同步操作
  Future<void> _executeOperation(SyncOperation op) async {
    Response response;
    
    switch (op.type) {
      case SyncOperationType.upload:
        response = await _networkService.post(
          '/documents',
          data: op.data,
        );
        break;
      case SyncOperationType.update:
        response = await _networkService.put(
          '/documents/${op.documentId}',
          data: op.data,
        );
        break;
      case SyncOperationType.delete:
        response = await _networkService.delete(
          '/documents/${op.documentId}',
        );
        break;
    }
    
    if (response.statusCode != 200) {
      throw Exception('Operation failed: ${response.statusCode}');
    }
  }
  
  /// 添加文档到同步队列
  Future<void> enqueueDocumentSync(Document doc) async {
    final updatedDoc = doc.copyWith(syncStatus: SyncStatus.syncing);
    await _databaseService.updateDocument(updatedDoc);
    
    if (_isOnline) {
      await _autoSync();
    }
  }
  
  /// 添加操作到同步队列
  Future<void> enqueueOperation(SyncOperation op) async {
    _syncQueue.add(op);
    await _saveSyncQueue();
    
    if (_isOnline) {
      await _autoSync();
    }
  }
  
  /// 获取同步状态
  Future<SyncStatusType> getSyncStatus() async {
    await _checkConnectivity();
    
    if (!_isOnline) return SyncStatusType.offline;
    if (_isSyncing) return SyncStatusType.syncing;
    if (_syncQueue.isNotEmpty) return SyncStatusType.pending;
    
    return SyncStatusType.synced;
  }
  
  /// 获取队列大小
  int get queueSize => _syncQueue.length;
  
  /// 清除同步队列
  Future<void> clearQueue() async {
    _syncQueue.clear();
    await _saveSyncQueue();
  }
  
  /// 加载同步队列
  Future<void> _loadSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString('sync_queue');
    
    if (queueJson != null && queueJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(queueJson);
        _syncQueue.clear();
        for (final item in list) {
          _syncQueue.add(SyncOperation.fromJson(item));
        }
      } catch (e) {
        // 队列加载失败，使用空队列
      }
    }
  }
  
  /// 保存同步队列
  Future<void> _saveSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _syncQueue.map((op) => op.toJson()).toList();
    await prefs.setString('sync_queue', json.encode(list));
  }
  
  /// 发送状态更新
  void _emitStatus(SyncStatusType status) {
    _syncStatusController.add(status);
  }
  
  /// 释放资源
  void dispose() {
    _autoSyncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// 同步操作
class SyncOperation {
  final String documentId;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  int retryCount;
  final DateTime createdAt;
  
  SyncOperation({
    required this.documentId,
    required this.type,
    required this.data,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'type': type.index,
    'data': data,
    'retryCount': retryCount,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    documentId: json['documentId'],
    type: SyncOperationType.values[json['type']],
    data: json['data'],
    retryCount: json['retryCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

  /// 同步操作类型
enum SyncOperationType {
  upload,
  update,
  delete,
}

/// 同步状态类型（用于 SyncService 内部）
enum SyncStatusType {
  synced,
  pending,
  syncing,
  offline,
  error,
}

/// 冲突解决策略
enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepNewer,
  manual,
}

/// 冲突信息
class ConflictInfo {
  final String documentId;
  final Document localVersion;
  final Document remoteVersion;
  final DateTime detectedAt;

  const ConflictInfo({
    required this.documentId,
    required this.localVersion,
    required this.remoteVersion,
    required this.detectedAt,
  });
}

/// 同步进度
class SyncProgress {
  final int total;
  final int completed;
  final int pending;
  final double progress;

  const SyncProgress({
    required this.total,
    required this.completed,
    required this.pending,
    required this.progress,
  });
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final int synced;
  final int failed;
  final List<String> errors;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.synced,
    required this.failed,
    required this.errors,
  });
}
