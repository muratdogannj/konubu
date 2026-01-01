
class ContentModerator {
  // Regex to catch standard Turkish phone numbers
  // Matches:
  // 05xx xxx xx xx
  // 5xx xxx xx xx
  // +90 5xx ...
  // 0 5xx ...
  static final RegExp _phoneRegex = RegExp(
    r'((\+?90\s?)?0?5\d{2}\s?\d{3}\s?\d{2}\s?\d{2})|' // Mobile standard
    r'(\b0?5\d{9}\b)|' // Mobile continuous
    r'(\b0?5\d{2}\s\d{3}\s\d{4}\b)', // Mobile alternate spacing
    multiLine: true,
  );

  // Expanded profanity/offensive words list
  static final List<String> _profanityList = [
    'amk',
    'aq',
    'sik',
    'sok',
    'yarak',
    'yarrak',
    'oç',
    'pic',
    'piç',
    'gavat',
    'kavat',
    'kahpe',
    'orospu',
    'siktir',
    'ananı',
    'bacını',
    'ibne',
    'puşt',
    'yavşak',
    'kaşar',
    'sikik',
    'mal', 
    'gerizekalı',
    'salak',
    'aptal',
    'ahmak',
    'öküz',
    'davul',
    'şerefsiz',
    'serefsiz',
    'haysiyetsiz',
    'yalaka',
    'dangalak',
  ];
  
  // Mapping Turkish number words to digits, including compounds
  static final Map<String, String> _numberWords = {
    // Compounds first (longer matches)
    'ikiyüz': '2',
    'üçyüz': '3',
    'ucyuz': '3',
    'dörtyüz': '4',
    'dortyuz': '4',
    'beşyüz': '5',
    'besyuz': '5',
    'altıyüz': '6',
    'altiyuz': '6',
    'yediyüz': '7',
    'sekizyüz': '8',
    'dokuzyüz': '9',
    
    // Standard words
    'sıfır': '0',
    'sifir': '0',
    'bir': '1',
    'iki': '2',
    'üç': '3',
    'uc': '3',
    'dört': '4',
    'dort': '4',
    'beş': '5',
    'bes': '5',
    'altı': '6',
    'alti': '6',
    'yedi': '7',
    'sekiz': '8',
    'dokuz': '9',
    'on': '1',     // Representing the '1' in 10
    'yirmi': '2',  // Representing the '2' in 20
    'otuz': '3',
    'kırk': '4',
    'kirk': '4',
    'elli': '5',
    'altmış': '6',
    'altmis': '6',
    'yetmiş': '7',
    'yetmis': '7',
    'seksen': '8',
    'doksan': '9',
    'yüz': '',     // Filler in phone numbers often (500 -> 5-0-0? No, 532 is said beş yüz otuz iki -> 5-3-2)
  };

  /// Checks if the text contains any phone number pattern, including text-based ones
  static bool hasPhoneNumber(String text) {
    if (_phoneRegex.hasMatch(text)) return true;
    return _hasTextPhoneNumber(text);
  }

  /// Converts text numbers to digits and checks regex
  static bool _hasTextPhoneNumber(String text) {
    String lowerText = text.toLowerCase();
    
    // Normalize: replace known words with digits
    // We sort keys by length descending to match compounds first "ikiyüz" before "iki"
    final sortedKeys = _numberWords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
      
    // Replace logic: scan and replace
    // We scan token by token to avoid partial word matches in non-number contexts
    // But compounds "ikiyüz" are tokens themselves.
    // Let's try to normalize valid number words to digits.
    
    final tokens = lowerText.split(RegExp(r'[\s\.,_-]+'));
    StringBuffer digitBuffer = StringBuffer();
    
    for (var token in tokens) {
      bool matched = false;
      // Check exact match first against our sorted keys
      for (final key in sortedKeys) {
        if (token == key) {
          digitBuffer.write(_numberWords[key]);
          matched = true;
          break;
        }
      }
      
      if (!matched) {
        // If it's already digits
        if (RegExp(r'^\d+$').hasMatch(token)) {
           digitBuffer.write(token);
        }
      }
    }
    
    final normalizedNumbers = digitBuffer.toString();
    
    // Check pattern: 0?5xxxxxxxxx (10 or 11 digits starting with 5 or 05)
    final textPhoneRegex = RegExp(r'(0?5\d{9})');
    return textPhoneRegex.hasMatch(normalizedNumbers);
  }

  /// Checks if text contains profanity
  static bool hasProfanity(String text) {
    return getProfanityWords(text).isNotEmpty;
  }

  /// Identifies all profanity words in the text
  static List<String> getProfanityWords(String text) {
    if (text.isEmpty) return [];
    
    final lowerText = text.toLowerCase();
    final List<String> foundBadWords = [];
    
    // Split text into tokens by whitespace and common punctuation
    // This avoids \b issues with Turkish characters
    final tokens = lowerText.split(RegExp(r'[\s\.,;:\?!\(\)\[\]\{\}_-]+'));

    // 1. Strict Exact Matches (Whole words only)
    final strictWords = ['mal', 'aq', 'amk', 'oç', 'pic', 'piç'];
    
    // 2. Prefix Matches (Starts with...)
    final prefixWords = [
      'sik', 'sok', 'yarak', 'yarrak', 'gavat', 'kavat', 'kahpe', 
      'orospu', 'ibne', 'puşt', 'yavşak', 'kaşar', 'şerefsiz', 'serefsiz',
      'haysiyetsiz', 'yalaka', 'dangalak', 'gerizekalı', 'amcık', 'yarram'
    ];

    for (final token in tokens) {
      if (token.isEmpty) continue;
      
      // Check strict words
      if (strictWords.contains(token)) {
        foundBadWords.add(token);
        continue; 
      }
      
      // Check prefix words
      for (final prefix in prefixWords) {
        if (token.startsWith(prefix)) {
          foundBadWords.add(prefix);
          break; // Stop checking prefixes for this token
        }
      }
    }
    
    // 3. Broad Containment (for specific phrases that might be hidden inside words)
    // Kept as 'contains' because these are distinct enough
    final broadWords = ['ananı', 'bacını']; 
    for (final word in broadWords) {
      if (lowerText.contains(word)) {
        foundBadWords.add(word);
      }
    }
    
    return foundBadWords.toSet().toList(); // Unique words only
  }

  /// Returns a specific checking result
  static ModerationResult check(String text) {
    if (hasPhoneNumber(text)) {
      return ModerationResult(isValid: false, message: "Telefon numarası paylaşmak yasaktır.");
    }
    
    final badWords = getProfanityWords(text);
    if (badWords.isNotEmpty) {
      final joinedWords = badWords.join(", ");
      return ModerationResult(
        isValid: false, 
        message: "İçerik uygunsuz ifadeler içeriyor ($joinedWords)",
        foundWords: badWords,
      );
    }
    
    return ModerationResult(isValid: true);
  }
}

class ModerationResult {
  final bool isValid;
  final String? message;
  final List<String>? foundWords;

  ModerationResult({
    required this.isValid, 
    this.message,
    this.foundWords,
  });
}
