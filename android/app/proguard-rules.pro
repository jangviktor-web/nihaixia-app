# Flutter插件已内嵌自己的consumer规则，无需手动keep
# 删除了：io.flutter.** / sqflite / path_provider / share_plus 规则

# 保留MainActivity（MethodChannel反射调用）
-keep class com.nihaisha.nihaisha_app.MainActivity { *; }

# 保留FileProvider（安装APK需要）
-keep class androidx.core.content.FileProvider { *; }
