import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage guest user ad quota
class GuestAdQuotaService {
  static const String _quotaKey = 'guest_confession_quota';
  static const String _lastResetKey = 'guest_quota_last_reset';
  static const int _quotaPerAd = 3; // Her reklam için 3 konu okuma hakkı

  /// Get remaining confession quota for guest user
  Future<int> getRemainingQuota() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Günlük reset kontrolü
    await _checkDailyReset(prefs);
    
    return prefs.getInt(_quotaKey) ?? 0;
  }

  /// Use one quota (when viewing a confession)
  Future<bool> useQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final currentQuota = await getRemainingQuota();
    
    if (currentQuota <= 0) {
      return false; // Kota yok
    }
    
    await prefs.setInt(_quotaKey, currentQuota - 1);
    return true;
  }

  /// Add quota after watching ad
  Future<void> addQuotaFromAd() async {
    final prefs = await SharedPreferences.getInstance();
    final currentQuota = await getRemainingQuota();
    await prefs.setInt(_quotaKey, currentQuota + _quotaPerAd);
  }

  /// Check if daily reset is needed
  Future<void> _checkDailyReset(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastReset != today) {
      // Yeni gün, kotayı sıfırla
      await prefs.setInt(_quotaKey, 0);
      await prefs.setString(_lastResetKey, today);
    }
  }

  /// Reset quota (for testing)
  Future<void> resetQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quotaKey, 0);
  }
}
