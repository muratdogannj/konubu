import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin({String method = 'email'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('📊 Analytics: Login logged ($method)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error: $e');
    }
  }

  Future<void> logSignUp({String method = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('📊 Analytics: SignUp logged ($method)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error: $e');
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('📊 Analytics: Screen View logged ($screenName)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error: $e');
    }
  }

  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('📊 Analytics: Custom Event logged ($name)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error: $e');
    }
  }

  Future<void> logConfessionCreated({required String category}) async {
    await logCustomEvent(
      name: 'create_confession',
      parameters: {'category': category},
    );
  }

  Future<void> logCommentCreated({required String confessionId}) async {
    await logCustomEvent(
      name: 'create_comment',
      parameters: {'confession_id': confessionId},
    );
  }
}
