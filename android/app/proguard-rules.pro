# Keep classes and members used by flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson TypeToken generic signatures
-keepattributes Signature

# Keep Gson classes used for serialization/deserialization
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*

# Keep all classes with generic type info for Gson
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}