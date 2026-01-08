import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:dedikodu_app/data/models/confession_model.dart';
import 'package:dedikodu_app/features/confession/confession_detail_screen.dart';
import 'package:dedikodu_app/main.dart'; // To access navigatorKey

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize() async {
    _appLinks = AppLinks();

    // Check initial link (cold start)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // Listen to link changes (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  void _handleLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    
    // Check if scheme matches 'konubu' or if it's a web link (optional)
    if (uri.scheme == 'konubu' || uri.pathSegments.contains('c')) {
      // url format: konubu://c/{id}
      // or https://konubu.com/c/{id}
      
      String? confessionId;
      
      // Try to extract ID from path segments
      // Example: /c/123 -> ['c', '123']
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
        confessionId = uri.pathSegments[1];
      }
      
      if (confessionId != null && confessionId.isNotEmpty) {
        _navigateToConfession(confessionId);
      }
    }
  }

  void _navigateToConfession(String confessionId) {
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
