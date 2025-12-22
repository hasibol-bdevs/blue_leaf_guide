# --- Gson Fix ---
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep TypeToken (must not be shrunk)
-keep class com.google.gson.reflect.TypeToken { *; }

# --- Flutter Local Notifications Fix ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Kotlin metadata (safe)
-keep class kotlin.Metadata { *; }
