# App Store Connect 填写清单

当前策略：首发用英文商品页上架中国大陆以外国家/地区；中国大陆等 ICP/App 备案完成后再添加或开放简体中文本地化。

## App 记录

- 平台：macOS
- 名称：TaskIsland
- 主语言：English (U.S.)
- Bundle ID：`com.yuxiao.TaskIsland`
- SKU：`taskisland-mac-001`
- 版本号：`0.1.7`
- 构建号：`1`
- 用户访问权限：Full Access

## 商品页

- 副标题：Keep important tasks in sight
- 分类：效率
- 关键词：task,manager,todo,focus,timer,reminder,productivity,menubar,local,tasks
- 隐私政策 URL：`https://howardrock88.github.io/TaskIsland/en/privacy.html`
- 技术支持 URL：`https://howardrock88.github.io/TaskIsland/en/support.html`

完整描述、本版本更新和审核备注见：

- `AppStore/metadata.zh-Hans.md`
- `AppStore/metadata.en-US.md`
- `AppStore/appstore-connect-copy-paste.zh-Hans.md`
- `AppStore/submission-status.zh-Hans.md`
- `AppStore/review-notes.zh-Hans.md`
- `AppStore/review-notes.en-US.md`
- `AppStore/appstore-connect-fill-guide.zh-Hans.md`
- `AppStore/provisioning-profile-guide.zh-Hans.md`
- `AppStore/privacy-evidence.zh-Hans.md`
- `AppStore/app-review-risk-audit.zh-Hans.md`
- `AppStore/export-compliance.zh-Hans.md`
- `AppStore/appstore-assets-upload-guide.zh-Hans.md`
- `AppStore/user-only-next-actions.zh-Hans.md`
- `AppStore/age-rating-answers.zh-Hans.md`
- `AppStore/agreements-tax-banking-guide.zh-Hans.md`
- `AppStore/finalize-after-profile.zh-Hans.md`
- `AppStore/transporter-upload-guide.zh-Hans.md`

## 简体中文本地化

- App 名称：任务岛
- 副标题：让重要的事，始终在眼前
- Support URL：`https://howardrock88.github.io/TaskIsland/support.html`
- Privacy Policy URL：`https://howardrock88.github.io/TaskIsland/privacy.html`
- 中文商品页草稿：`AppStore/metadata.zh-Hans.md`
- 中文隐私说明：`AppStore/privacy.zh-Hans.md`
- 中文审核备注：`AppStore/review-notes.zh-Hans.md`
- 当前建议：先不作为首发必填；备案完成、准备开放中国大陆后再启用

## 价格与销售范围

- 价格：一次性付费，档位待定
- 销售范围：先选择中国大陆以外国家/地区
- 中国大陆：暂不选择；等 ICP/App 备案通过后再打开

付费协议、税务和银行信息见：

- `AppStore/agreements-tax-banking-guide.zh-Hans.md`

年龄分级填写建议见：

- `AppStore/age-rating-answers.zh-Hans.md`

## App Privacy

如果提交版本仍符合当前实现：

- 不需要账号登录
- 不包含广告 SDK
- 不包含第三方统计
- 不包含云同步
- 不把任务、提醒事项或导入文件上传到开发者服务器

则 App Privacy 可按“开发者不收集此 App 的任何数据”方向填写。上线前仍需按实际构建复核。

隐私填写依据见：

- `AppStore/privacy-evidence.zh-Hans.md`
- `AppStore/app-review-risk-audit.zh-Hans.md`

出口合规填写依据见：

- `AppStore/export-compliance.zh-Hans.md`

## 构建包

当前不保留未嵌入 provisioning profile 的测试 `.pkg`，避免误传 Transporter。

profile 补齐后，正式目标包是：

```text
dist/appstore/TaskIsland-AppStore-0.1.7-b1.pkg
```

当前上架版本采用最新功能版 `0.1.7`，包含开源版 bug 修复和中英文界面切换功能。

截图和图标上传顺序见：

- `AppStore/appstore-assets-upload-guide.zh-Hans.md`

新素材已整理到：

- `dist/appstore/assets/screenshots/zh-Hans-promo/`
- `dist/appstore/assets/screenshots/en-promo/`
- `dist/appstore/assets/videos/zh-Hans/`
- `dist/appstore/assets/videos/en/`

正式提交前必须补齐 App Store provisioning profile，并重新运行：

```sh
Scripts/check-appstore-readiness.sh
Scripts/package-appstore.sh
Scripts/prepare-appstore-upload-kit.sh
```

也可以直接使用 profile 一键收尾脚本：

```sh
Scripts/finalize-appstore-profile.sh "/完整路径/TaskIsland_Mac_App_Store.provisionprofile"
```

上传资料包会生成在：

```text
dist/appstore/upload-kit/
```

Transporter 上传步骤见：

- `AppStore/transporter-upload-guide.zh-Hans.md`

## 仍需补齐

- App Store provisioning profile
- App Store Connect 付费协议、税务和银行信息
- App Store Connect App 记录
- 截图、图标和商品页文案上传
- 备案通过后：中国大陆 ICP/App 备案号、官网备案号页脚、App 内备案号展示
