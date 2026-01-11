import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/main.dart'; // To access navigatorKey

class DeepLinkService {
  // Singleton instance
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize() async {
    _appLinks = AppLinks();

    // Check initial link (cold start)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('Deep Link Initial Access Error: $e');
    }

    // Listen to link changes (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint('Deep Link Stream Error: $err');
      },
    );
  }

  void _handleLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    
    // Check if scheme matches 'konubu' or if it's a web link
    // Support: konubu://c/{id} AND https://konubu.app/c/{id}
    bool isValidScheme = uri.scheme == 'konubu' || uri.scheme == 'https' || uri.scheme == 'http';
    bool hasPath = uri.pathSegments.contains('c');

    if (isValidScheme && hasPath) {
      String? confessionId;
      
      // Extract ID from path segments
      // Example: /c/123 -> ['c', '123']
      int cIndex = uri.pathSegments.indexOf('c');
      if (cIndex != -1 && cIndex + 1 < uri.pathSegments.length) {
        confessionId = uri.pathSegments[cIndex + 1];
      }
      
      if (confessionId != null && confessionId.isNotEmpty) {
        _navigateToConfession(confessionId);
      }
    }
  }

  void _navigateToConfession(String confessionId) {
    debugPrint('Navigating to Confession ID: $confessionId');
    
    // Ensure Navigator is ready
    if (navigatorKey.currentState == null) {
      debugPrint('Navigator not ready, retrying in 1s...');
      Future.delayed(const Duration(seconds: 1), () => _navigateToConfession(confessionId));
      return;
    }

    // Navigate using global key
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ConfessionDetailScreen(
          confessionId: confessionId,
        ),
      ),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
