import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/storage_service.dart';
import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/core/services/update_service.dart';
import 'package:scanpdf/features/update/update_bloc.dart';
import 'package:scanpdf/shared/widgets/update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final NetworkService _networkService = NetworkService();
  final DatabaseService _databaseService = DatabaseService();
  bool _autoEnhance = true;
  bool _autoSave = true;
  bool _cloudSync = false;
  bool _darkMode = false;
  String _defaultExportFormat = 'PDF';
  String _imageQuality = '高';
  int _storageUsed = 0;
  String _serverUrl = 'https://jp.zenjan.store';
  bool _isLoggedIn = false;
  String _username = '';
  String _email = '';
  int _documentCount = 0;
  int _recycleBinCount = 0;
  int _offlineQueueSize = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageSize();
    _loadStats();
    _checkNetworkStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoEnhance = prefs.getBool('autoEnhance') ?? true;
      _autoSave = prefs.getBool('autoSave') ?? true;
      _cloudSync = prefs.getBool('cloudSync') ?? false;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _defaultExportFormat = prefs.getString('defaultExportFormat') ?? 'PDF';
      _imageQuality = prefs.getString('imageQuality') ?? '高';
      _serverUrl = prefs.getString('serverUrl') ?? 'https://jp.zenjan.store';
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username') ?? '';
      _email = prefs.getString('email') ?? '';
    });
  }

  Future<void> _loadStorageSize() async {
    final size = await _storageService.getStorageSize();
    setState(() => _storageUsed = size);
  }

  Future<void> _loadStats() async {
    final docCount = await _databaseService.getDocumentCount();
    final recycleBinDocs = await _databaseService.getRecycleBinDocuments();
    setState(() {
      _documentCount = docCount;
      _recycleBinCount = recycleBinDocs.length;
      _offlineQueueSize = _networkService.offlineQueueSize;
    });
  }

  Future<void> _checkNetworkStatus() async {
    _networkService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {});
        _loadStats();
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('账户'),
          _buildAccountCard(),

          const SizedBox(height: 16),

          // Scan Settings
          _buildSectionHeader('扫描设置'),
          _buildSwitchTile(
            icon: Icons.auto_fix_high,
            title: '自动增强',
            subtitle: '拍摄后自动优化图片质量',
            value: _autoEnhance,
            onChanged: (value) {
              setState(() => _autoEnhance = value);
              _saveSetting('autoEnhance', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.save_alt,
            title: '自动保存',
            subtitle: '扫描完成后自动保存到本地',
            value: _autoSave,
            onChanged: (value) {
              setState(() => _autoSave = value);
              _saveSetting('autoSave', value);
            },
          ),
          _buildSelectionTile(
            icon: Icons.image_aspect_ratio,
            title: '图片质量',
            value: _imageQuality,
            options: const ['低', '中', '高', '超高'],
            onChanged: (value) {
              setState(() => _imageQuality = value);
              _saveSetting('imageQuality', value);
            },
          ),
          _buildSelectionTile(
            icon: Icons.picture_as_pdf,
            title: '默认导出格式',
            value: _defaultExportFormat,
            options: const ['PDF', 'JPG', 'PNG'],
            onChanged: (value) {
              setState(() => _defaultExportFormat = value);
              _saveSetting('defaultExportFormat', value);
            },
          ),

          const SizedBox(height: 16),

          // Cloud Settings
          _buildSectionHeader('云服务'),
          _buildSwitchTile(
            icon: Icons.cloud,
            title: '云端同步',
            subtitle: '将文档同步到 $_serverUrl',
            value: _cloudSync,
            onChanged: (value) {
              setState(() => _cloudSync = value);
              _saveSetting('cloudSync', value);
            },
          ),
          _buildNavigationTile(
            icon: Icons.dns,
            title: '服务器地址',
            subtitle: _serverUrl,
            onTap: () => _showServerUrlDialog(),
          ),

          const SizedBox(height: 16),

          // Appearance
          _buildSectionHeader('外观'),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: '深色模式',
            subtitle: '使用深色主题',
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _saveSetting('darkMode', value);
            },
          ),

          const SizedBox(height: 16),

          // Storage & Data
          _buildSectionHeader('存储与数据'),
          _buildInfoTile(
            icon: Icons.storage,
            title: '已用空间',
            subtitle: _formatBytes(_storageUsed),
          ),
          _buildInfoTile(
            icon: Icons.description,
            title: '文档数量',
            subtitle: '$_documentCount 个文档',
          ),
          _buildInfoTile(
            icon: Icons.delete_outline,
            title: '回收站',
            subtitle: '$_recycleBinCount 个文档',
            onTap: () => _showRecycleBinDialog(),
          ),
          _buildInfoTile(
            icon: Icons.cloud_off,
            title: '离线队列',
            subtitle: '$_offlineQueueSize 个待同步',
            onTap: () => _showOfflineQueueDialog(),
          ),
          _buildActionTile(
            icon: Icons.delete_sweep,
            title: '清除缓存',
            subtitle: '释放存储空间',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _storageService.clearCache();
              await _loadStorageSize();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
          ),

          const SizedBox(height: 16),

          // About
          _buildSectionHeader('关于'),
          _buildNavigationTile(
            icon: Icons.system_update,
            title: '检查更新',
            subtitle: '当前版本 v1.2.0',
            onTap: () => _checkForUpdate(),
          ),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: '版本',
            subtitle: 'v1.2.0',
          ),
          _buildNavigationTile(
            icon: Icons.article_outlined,
            title: '隐私政策',
            subtitle: '',
            onTap: () {},
          ),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: '用户协议',
            subtitle: '',
            onTap: () {},
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Icon(
                _isLoggedIn ? Icons.person : Icons.person_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoggedIn ? _username : '未登录',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isLoggedIn ? _email : '登录以使用云同步功能',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isLoggedIn ? _logout : _showLoginDialog,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(_isLoggedIn ? '退出' : '登录'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('登录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _showPasswordResetDialog(),
            child: const Text('忘记密码'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _login(
                usernameController.text,
                passwordController.text,
              );
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置密码'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: '注册邮箱',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _requestPasswordReset(emailController.text);
            },
            child: const Text('发送重置链接'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPasswordReset(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱')),
      );
      return;
    }

    try {
      await _networkService.post(
        '/auth/password-reset/request',
        data: {'email': email},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重置链接已发送到您的邮箱')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请求失败: $e')),
        );
      }
    }
  }

  Future<void> _login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱和密码')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await _networkService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final accessToken = data['access_token'];
        final userId = data['user_id'] ?? data['user']?['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', email);
        await prefs.setString('email', email);
        await prefs.setString('accessToken', accessToken);
        if (userId != null) {
          await prefs.setString('userId', userId);
        }

        setState(() {
          _isLoggedIn = true;
          _username = email;
          _email = email;
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录成功')),
          );
        }
      } else {
        throw Exception('登录失败');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('username');
              await prefs.remove('email');
              await prefs.remove('accessToken');
              await prefs.remove('userId');

              setState(() {
                _isLoggedIn = false;
                _username = '';
                _email = '';
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已退出登录')),
                );
              }
            },
            child: const Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: _serverUrl);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
            hintText: 'https://jp.zenjan.store',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() => _serverUrl = newUrl);
                final messenger = ScaffoldMessenger.of(context);
                await _saveSetting('serverUrl', newUrl);
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('服务器地址已更新')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showRecycleBinDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('回收站'),
        content: Text('回收站中有 $_recycleBinCount 个文档。\n\n清空回收站将永久删除这些文档，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _emptyRecycleBin();
            },
            child: const Text('清空回收站'),
          ),
        ],
      ),
    );
  }

  Future<void> _emptyRecycleBin() async {
    try {
      await _databaseService.emptyRecycleBin();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回收站已清空')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  void _showOfflineQueueDialog() {
    final queue = _networkService.offlineQueue;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('离线队列'),
        content: SizedBox(
          width: double.maxFinite,
          child: queue.isEmpty
              ? const Text('没有待同步的请求')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('共 ${queue.length} 个待同步请求'),
                    const SizedBox(height: 8),
                    const Text('这些操作将在恢复网络后自动同步到服务器。'),
                    const SizedBox(height: 16),
                    if (queue.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _networkService.syncOfflineQueue();
                          await _loadStats();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('同步完成')),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('立即同步'),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _networkService.clearOfflineQueue();
                        await _loadStats();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('离线队列已清空')),
                          );
                        }
                      },
                      icon: const Icon(Icons.clear_all, color: AppColors.error),
                      label: const Text('清空队列', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: option == value
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(option);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.error),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(subtitle)
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _checkForUpdate() {
    context.read<UpdateBloc>().add(CheckForUpdate());
  }
}
