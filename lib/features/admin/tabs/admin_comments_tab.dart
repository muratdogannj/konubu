import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/constants/app_constants.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:intl/intl.dart';

class AdminCommentsTab extends StatefulWidget {
  const AdminCommentsTab({super.key});

  @override
  State<AdminCommentsTab> createState() => _AdminCommentsTabState();
}

class _AdminCommentsTabState extends State<AdminCommentsTab> {
  final _commentRepo = CommentRepository();
  CommentStatus? _selectedStatus = CommentStatus.pending; // Default to pending

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<CommentStatus?>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: CommentStatus.pending, child: Text('Bekleyen')),
                    DropdownMenuItem(value: CommentStatus.approved, child: Text('Onaylı')),
                    DropdownMenuItem(value: CommentStatus.rejected, child: Text('Reddedilen')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<CommentModel>>(
            stream: _commentRepo.getCommentsForAdmin(status: _selectedStatus),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Text('Görüntülenecek yorum yok'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildCommentCard(comments[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    Color statusColor;
    switch (comment.status) {
      case CommentStatus.approved: statusColor = AppTheme.successColor; break;
      case CommentStatus.pending: statusColor = Colors.orange; break;
      case CommentStatus.rejected: statusColor = AppTheme.errorColor; break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    comment.isAnonymous ? Icons.visibility_off : Icons.person,
                    size: 12,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  NameMaskingHelper.getDisplayName(
                    isAnonymous: comment.isAnonymous,
                    fullName: comment.authorName,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM HH:mm').format(comment.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
             const SizedBox(height: 4),
            Text(
              'ID: ${comment.id}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 if (comment.status != CommentStatus.rejected)
                  TextButton.icon(
                    onPressed: () => _updateStatus(comment, CommentStatus.rejected),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    label: const Text('Reddet', style: TextStyle(color: Colors.red)),
                  ),
                if (comment.status != CommentStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(comment, CommentStatus.approved),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete option for everyone (Admins might want to delete spam entirely)
                  IconButton(
                     onPressed: () => _deleteComment(comment),
                     icon: const Icon(Icons.delete_outline, color: Colors.grey),
                     tooltip: 'Sil',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(CommentModel comment, CommentStatus status) async {
    try {
      if (comment.confessionId.isEmpty) {
        throw 'Confession ID missing';
      }
      await _commentRepo.updateCommentStatus(
        confessionId: comment.confessionId,
        commentId: comment.id,
        status: status,
        moderatorId: 'admin', // Ideally get from Auth
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum ${status == CommentStatus.approved ? "onaylandı" : "reddedildi"}'), 
            backgroundColor: status == CommentStatus.approved ? Colors.green : Colors.orange
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
  
  Future<void> _deleteComment(CommentModel comment) async {
     try {
       if (comment.confessionId.isEmpty) throw 'Confession ID missing';
      await _commentRepo.deleteComment(comment.confessionId, comment.id);
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum silindi'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}
