# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# ============= Retrofit =============
# Keep Retrofit interfaces and their generic signatures
-keep interface * {
    @retrofit2.http.* <methods>;
}
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}
# Explicitly keep Ocean Sentinels API interfaces
-keep interface com.oceansentinels.app.data.remote.api.** { *; }

# Retrofit internals
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Exceptions

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ============= Gson =============
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }

# ============= DTOs & Models =============
-keep class com.oceansentinels.app.data.remote.dto.** { *; }
-keep class com.oceansentinels.app.domain.model.** { *; }

# ============= Room =============
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keep class com.oceansentinels.app.data.local.database.** { *; }

# ============= Hilt / DI =============
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# ============= Firebase =============
-keep class com.google.firebase.** { *; }

# ============= Mapbox SDK =============
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# ============= Kotlin =============
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-keep class kotlin.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
