class BadgeHelper {
  // Badge emojis and names
  static const Map<String, String> badgeEmojis = {
    'new_confessor': '🥉',
    'active_confessor': '🥈',
    'elite_confessor': '🥇',
    'city_voice': '💎',
    'legend_confessor': '👑',
    'trend_maker': '🔥',
    'chatty': '💬',
    'beloved': '❤️',
    'hashtag_master': '#️⃣',
  };

  static const Map<String, String> badgeNames = {
    'new_confessor': 'Yeni Yazar',
    'active_confessor': 'Aktif Yazar',
    'elite_confessor': 'Elite Yazar',
    'city_voice': 'Şehrin Sesi',
    'legend_confessor': 'Efsane Yazar',
    'trend_maker': 'Trend Yaratıcı',
    'chatty': 'Konuşkan',
    'beloved': 'Sevilen',
    'hashtag_master': 'Hashtag Ustası',
  };

  static const Map<String, String> badgeDescriptions = {
    'new_confessor': 'İlk konusunu paylaştı',
    'active_confessor': '5 konu paylaştı',
    'elite_confessor': '20 konu paylaştı',
    'city_voice': '50 konu paylaştı',
    'legend_confessor': '100 konu paylaştı',
    'trend_maker': 'Bir konu 100+ beğeni aldı',
    'chatty': '50+ yorum yaptı',
    'beloved': 'Toplam 500+ beğeni aldı',
    'hashtag_master': '10+ farklı hashtag kullandı',
  };

  /// Calculate which badges a user has earned
  static List<String> calculateBadges({
    required int confessionCount,
    required int totalLikesReceived,
    required int totalCommentsGiven,
    required int maxConfessionLikes,
    required int uniqueHashtagsUsed,
  }) {
    final List<String> earnedBadges = [];

    // Confession count badges
    if (confessionCount >= 100) {
      earnedBadges.add('legend_confessor');
    } else if (confessionCount >= 50) {
      earnedBadges.add('city_voice');
    } else if (confessionCount >= 20) {
      earnedBadges.add('elite_confessor');
    } else if (confessionCount >= 5) {
      earnedBadges.add('active_confessor');
    } else if (confessionCount >= 1) {
      earnedBadges.add('new_confessor');
    }

    // Special achievement badges
    if (maxConfessionLikes >= 100) {
      earnedBadges.add('trend_maker');
    }

    if (totalCommentsGiven >= 50) {
      earnedBadges.add('chatty');
    }

    if (totalLikesReceived >= 500) {
      earnedBadges.add('beloved');
    }

    if (uniqueHashtagsUsed >= 10) {
      earnedBadges.add('hashtag_master');
    }

    return earnedBadges;
  }

  /// Get the highest badge (for display)
  static String getHighestBadge(List<String> badges) {
    // Priority order (highest to lowest)
    const priority = [
      'legend_confessor',
      'city_voice',
      'elite_confessor',
      'active_confessor',
      'new_confessor',
      'trend_maker',
      'beloved',
      'chatty',
      'hashtag_master',
    ];

    for (final badge in priority) {
      if (badges.contains(badge)) {
        return badge;
      }
    }

    return '';
  }

  /// Get badge display text (emoji + name)
  static String getBadgeDisplay(String badgeKey) {
    final emoji = badgeEmojis[badgeKey] ?? '';
    final name = badgeNames[badgeKey] ?? '';
    return '$emoji $name';
  }

  /// Get just the emoji
  static String getBadgeEmoji(String badgeKey) {
    return badgeEmojis[badgeKey] ?? '';
  }

  /// Get just the name
  static String getBadgeName(String badgeKey) {
    return badgeNames[badgeKey] ?? '';
  }

  /// Get description
  static String getBadgeDescription(String badgeKey) {
    return badgeDescriptions[badgeKey] ?? '';
  }

  /// Format number with K/M suffix
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
