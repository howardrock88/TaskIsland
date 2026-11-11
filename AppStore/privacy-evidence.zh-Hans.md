# App Privacy 填写依据

更新时间：2026-06-13

这份文件用于留档说明：为什么当前提交版本可以按“开发者不收集此 App 的任何数据”方向填写 App Store Connect 的 App Privacy。

## 当前结论

按当前代码和提交配置判断，任务岛当前版本是本地优先工具：

- 没有账号登录。
- 没有广告 SDK。
- 没有第三方统计 SDK。
- 没有崩溃日志收集 SDK。
- 没有云同步或开发者服务器上传。
- 没有内购或外部支付逻辑。
- 任务、标签、项目、提醒时间和专注记录默认保存在用户本机。

因此 App Privacy 可按：

```text
Do you or your third-party partners collect data from this app?
No, we do not collect data from this app.
```

## 已检查的代码迹象

代码搜索未发现以下常见联网或数据收集实现：

- `URLSession`
- `NWConnection`
- `NWPathMonitor`
- `Firebase`
- `Sentry`
- `Crashlytics`
- `Amplitude`
- `Mixpanel`
- `AdMob`
- `CloudKit`
- `StoreKit`

如果未来加入这些能力，App Privacy 必须重新填写。

## 已确认的本地能力

当前版本包含以下本地或用户主动触发能力：

- Apple 提醒事项：通过 EventKit 读取未完成提醒事项，或把任务导出到系统提醒事项。
- 本地通知：通过 UserNotifications 安排用户设置的任务提醒。
- 文件导入/导出：用户主动选择 JSON、Markdown、CSV 文件进行导入或导出。

这些能力的共同点是：数据在用户设备上处理，当前版本不上传到开发者服务器。

## App Store 审核说明口径

如果审核问到提醒事项、本地通知或文件访问，可以这样解释：

```text
TaskIsland stores task data locally on the user's Mac. Apple Reminders access is only used when the user explicitly imports incomplete reminders or exports TaskIsland tasks to Apple Reminders. Local notifications are only used for reminders configured by the user. File access is only used for user-selected JSON, Markdown, and CSV import/export. The app does not include accounts, cloud sync, advertising, third-party analytics, or developer-side data collection.
```

## 上线前复核清单

提交每个新版本前都重新确认：

- 没有新增服务器请求。
- 没有新增第三方 SDK。
- 没有新增账号、云同步、统计、崩溃上报或广告。
- 没有新增内购或外部支付。
- 隐私政策 URL 能正常打开。
- App Review Notes 仍与实际功能一致。
