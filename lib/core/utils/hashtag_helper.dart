class HashtagHelper {
  /// Extracts hashtags from text content
  /// Example: "itirafını etti #aldatma" -> ["aldatma"]
  static List<String> extractHashtags(String content) {
    if (content.isEmpty) return [];

    // Regex for hashtags (supports Turkish characters)
    final regex = RegExp(r'#[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_]+');
    final matches = regex.allMatches(content);

    // Extract hashtags without # symbol and convert to lowercase
    return matches
        .map((match) => content.substring(match.start + 1, match.end).toLowerCase())
        .toSet() // Remove duplicates
        .toList();
  }

  /// Checks if text contains any hashtags
  static bool hasHashtags(String content) {
    return content.contains(RegExp(r'#[a-zA-ZğüşıöçĞÜŞİÖÇ0-9_]+'));
  }

  /// Formats hashtag for display (adds # prefix)
  static String formatHashtag(String hashtag) {
    return hashtag.startsWith('#') ? hashtag : '#$hashtag';
  }
}
