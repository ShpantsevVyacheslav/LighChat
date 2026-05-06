# LighChat Android release — R8/ProGuard rules.
#
# Goal: shrink + obfuscate without breaking runtime reflection used by Flutter,
# Firebase, Crashlytics, Riverpod, FlutterFire and the engine itself.
# Anything kept here is justified by a known reflective lookup; the rest of
# the app is fair game for R8 to remove/rename.

# --- Flutter engine -----------------------------------------------------------
# The engine resolves these classes by name from native code.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / FlutterFire ---------------------------------------------------
# Firebase SDK uses reflection to discover Components and Crashlytics keeps
# field names in stack traces; preserve fully.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics: keep line numbers and source file attribute so de-obfuscated
# stack traces in the dashboard remain useful (mapping file is uploaded
# automatically by the Crashlytics Gradle plugin).
-keepattributes SourceFile,LineNumberTable

# Annotations referenced via reflection by some FlutterFire plugins.
-keepattributes *Annotation*

# --- AndroidX / Kotlin --------------------------------------------------------
# Coroutines internals occasionally surface via reflection; standard Android
# templates keep these.
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# --- App-specific -------------------------------------------------------------
# Keep our own `MainActivity` (the manifest references it by name).
-keep class com.lighchat.lighchat_mobile.** { *; }

# Plugins occasionally bridge native code via JNI; play it safe with all
# methods marked native.
-keepclasseswithmembers class * {
    native <methods>;
}

# Parcelables (some plugin types are parceled).
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Optional: WebView JS interfaces — only relevant if we add @JavascriptInterface
# bridges; harmless to keep.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
