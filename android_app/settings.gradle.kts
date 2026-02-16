pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Load local.properties for Mapbox token
val localProperties = java.util.Properties()
val localPropertiesFile = File(rootDir, "local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        // Mapbox Maven repository
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                // Token must have Downloads:Read scope
                // Reads from: gradle.properties -> local.properties -> MAPBOX_DOWNLOADS_TOKEN env var
                username = "mapbox"
                password = providers.gradleProperty("MAPBOX_DOWNLOADS_TOKEN").getOrElse(
                    localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                        ?: System.getenv("MAPBOX_DOWNLOADS_TOKEN") ?: ""
                )
            }
        }
    }
}

rootProject.name = "OceanSentinels"
include(":app")
