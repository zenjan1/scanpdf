import 'package:flutter/material.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  bool _autoEnhance = true;
  bool _autoSave = true;
  bool _cloudSync = false;
  bool _darkMode = false;
  String _defaultExportFormat = 'PDF';
  String _imageQuality = '高';
  int _storageUsed = 0;
  String _serverUrl = 'https://jp.zenjan.store';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageSize();
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
    });
  }

  Future<void> _loadStorageSize() async {
    final size = await _storageService.getStorageSize();
    setState(() => _storageUsed = size);
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

          // Storage
          _buildSectionHeader('存储'),
          _buildInfoTile(
            icon: Icons.storage,
            title: '已用空间',
            subtitle: _formatBytes(_storageUsed),
          ),
          _buildActionTile(
            icon: Icons.delete_sweep,
            title: '清除缓存',
            subtitle: '释放存储空间',
            onTap: () async {
              await _storageService.clearCache();
              await _loadStorageSize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清除')),
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // About
          _buildSectionHeader('关于'),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: '版本',
            subtitle: 'v1.0.0',
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
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '登录以使用云同步功能',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('登录'),
            ),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        value: value,
        onChanged: onChanged,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.error),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://jp.zenjan.store',
            prefixIcon: Icon(Icons.dns),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _serverUrl = controller.text);
              await _saveSetting('serverUrl', controller.text);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
