import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:dedikodu_app/main.dart'; // For navigatorKey
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/features/private_messages/private_chat_screen.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Request notification permission
  Future<bool> requestPermission() async {
    try {
      // 1. Check current status first to avoid unnecessary method calls
      final currentSettings = await _messaging.getNotificationSettings();
      if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
          currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
        return true;
      }

      // 2. Request permission if not determined
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      // 3. Handle race conditions or other errors
      print('⚠️ Notification permission error: $e');
      return false;
    }
  }

  // Initialize and Request permission
  Future<void> initialize() async {
    // Request permission
    final hasPermission = await requestPermission();

    if (!hasPermission) {
      print('❌ Notification permission denied by user/browser.');
      return;
    }

    // Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings, 
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground notification tap
        if (response.payload != null) {
          _handleNavigation(response.payload!);
        }
      },
    );

    // Create Notification Channel for Android
    final androidChannel = const AndroidNotificationChannel(
      'konubu_channel', // id
      'Konubu Bildirimleri', // title
      description: 'Yeni itiraf ve yorum bildirimleri', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Get and save token
    final token = await getToken();
    if (token != null) {
      await saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore(newToken);
    });

    // 1. Handle Terminated State (App was closed)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 2. Handle Background State (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        // Encode data to pass as payload
        String? payload;
        try {
          payload = jsonEncode(message.data);
        } catch (e) {
          print('Error encoding payload: $e');
        }

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'konubu_channel',
              'Konubu Bildirimleri',
              channelDescription: 'Yeni itiraf ve yorum bildirimleri',
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: payload,
        );
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Handle RemoteMessage (Background/Terminated)
  void _handleMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _handleNavigation(message.data);
    }
  }

  // Handle Navigation
  void _handleNavigation(dynamic data) {
    if (data == null) return;

    Map<String, dynamic> messageData;
    
    // Parse data if it comes as a JSON string (from LocalNotification payload)
    if (data is String) {
      try {
        messageData = jsonDecode(data);
      } catch (e) {
        print('Error decoding navigation data: $e');
        // Fallback for old style payloads (just ID)
        if (data.isNotEmpty) {
           _navigateToConfession(data);
        }
        return;
      }
    } else {
      messageData = Map<String, dynamic>.from(data);
    }

    print('Processing navigation for data: $messageData');

    final type = messageData['type'];

    // 1. Handle Private Messages
    if (type == 'new_message') {
      final senderId = messageData['senderId'];
      // Use placeholder title, or fetch user if needed (but we want speed)
      // Usually the notification title has the name "Mehmet mesaj gönderdi".
      // We can't access notification title here easily if passed from background data only.
      // So we use a generic name or "Kullanıcı".
      if (senderId != null && senderId.toString().isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => PrivateChatScreen(
              otherUserId: senderId,
              otherUserName: 'Mesaj', // Placeholder, screen will fetch fresh image anyway
            ),
          ),
        );
      } else {
        print('❌ senderId is missing or empty for message notification');
      }
      return;
    }

    // 2. Handle Confession/Comment/Like/Reply
    // All these point to ConfessionDetail
    final confessionId = messageData['confessionId'];
    if (confessionId != null && confessionId.toString().isNotEmpty) {
      _navigateToConfession(confessionId);
    } else {
      print('❌ confessionId is missing or empty for type: $type');
    }
  }

  void _navigateToConfession(String confessionId) {
    print('Navigating to confession: $confessionId');
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ConfessionDetailScreen(
          confessionId: confessionId,
        ),
      ),
    );
  }

  // ... (rest of the methods: getToken, saveTokenToFirestore, deleteToken)
  // Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: 'BK5pd3kFllWmG1226LF8cks86HWD_Vu-4CbTd19p2Ino1h8VUo0jUSQr1yCBGlrbzcUX0ps7CjDUm0XOSM7Aqbs',
      );
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Save token to Firestore
  Future<void> saveTokenToFirestore(String token) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Unsubscribe (remove token)
  Future<void> deleteToken() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await _messaging.deleteToken();
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}

// Top-level function for background message handler
// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp();
  print('Background message received: ${message.notification?.title}');
}
