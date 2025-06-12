plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.crmapp"
    compileSdk = 35 // або flutter.compileSdkVersion, але краще вказати явно
    ndkVersion = "27.2.12479018" // можна взяти з flutter doctor --verbose

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.crmapp"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false // или false, если пока не хочешь обфускацию
            shrinkResources true // уменьшение размера ресурсов
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }

    signingConfigs {
    release {
        storeFile file('release.keystore')
        storePassword RELEASE_STORE_PASSWORD
        keyAlias 'key_alias'
        keyPassword RELEASE_KEY_PASSWORD
    }
}

}

flutter {
    source = "../.." // все правильно
}
