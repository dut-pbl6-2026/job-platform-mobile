# Flutter wrapper & engine JNI rules (SEC-06 / Release R8 shrinking)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Cloud Messaging & Google Play Services
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter Local Notifications (Gson serialized scheduled notification models)
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
