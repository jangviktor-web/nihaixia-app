plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nihaisha.nihaisha_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nihaisha.nihaisha_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // 从 key.properties 读取签名配置
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val map = mutableMapOf<String, String>()
                keyPropertiesFile.readLines().forEach { line ->
                    val trimmed = line.trim()
                    if (trimmed.isNotEmpty() && !trimmed.startsWith("#") && trimmed.contains("=")) {
                        val parts = trimmed.split("=", limit = 2)
                        map[parts[0].trim()] = parts[1].trim()
                    }
                }
                keyAlias = map["keyAlias"]
                keyPassword = map["keyPassword"]
                storeFile = file(map["storeFile"] ?: "")
                storePassword = map["storePassword"]
                // canonical keystore 是 openssl 生成的 PKCS12（.jks 后缀），必须显式 storeType 否则 Gradle 按默认 jks 解析失败
                storeType = map["storeType"] ?: "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            // 如果key.properties存在则用release签名，否则fallback到debug签名
            val keyPropertiesFile = rootProject.file("key.properties")
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 生产构建：开启 R8 混淆 + 资源收缩（瘦身 + 符号混淆）
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ABI 分包：生成 armeabi-v7a / arm64-v8a / x86_64 独立 APK + 通用包，
    // 单架构 APK 体积约减半（原 52MB 通用包），便于 GitHub 直发与 Play 上架。
    //
    // 本地测试包只出 arm64（2026-11-07 用户定）：本地只用于发钉钉自测，现代安卓机
    // 清一色 arm64，另外 3 个包从来没人装，白烧一倍构建时间。
    // 本地用法：LOCAL_ARM64_ONLY=1 flutter build apk --release --target-platform android-arm64
    //
    // ⚠️ 三条都试过、只有这条成立：
    //   1) 只加 `--target-platform android-arm64` → 拦不住 splits，照样出 4 包、耗时不变
    //   2) 只把 include 收窄成 arm64 → Gradle 直接报冲突：
    //      "Conflicting configuration : 'armeabi-v7a,arm64-v8a,x86_64' in ndk abiFilters
    //       cannot be present when splits abi filters are set : arm64-v8a"
    //      （Flutter plugin 会把 ndk.abiFilters 设成全量常量，项目侧改不动）
    //   3) 关掉 splits + --target-platform android-arm64 → 只出 1 个 app-release.apk ✓
    // CI 不设该环境变量，行为完全不变，仍出 4 包。
    val localArm64Only = System.getenv("LOCAL_ARM64_ONLY") == "1"
    splits {
        abi {
            isEnable = !localArm64Only
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
