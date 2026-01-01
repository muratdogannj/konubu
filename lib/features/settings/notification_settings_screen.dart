import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _userRepo = UserRepository();
  final _authService = AuthService();
  
  bool _isLoading = true;
  UserModel? _user;
  
  // Settings state
  bool _notifyOnCityConfession = true;
  bool _notifyOnComment = true;
  bool _notifyOnLike = true;
  bool _notifyOnReply = true;
  bool _notifyOnMessage = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final user = await _userRepo.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          _user = user;
          _notifyOnCityConfession = user.notifyOnCityConfession;
          _notifyOnComment = user.notifyOnComment;
          _notifyOnLike = user.notifyOnLike;
          _notifyOnReply = user.notifyOnReply;
          _notifyOnMessage = user.notifyOnMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    if (_user == null) return;

    // Optimistic update
    setState(() {
      switch (key) {
        case 'notifyOnCityConfession':
          _notifyOnCityConfession = value;
          break;
        case 'notifyOnComment':
          _notifyOnComment = value;
          break;
        case 'notifyOnLike':
          _notifyOnLike = value;
          break;
        case 'notifyOnReply':
          _notifyOnReply = value;
          break;
        case 'notifyOnMessage':
          _notifyOnMessage = value;
          break;
      }
    });

    try {
      await _userRepo.updateUserFields(_user!.uid, {key: value});
      // Silent success or show snackbar if needed
    } catch (e) {
      // Revert on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayarlar güncellenemedi: $e')),
        );
        _loadSettings(); // Reload to revert
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('Konu & Paylaşım Bildirimleri'),
                _buildSwitchTile(
                  title: 'Şehrimden Yeni Konular',
                  subtitle: 'Takip ettiğin şehirlerde yeni bir konu paylaşıldığında bildirim al.',
                  value: _notifyOnCityConfession,
                  onChanged: (val) => _updateSetting('notifyOnCityConfession', val),
                  icon: Icons.location_city,
                ),
                const Divider(),
                
                _buildSectionHeader('Etkileşim Bildirimleri'),
                _buildSwitchTile(
                  title: 'Yorumlar',
                  subtitle: 'Konularına yorum yapıldığında bildirim al.',
                  value: _notifyOnComment,
                  onChanged: (val) => _updateSetting('notifyOnComment', val),
                  icon: Icons.comment,
                ),
                _buildSwitchTile(
                  title: 'Yanıtlar',
                  subtitle: 'Yorumlarına yanıt verildiğinde bildirim al.',
                  value: _notifyOnReply,
                  onChanged: (val) => _updateSetting('notifyOnReply', val),
                  icon: Icons.reply,
                ),
                _buildSwitchTile(
                  title: 'Beğeniler',
                  subtitle: 'Konuların beğenildiğinde bildirim al.',
                  value: _notifyOnLike,
                  onChanged: (val) => _updateSetting('notifyOnLike', val),
                  icon: Icons.favorite,
                ),
                 const Divider(),

                _buildSectionHeader('Mesajlaşma'),
                _buildSwitchTile(
                  title: 'Özel Mesajlar',
                  subtitle: 'Yeni bir mesaj aldığında bildirim al.',
                  value: _notifyOnMessage,
                  onChanged: (val) => _updateSetting('notifyOnMessage', val),
                  icon: Icons.message,
                ),
                
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Not: Bildirim ayarlarını değiştirdiğinde etkisinin görülmesi biraz zaman alabilir.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: AppTheme.primaryColor),
      activeColor: AppTheme.primaryColor,
    );
  }
}
