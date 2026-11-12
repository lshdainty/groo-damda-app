import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리스 서명 키 — android/key.properties (gitignore). 없으면 debug 키로 폴백(빌드는 됨).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.porest.desk.porest_desk_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 가 java.time 을 쓴다. minSdk 가 그보다 낮은 기기에서
        // 돌려면 desugaring 이 필요하다 — 없으면 checkDebugAarMetadata 에서 빌드가 멈춘다.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.porest.desk.porest_desk_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties 가 있으면 전용 릴리스 키로 서명, 없으면 debug 키 폴백.
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 위 isCoreLibraryDesugaringEnabled 와 한 쌍이다. 버전을 올릴 땐 둘을 같이 본다.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // 네이티브 단위 테스트(android/app/src/test) — `./gradlew :app:testDebugUnitTest`.
    // org.json 은 android.jar 에 껍데기만 있어(호출하면 "not mocked") 실제 구현을 따로 단다.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
