# Transporter 上传指南

这份文件用于 provisioning profile 补齐、正式 `.pkg` 生成之后上传构建包。

## 前提

必须先完成：

- App Store Connect 已创建 App 记录
- Bundle ID 是 `com.yuxiao.TaskIsland`
- App Store provisioning profile 已下载并写入 `AppStore/submission.env`
- `Scripts/check-appstore-readiness.sh` 是 `0 error`
- `Scripts/package-appstore.sh` 已重新生成正式 `.pkg`

目标上传包：

```text
dist/appstore/TaskIsland-AppStore-1.0-b1.pkg
```

## 下载 Transporter

Mac App Store：

https://apps.apple.com/us/app/transporter/id1450874784?mt=12

## 上传步骤

1. 打开 Transporter。
2. 使用同一个 Apple Developer / App Store Connect 账号登录。
3. 把正式 `.pkg` 拖进 Transporter。
4. 等待验证。
5. 如果验证通过，点击 `Deliver`。
6. 上传完成后回到 App Store Connect 的版本页面。
7. 等 Apple 处理构建完成。
8. 在版本页面选择刚上传的 build。
9. 完成 App Review 信息后提交审核。

## 可选：命令行验证和上传

如果不想手动拖 Transporter，可以使用本仓库脚本：

```sh
Scripts/upload-appstore-package.sh --validate
Scripts/upload-appstore-package.sh --upload --wait
```

脚本不会保存账号密码。认证信息只从 `AppStore/submission.env` 或当前 shell 环境读取。

推荐使用 App Store Connect API Key：

```sh
TASKISLAND_APPSTORE_API_KEY="你的 Key ID"
TASKISLAND_APPSTORE_API_ISSUER="你的 Issuer ID"
TASKISLAND_APPSTORE_API_KEY_PATH="/完整路径/AuthKey_你的KeyID.p8"
```

也可以使用 Apple ID 的 App 专用密码，并先存入钥匙串：

```sh
xcrun altool --store-password-in-keychain-item TASKISLAND_APPSTORE_CONNECT_PASSWORD -u "你的 Apple ID 邮箱" -p "App 专用密码"
```

然后在本地 `AppStore/submission.env` 填：

```text
TASKISLAND_APPSTORE_UPLOAD_USERNAME="你的 Apple ID 邮箱"
TASKISLAND_APPSTORE_UPLOAD_PASSWORD_KEYCHAIN="TASKISLAND_APPSTORE_CONNECT_PASSWORD"
```

## 上传前检查

我会在生成正式包后确认：

```sh
Scripts/verify-appstore-package.sh
```

它会确认：

- `.app` 的 Bundle ID、版本号、构建号、最低系统版本、分类、URL Scheme 和隐私说明
- `.app` 内存在 `Contents/embedded.provisionprofile`
- embedded profile 的 App ID 匹配 `com.yuxiao.TaskIsland`
- embedded profile 不是开发/Ad Hoc profile
- `.app` 代码签名和 sandbox entitlements
- `.pkg` 安装包签名和 payload

## 常见状态

```text
Processing
```

上传成功后 App Store Connect 还要处理一段时间，期间构建可能不会马上可选。

```text
Invalid Binary
```

通常是签名、profile、Bundle ID、entitlements 或 Info.plist 问题。把错误截图发给我，我继续定位。

```text
Missing Compliance
```

通常需要在 App Store Connect 填出口合规/加密相关问题。当前 Info.plist 已声明：

```text
ITSAppUsesNonExemptEncryption = false
```

如果页面仍提示，按实际情况说明当前 App 不使用非豁免加密。
