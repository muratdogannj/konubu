import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/core/utils/name_masking_helper.dart';

class ShareableConfessionCard extends StatelessWidget {
  final ConfessionModel confession;

  const ShareableConfessionCard({
    super.key,
    required this.confession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, // Fixed width for consistent image size
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF5), // Light warm background (paper-like)
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Author & Location
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  image: (!confession.isAnonymous && confession.authorImageUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(confession.authorImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (!confession.isAnonymous && confession.authorImageUrl != null)
                    ? null
                    : Icon(
                        confession.isAnonymous ? Icons.visibility_off : Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              // Name & Loc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NameMaskingHelper.getDisplayName(
                        isAnonymous: confession.isAnonymous,
                        fullName: confession.authorName,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: confession.isAnonymous ? Colors.black87 : Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocationText(),
                            style: TextStyle(
                              fontSize: 14,
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
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // CONTENT
          Text(
            confession.content,
            style: const TextStyle(
              fontSize: 20,
              height: 1.5,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 32),

          // FOOTER: Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'KONUBU',
                      style: TextStyle(
                        fontFamily: 'Montserrat', // Assuming app uses a nice font
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'google play & app store',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocationText() {
    final parts = <String>[confession.cityName];
    if (confession.districtName != null) {
      parts.add(confession.districtName!);
    }
    return parts.join(', ');
  }
}
