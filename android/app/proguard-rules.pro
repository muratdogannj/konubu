# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Models (If you use reflection/json_serializable, usually handled by code generation but good safety)
-keep class com.dgn.konubu.** { *; }

# Prevent warnings
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
