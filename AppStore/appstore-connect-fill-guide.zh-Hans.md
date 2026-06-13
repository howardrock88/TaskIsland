# App Store Connect 填写操作指南

这份文件用于你打开 App Store Connect 时逐项照填。当前策略是第一版先用英文商品页提交中国大陆以外国家/地区，中国大陆等 ICP/App 备案通过后再添加或开放简体中文本地化。

## 入口

打开：

https://appstoreconnect.apple.com/apps

## 创建 App 记录

路径：

1. 进入 `Apps`
2. 点 `+`
3. 选择 `New App`

填写：

```text
Platform: macOS
Name: TaskIsland
Primary Language: English (U.S.)
Bundle ID: com.yuxiao.TaskIsland
SKU: taskisland-mac-001
User Access: Full Access
```

如果 Bundle ID 下拉框里没有 `com.yuxiao.TaskIsland`，先回 Apple Developer 确认 Identifiers 是否创建在同一个团队下。

## App Information

建议填写：

```text
Category: Productivity
Secondary Category: 不选
Content Rights: 不包含第三方受版权保护内容
Age Rating: 4+
```

年龄分级问卷按当前功能建议：

```text
Cartoon or Fantasy Violence: None
Realistic Violence: None
Sexual Content or Nudity: None
Profanity or Crude Humor: None
Alcohol, Tobacco, Drug Use or References: None
Medical or Treatment Information: None
Gambling: None
Contests: None
Unrestricted Web Access: No
User-Generated Content: No
Messaging and Chat: No
Advertising: No
```

更完整的年龄分级答案表见：

```text
AppStore/age-rating-answers.zh-Hans.md
```

## Pricing and Availability

路径：

```text
左侧 Monetization -> Pricing and Availability
```

建议：

```text
Price: 一次性付费，低价档先启动
Availability: 选择所有国家/地区，但取消 China Mainland
Distribution Method: Public
```

如果你想先用最稳妥方式上线，价格可以先选择接近 0.99 美元的最低付费档。后续可以涨价或降价，但每次调价都会影响转化和用户预期。

付费协议、税务和银行信息办理见：

```text
AppStore/agreements-tax-banking-guide.zh-Hans.md
```

## 英文商品页（首发主语言）

路径：

```text
左侧 macOS App -> 当前版本
```

从这些文件复制：

```text
AppStore/metadata.en-US.md
AppStore/review-notes.en-US.md
```

关键字段：

```text
Name: TaskIsland
Subtitle: Keep important tasks in sight
Keywords: task,manager,todo,focus,timer,reminder,productivity,menubar,local,tasks
Support URL: https://howardrock88.github.io/TaskIsland/en/support.html
Privacy Policy URL: https://howardrock88.github.io/TaskIsland/en/privacy.html
```

## 简体中文本地化（先不要作为首发必填）

如果后面要同步准备中文商品页，可以在语言菜单里添加：

```text
Add Localization -> Simplified Chinese
```

从这些文件复制：

```text
AppStore/metadata.zh-Hans.md
AppStore/review-notes.zh-Hans.md
```

关键字段：

```text
Name: 任务岛
Subtitle: 让重要的事，始终在眼前
Keywords: 任务管理,待办,专注,提醒,效率,悬浮窗,时间管理,本地任务
Support URL: https://howardrock88.github.io/TaskIsland/support.html
Privacy Policy URL: https://howardrock88.github.io/TaskIsland/privacy.html
```

注意：Apple 官方说明里，后续更改主语言通常要求新语言已经作为本地化通过一次审核。所以首发想用英文，就在创建 App 记录时直接选 `English (U.S.)`。

## App Privacy

路径：

```text
左侧 App Privacy
```

如果提交版本仍然没有账号、云同步、广告、统计、崩溃上报或服务器上传，按这个方向填写：

```text
Do you or your third-party partners collect data from this app?
No, we do not collect data from this app.
```

填写前再对照：

```text
AppStore/privacy.zh-Hans.md
```

## 截图和图标

素材位置：

```text
dist/appstore/assets/
```

当前已有：

```text
8 张 1440x900 真实界面 Mac 截图
10 张 2880x1800 中英文宣传关键帧 Mac 截图
2 条 1920x1080 中英文 App Preview 视频
1 张 1024x1024 图标预览
```

上传顺序见：

```text
AppStore/appstore-assets-upload-guide.zh-Hans.md
```

首发英文版优先上传 `English (U.S.)` 这一组：

```text
dist/appstore/assets/videos/en/taskisland-app-preview-en-1920x1080.mp4
dist/appstore/assets/screenshots/en-promo/
```

图标如果 App Store Connect 要求上传 App Icon，使用素材目录里的 1024x1024 预览，或从正式 App icon 集导出。

## 构建包上传

等 provisioning profile 补齐后，我会重新生成：

```text
dist/appstore/TaskIsland-AppStore-0.1.7-b1.pkg
```

上传方式：

1. 打开 Apple Transporter
2. 登录同一个 Apple Developer 账号
3. 拖入 `.pkg`
4. 等验证通过后点 `Deliver`

上传成功后，App Store Connect 的构建处理需要等一会儿。处理完成后，在版本页面选择这个 build，再提交审核。

详细上传步骤见：

```text
AppStore/transporter-upload-guide.zh-Hans.md
```

## 暂时不要填中国大陆

现在 `taskisland.cn` 还在 ICP 备案阶段。中国大陆区先不开放，避免因为官网无法访问、App 备案号缺失或主体信息未完成影响审核。备案通过后再做：

1. 更新 `taskisland.cn` 官网页脚备案号
2. 更新 App Store Connect 中国大陆合规信息
3. 如监管要求，在 App 内展示 App 备案号
4. 打开中国大陆销售范围
