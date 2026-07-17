import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';

/// 版本信息模型
class VersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  final String? apkSize;

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
    this.apkSize,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] ?? '',
      buildNumber: json['buildNumber'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      changelog: json['changelog'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      apkSize: json['apkSize'],
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'buildNumber': buildNumber,
        'downloadUrl': downloadUrl,
        'changelog': changelog,
        'forceUpdate': forceUpdate,
        'apkSize': apkSize,
      };
}

/// 更新检查状态
enum UpdateStatus {
  idle,
  checking,
  available,
  notAvailable,
  downloading,
  downloaded,
  error,
}

/// 自动更新服务
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = Dio();
  static const String _versionCheckUrl =
      'https://api.github.com/repos/zenjan1/scanpdf/releases/latest';
  static const String _skipVersionKey = 'skip_version';

  /// 获取当前应用版本信息
  Future<PackageInfo> getCurrentVersion() async {
    return await PackageInfo.fromPlatform();
  }

  /// 检查是否有新版本
  Future<VersionInfo?> checkForUpdate() async {
    try {
      // 从 GitHub 获取最新版本信息
      final response = await _dio.get(_versionCheckUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String? ?? '';
        final body = data['body'] as String? ?? '';

        // 解析版本号 (例如: v1.3.0 -> 1.3.0)
        final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        // 获取 APK 下载链接
        String downloadUrl = '';
        String? apkSize;
        final assets = data['assets'] as List? ?? [];
        for (var asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            final size = asset['size'] as int? ?? 0;
            apkSize = _formatFileSize(size);
            break;
          }
        }

        // 如果没有找到 APK，使用 zipball 作为备选
        if (downloadUrl.isEmpty) {
          downloadUrl = data['zipball_url'] as String? ?? '';
        }

        final currentPackage = await getCurrentVersion();
        final currentBuild = int.tryParse(currentPackage.buildNumber) ?? 0;

        // 比较版本号
        final newBuild = _parseVersionToNumber(version);

        if (newBuild > currentBuild) {
          return VersionInfo(
            version: version,
            buildNumber: newBuild,
            downloadUrl: downloadUrl,
            changelog: body,
            forceUpdate: false, // GitHub releases 不支持强制更新
            apkSize: apkSize,
          );
        }
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
    return null;
  }

  /// 下载 APK 文件
  Future<String?> downloadApk(
    String url,
    void Function(int received, int total)? onProgress,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/scanpdf_update.apk';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      debugPrint('下载 APK 失败: $e');
      return null;
    }
  }

  /// 安装 APK (Android)
  Future<void> installApk(String filePath) async {
    if (Platform.isAndroid) {
      final result = await OpenFile.open(filePath);
      debugPrint('安装 APK 结果: ${result.type} - ${result.message}');
    }
  }

  /// 跳过当前版本
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipVersionKey, version);
  }

  /// 检查是否已跳过当前版本
  Future<bool> isVersionSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(_skipVersionKey);
    return skippedVersion == version;
  }

  /// 清除跳过记录
  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipVersionKey);
  }

  /// 将版本号转换为数字用于比较
  int _parseVersionToNumber(String version) {
    final parts = version.split('.');
    if (parts.length >= 3) {
      final major = int.tryParse(parts[0]) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;
      final patch = int.tryParse(parts[2]) ?? 0;
      return major * 10000 + minor * 100 + patch;
    }
    return int.tryParse(version) ?? 0;
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void dispose() {
    _dio.close();
  }
}
