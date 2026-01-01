import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/data/models/report_model.dart';
import 'package:dedikodu_app/features/reports/widgets/report_dialog.dart';
import 'package:dedikodu_app/features/profile/user_profile_view_screen.dart';
import 'package:dedikodu_app/core/utils/date_helper.dart';
import 'package:dedikodu_app/core/widgets/live_time_ago_text.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback? onReply;
  final bool showReplyButton;

  const CommentItem({
    super.key,
    required this.comment,
    this.onReply,
    this.showReplyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: (!comment.isAnonymous && comment.authorImageUrl != null)
                ? NetworkImage(comment.authorImageUrl!)
                : null,
            child: (!comment.isAnonymous && comment.authorImageUrl != null)
                ? null
                : Icon(
                    comment.isAnonymous ? Icons.visibility_off : Icons.person,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and time
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (!comment.isAnonymous) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileViewScreen(
                                userId: comment.authorId,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        NameMaskingHelper.getDisplayName(
                          isAnonymous: comment.isAnonymous,
                          fullName: comment.authorName,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: comment.isAnonymous ? Colors.black : Colors.blue[800],
                          decoration: comment.isAnonymous ? TextDecoration.none : TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LiveTimeAgoText(
                      dateTime: comment.createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Comment text - Selectable for copying
                SelectableText(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 8),
                
                // Actions (like, reply)
                Row(
                  children: [
                    LikeButton(
                      targetType: 'comment',
                      targetId: comment.id,
                      initialLikeCount: comment.likeCount,
                    ),
                    if (showReplyButton && onReply != null) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.reply, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Yanıtla',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Menu button for comment author
          _buildCommentMenu(context),
        ],
      ),
    );
  }

  Widget _buildCommentMenu(BuildContext context) {
    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Show menu for everyone (report option available to all)
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
      onSelected: (value) async {
        if (value == 'edit') {
          _showEditDialog(context);
        } else if (value == 'delete') {
          _showDeleteDialog(context);
        } else if (value == 'report') {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: ReportType.comment,
              targetId: comment.id,
              confessionId: comment.confessionId,
            ),
          );
        }
      },
      itemBuilder: (context) => [
        if (currentUserId == comment.authorId) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Düzenle'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Sil', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Şikayet Et', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: comment.content);
    final commentRepo = CommentRepository();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Yorumunuzu düzenleyin...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yorum boş olamaz')),
                );
                return;
              }
              
              try {
                await commentRepo.updateComment(
                  comment.confessionId,
                  comment.id,
                  newContent,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum güncellendi')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final commentRepo = CommentRepository();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await commentRepo.deleteComment(
                  comment.confessionId,
                  comment.id,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yorum silindi')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    return DateHelper.getTimeAgo(dateTime);
  }
}
