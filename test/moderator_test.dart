
import 'package:flutter_test/flutter_test.dart';
import 'package:dedikodu_app/core/utils/content_moderator.dart';

void main() {
  group('ContentModerator Tests', () {
    test('Should detect text-based phone number', () {
      final text = "sıfır beş yüz otuz iki ikiyüz yirmi yedi sıfır beş altmış beş";
      final hasPhone = ContentModerator.hasPhoneNumber(text);
      expect(hasPhone, isTrue, reason: "Should detect text phone number");
      
      final result = ContentModerator.check(text);
      expect(result.isValid, isFalse, reason: "Check should return invalid");
    });
    
     test('Should detect standard phone number', () {
      final text = "Numaram 0532 123 45 67";
      final hasPhone = ContentModerator.hasPhoneNumber(text);
      expect(hasPhone, isTrue);
    });

    test('Should detect profanity', () {
      final text = "Bu bir şerefsiz denemesidir";
      final hasProfanity = ContentModerator.hasProfanity(text);
      expect(hasProfanity, isTrue);
    });
    
     test('Should detect profanity from expanded list', () {
      final text = "yalaka insan";
      final hasProfanity = ContentModerator.hasProfanity(text);
      expect(hasProfanity, isTrue);
    });
  });
}
