import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase n'est activé que si google-services.json est présent. Le plugin
// échoue sur son absence : l'appliquer sans condition rendrait le projet
// incompilable tant que le fichier n'a pas été déposé. Sans lui, l'application
// se construit et fonctionne, seul le push hors ligne est indisponible.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "google-services.json absent : Firebase désactivé, " +
            "les notifications push hors ligne ne fonctionneront pas."
    )
}

// Chargement des identifiants de signature release depuis android/key.properties
// (ce fichier ne doit PAS être versionné — voir .gitignore). Si absent, on retombe
// sur les clés debug pour que `flutter run` continue de fonctionner.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yobante.boutique"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Exigé par flutter_local_notifications : il utilise des API Java 8+
        // (java.time) qui doivent être rétroportées sur les anciens Android.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Identifiant unique de l'application sur les stores.
        applicationId = "com.yobante.boutique"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signature release si key.properties présent, sinon repli sur debug
            // (permet de continuer à lancer `flutter run` sans keystore).
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // Shrink + obfuscation R8 pour la release : réduit la taille de l'AAB
            // et complique la rétro-ingénierie (règles de conservation dans proguard-rules.pro).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
