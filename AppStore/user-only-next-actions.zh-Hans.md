# 需要你本人处理的事项

这份清单只保留需要你本人登录、确认、付款、签协议或在 Apple 页面操作的事项。工程、素材、文案、profile、签名和最终 `.pkg` 已经在本机准备好。

## 已完成

- App Store Bundle ID：`com.yuxiao.TaskIsland`
- App Store provisioning profile：`证书/TaskIsland_Mac_App_Store.provisionprofile`
- App Store 应用签名证书：`D358BFF86BA374109204030BFA807E223F99F087`
- App Store 安装包签名证书：`3rd Party Mac Developer Installer: Xiao Yu (9PZ46S64H2)`
- App Store 自检：`0 error(s), 0 warning(s)`
- 最终上传包：`dist/appstore/TaskIsland-AppStore-1.0-b1.pkg`
- 上传资料包：`dist/appstore/upload-kit/TaskIsland-AppStore-1.0-b1-upload-kit.zip`

## 1. App Store Connect 商品页保存

入口：

https://appstoreconnect.apple.com/apps

当前首发策略：

```text
App Store 版本：1.0
构建号：1
主语言：English (U.S.)
销售范围：先开放中国大陆以外国家/地区
中国大陆：等 ICP/App 备案完成后再开放
```

需要确认并保存：

- 英文截图和 App Preview 已上传
- Promotional Text
- Description
- Keywords
- Support URL
- Privacy Policy URL
- Copyright
- Category
- Price
- Availability

复制粘贴值见：

```text
AppStore/appstore-connect-copy-paste.zh-Hans.md
AppStore/metadata.en-US.md
```

## 2. App Privacy 最终确认

如果提交版本仍然满足：

- 没有账号登录
- 没有广告
- 没有第三方统计
- 没有云同步
- 没有崩溃日志上传
- 没有把任务或提醒事项上传到服务器

则 App Privacy 可选择：

```text
No, we do not collect data from this app.
```

填写依据见：

```text
AppStore/privacy-evidence.zh-Hans.md
```

## 3. 出口合规与年龄分级

出口合规按当前版本选择“不使用非豁免加密”或同等含义选项。

年龄分级填写建议见：

```text
AppStore/export-compliance.zh-Hans.md
AppStore/age-rating-answers.zh-Hans.md
```

## 4. 上传最终 pkg

最终上传包：

```text
/Users/yuxiao/Vibe Coding/TaskIsland/dist/appstore/TaskIsland-AppStore-1.0-b1.pkg
```

上传方式：

1. 打开 Transporter。
2. 登录同一个 Apple Developer 账号。
3. 把上面的 `.pkg` 拖进去。
4. 点击验证/交付。
5. 等 App Store Connect 处理构建。

Transporter 指南见：

```text
AppStore/transporter-upload-guide.zh-Hans.md
```

## 5. 选择构建并提交审核

等构建处理完成后回到：

https://appstoreconnect.apple.com/apps

在 `macOS App Version 1.0` 里选择刚上传的 build `1`，然后检查所有页面没有红色错误，再点 `Add for Review` / `Submit for Review`。

审核备注可复制：

```text
AppStore/review-notes.en-US.md
```

## 6. 中国大陆 ICP/App 备案

当前中国大陆先不开放。等备案继续走完后再处理：

- 阿里云 ICP 初审
- 工信部短信核验
- 管局审核
- 拿到网站备案号
- 更新 `taskisland.cn` 页脚备案号
- 视监管要求继续做 App 备案
- 再打开中国大陆销售范围
