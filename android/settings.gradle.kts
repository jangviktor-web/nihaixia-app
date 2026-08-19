pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // ✅阿里云镜像放到最最前面
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        // 原有源往后挪，做兜底
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// ✅依赖工件仓库（AGP/androidx 等走这里；Gradle 7+ 必须写 settings，写在 build.gradle 不生效）
// 注意：必须 PREFER_SETTINGS 而非 FAIL_ON_PROJECT_REPOS——Flutter Gradle 插件应用时会向项目级注入 maven 仓库，FAIL 模式会拒绝导致构建失败
// 注意：必须显式加 Flutter 引擎仓库（storage.googleapis.com/download.flutter.io）——PREFER_SETTINGS 下项目级仓库被忽略，
//      而阿里镜像/公共镜像均无 io.flutter 引擎 artifact，漏加则 flutter_embedding/x86_64_release 解析失败
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        // 阿里云镜像优先（AGP/androidx 等）
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/jcenter")
        // Flutter 引擎 artifact 仓库（必加，与 Flutter 插件同源）
        maven("https://storage.googleapis.com/download.flutter.io")
        // 兜底
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
