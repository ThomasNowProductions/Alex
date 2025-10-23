pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            if (localProperties.exists()) {
                localProperties.inputStream().use { properties.load(it) }
            }
            properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_HOME")
                ?: System.getenv("FLUTTER_SDK")
                ?: System.getenv("FLUTTER_ROOT")
                ?: error(
                    "flutter.sdk not set. Provide it via local.properties or the FLUTTER_HOME/FLUTTER_SDK/FLUTTER_ROOT environment variables."
                )
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
