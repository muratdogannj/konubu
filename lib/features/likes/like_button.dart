import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/data/repositories/like_repository.dart';

class LikeButton extends StatefulWidget {
  final String targetType;
  final String targetId;
  final int initialLikeCount;
  final bool initialIsLiked;

  const LikeButton({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.initialLikeCount,
    this.initialIsLiked = false,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  final _likeRepo = LikeRepository();
  final _authService = AuthService();
  
  late bool _isLiked;
  late int _likeCount;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkLikeStatus();
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLikeCount != oldWidget.initialLikeCount) {
      if (!_isProcessing) {
        _likeCount = widget.initialLikeCount;
        // Check status again because count changed implies interaction
        _checkLikeStatus();
      }
    }
  }

  Future<void> _checkLikeStatus() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      try {
        final isLiked = await _likeRepo.hasUserLiked(
          userId: userId,
          targetType: widget.targetType,
          targetId: widget.targetId,
        );
        
        if (mounted) {
          setState(() {
            _isLiked = isLiked;
          });
        }
      } catch (e) {
        debugPrint('Error checking like status: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isProcessing) return;
    
    final userId = _authService.currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beğenmek için giriş yapmalısınız')),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    // Optimistic UI update
    final previousIsLiked = _isLiked;
    final previousLikeCount = _likeCount;
    
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Play animation
    _animationController.forward().then((_) => _animationController.reverse());

    try {
      await _likeRepo.toggleLike(
        userId: userId,
        targetType: widget.targetType,
        targetId: widget.targetId,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = previousIsLiked;
          _likeCount = previousLikeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _likeCount > 0 ? _likeCount.toString() : '',
              style: TextStyle(
                color: _isLiked ? Colors.red : Colors.grey[600],
                fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
