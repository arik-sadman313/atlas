# ATLAS — ProGuard / R8 Rules (Milestone 9)

# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**

# Drift / SQLite3 Native Runtime & Bindings
-keep class com.simonbinder.sqlite3.** { *; }
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }
-dontwarn com.simonbinder.sqlite3.**

# PDF Rendering (pdfrx / PDFium / native bindings)
-keep class com.mypdfrx.** { *; }
-keep class com.shockwave.** { *; }
-dontwarn com.mypdfrx.**

# Local Notifications Receiver & Scheduled Alarms
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Desugared Java 8 Time APIs (java.time, java.util.concurrent)
-keep class java.time.** { *; }
-keep class j$.time.** { *; }
-dontwarn java.time.**
-dontwarn j$.time.**

# Keep generic signatures and line number tables for stacktraces
-keepattributes Signature,Exceptions,*Annotation*,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable
