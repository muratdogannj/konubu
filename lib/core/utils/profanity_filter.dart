class ProfanityFilter {
  // Türkçe küfür listesi (basitleştirilmiş)
  static const List<String> _badWords = [
    'amk',
    'aq',
    'orospu',
    'piç',
    'sik',
    'göt',
    'yarrak',
    'amcık',
    'pezevenk',
    'kahpe',
    'ibne',
    'puşt',
    'salak',
    'aptal',
    'gerizekalı',
    // Daha fazla eklenebilir
  ];

  /// Metinde küfür var mı kontrol eder
  static bool containsProfanity(String text) {
    final lowerText = text.toLowerCase();
    
    for (final word in _badWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    
    return false;
  }

  /// Küfürleri yıldızla değiştirir
  static String filterProfanity(String text) {
    String filtered = text;
    
    for (final word in _badWords) {
      final regex = RegExp(word, caseSensitive: false);
      filtered = filtered.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    
    return filtered;
  }

  /// Mesaj gönderilebilir mi kontrol eder
  static bool isMessageAllowed(String message) {
    // Boş mesaj kontrolü
    if (message.trim().isEmpty) {
      return false;
    }

    // Uzunluk kontrolü (max 500 karakter)
    if (message.length > 500) {
      return false;
    }

    // Küfür kontrolü
    if (containsProfanity(message)) {
      return false;
    }

    return true;
  }

  /// Mesaj için hata mesajı döndürür
  static String? getErrorMessage(String message) {
    if (message.trim().isEmpty) {
      return 'Mesaj boş olamaz';
    }

    if (message.length > 500) {
      return 'Mesaj çok uzun (max 500 karakter)';
    }

    if (containsProfanity(message)) {
      return 'Mesajınız uygunsuz içerik barındırıyor';
    }

    return null;
  }
}
