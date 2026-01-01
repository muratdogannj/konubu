import 'package:shared_preferences/shared_preferences.dart';

class GuestAccessService {
  static final GuestAccessService _instance = GuestAccessService._internal();
  factory GuestAccessService() => _instance;
  GuestAccessService._internal();

  static const String _readCreditsKey = 'guest_read_credits';
  static const int _adRewardCredits = 3; // Her reklam 3 okuma hakkı verir

  SharedPreferences? _prefs;

  /// Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get remaining read credits
  int get remainingCredits {
    if (_prefs == null) return 0;
    return _prefs!.getInt(_readCreditsKey) ?? 0;
  }

  /// Check if user can read
  bool canRead() {
    return remainingCredits > 0;
  }

  /// Use one read credit
  Future<void> useCredit() async {
    if (_prefs == null) return;

    final current = remainingCredits;
    if (current > 0) {
      await _prefs!.setInt(_readCreditsKey, current - 1);
      print('📖 Okuma hakkı kullanıldı. Kalan: ${current - 1}');
    }
  }

  /// Grant credits after watching ad
  Future<void> grantAdReward() async {
    if (_prefs == null) return;

    final current = remainingCredits;
    await _prefs!.setInt(_readCreditsKey, current + _adRewardCredits);
    print(
      '🎁 +$_adRewardCredits okuma hakkı verildi. Toplam: ${current + _adRewardCredits}',
    );
  }

  /// Reset credits (for testing or registered users)
  Future<void> resetCredits() async {
    if (_prefs == null) return;
    await _prefs!.setInt(_readCreditsKey, 0);
    print('🔄 Okuma hakları sıfırlandı');
  }

  /// Set unlimited credits for registered users
  Future<void> setUnlimited() async {
    if (_prefs == null) return;
    await _prefs!.setInt(_readCreditsKey, 999999);
    print('♾️ Sınırsız okuma hakkı verildi');
  }
}
