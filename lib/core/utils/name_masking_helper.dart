class NameMaskingHelper {
  /// Gets display name based on anonymity
  /// - Anonymous users: masked name (t**** u***)
  /// - Non-anonymous users: full name (Taha Uslu)
  static String getDisplayName({
    required bool isAnonymous,
    required String? fullName,
  }) {
    // Use default name if fullName is empty
    final name = (fullName == null || fullName.trim().isEmpty) 
        ? 'Gizli Kullanıcı' 
        : fullName.trim();

    if (isAnonymous) {
      // Show masked name for anonymous users
      return maskName(name);
    } else {
      // Show full name for non-anonymous users
      return name;
    }
  }

  /// Masks a full name to show only first letters
  /// Example: "Murat Yılmaz" -> "M*** Y***"
  static String maskName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Anonim';
    }

    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return 'Anonim';

    final maskedParts = parts.map((part) {
      if (part.isEmpty) return '';
      if (part.length == 1) return part;
      // Convert to lowercase and mask
      final lowerPart = part.toLowerCase();
      return lowerPart[0] + '*' * (lowerPart.length - 1);
    }).where((part) => part.isNotEmpty);

    return maskedParts.join(' ');
  }

  /// Masks a username to show only first letter
  /// Example: "taha_uslu" -> "t*****"
  static String maskUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'anonim';
    }

    final cleaned = username.trim().toLowerCase();
    if (cleaned.length == 1) return cleaned;
    
    return cleaned[0] + '*' * (cleaned.length - 1);
  }

  /// Gets initials from full name
  /// Example: "Murat Yılmaz" -> "MY"
  static String getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'A';
    }

    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return 'A';

    final initials = parts
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();

    return initials.isEmpty ? 'A' : initials;
  }
}
