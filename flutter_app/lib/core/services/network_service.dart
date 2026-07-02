import 'package:dio/dio.dart';
import 'package:scanpdf/core/constants/app_constants.dart';

class NetworkService {
  late Dio _dio;

  NetworkService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl + AppConstants.apiEndpoint,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
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
}
