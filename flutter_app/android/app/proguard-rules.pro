# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep camera
-keep class androidx.camera.** { *; }

# Keep image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep file picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep share plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep printing
-keep class net.nfet.flutter.printing.** { *; }

# Keep PDF
-keep class com.pdftools.** { *; }

# Keep OCR service
-keep class com.scanpdf.app.ocr.** { *; }

# Suppress Play Core warnings (deferred components)
-dontwarn com.google.android.play.core.**
