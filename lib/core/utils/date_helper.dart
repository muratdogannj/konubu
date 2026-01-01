class DateHelper {
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final createdAt = dateTime.toLocal();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} hafta önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} saniye önce';
    } else {
      // difference <= 0 means now is before createdAt (future) or same time
      // This happens if local clock is behind server time
      // Return "Az önce" for small differences, but handle large future diffs if needed
      return 'Az önce';
    }
  }
}
