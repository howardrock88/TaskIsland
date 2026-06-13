# 任务岛 Mac App Store 渠道说明

这个目录只放 Mac App Store 提交流程相关文件。GitHub Release / 直接分发的安装包走 `dist/github/`，App Store 上传包走 `dist/appstore/`，两个渠道不要混放。

## 目录约定

```text
AppStore/
  README.md                         App Store 提交准备说明
  TaskIsland-AppStore.entitlements  App Store 沙盒权限文件
  metadata.zh-Hans.md               简体中文商品页信息草稿
  privacy.zh-Hans.md                App Privacy / 隐私政策准备草稿
  review-notes.zh-Hans.md           App Review 审核备注草稿
  submission.env.example            App Store 本地配置模板
  submission.env                    你的真实配置，本地忽略，不提交

dist/github/
  TaskIsland-版本号.dmg             GitHub Release / 直接分发 DMG
  TaskIsland-版本号.pkg             GitHub Release / 直接分发 PKG

dist/appstore/
  TaskIsland-AppStore-版本号-b构建号.pkg
                                    App Store 上传包
  assets/                           App Store Connect 截图和图标准备产物
```

根目录 `VERSION` 仍然代表当前 GitHub / 功能版本。App Store 版本和构建号可以单独通过 `TASKISLAND_APPSTORE_VERSION`、`TASKISLAND_APPSTORE_BUILD` 指定，不因为“准备上架”自动修改功能版本号。

本次 App Store 版本使用 `1.0`，基于当前最新功能版 `0.1.7`，包含开源版 bug 修复和中英文界面切换功能。

## 本地配置文件

先复制模板：

```sh
cp AppStore/submission.env.example AppStore/submission.env
```

然后打开 `AppStore/submission.env`，填入你的真实 Bundle ID、证书名称、provisioning profile 路径、隐私政策 URL 和技术支持 URL。这个文件已经被 `.gitignore` 忽略，不会被误提交。

查看本机可用证书：

```sh
Scripts/list-appstore-signing-info.sh
```

准备 App Store Connect 文案时参考：

- `AppStore/metadata.zh-Hans.md`
- `AppStore/appstore-connect-copy-paste.zh-Hans.md`
- `AppStore/submission-status.zh-Hans.md`
- `AppStore/privacy.zh-Hans.md`
- `AppStore/review-notes.zh-Hans.md`
- `AppStore/appstore-connect-fill-guide.zh-Hans.md`
- `AppStore/provisioning-profile-guide.zh-Hans.md`
- `AppStore/privacy-evidence.zh-Hans.md`
- `AppStore/app-review-risk-audit.zh-Hans.md`
- `AppStore/export-compliance.zh-Hans.md`
- `AppStore/appstore-assets-upload-guide.zh-Hans.md`
- `AppStore/appstore-upload-selection.zh-Hans.md`
- `AppStore/github-publish-plan.zh-Hans.md`
- `AppStore/user-only-next-actions.zh-Hans.md`
- `AppStore/age-rating-answers.zh-Hans.md`
- `AppStore/agreements-tax-banking-guide.zh-Hans.md`
- `AppStore/finalize-after-profile.zh-Hans.md`
- `AppStore/transporter-upload-guide.zh-Hans.md`

## 官方入口

- Apple Developer 账号：[developer.apple.com/account](https://developer.apple.com/account)
- Bundle ID / Identifiers：[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
- 证书列表：[Certificates](https://developer.apple.com/account/resources/certificates/list)
- Provisioning Profiles：[Profiles](https://developer.apple.com/account/resources/profiles/list)
- App Store Connect：[appstoreconnect.apple.com](https://appstoreconnect.apple.com)
- Transporter 上传工具：[Mac App Store 下载](https://apps.apple.com/us/app/transporter/id1450874784?mt=12)
- Apple 文档：注册 App ID：[Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/)
- Apple 文档：证书类型：[Certificates overview](https://developer.apple.com/help/account/certificates/certificates-overview/)
- Apple 文档：创建 App 记录：[Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- Apple 文档：上传构建：[Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- Apple 文档：截图规格：[Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
- Apple 文档：macOS App Sandbox：[Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
- Apple 文档：提醒事项权限说明：[NSRemindersFullAccessUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsremindersfullaccessusagedescription)

## 已准备好的项目配置

- `Scripts/package-app.sh` 支持通过 `TASKISLAND_BUNDLE_ID` 写入正式 Bundle ID。
- `Scripts/package-app.sh` 支持通过 `TASKISLAND_APP_VERSION`、`TASKISLAND_APP_BUILD` 写入 App 版本和构建号。
- `Info.plist` 已补充提醒事项完整访问说明和 App Store 加密声明。
- `AppStore/TaskIsland-AppStore.entitlements` 已加入 App Sandbox、用户选择文件读写和系统日历/提醒事项访问权限。
- `AppStore/metadata.zh-Hans.md`、`AppStore/privacy.zh-Hans.md`、`AppStore/review-notes.zh-Hans.md` 已准备 App Store Connect 文案草稿。
- `AppStore/app-review-risk-audit.zh-Hans.md`、`AppStore/export-compliance.zh-Hans.md` 已准备审核问答和出口合规填写依据。
- `Scripts/prepare-appstore-assets.sh` 会从真实 UI 截图生成 App Store Connect 素材，输出到 `dist/appstore/assets/`。
- `Scripts/package-appstore.sh` 会构建 App Store 上传包，并输出到 `dist/appstore/`。
- `Scripts/check-sensitive-files.sh` 会检查证书、profile 和本地配置没有被误提交。
- `Scripts/check-appstore-metadata-limits.sh` 会检查 App Store Connect 文案字段长度。
- `Scripts/preview-github-publish-scope.sh` 会预览 GitHub 提交范围，避免混入敏感文件或生成产物。
- `Scripts/package-dmg.sh`、`Scripts/package-pkg.sh` 的直接分发产物输出到 `dist/github/`。

## 需要你补充的信息

### 1. Apple Developer Team ID

位置：Apple Developer 账号会员页或证书详情里。

用途：确认签名证书属于哪个开发者团队。

### 2. 正式 Bundle ID

建议格式：

```text
com.yourname.TaskIsland
```

注意：正式 Bundle ID 需要在 Apple Developer 的 Identifiers 里创建，并且 App Store Connect 里的 App 记录也要使用同一个 Bundle ID。当前本地占位 `local.taskisland.app` 不能用于上架。

### 3. Mac App Store 应用签名证书名称

通常会出现在钥匙串或命令输出里，名称类似：

```text
Mac App Distribution: Your Name (TEAMID)
```

或：

```text
Apple Distribution: Your Name (TEAMID)
```

也可能是较旧账号里的：

```text
3rd Party Mac Developer Application: Your Name (TEAMID)
```

### 4. Mac App Store 安装包签名证书名称

通常会出现在钥匙串里，名称类似：

```text
Mac Installer Distribution: Your Name (TEAMID)
```

也可能是较旧账号里的：

```text
3rd Party Mac Developer Installer: Your Name (TEAMID)
```

### 5. App Store provisioning profile

如果使用脚本手动签名，而不是 Xcode 自动签名，需要从 Apple Developer 创建并下载 App Store / Distribution provisioning profile，并在 `AppStore/submission.env` 里填写绝对路径：

```text
TASKISLAND_APPSTORE_PROVISIONING_PROFILE="/Users/you/Downloads/TaskIsland_AppStore.provisionprofile"
```

脚本会把它复制到：

```text
TaskIsland.app/Contents/embedded.provisionprofile
```

### 6. App Store Connect App 信息

需要你决定或准备：

- App 名称：TaskIsland
- SKU：例如 `taskisland-mac-001`
- 主语言：English (U.S.)
- 上架地区：先选择中国大陆以外国家/地区；中国大陆等 ICP/App 备案完成后再开放
- 隐私政策 URL：`https://howardrock88.github.io/TaskIsland/en/privacy.html`
- 技术支持 URL：`https://howardrock88.github.io/TaskIsland/en/support.html`
- App 分类：效率
- 价格：一次性付费档位
- App Store 版本号：例如 `1.0`
- App Store 构建号：例如 `1`
- 最低系统版本：`macOS 15.0`
- 架构：默认生成 `arm64 x86_64` 通用 App，覆盖 Apple Silicon 和 Intel Mac。

### 7. 功能取舍确认

上架前需要确认这些能力是否保留：

- Apple 提醒事项导入/导出：保留的话，需要 App Store 审核能理解为什么需要提醒事项权限。
- 本地文件导入/导出：保留，走用户选择文件权限。
- `taskisland://` URL Scheme：保留的话，需要在审核说明里解释它用于快捷指令和启动器。
- 登录启动：当前直接分发 `.pkg` 通过 LaunchAgent 配置，不适合作为 App Store 路线；App Store 版本如果要保留登录启动，需要改成用户可控制的 App 内设置或系统登录项能力。

## 当前重点风险

### App Sandbox 兼容性

App Store 版本必须开启 App Sandbox。任务岛的本地 SwiftData 存储、用户选择文件导入导出、本地通知通常适合沙盒；提醒事项访问、全局快捷键、浮动窗口和事件监听需要用真实 App Store 签名包再测一轮。

### 登录启动

`Scripts/package-pkg.sh` 会写入 `/Library/LaunchAgents`，这是直接分发安装包逻辑，不应作为 App Store 上传包使用。`Scripts/package-appstore.sh` 不会写 LaunchAgent。

### 上传包不是普通 `.pkg`

Mac App Store 上传包只用于提交，不等同于给用户双击安装的安装包。提交后由 App Store 负责分发安装。

## 提交前自检

```sh
Scripts/check-appstore-readiness.sh
```

如果已经填好 `AppStore/submission.env`，自检脚本会自动读取它。

如果要同时测试 `.app` 是否能写入正式 Bundle ID：

```sh
TASKISLAND_BUNDLE_ID="com.yourname.TaskIsland" Scripts/check-appstore-readiness.sh --build-app
```

## 准备 App Store 素材

```sh
Scripts/prepare-appstore-assets.sh
```

生成位置：

```text
dist/appstore/assets/
```

当前脚本会从 `assets/screenshots/` 的真实 UI 截图生成简体中文 Mac 截图集，默认尺寸为 `1440x900`。如果需要其他 Apple 支持的 Mac 截图尺寸，可以通过环境变量覆盖：

```sh
TASKISLAND_APPSTORE_SCREENSHOT_WIDTH="1280" \
TASKISLAND_APPSTORE_SCREENSHOT_HEIGHT="800" \
Scripts/prepare-appstore-assets.sh
```

如果 `dist/app-store-promo-assets/` 存在，脚本也会自动整理中英文宣传图片和 App Preview 视频：

- 将 `3840x2160` 的中英文关键帧转换为 `2880x1800` 的 16:10 Mac 截图
- 将中英文 App Preview 视频复制到 `dist/appstore/assets/videos/`

素材上传顺序见：

- `AppStore/appstore-assets-upload-guide.zh-Hans.md`

## 生成 App Store 上传资料包

```sh
Scripts/prepare-appstore-upload-kit.sh
```

生成位置：

```text
dist/appstore/upload-kit/
```

资料包会集中包含：

- App Store Connect 截图、图标和 App Preview 视频
- 商品页文案、隐私说明、审核备注
- 当前上架状态总览
- App Store Connect 填写指南
- 年龄分级、App Privacy、付费协议/税务/银行、Transporter 上传指南
- profile 到位后一键收尾指南
- App Review 风险点核对和出口合规填写说明
- GitHub Pages 隐私政策和技术支持页备份
- 正式 `.pkg` 上传包；仅在 provisioning profile 已配置并重新打包后包含

## 构建 App Store 上传包

拿到正式 Bundle ID、证书和 provisioning profile 后执行：

```sh
Scripts/package-appstore.sh
```

也可以不用配置文件，直接通过环境变量执行：

```sh
TASKISLAND_BUNDLE_ID="com.yourname.TaskIsland" \
TASKISLAND_APPSTORE_VERSION="1.0" \
TASKISLAND_APPSTORE_BUILD="1" \
TASKISLAND_APPSTORE_APP_SIGN_IDENTITY="Mac App Distribution: Your Name (TEAMID)" \
TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY="Mac Installer Distribution: Your Name (TEAMID)" \
TASKISLAND_APPSTORE_PROVISIONING_PROFILE="/absolute/path/to/TaskIsland_Mac_App_Store.provisionprofile" \
Scripts/package-appstore.sh
```

构建成功后会生成：

```text
dist/appstore/TaskIsland-AppStore-1.0-b1.pkg
```

然后用 Transporter 或 App Store Connect 上传。
