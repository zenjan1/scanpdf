import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanpdf/core/constants/app_constants.dart';

/// 离线请求项
class OfflineRequest {
  final String id;
  final String method; // 'GET', 'POST', 'PUT', 'DELETE'
  final String path;
  final dynamic data;
  final DateTime timestamp;
  final int retryCount;

  OfflineRequest({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory OfflineRequest.fromJson(Map<String, dynamic> json) => OfflineRequest(
        id: json['id'],
        method: json['method'],
        path: json['path'],
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'] ?? 0,
      );
}

class NetworkService {
  late Dio _dio;
  bool _isOnline = true;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final List<OfflineRequest> _offlineQueue = [];
  static const int maxRetryCount = 3;
  Timer? _networkMonitorTimer;
  bool _networkMonitorStarted = false;

  /// 网络连接状态流
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// 当前网络状态
  bool get isOnline => _isOnline;

  /// 离线队列大小
  int get offlineQueueSize => _offlineQueue.length;

  /// 离线队列变更流
  final StreamController<List<OfflineRequest>> _queueController =
      StreamController<List<OfflineRequest>>.broadcast();
  Stream<List<OfflineRequest>> get offlineQueueStream =>
      _queueController.stream;

  NetworkService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl + AppConstants.apiEndpoint,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _initializeNetworkMonitoring();
    _loadOfflineQueue();

    // 添加拦截器
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 检查网络状态
          await _checkConnectivity();
          if (!_isOnline) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'No internet connection',
                type: DioExceptionType.connectionError,
              ),
            );
          }

          // 自动添加 Authorization header
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // 处理 401 未授权错误
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('isLoggedIn');
            await prefs.remove('accessToken');
          }
          return handler.next(error);
        },
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  Future<Response> upload(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<Response> download(
    String path,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// 初始化网络监控
  void _initializeNetworkMonitoring() {
    // 延迟初始化，避免在测试环境中立即创建 Timer
    // 只在真正需要时才启动网络监控
  }

  /// 开始网络监控（延迟调用）
  Future<void> startNetworkMonitoring() async {
    if (_networkMonitorStarted) return;

    _networkMonitorStarted = true;
    _networkMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
    // 启动时立即检查一次
    await _checkConnectivity();
  }

  /// 检查网络连接
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      // 如果状态发生变化，通知监听者
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        // 如果从离线变为在线，自动同步离线队列
        if (_isOnline && !wasOnline) {
          _syncOfflineQueue();
        }
      }

      return _isOnline;
    } catch (e) {
      final wasOnline = _isOnline;
      _isOnline = false;
      if (wasOnline) {
        _connectivityController.add(_isOnline);
      }
      return false;
    }
  }

  /// 加载离线队列
  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString('offline_queue');
      if (queueJson != null) {
        final List<dynamic> list = json.decode(queueJson);
        _offlineQueue.clear();
        _offlineQueue.addAll(
          list.map((item) => OfflineRequest.fromJson(item)).toList(),
        );
        _queueController.add(List.unmodifiable(_offlineQueue));
      }
    } catch (e) {
      debugPrint('Failed to load offline queue: $e');
    }
  }

  /// 保存离线队列
  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _offlineQueue.map((req) => req.toJson()).toList();
      await prefs.setString('offline_queue', json.encode(list));
      _queueController.add(List.unmodifiable(_offlineQueue));
    } catch (e) {
      debugPrint('Failed to save offline queue: $e');
    }
  }


  /// 同步离线队列
  Future<void> syncOfflineQueue() async {
    await _syncOfflineQueue();
  }

  Future<void> _syncOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final queueToRemove = <OfflineRequest>[];

    for (final request in _offlineQueue) {
      try {
        Response response;
        switch (request.method) {
          case 'POST':
            response = await post(request.path, data: request.data);
            break;
          case 'PUT':
            response = await put(request.path, data: request.data);
            break;
          case 'DELETE':
            response = await delete(request.path);
            break;
          default:
            queueToRemove.add(request);
            continue;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          queueToRemove.add(request);
        }
      } catch (e) {
        // 增加重试计数
        if (request.retryCount >= maxRetryCount) {
          queueToRemove.add(request);
        } else {
          final index = _offlineQueue.indexOf(request);
          if (index != -1) {
            _offlineQueue[index] = OfflineRequest(
              id: request.id,
              method: request.method,
              path: request.path,
              data: request.data,
              timestamp: request.timestamp,
              retryCount: request.retryCount + 1,
            );
          }
        }
      }
    }

    // 移除已处理的请求
    _offlineQueue.removeWhere((req) => queueToRemove.contains(req));
    await _saveOfflineQueue();
  }

  /// 清除离线队列
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _saveOfflineQueue();
  }

  /// 获取离线队列
  List<OfflineRequest> get offlineQueue => List.unmodifiable(_offlineQueue);

  /// 添加到离线队列
  Future<void> addToOfflineQueue({
    required String method,
    required String path,
    dynamic data,
  }) async {
    final request = OfflineRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      path: path,
      data: data,
      timestamp: DateTime.now(),
    );
    _offlineQueue.add(request);
    await _saveOfflineQueue();
  }

  /// 释放资源
  void dispose() {
    _networkMonitorTimer?.cancel();
    _networkMonitorTimer = null;
    _networkMonitorStarted = false;
    _connectivityController.close();
    _queueController.close();
  }
}
