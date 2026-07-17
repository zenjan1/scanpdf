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
  final String source; // 'github' or 'gitee'

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
    this.forceUpdate = false,
    this.apkSize,
    this.source = 'github',
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json, {String source = 'github'}) {
    return VersionInfo(
      version: json['version'] ?? '',
      buildNumber: json['buildNumber'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      changelog: json['changelog'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      apkSize: json['apkSize'],
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'buildNumber': buildNumber,
        'downloadUrl': downloadUrl,
        'changelog': changelog,
        'forceUpdate': forceUpdate,
        'apkSize': apkSize,
        'source': source,
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

/// 更新源配置
class UpdateSource {
  final String name;
  final String apiUrl;
  final String downloadBaseUrl;

  const UpdateSource({
    required this.name,
    required this.apiUrl,
    required this.downloadBaseUrl,
  });

  static const github = UpdateSource(
    name: 'github',
    apiUrl: 'https://api.github.com/repos/zenjan1/scanpdf/releases/latest',
    downloadBaseUrl: 'https://github.com/zenjan1/scanpdf/releases/download',
  );

  static const gitee = UpdateSource(
    name: 'gitee',
    apiUrl: 'https://gitee.com/api/v5/repos/zenjan1/scanpdf/releases/latest',
    downloadBaseUrl: 'https://gitee.com/zenjan1/scanpdf/releases/download',
  );
}

/// 自动更新服务
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = Dio();
  static const String _skipVersionKey = 'skip_version';
  static const String _updateSourceKey = 'update_source';

  /// 获取当前应用版本信息
  Future<PackageInfo> getCurrentVersion() async {
    return await PackageInfo.fromPlatform();
  }

  /// 检测是否在中国大陆
  Future<bool> isInChina() async {
    try {
      // 方法1: 检查系统语言
      final locale = Platform.localeName.toLowerCase();
      if (locale.contains('zh_cn') || locale.contains('zh_hans')) {
        return true;
      }

      // 方法2: 检查时区
      final tz = DateTime.now().timeZoneName;
      if (tz == 'CST' || tz.contains('China')) {
        return true;
      }

      // 方法3: 尝试访问 Google，如果失败则可能在中国
      try {
        final response = await _dio.get(
          'https://www.google.com',
          options: Options(connectTimeout: const Duration(seconds: 3)),
        );
        return response.statusCode != 200;
      } catch (e) {
        // 连接失败，可能在中国
        return true;
      }
    } catch (e) {
      debugPrint('检测地区失败: $e');
      return false; // 默认使用 GitHub
    }
  }

  /// 获取更新源
  Future<UpdateSource> getUpdateSource() async {
    // 优先使用用户设置
    final prefs = await SharedPreferences.getInstance();
    final userSource = prefs.getString(_updateSourceKey);
    if (userSource == 'github') return UpdateSource.github;
    if (userSource == 'gitee') return UpdateSource.gitee;

    // 自动检测
    final inChina = await isInChina();
    return inChina ? UpdateSource.gitee : UpdateSource.github;
  }

  /// 设置更新源
  Future<void> setUpdateSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_updateSourceKey, source);
  }

  /// 检查是否有新版本
  Future<VersionInfo?> checkForUpdate() async {
    // 获取主要更新源
    final primarySource = await getUpdateSource();
    final fallbackSource = primarySource.name == 'github' 
        ? UpdateSource.gitee 
        : UpdateSource.github;

    // 尝试主要源
    var versionInfo = await _checkFromSource(primarySource);
    
    // 如果主要源失败，尝试备用源
    if (versionInfo == null) {
      debugPrint('主要源 ${primarySource.name} 失败，尝试备用源 ${fallbackSource.name}');
      versionInfo = await _checkFromSource(fallbackSource);
    }

    return versionInfo;
  }

  /// 从指定源检查更新
  Future<VersionInfo?> _checkFromSource(UpdateSource source) async {
    try {
      final response = await _dio.get(
        source.apiUrl,
        options: Options(
          headers: source.name == 'github' 
              ? {'Accept': 'application/vnd.github.v3+json'}
              : {},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

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
            // GitHub 和 Gitee 的 asset 结构略有不同
            if (source.name == 'github') {
              downloadUrl = asset['browser_download_url'] as String? ?? '';
            } else {
              // Gitee 的下载链接
              final browserUrl = asset['browser_download_url'] as String? ?? '';
              downloadUrl = browserUrl.isNotEmpty 
                  ? browserUrl 
                  : '${source.downloadBaseUrl}/$tagName/$name';
            }
            
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
            forceUpdate: false,
            apkSize: apkSize,
            source: source.name,
          );
        }
      }
    } catch (e) {
      debugPrint('从 ${source.name} 检查更新失败: $e');
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
