import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/models/comment_model.dart';
import 'package:dedikodu_app/data/repositories/comment_repository.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';

class CommentInput extends StatefulWidget {
  final String confessionId;
  final String? parentCommentId;
  final String? replyingTo;
  final VoidCallback? onCommentPosted;

  const CommentInput({
    super.key,
    required this.confessionId,
    this.parentCommentId,
    this.replyingTo,
    this.onCommentPosted,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _commentController = TextEditingController();
  final _authService = AuthService();
  final _commentRepo = CommentRepository();
  final _userRepo = UserRepository();
  bool _isSubmitting = false;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = _authService.currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız')),
        );
      }
      return;
    }

    // Block Guest/Anonymous users
    if (_authService.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Misafirler yorum yapamaz. Lütfen kayıt olun.'),
            action: SnackBarAction(
              label: 'Giriş Yap',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to welcome/auth screen
                // Note: Navigator logic might depend on app structure, 
                // but usually signing out triggers AuthWrapper update
                _authService.signOut(); 
              },
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get user info
      final user = await _userRepo.getUserById(userId);
      final authorName = user?.username ?? 'kullanıcı';

      final comment = CommentModel(
        id: '',
        confessionId: widget.confessionId,
        content: content,
        authorId: userId,
        authorName: authorName,
        authorImageUrl: user?.profileImageUrl,
        isAnonymous: _isAnonymous,
        parentCommentId: widget.parentCommentId,
        status: CommentStatus.approved, // Auto-approve comments
        createdAt: DateTime.now(),
      );

      await _commentRepo.createComment(comment);



      if (mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz paylaşıldı!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onCommentPosted?.call();
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.replyingTo} kullanıcısına yanıt veriyorsunuz',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: widget.parentCommentId != null
                        ? 'Yanıtınızı yazın...'
                        : 'Yorumunuzu yazın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              
              IconButton(
                onPressed: _isSubmitting ? null : _submitComment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          
          // Anonymous toggle
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) => setState(() => _isAnonymous = value ?? false),
              ),
              const Text('Anonim olarak gönder'),
            ],
          ),
        ],
      ),
    );
  }
}
