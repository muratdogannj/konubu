import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/guest_access_service.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/features/comments/widgets/comment_item.dart';
import 'package:dedikodu_app/features/comments/widgets/comment_input.dart';
import 'package:dedikodu_app/features/hashtag/hashtag_confessions_screen.dart';
import 'package:dedikodu_app/features/confession/edit_confession_screen.dart';
import 'package:dedikodu_app/data/models/report_model.dart';
import 'package:dedikodu_app/features/reports/widgets/report_dialog.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dedikodu_app/core/services/ad_service.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:dedikodu_app/data/models/user_model.dart';

import 'package:screenshot/screenshot.dart';
import 'package:dedikodu_app/features/confession/widgets/shareable_confession_card.dart';

class ConfessionDetailScreen extends StatefulWidget {
  final ConfessionModel? confession;
  final String? confessionId;

  const ConfessionDetailScreen({
    super.key,
    this.confession,
    this.confessionId,
  }) : assert(confession != null || confessionId != null, 
       'Either confession or confessionId must be provided');

  @override
  State<ConfessionDetailScreen> createState() => _ConfessionDetailScreenState();
}

class _ConfessionDetailScreenState extends State<ConfessionDetailScreen> {
  final _screenshotController = ScreenshotController();
  final _confessionRepo = ConfessionRepository();
  final _commentRepo = CommentRepository();
  final _authService = AuthService();
  final _guestAccessService = GuestAccessService();
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _showFullContent = false;
  bool _isGuest = false;

  bool _isLoading = true;
  ConfessionModel? _confession;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkGuestStatus();
    
    if (widget.confession != null) {
      setState(() {
        _confession = widget.confession;
        _isLoading = false;
      });
      _incrementViewCount();
    } else if (widget.confessionId != null) {
      _loadConfession(widget.confessionId!);
    }
  }

  Future<void> _loadConfession(String id) async {
    try {
      final confession = await _confessionRepo.getConfessionById(id);
      if (confession != null) {
        if (mounted) {
          setState(() {
            _confession = confession;
            _isLoading = false;
          });
          _incrementViewCount();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Konu bulunamadı veya silinmiş';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Hata: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkGuestStatus() async {
    await _guestAccessService.initialize();
    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        _isGuest = user?.isAnonymous ?? true;
        // Kayıtlı kullanıcılar için tam içeriği göster
        _showFullContent = !_isGuest || _guestAccessService.canRead();
      });
    }
  }

  Future<void> _incrementViewCount() async {
    if (_confession == null) return;
    try {
      await _confessionRepo.incrementViewCount(_confession!.id);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _confession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Bir hata oluştu'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konu Detayı'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildConfessionCard(),
                const SizedBox(height: 24),
                _buildCommentsSection(),
              ],
            ),
          ),
          CommentInput(
            confessionId: _confession!.id,
            parentCommentId: _replyingToCommentId,
            replyingTo: _replyingToAuthorName,
            onCommentPosted: () {
              setState(() {
                _replyingToCommentId = null;
                _replyingToAuthorName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfessionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_confession!.isAnonymous && _confession!.authorId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileViewScreen(
                              userId: _confession!.authorId!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: (!_confession!.isAnonymous && _confession!.authorImageUrl != null)
                              ? NetworkImage(_confession!.authorImageUrl!)
                              : null,
                          child: (!_confession!.isAnonymous && _confession!.authorImageUrl != null)
                              ? null
                              : Icon(
                                  _confession!.isAnonymous ? Icons.visibility_off : Icons.person,
                                  color: AppTheme.primaryColor,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                NameMaskingHelper.getDisplayName(
                                  isAnonymous: _confession!.isAnonymous,
                                  fullName: _confession!.authorName,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _confession!.isAnonymous ? Colors.black : Colors.blue[800],
                                  decoration: _confession!.isAnonymous ? TextDecoration.none : TextDecoration.underline,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _buildLocationText(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // More options button - top right
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Daha fazla',
                  onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareConfession();
                      break;
                    case 'report':
                      showDialog(
                        context: context,
                        builder: (context) => ReportDialog(
                          type: ReportType.confession,
                          targetId: _confession!.id,
                        ),
                      );
                      break;
                    case 'edit':
                      _editConfession();
                      break;
                    case 'delete':
                      _showDeleteConfessionDialog();
                      break;
                  }
                },
                  itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: Colors.grey),
                        SizedBox(width: 12),
                        Text('Paylaş'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Şikayet Et', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                  // Edit and Delete only for author
                  if (_confession!.authorId == _authService.currentUserId) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content - Blurred for guest users
            _buildContentSection(),
            const SizedBox(height: 16),
            
            // Interaction Row
            Row(
              children: [
                LikeButton(
                  targetType: 'confession',
                  targetId: _confession!.id,
                  initialLikeCount: _confession!.likeCount,
                ),
                const SizedBox(width: 16),
                _buildStat(Icons.chat_bubble_outline, _confession!.commentCount),
                const SizedBox(width: 16),
                _buildStat(Icons.visibility_outlined, _confession!.viewCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Yorumlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_confession!.commentCount} yorum',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<UserModel?>(
          stream: (_authService.currentUser?.isAnonymous ?? true)
              ? Stream.value(null)
              : UserRepository().getUserStream(_authService.currentUser!.uid),
          builder: (context, userSnapshot) {
            final isPremium = userSnapshot.data?.isPremium ?? false;

            return StreamBuilder<List<CommentModel>>(
              stream: _commentRepo.getComments(_confession!.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz yorum yok',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'İlk yorumu sen yap!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < comments.length; i++) ...[
                      Column(
                        children: [
                          CommentItem(
                            comment: comments[i],
                            onReply: () {
                              setState(() {
                                _replyingToCommentId = comments[i].id;
                                _replyingToAuthorName = NameMaskingHelper.getDisplayName(
                                  isAnonymous: comments[i].isAnonymous,
                                  fullName: comments[i].authorName,
                                );
                              });
                            },
                          ),
                          // Replies
                          StreamBuilder<List<CommentModel>>(
                            stream: _commentRepo.getReplies(comments[i].id),
                            builder: (context, replySnapshot) {
                              if (!replySnapshot.hasData || replySnapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(left: 40),
                                child: Column(
                                  children: replySnapshot.data!.map((reply) {
                                    return CommentItem(
                                      comment: reply,
                                      showReplyButton: false,
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                      // Show banner ad after every 3 comments ONLY if not premium
                      if (!isPremium && (i + 1) % 3 == 0 && i < comments.length - 1)
                        _buildBannerAd(),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _buildLocationText() {
    final parts = <String>[_confession!.cityName];
    if (_confession!.districtName != null) {
      parts.add(_confession!.districtName!);
    }
    return parts.join(', ');
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    // Kayıtlı kullanıcı veya okuma hakkı varsa tam içeriği göster
    if (_showFullContent) {
      return SelectableHashtagText(
        text: _confession!.content,
        style: const TextStyle(fontSize: 16, height: 1.6),
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
      );
    }

    // Misafir kullanıcı için blur efekti
    final lines = _confession!.content.split('\n');
    final previewLines = lines.take(3).join('\n');
    final hasMore = lines.length > 3;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlk 3 satır
            SelectableHashtagText(
              text: previewLines,
              style: const TextStyle(fontSize: 16, height: 1.6),
              onHashtagTap: (hashtag) {
                // Misafir kullanıcı hashtag'e tıklayamaz
              },
            ),
            
            if (hasMore) ...[
              const SizedBox(height: 8),
              // Blur efekti ile kapalı kısım
              ClipRect(
                child: Stack(
                  children: [
                    Text(
                      lines.skip(3).join('\n'),
                      style: const TextStyle(fontSize: 16, height: 1.6),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Devamını Oku Butonu
              Center(
                child: ElevatedButton.icon(
                  onPressed: _handleContinueReading,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Devamını Oku'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Bilgilendirme
              Center(
                child: Text(
                  'Kalan okuma hakkı: ${_guestAccessService.remainingCredits}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _handleContinueReading() async {
    // Okuma hakkı kontrolü
    if (_guestAccessService.canRead()) {
      // Hak varsa direkt göster
      await _guestAccessService.useCredit();
      setState(() {
        _showFullContent = true;
      });
      return;
    }

    // Hak yoksa dialog göster
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Devam Etmek İçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reklam izleyerek 3 itiraf okuma hakkı kazanabilir veya kayıt olarak sınırsız erişim sağlayabilirsiniz.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'register'),
            child: const Text('Kayıt Ol'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'watch_ad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reklam İzle'),
          ),
        ],
      ),
    );

    if (result == 'watch_ad') {
      // Web'de AdMob çalışmadığı için simüle et
      // Mobil platformda gerçek reklam gösterilecek
      await _showAdSimulation();
    } else if (result == 'register') {
      // Kayıt ekranına yönlendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt ekranına yönlendiriliyorsunuz...'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _showAdSimulation() async {
    // Web için simülasyon (mobilde gerçek reklam gösterilecek)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reklam Gösteriliyor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Lütfen bekleyin...'),
            const SizedBox(height: 8),
            Text(
              '(Web sürümünde simülasyon. Mobil uygulamada gerçek reklam gösterilecek)',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // 3 saniye bekle (reklam simülasyonu)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context); // Dialog'u kapat
      
      // Ödül ver
      await _guestAccessService.grantAdReward();
      await _guestAccessService.useCredit();
      
      setState(() {
        _showFullContent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎁 +3 okuma hakkı kazandınız! Kalan: ${_guestAccessService.remainingCredits}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Konuyu Sil'),
          ],
        ),
        content: const Text(
          'Bu konuyu silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz ve tüm yorumlar da silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteConfession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConfession() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _confessionRepo.deleteConfession(_confession!.id);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Go back to home
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konu başarıyla silindi'),
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

  Future<void> _shareConfession() async {
    // URL Link Sharing Strategy
    final confessionId = _confession!.id;
    
    // CUSTOM DOMAIN SETUP
    // IMPORTANT: You must add 'konubu.app' to Firebase Console -> Hosting -> Connect Domain
    const baseUrl = 'https://konubu.app';
    
    final shareUrl = '$baseUrl/c/$confessionId';
    final storeUrl = '$baseUrl/download'; 

    final shareText = '''
🔥 KONUBU'da bir itiraf paylaşıldı!

Konuyu görüntülemek için tıkla:
$shareUrl

Uygulamayı indir:
$storeUrl
''';

      await Share.share(
        'https://konubu.app/c/${_confession!.id}',
        subject: 'KONUBU Paylaşımı',
      );
  }

  void _editConfession() {
    // Navigate to edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditConfessionScreen(confession: _confession!),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context); // Go back to refresh
      }
    });
  }

  Widget _buildBannerAd() {
    final adService = AdService();
    final bannerAd = adService.createBannerAd();
    
    if (bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 60,
      child: AdWidget(ad: bannerAd),
    );
  }
}
