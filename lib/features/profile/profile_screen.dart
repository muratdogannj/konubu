import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/features/profile/city_subscription_screen.dart';
import 'package:dedikodu_app/features/profile/profile_edit_screen.dart';
import 'package:dedikodu_app/features/settings/notification_settings_screen.dart';
import 'package:dedikodu_app/core/utils/badge_helper.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dedikodu_app/core/services/storage_service.dart';
import 'package:dedikodu_app/features/admin/admin_panel_screen.dart';
import 'package:dedikodu_app/features/moderation/moderation_screen.dart';
import 'package:dedikodu_app/features/profile/feedback_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _userRepo = UserRepository();
  final _storageService = StorageService(); // Add StorageService
  
  bool _isLoading = true;
  bool _isUploadingImage = false; // Add loading state for image upload
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final user = await _userRepo.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image;
      if (source == ImageSource.camera) {
        image = await _storageService.pickImageFromCamera();
      } else {
        image = await _storageService.pickImageFromGallery();
      }

      if (image == null) return;

      // Crop image
      final croppedFile = await _storageService.cropImage(
        imageFile: image,
        context: context,
      );
      if (croppedFile == null) return; // User cancelled cropping

      setState(() => _isUploadingImage = true);

      final userId = _authService.currentUserId;
      if (userId == null) return;

      final url = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: XFile(croppedFile.path),
      );

      if (url != null) {
        // Update user profile in Firestore
        final updatedUser = _currentUser!.copyWith(profileImageUrl: url);
        await _userRepo.updateUser(updatedUser);
        
        // Refresh local state
        setState(() {
          _currentUser = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellendi'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Profili'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile avatar
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: _currentUser?.profileImageUrl != null
                                  ? NetworkImage('${_currentUser!.profileImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}')
                                  : null,
                              child: _currentUser?.profileImageUrl != null
                                  ? null
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppTheme.primaryColor,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _isUploadingImage
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Username
                    if (_currentUser?.username != null)
                      Center(
                        child: Text(
                          '@${_currentUser!.username!}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Premium badge - show if user is premium
                    if (_currentUser?.isPremium == true)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '👑',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'KONUBU+ Üye',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_currentUser?.isPremium == true)
                      const SizedBox(height: 8),
                    
                    // Badge display - activity badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getUserBadge(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Statistics Cards
                    _buildStatisticsSection(),
                    
                    const SizedBox(height: 24),


                    // Profile Edit Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileEditScreen(),
                            ),
                          ).then((_) => _loadUserProfile());
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Profil Bilgileri',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_outlined),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Bildirim Ayarları',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City Subscription Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CitySubscriptionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_city),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Takip Ettiğim Şehirler',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Feedback Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeedbackScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.feedback_outlined),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Şikayet ve Öneri',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Çıkış Yap',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteAccountDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[900],
                          side: BorderSide(color: Colors.red[900]!),
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Hesabı Sil',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50), // Bottom padding for better scrolling accessibility
                  ],
                ),
              ),
            ),
          ),
    );
  }





  Widget _buildStatisticsSection() {
    if (_currentUser == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İstatistikler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.article_outlined,
                label: 'Konu',
                value: _currentUser!.confessionCount < 0 ? 0 : _currentUser!.confessionCount,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_outline,
                label: 'Beğeni',
                value: _currentUser!.totalLikesReceived < 0 ? 0 : _currentUser!.totalLikesReceived,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.chat_bubble_outline,
                label: 'Yorum',
                value: _currentUser!.totalCommentsGiven < 0 ? 0 : _currentUser!.totalCommentsGiven,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.visibility_outlined,
                label: 'Görüntülenme',
                value: _currentUser!.totalViewsReceived < 0 ? 0 : _currentUser!.totalViewsReceived,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_currentUser != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => UserProfileViewScreen(
                  userId: _currentUser!.uid,
                  initialUser: _currentUser,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                BadgeHelper.formatNumber(value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String badgeId) {
    print('Badge ID: "$badgeId"'); // Debug
    print('Badge Display: "${BadgeHelper.getBadgeDisplay(badgeId)}"'); // Debug
    
    // If badge is empty or invalid, show default
    if (badgeId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: Colors.grey,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Yeni Üye',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            BadgeHelper.getBadgeDisplay(badgeId),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabı Sil'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hesabınızı silmek istediğinizden emin misiniz?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text('Bu işlem geri alınamaz ve:'),
            SizedBox(height: 8),
            Text('• Tüm konularınız silinecek'),
            Text('• Tüm yorumlarınız silinecek'),
            Text('• Tüm mesajlarınız silinecek'),
            Text('• Profil bilgileriniz silinecek'),
            Text('• KONUBU+ aboneliğiniz iptal olacak'),
            SizedBox(height: 16),
            Text(
              'Bu işlem kalıcıdır ve geri alınamaz!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }



  Future<void> _deleteAccount() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Delete user data from Firestore
      await _userRepo.deleteUser(userId);

      // Delete Firebase Auth account
      await _authService.deleteAccount();

      // Navigate to welcome screen
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabınız başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUserBadge() {
    if (_currentUser == null) return '🥉 Yeni Üye';
    
    final badges = BadgeHelper.calculateBadges(
      confessionCount: _currentUser!.confessionCount,
      totalLikesReceived: _currentUser!.totalLikesReceived,
      totalCommentsGiven: _currentUser!.totalCommentsGiven,
      maxConfessionLikes: 0, // Could track this separately
      uniqueHashtagsUsed: 0, // Could track this separately
    );
    

    
    if (badges.isEmpty) {
      return '🥉 Yeni Üye';
    }
    
    final highestBadge = BadgeHelper.getHighestBadge(badges);
    return BadgeHelper.getBadgeDisplay(highestBadge);
  }


}


