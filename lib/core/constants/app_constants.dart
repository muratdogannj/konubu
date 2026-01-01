// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Dedikodu';
  static const String appVersion = '1.0.0';
  
  // Confession
  static const int confessionMinLength = 10;
  static const int confessionMaxLength = 5000;
  
  // API
  static const String turkeyApiBaseUrl = 'https://api.turkiyeapi.dev/v1';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String confessionsCollection = 'confessions';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  
  // Pagination
  static const int confessionsPerPage = 20;
}

enum ConfessionStatus {
  pending,
  approved,
  rejected,
}
