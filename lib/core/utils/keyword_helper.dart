
class KeywordHelper {
  /// Generates a list of keywords for search indexing
  /// [indexPrefixes] If true, generates prefixes for words (e.g. "kalem" -> "kal", "kale", "kalem")
  static List<String> generateKeywords(String text, {bool indexPrefixes = false}) {
    if (text.isEmpty) return [];

    // Convert to lowercase and replace punctuation with spaces
    // Keep Turkish characters but remove standard punctuation
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), ' ');

    List<String> keywords = [];
    
    // Split by whitespace
    List<String> words = cleanText.split(RegExp(r'\s+'));

    for (String word in words) {
      if (word.length >= 2) { // Filter out single characters
        keywords.add(word);
        
        if (indexPrefixes && word.length >= 3) {
          // Generate prefixes for partial search (start-with)
          // Min 3 chars to avoid noise (e.g. don't index "ka" for "kalem")
          for (int i = 3; i < word.length; i++) {
            keywords.add(word.substring(0, i));
          }
        }
      }
    }

    return keywords.toSet().toList(); // Unique keywords only
  }
}
