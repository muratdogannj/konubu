import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/user_model.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/core/utils/badge_helper.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/features/hashtag/hashtag_confessions_screen.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/features/private_messages/private_chat_screen.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/data/repositories/like_repository.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/features/auth/login_screen.dart';
import 'package:dedikodu_app/features/auth/register_screen.dart';
import 'package:dedikodu_app/features/premium/premium_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dedikodu_app/core/utils/date_helper.dart';
import 'package:dedikodu_app/core/widgets/live_time_ago_text.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final UserModel? initialUser;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final _userRepo = UserRepository();
  final _confessionRepo = ConfessionRepository();
  final _commentRepo = CommentRepository();
  final _authService = AuthService();
  
  UserModel? _user;
  List<ConfessionModel> _confessions = [];
  List<ConfessionModel> _likedConfessions = [];
  List<CommentModel> _comments = [];
  
  String _selectedTab = 'confessions'; // confessions, likes, comments
  bool _isLoading = true;
  bool _isLoadingLikes = false;
  bool _isLoadingComments = false;
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _user = widget.initialUser;
      _isLoading = false; // We have data, so not loading user
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userRepo.getUserById(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _user = user;
        });
        
        // Load user's confessions
        _loadConfessions();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _loadConfessions() {
    final currentUserId = _authService.currentUserId;
    final isOwnProfile = currentUserId == widget.userId;

    _confessionRepo.getConfessionsByAuthor(
      widget.userId, 
      includeAnonymous: isOwnProfile,
    ).listen(
      (confessions) {
        if (mounted) {
          setState(() {
            _confessions = confessions;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading confessions: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _recalculateUserStats() async {
    setState(() => _isRecalculating = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('recalculateUserStats');
      
      final result = await callable.call();
      
      if (mounted) {
        // Reload user data to get updated stats
        await _loadUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'İstatistikler güncellendi! '
              'Konu: ${result.data['stats']['confessionCount']}, '
              'Beğeni: ${result.data['stats']['totalLikesReceived']}, '
              'Yorum: ${result.data['stats']['totalCommentsGiven']}',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecalculating = false);
      }
    }
  }

  Future<void> _fixAllUserStats() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Admin İşlemi'),
        content: const Text(
          'TÜM kullanıcıların istatistiklerini yeniden hesaplamak istediğinize emin misiniz?\n\n'
          'Bu işlem uzun sürebilir ve sadece bir kez yapılmalıdır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Evet, Devam Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRecalculating = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('recalculateAllUserStats');
      
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      
      if (mounted) {
        // Reload user data
        await _loadUserData();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Başarılı!'),
            content: Text(
              'Tüm kullanıcı istatistikleri güncellendi!\n\n'
              'Toplam Kullanıcı: ${data['totalUsers']}\n'
              'Başarılı: ${data['successCount']}\n'
              'Hata: ${data['errorCount']}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Hata'),
            content: Text('Hata: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecalculating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Profili'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userRepo.getUserStream(widget.userId),
        initialData: widget.initialUser,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          // Only show loading if we don't have data AND we are waiting
          // But since we use initialData, hasData should be true if logic is correct
          // Logic: if snapshot.hasData use it. 
          
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı'));
          }

          // Initial load of confessions if not done
          if (_confessions.isEmpty && _isLoading) {
             // We can do this safely here as it's a one-off side effect that doesn't trigger loop
             // Or better, move this to initState but only if we have ID.
             // Actually, the current logic calls _loadConfessions() in _loadUserData() called in initState.
             // But we are now ignoring _loadUserData() partly because of StreamBuilder.
             // Let's ensure _loadConfessions() is called once.
             // Since _isLoading starts true, we can check it.
             WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isLoading) _loadConfessions();
             });
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                _buildStatisticsSection(user),
                const SizedBox(height: 16),
                _buildContentSection(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl != null
                ? null
                : Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            '@${user.username ?? 'kullanıcı'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (user.isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  SizedBox(width: 4),
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
          if (user.isPremium) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getDisplayBadge(user),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user.uid != _authService.currentUserId)
            ElevatedButton.icon(
              onPressed: () async {
                final currentUser = _authService.currentUser;
                if (currentUser == null || currentUser.isAnonymous) {
                  _showGuestLoginDialog();
                  return;
                }
                final currentUserData = await _userRepo.getUserById(currentUser.uid);
                if (currentUserData != null && currentUserData.isPremium) {
                  if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivateChatScreen(
                            otherUserId: widget.userId,
                            otherUserName: user.username ?? 'kullanıcı',
                            otherUserProfileImage: user.profileImageUrl,
                          ),
                        ),
                      );
                  }
                } else {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.message),
              label: const Text('Mesaj Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(UserModel user) {
    final isOwnProfile = _authService.currentUserId == widget.userId;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'İstatistikler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  onTap: () => setState(() => _selectedTab = 'confessions'),
                  icon: Icons.article_outlined,
                  label: 'Konu',
                  value: user.confessionCount < 0 ? 0 : user.confessionCount,
                  color: AppTheme.primaryColor,
                  isSelected: _selectedTab == 'confessions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  onTap: () {
                    setState(() => _selectedTab = 'likes');
                    if (_likedConfessions.isEmpty) _loadLikedConfessions();
                  },
                  icon: Icons.favorite_outline, // Standard icon for everyone
                  label: 'Beğeni',
                  value: user.totalLikesReceived < 0 ? 0 : user.totalLikesReceived, // Reverted to Popularity (Received)
                  color: Colors.red,
                  isSelected: _selectedTab == 'likes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  onTap: () {
                    setState(() => _selectedTab = 'comments');
                    if (_comments.isEmpty) _loadComments();
                  },
                  icon: Icons.chat_bubble_outline,
                  label: 'Yorum',
                  value: user.totalCommentsGiven < 0 ? 0 : user.totalCommentsGiven,
                  color: Colors.blue,
                  isSelected: _selectedTab == 'comments',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  onTap: () {}, // No tab for views yet
                  icon: Icons.visibility_outlined,
                  label: 'Görüntülenme',
                  value: user.totalViewsReceived < 0 ? 0 : user.totalViewsReceived,
                  color: Colors.green,
                  isSelected: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadLikedConfessions() async {
    if (_isLoadingLikes) return;
    
    setState(() => _isLoadingLikes = true);
    
    try {
      // 1. Get IDs of liked confessions
      // Note: We need to import LikeRepository first, I'll assume it's available or add import 
      // But since I'm in multi_replace, I can't easily add import if not present.
      // Let's use what we have. If LikeRepository is not imported, I will need a separate step.
      // Checking imports... LikeButton is imported, which uses LikeRepository.
      // But Repository itself needs to be usable here.
      // Actually, I'll instantiate it here.
      
      final likeRepo = LikeRepository(); // Warning: Need import if not present
      final likedIds = await likeRepo.getLikedConfessionIds(widget.userId);
      
      if (likedIds.isEmpty) {
        setState(() {
          _likedConfessions = [];
          _isLoadingLikes = false;
        });
        return;
      }
      
      // 2. Get confessions by IDs
      final confessions = await _confessionRepo.getConfessionsByIds(likedIds);
      
      if (mounted) {
        setState(() {
          _likedConfessions = confessions;
          _isLoadingLikes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLikes = false);
      }
    }
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments) return;
    
    setState(() => _isLoadingComments = true);
    
    try {
      // already instantiated
      
      final currentUserId = _authService.currentUserId;
      final isOwnProfile = currentUserId == widget.userId;
      
      _commentRepo.getCommentsByAuthor(
        widget.userId,
        includeAnonymous: isOwnProfile,
      ).listen(
        (comments) {
          if (mounted) {
            setState(() {
              _comments = comments;
              _isLoadingComments = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Error loading comments: $error');
          if (mounted) {
            setState(() => _isLoadingComments = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Widget _buildContentSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getTabTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if ((_selectedTab == 'likes' && _isLoadingLikes) || 
                  (_selectedTab == 'comments' && _isLoadingComments))
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActiveList(),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedTab) {
      case 'likes':
        return 'Beğendikleri (${_likedConfessions.length})';
      case 'comments':
        return 'Yorumları (${_comments.length})';
      case 'confessions':
      default:
        return 'Konular (${_confessions.length})';
    }
  }

  Widget _buildActiveList() {
    switch (_selectedTab) {
      case 'likes':
        return _buildLikedConfessionsList();
      case 'comments':
        return _buildCommentsList();
      case 'confessions':
      default:
        return _buildConfessionsList();
    }
  }

  Widget _buildConfessionsList() {
    if (_confessions.isEmpty) return _buildEmptyState('Henüz konu paylaşılmadı');
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _confessions.length,
      itemBuilder: (context, index) {
        return _buildConfessionCard(_confessions[index]);
      },
    );
  }
  
  Widget _buildLikedConfessionsList() {
    if (_likedConfessions.isEmpty && !_isLoadingLikes) {
      return _buildEmptyState('Henüz beğenilen konu yok');
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _likedConfessions.length,
      itemBuilder: (context, index) {
        return _buildConfessionCard(_likedConfessions[index]);
      },
    );
  }
  
  Widget _buildCommentsList() {
    if (_comments.isEmpty && !_isLoadingComments) {
      return _buildEmptyState('Henüz yorum yok');
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
               _navigateToCommentContext(comment.confessionId);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Avatar and Username
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: (!comment.isAnonymous && comment.authorImageUrl != null)
                            ? NetworkImage(comment.authorImageUrl!)
                            : null,
                        child: (!comment.isAnonymous && comment.authorImageUrl != null)
                            ? null
                            : Icon(
                                comment.isAnonymous ? Icons.visibility_off : Icons.person,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  NameMaskingHelper.getDisplayName(
                                    isAnonymous: comment.isAnonymous,
                                    fullName: comment.authorName,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: comment.isAnonymous
                                        ? Colors.black54
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            LiveTimeAgoText(
                              dateTime: comment.createdAt,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Menu (Edit/Delete)
                      if (_authService.currentUserId == comment.authorId)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditCommentDialog(comment);
                            } else if (value == 'delete') {
                              _deleteComment(comment);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Düzenle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Sil', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Comment Content
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _navigateToCommentContext(String confessionId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final confession = await _confessionRepo.getConfessionById(confessionId);
      
      if (mounted) Navigator.pop(context); // Close loading
      
      if (confession != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfessionDetailScreen(confession: confession),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Konu bulunamadı veya silinmiş.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    }
  }

  String _getDisplayBadge(UserModel user) {
    // Calculate badges dynamically based on current stats
    // This ensures consistency with ProfileScreen which also calculates dynamically
    final badges = BadgeHelper.calculateBadges(
      confessionCount: user.confessionCount,
      totalLikesReceived: user.totalLikesReceived,
      totalCommentsGiven: user.totalCommentsGiven,
      maxConfessionLikes: 0, // Not tracked in basic stats yet
      uniqueHashtagsUsed: 0, // Not tracked in basic stats yet
    );
    
    if (badges.isEmpty) {
      return BadgeHelper.getBadgeDisplay('new_confessor');
    }
    
    final highestBadge = BadgeHelper.getHighestBadge(badges);
    return BadgeHelper.getBadgeDisplay(highestBadge);
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfessionCard(ConfessionModel confession) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfessionDetailScreen(
                confession: confession,
              ),
            ),
          );
          
          // Refresh data when returning from detail screen
          if (mounted) {
            _loadUserData(); // Refresh stats (likes count etc)
            
            // Refresh current tab content
            if (_selectedTab == 'confessions') {
              _loadConfessions();
            } else if (_selectedTab == 'likes') {
              _loadLikedConfessions();
            } else if (_selectedTab == 'comments') {
              _loadComments();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Avatar and Username
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: (!confession.isAnonymous && confession.authorImageUrl != null)
                        ? NetworkImage(confession.authorImageUrl!)
                        : null,
                    child: (!confession.isAnonymous && confession.authorImageUrl != null)
                        ? null
                        : Icon(
                            confession.isAnonymous ? Icons.visibility_off : Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              NameMaskingHelper.getDisplayName(
                                isAnonymous: confession.isAnonymous,
                                fullName: confession.authorName,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: confession.isAnonymous
                                    ? Colors.black87
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        // City and date row (moved here)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              confession.cityName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            LiveTimeAgoText(
                              dateTime: confession.createdAt,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Menu (Edit/Delete) - Top Right
                  if (_authService.currentUserId == confession.authorId)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditConfessionDialog(confession);
                        } else if (value == 'delete') {
                          _deleteConfession(confession);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),
              
              // Content with clickable hashtags
              HashtagText(
                text: confession.content,
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                onHashtagTap: (hashtag) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HashtagConfessionsScreen(
                        hashtag: hashtag,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Interaction Row
              Row(
                children: [
                  LikeButton(
                    targetType: 'confession',
                    targetId: confession.id,
                    initialLikeCount: confession.likeCount,
                    initialIsLiked: _selectedTab == 'likes',
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${confession.commentCount}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${confession.viewCount}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    return DateHelper.getTimeAgo(dateTime);
  }

  Future<void> _showGuestLoginDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap İşlemleri'),
        content: const Text('Mesaj göndermek için üye olmanız gerekmektedir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'register'),
            child: const Text('Kayıt Ol'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'login'),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );

    if (result == 'login') {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } else if (result == 'register') {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(),
          ),
        );
      }
    }
  }


  // Edit/Delete Helpers
  
  void _showEditConfessionDialog(ConfessionModel confession) {
    final controller = TextEditingController(text: confession.content);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konuyu Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'İçerik...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != confession.content) {
                Navigator.pop(dialogContext);
                try {
                  await _confessionRepo.updateConfessionContent(confession.id, newContent);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Konu güncellendi')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteConfession(ConfessionModel confession) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konuyu Sil'),
        content: const Text('Bu konuyu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _confessionRepo.deleteConfession(confession.id);
                // List will update automatically via Stream
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konu silindi')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(CommentModel comment) {
    final controller = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yorumu Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Yorumunuz...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != comment.content) {
                Navigator.pop(dialogContext);
                try {
                  await _commentRepo.updateComment(comment.confessionId, comment.id, newContent);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum güncellendi')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _commentRepo.deleteComment(comment.confessionId, comment.id);
                // List will update automatically via Stream
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yorum silindi')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
