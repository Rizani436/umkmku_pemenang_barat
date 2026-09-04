# flutter_local_notifications menyimpan notifikasi terjadwal ke disk dalam
# bentuk JSON lewat Gson, lalu membacanya kembali dari receiver setelah HP
# booting. Tanpa aturan di bawah, R8 (minifyEnabled aktif di build release)
# mengaburkan nama field model plugin dan pengingat yang sudah dijadwalkan
# gagal dipulihkan — bug yang HANYA muncul di build release.
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Aturan bawaan Gson: menjaga field yang dianotasi dan signature generic.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes AnnotationDefault
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
