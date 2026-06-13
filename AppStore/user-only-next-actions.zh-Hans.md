# 需要你本人处理的事项

这份清单只保留需要你本人登录、确认、付款、签协议或做实名/主体操作的事项。其它本地工程、素材、文案和脚本我已经尽量自动化。

## 1. 下载 App Store provisioning profile

入口：

https://developer.apple.com/account/resources/profiles/list

要创建：

```text
Mac App Store / App Store Connect distribution profile
```

选择：

```text
App ID: com.yuxiao.TaskIsland
Certificate: 3rd Party Mac Developer Application: Xiao Yu (9PZ46S64H2)
Certificate SHA-1: 135BDFC94ED69E46F8EB625312F0553968045A73
Profile Name: TaskIsland Mac App Store
```

你本机有两个同名应用签名证书。如果 Apple Developer 创建 profile 时也显示多个同名证书，选和上面 SHA-1 对应的那个；如果页面不显示指纹，就选最新下载/刚创建的 Mac App Distribution 应用证书，后面本地脚本会自动校验。

下载后建议放到：

```text
/Users/yuxiao/Vibe Coding/TaskIsland/证书/TaskIsland_Mac_App_Store.provisionprofile
```

然后把这个完整路径发给我。

## 2. App Store Connect 付费协议、税务和银行信息

入口：

https://appstoreconnect.apple.com/agreements

需要你本人处理：

- Paid Apps Agreement
- 税务信息
- 银行收款信息
- 联系人信息

这是付费 App 上架和收款必须完成的部分，我不能替你签署或填写真实收款信息。

详细操作见：

```text
AppStore/agreements-tax-banking-guide.zh-Hans.md
```

## 3. 创建 App Store Connect App 记录

入口：

https://appstoreconnect.apple.com/apps

填写：

```text
Platform: macOS
Name: 任务岛
Primary Language: Simplified Chinese
Bundle ID: com.yuxiao.TaskIsland
SKU: taskisland-mac-001
User Access: Full Access
```

如果你愿意让我跟着页面继续指引，可以打开页面后把截图发我。

## 4. 价格档位确认

当前策略：

```text
一次性付费
先上架中国大陆以外国家/地区
中国大陆等 ICP/App 备案完成后再开放
```

需要你决定具体价格档位。建议先用低价档启动，后面根据反馈调整。

价格要在 Paid Apps Agreement 生效后才能完整配置。

## 5. App Privacy 最终确认

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

## 6. 中国大陆 ICP/App 备案

当前中国大陆先不开放。等备案继续走完后再处理：

- 阿里云 ICP 初审
- 工信部短信核验
- 管局审核
- 拿到网站备案号
- 更新 `taskisland.cn` 页脚备案号
- 视监管要求继续做 App 备案
- 再打开中国大陆销售范围

## 7. 我拿到 profile 后会继续做什么

你把 `.provisionprofile` 路径发我后，我会继续：

1. 写入 `AppStore/submission.env`
2. 运行 `Scripts/check-appstore-readiness.sh`
3. 运行 `Scripts/package-appstore.sh`
4. 验证 `.app` 内包含 `Contents/embedded.provisionprofile`
5. 验证 `.pkg` 签名
6. 重新生成 `dist/appstore/upload-kit/`
7. 告诉你哪个 `.pkg` 可以拖进 Transporter 上传

在 profile 补齐前，`Scripts/package-appstore.sh` 会主动停止，避免生成容易误上传的非最终包。

如果你想直接本地一键收尾，也可以运行：

```sh
Scripts/finalize-appstore-profile.sh "/完整路径/TaskIsland_Mac_App_Store.provisionprofile"
```
