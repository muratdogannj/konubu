import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/data/repositories/confession_repository.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/features/likes/like_button.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';
import 'package:dedikodu_app/core/widgets/hashtag_text.dart';
import 'package:dedikodu_app/core/utils/date_helper.dart';
import 'package:dedikodu_app/core/widgets/live_time_ago_text.dart';

class HashtagConfessionsScreen extends StatefulWidget {
  final String hashtag;

  const HashtagConfessionsScreen({
    super.key,
    required this.hashtag,
  });

  @override
  State<HashtagConfessionsScreen> createState() => _HashtagConfessionsScreenState();
}

class _HashtagConfessionsScreenState extends State<HashtagConfessionsScreen> {
  final _confessionRepo = ConfessionRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu konu konuşuluyor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '#${widget.hashtag}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ConfessionModel>>(
        stream: _confessionRepo.getConfessionsByHashtag(widget.hashtag),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final confessions = snapshot.data ?? [];

          if (confessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tag,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '#${widget.hashtag} ile ilgili itiraf yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: confessions.length,
            itemBuilder: (context, index) {
              return _buildConfessionCard(confessions[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildConfessionCard(ConfessionModel confession) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfessionDetailScreen(
                confession: confession,
              ),
            ),
          );
        },
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
                    child: Icon(
                      confession.isAnonymous ? Icons.visibility_off : Icons.person,
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
                            isAnonymous: confession.isAnonymous,
                            fullName: confession.authorName,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14),
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
                ],
              ),
              const SizedBox(height: 12),
              
              // Content with clickable hashtags - wrapped to prevent card tap
              GestureDetector(
                onTap: () {}, // Absorb taps to prevent card navigation
                child: HashtagText(
                  text: confession.content,
                  style: const TextStyle(
                    fontSize: 15, 
                    height: 1.5,
                    color: Colors.black87,
                  ),
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
              ),
              const SizedBox(height: 12),
              
              // Interaction Row
              Row(
                children: [
                  LikeButton(
                    targetType: 'confession',
                    targetId: confession.id,
                    initialLikeCount: confession.likeCount,
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
}
