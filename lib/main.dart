import 'package:firebase_core/firebase_core.dart';
import 'package:dedikodu_app/core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/core/services/auth_service.dart';
import 'package:dedikodu_app/core/services/fcm_service.dart';
import 'package:dedikodu_app/features/auth/welcome_screen.dart';
import 'package:dedikodu_app/features/home/home_screen.dart';
import 'package:dedikodu_app/firebase_options.dart';
import 'package:dedikodu_app/data/repositories/user_repository.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:dedikodu_app/core/widgets/connectivity_wrapper.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge for Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Remove splash screen explicitly
  FlutterNativeSplash.remove();
  
  // Initialize Firebase
  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized: $e');
    } else {
      debugPrint('Firebase initialization error: $e');
    }
  }
  
  // Set Turkish locale for timeago
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  // Request ATT Permission (iOS)
  // Wait for the first frame to ensure context is available if needed, though mostly for the plugin
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const DedikoduApp());
  
  // Request tracking after a short delay to ensure app is ready
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('ATT Status: $status');
    } catch (e) {
      debugPrint('ATT Error: $e');
    }
  });
}

class DedikoduApp extends StatelessWidget {
  const DedikoduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'KONUBU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorObservers: [
        AnalyticsService().getAnalyticsObserver(),
      ],
      home: const ConnectivityWrapper(
        child: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _premiumChecked = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, check premium status and show home screen
        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;
          
          // Check premium status once per session
          if (!_premiumChecked) {
            _premiumChecked = true;
            // Run premium check asynchronously
            Future.microtask(() async {
              final userRepo = UserRepository();
              await userRepo.checkAndUpdatePremiumStatus(userId);
            });
          }
          
          return const HomeScreen();
        }
        
        // Reset premium check flag when user logs out
        _premiumChecked = false;
        
        // Otherwise show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
