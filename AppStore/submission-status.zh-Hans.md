# 任务岛 App Store 上架状态总览

更新时间：2026-06-13

## 当前结论

工程、素材、文案、隐私说明、审核备注、出口合规说明、provisioning profile、签名和最终 `.pkg` 已经准备完成。

当前自检结果：

```text
Scripts/check-appstore-readiness.sh --build-app
Result: 0 error(s), 0 warning(s)
```

最终上传包已通过 `Scripts/verify-appstore-package.sh` 校验。

## 当前上架版本

```text
App Store 版本号：1.0
构建号：1
Bundle ID：com.yuxiao.TaskIsland
Team ID：9PZ46S64H2
最低系统：macOS 15.0
架构：arm64 x86_64 通用 App
渠道：Mac App Store
销售范围：先开放中国大陆以外国家/地区；中国大陆等 ICP/App 备案完成后再开放
```

本次 App Store 版本 `1.0` 基于最新功能版 `0.1.7`，包含开源版 bug 修复和中英文界面切换功能。

## 现在可以使用的资料

上传资料包：

```text
dist/appstore/upload-kit/TaskIsland-AppStore-1.0-b1-upload-kit.zip
```

这个 zip 当前包含：

- App Store Connect 截图、图标和 App Preview 视频
- 不超过 Apple 数量限制的最终上传素材选择清单
- 中英文商品页文案
- App Privacy 填写依据
- App Review 审核备注
- 出口合规填写说明
- 年龄分级建议
- 付费协议、税务和银行信息指南
- Transporter 上传指南
- GitHub Pages 隐私政策和支持页备份
- 素材清单 `metadata/asset-manifest.md`

## 现在可以上传的东西

Transporter 上传包：

```text
dist/appstore/TaskIsland-AppStore-1.0-b1.pkg
```

上传资料包：

```text
dist/appstore/upload-kit/TaskIsland-AppStore-1.0-b1-upload-kit.zip
```

## Apple 侧仍需本人处理

1. 确认 App Store Connect 商品页字段、截图和视频已保存。
2. 确认 Paid Apps Agreement、税务和银行信息已生效。
3. 选择一次性付费价格档位和销售范围。
4. 填 App Privacy、出口合规和年龄分级。
5. 用 Transporter 上传正式 `.pkg`。
6. 构建处理完成后选择 build `1` 并提交审核。

## 中国大陆策略

当前先不选择中国大陆销售范围。

等备案完成后再处理：

- 网站 ICP 备案号
- 官网页脚备案号
- 可能需要的 App 备案
- App Store Connect 中国大陆销售范围开启

## 当前关键文件

- `AppStore/appstore-connect-copy-paste.zh-Hans.md`：页面字段复制粘贴值表
- `AppStore/appstore-assets-upload-guide.zh-Hans.md`：截图和视频上传顺序
- `AppStore/appstore-upload-selection.zh-Hans.md`：最终上传素材选择清单
- `AppStore/github-publish-plan.zh-Hans.md`：GitHub 发布范围建议
- `AppStore/privacy-evidence.zh-Hans.md`：App Privacy 填写依据
- `AppStore/app-review-risk-audit.zh-Hans.md`：审核问答和权限解释
- `AppStore/export-compliance.zh-Hans.md`：出口合规填写说明
- `AppStore/finalize-after-profile.zh-Hans.md`：拿到 profile 后一键收尾
- `AppStore/transporter-upload-guide.zh-Hans.md`：Transporter 上传步骤
- `Scripts/check-appstore-readiness.sh`：上架自检
- `Scripts/finalize-appstore-profile.sh`：profile 到位后一键收尾
- `Scripts/verify-appstore-package.sh`：正式上传包校验
- `Scripts/check-sensitive-files.sh`：提交前敏感文件检查
- `Scripts/check-appstore-metadata-limits.sh`：App Store Connect 文案长度检查
- `Scripts/preview-github-publish-scope.sh`：GitHub 发布范围预览
