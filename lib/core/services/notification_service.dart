import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to users who follow a specific city
  Future<void> sendConfessionNotification({
    required String confessionId,
    required int cityPlateCode,
    required String cityName,
    String? districtName,
    required String confessionPreview,
  }) async {
    try {
      // Find users who subscribed to this city
      final usersSnapshot = await _firestore
          .collection('users')
          .where('subscribedCities', arrayContains: cityPlateCode)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('No subscribers found for city: $cityName');
        return;
      }

      // Collect FCM tokens
      final tokens = <String>[];
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (tokens.isEmpty) {
        print('No FCM tokens found for subscribers');
        return;
      }

      // Prepare notification
      final locationText = districtName != null
          ? '$cityName, $districtName'
          : cityName;

      final title = 'Yeni İtiraf - $locationText';
      final body = confessionPreview.length > 100
          ? '${confessionPreview.substring(0, 100)}...'
          : confessionPreview;

      // Send notifications to all tokens
      await _sendToMultipleDevices(
        tokens: tokens,
        title: title,
        body: body,
        data: {
          'confessionId': confessionId,
          'cityName': cityName,
          'cityPlateCode': cityPlateCode.toString(),
          if (districtName != null) 'districtName': districtName,
          'type': 'new_confession',
        },
      );

      print(
        'Sent notifications to ${tokens.length} users for confession: $confessionId',
      );
    } catch (e) {
      print('Error sending confession notification: $e');
    }
  }

  /// Send FCM notification to multiple devices
  /// Note: This is a simplified version. In production, you should use Firebase Cloud Functions
  /// or a backend service to send notifications using the Firebase Admin SDK
  Future<void> _sendToMultipleDevices({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // For web, we'll use the FCM REST API
    // In a real app, this should be done from a secure backend

    // Note: This is a placeholder. Web push notifications from client-side
    // are limited. You should implement this in Firebase Cloud Functions
    // or your backend server using Firebase Admin SDK

    print('Would send notification to ${tokens.length} devices:');
    print('Title: $title');
    print('Body: $body');
    print('Data: $data');

    // TODO: Implement actual FCM sending via Cloud Functions
    // For now, we'll just log the notification
    // In production, create a Cloud Function that:
    // 1. Receives confession approval event
    // 2. Queries users with matching subscribedCities
    // 3. Sends FCM notifications using Admin SDK
  }

  /// Alternative: Trigger a Cloud Function to send notifications
  /// This is the recommended approach for production
  Future<void> triggerNotificationFunction({
    required String confessionId,
    required int cityPlateCode,
    required String cityName,
    String? districtName,
  }) async {
    try {
      // Create a notification request document that Cloud Function will process
      await _firestore.collection('notification_queue').add({
        'confessionId': confessionId,
        'cityPlateCode': cityPlateCode,
        'cityName': cityName,
        'districtName': districtName,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      print('Notification queued for confession: $confessionId');
    } catch (e) {
      print('Error queuing notification: $e');
    }
  }

  /// Send a system notification to a specific user (e.g., Ban/Unban info)
  Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String body,
    String? type = 'system',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('System notification sent to user: $userId');
    } catch (e) {
      print('Error sending system notification: $e');
    }
  }
}
