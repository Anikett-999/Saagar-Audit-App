# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Workmanager (Background Sync & Auto-Aging)
-keep class androidx.work.** { *; }
-keep class dev.fluttercommunity.workmanager.** { *; }

# Firebase, Firestore, Storage & Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Play Core (Flutter deferred components engine references)
-dontwarn com.google.android.play.core.**

# Sqflite Native JNI
-keep class com.tekartik.sqflite.** { *; }

# Core Desugaring & Java Time APIs
-dontwarn java.lang.invoke.**
-dontwarn java.time.**

# Preserve annotations and generic signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
