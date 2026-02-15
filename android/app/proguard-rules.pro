# ProGuard Rules for Sohba App
# Keep Flutter and Firebase classes

# Flutter Wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (required for Flutter deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Keep Kotlin metadata
-keepattributes RuntimeVisibleAnnotations

# Prevent R8 from removing classes used via reflection
-keep class * extends androidx.lifecycle.ViewModel { *; }
