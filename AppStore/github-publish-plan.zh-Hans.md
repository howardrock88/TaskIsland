# GitHub 发布范围建议

这份文件用于把当前上架准备工作推到 GitHub 前做范围拆分，避免把证书、profile、上传包或大型生成产物误提交。

## 先看范围预览

运行：

```sh
Scripts/preview-github-publish-scope.sh
```

这个脚本只读，不会 stage、commit 或 push。它会把当前工作区分成几组：

- App Store 准备文件
- 官网/隐私政策/支持页
- GitHub issue templates
- 应用源码改动
- 视频工程文件
- 应保持本地的敏感或生成文件

## 建议提交分组

### 1. 应用功能和版本提交

适合包含：

- `VERSION`
- `Sources/`
- `README.md`
- `README.en.md`
- 与直接分发相关的既有 package 脚本改动

这组对应你这次同步的 bug 修复和中英文界面切换功能。

### 2. App Store 准备提交

适合包含：

- `AppStore/`
- `Scripts/check-appstore-readiness.sh`
- `Scripts/check-appstore-metadata-limits.sh`
- `Scripts/check-sensitive-files.sh`
- `Scripts/finalize-appstore-profile.sh`
- `Scripts/list-appstore-signing-info.sh`
- `Scripts/package-appstore.sh`
- `Scripts/prepare-appstore-assets.sh`
- `Scripts/prepare-appstore-promo-assets.sh`
- `Scripts/prepare-appstore-upload-kit.sh`
- `Scripts/verify-appstore-package.sh`
- `dist/README.md`
- `dist/appstore/.gitkeep`
- `dist/github/.gitkeep`

### 3. 公开页面提交

适合包含：

- `docs/index.html`
- `docs/privacy.html`
- `docs/support.html`
- `docs/en/`

这组对应 GitHub Pages 上的隐私政策和技术支持页面。

### 4. GitHub 社区文件提交

适合包含：

- `.github/ISSUE_TEMPLATE/`

## 不要提交

这些必须留在本地：

- `AppStore/submission.env`
- `证书/`
- `*.cer`
- `*.certSigningRequest`
- `*.provisionprofile`
- `*.mobileprovision`
- `dist/appstore/assets/`
- `dist/appstore/upload-kit/`
- `dist/appstore/*.pkg`

## 视频工程

这些目录体积较大，通常不建议混进 App 上架准备提交：

- `taskisland-promo-video/`
- `taskisland-promo-video-en/`

如果你希望把视频工程也归档到 GitHub，建议单独开一个提交，或放到独立仓库/Release 附件里。

## 提交前检查

提交前至少运行：

```sh
Scripts/check-sensitive-files.sh
Scripts/check-appstore-readiness.sh
swift build
swift run TaskIslandChecks
```
