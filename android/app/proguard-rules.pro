## --- Gson Fix ---
#-keep class com.google.gson.** { *; }
#-dontwarn com.google.gson.**
#
## Keep TypeToken (must not be shrunk)
#-keep class com.google.gson.reflect.TypeToken { *; }
#
## --- Flutter Local Notifications Fix ---
#-keep class com.dexterous.flutterlocalnotifications.** { *; }
#
## Kotlin metadata (safe)
#-keep class kotlin.Metadata { *; }









# 1. Essential Attributes (Crucial for Gson & Firebase)
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable

# 2. Gson Fix (Standard Production Rules)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-dontwarn sun.misc.**
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.reflect.TypeToken { *; }

# 3. Flutter Local Notifications Fix
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# 4. Kotlin & Flutter Core
-keep class kotlin.Metadata { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 5. Entry Point (MainActivity)
-keep class com.example.blue_leaf_guide.MainActivity { *; }

# 6. Firebase & Data Models
-keep @com.google.errorprone.annotations.Keep class *
-keepclassmembers class * {
  @com.google.errorprone.annotations.Keep *;
}
-keepclassmembers class com.example.blue_leaf_guide.** {
  @com.google.firebase.database.IgnoreExtraProperties *;
  @com.google.firebase.firestore.IgnoreExtraProperties *;
}

# 7. FIX FOR YOUR BUILD FAILURE (Missing Play Core Classes)
# This prevents R8 from failing when it can't find Play Store Split logic
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
