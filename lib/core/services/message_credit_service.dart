import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';

/// Service to manage message credits for users
class MessageCreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  //  static const int _creditsPerAd = 10; // Her reklam için kredi

  /// Check if user has enough credits to send a message (Premium only)
  Future<bool> hasCredits() async {
    return await isPremium();
  }

  /// Use one message credit (Premium users only)
  Future<bool> useCredit() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return false;

    // Only premium users can send messages
    final premium = await isPremium();
    if (!premium) return false;

    // Track message count for premium users
    await _firestore.collection('users').doc(userId).update({
      'totalMessagesSent': FieldValue.increment(1),
      'dailyMessageCount': FieldValue.increment(1),
    });

    return true;
  }

  /// Check and perform daily reset (removed - no free messages)
  //Future<void> _checkDailyReset(String userId, Map<String, dynamic> userData) async {
  // No daily free messages anymore
  // Users must watch ads or get premium
  //}

  /// Get daily message count
  Future<int> getDailyMessageCount() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return 0;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return 0;

    return userDoc.data()?['dailyMessageCount'] ?? 0;
  }

  /// Check if user is premium
  Future<bool> isPremium() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return false;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    final isPremium = data['isPremium'] ?? false;

    if (!isPremium) return false;

    // Expiry kontrolü
    final expiry = data['premiumExpiry'] as Timestamp?;
    if (expiry == null) return false;

    return expiry.toDate().isAfter(DateTime.now());
  }
}
