import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/core/widgets/live_time_ago_text.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/features/hashtag/hashtag_confessions_screen.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:share_plus/share_plus.dart';

import 'package:screenshot/screenshot.dart';
import 'package:dedikodu_app/features/confession/widgets/shareable_confession_card.dart';

class ConfessionCard extends StatefulWidget {
  final ConfessionModel confession;
  final bool showLocation;
  final VoidCallback? onTap;

  const ConfessionCard({
    super.key,
    required this.confession,
    this.showLocation = true,
    this.onTap,
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> {
  final _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: (!widget.confession.isAnonymous && widget.confession.authorImageUrl != null)
                        ? NetworkImage(widget.confession.authorImageUrl!)
                        : null,
                    child: (!widget.confession.isAnonymous && widget.confession.authorImageUrl != null)
                        ? null
                        : Icon(
                            widget.confession.isAnonymous ? Icons.visibility_off : Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: widget.confession.isAnonymous || widget.confession.authorId == null || widget.confession.authorId!.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileViewScreen(
                                        userId: widget.confession.authorId!,
                                      ),
                                    ),
                                  );
                                },
                          child: Row(
                            children: [
                              Text(
                                widget.confession.isAnonymous
                                    ? NameMaskingHelper.maskUsername(widget.confession.authorName)
                                    : '@${widget.confession.authorName ?? 'kullanıcı'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: widget.confession.isAnonymous
                                      ? Colors.black54
                                      : AppTheme.primaryColor,
                                  decoration: widget.confession.isAnonymous
                                      ? null
                                      : TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (widget.showLocation) ...[
                              const Icon(Icons.location_on, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _buildLocationText(widget.confession),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            LiveTimeAgoText(
                              dateTime: widget.confession.createdAt,
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
                ],
              ),
              const SizedBox(height: 12),
              
              // Content with clickable hashtags
              _ExpandableConfessionText(
                confession: widget.confession,
                onReadMore: widget.onTap ?? () {},
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
                    targetId: widget.confession.id,
                    initialLikeCount: widget.confession.likeCount,
                  ),
                  const SizedBox(width: 16),
                  _buildStatButton(Icons.chat_bubble_outline, '${widget.confession.commentCount}'),
                  const SizedBox(width: 16),
                  _buildStatButton(Icons.visibility_outlined, '${widget.confession.viewCount}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      _shareConfession(widget.confession);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationText(ConfessionModel confession) {
    final parts = <String>[confession.cityName];
    if (confession.districtName != null) {
      parts.add(confession.districtName!);
    }
    return parts.join(', ');
  }

  Widget _buildStatButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _shareConfession(ConfessionModel confession) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görsel hazırlanıyor...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Capture widget as image
      final uint8List = await _screenshotController.captureFromWidget(
        ShareableConfessionCard(confession: confession),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      // Share image directly from memory (Works on Web & Mobile)
      final xFile = XFile.fromData(
        uint8List,
        mimeType: 'image/png',
        name: 'konubu_share.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'KONUBU\'da bunu gördüm! 👀\n#KONUBU',
        subject: 'KONUBU Paylaşımı',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım hatası: $e')),
        );
      }
    }
  }
}

class _ExpandableConfessionText extends StatelessWidget {
  final ConfessionModel confession;
  final Function(String) onHashtagTap;
  final VoidCallback onReadMore;

  const _ExpandableConfessionText({
    required this.confession,
    required this.onHashtagTap,
    required this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    final fullText = confession.content;
    
    // User requested strict 50% visibility
    int truncateAt = (fullText.length * 0.5).ceil();
    if (truncateAt < 1 && fullText.isNotEmpty) {
      truncateAt = 1;
    }
    
    bool shouldTruncate = fullText.length > truncateAt;
    
    final displayText = shouldTruncate ? fullText.substring(0, truncateAt) : fullText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HashtagText(
          text: displayText + (shouldTruncate ? '...' : ''),
          onHashtagTap: onHashtagTap,
          style: const TextStyle(
            fontSize: 15, 
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        if (shouldTruncate)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: onReadMore,
              child: const Text(
                'Devamını Oku',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
