# 任务岛 App Review 风险点核对

这份文件用于提交前自查，也可以在 Apple 审核问到权限、快捷键或 URL Scheme 时复制要点回复。

## 当前结论

- 当前版本是本地优先的 macOS 任务管理工具。
- 当前版本不需要账号登录。
- 当前版本不包含云同步、广告或第三方统计 SDK。
- 当前版本不把任务、提醒事项或导入文件上传到开发者服务器。
- App Store 渠道上传包不安装 LaunchAgent。

## 权限与能力说明

### Apple 提醒事项

用途：用户主动从系统提醒事项导入任务，或把任务导出到系统提醒事项。

审核说明：

```text
Apple Reminders access is used only when the user explicitly imports tasks from Apple Reminders or exports TaskIsland tasks to Apple Reminders. TaskIsland does not upload Reminders data to a developer server.
```

### 本地通知

用途：用户给任务设置提醒时间后，在本机显示提醒通知。

审核说明：

```text
Notification permission is used only for local task reminders configured by the user.
```

### 用户选择文件读写

用途：用户主动选择 JSON、Markdown 或 CSV 文件进行导入和导出。

审核说明：

```text
File access is limited to user-selected files for import and export. TaskIsland does not scan user folders.
```

### 全局快捷键

用途：打开快速新增任务面板，降低记录任务的操作成本。

当前实现只注册固定快捷键触发事件，不记录键盘输入内容。

审核说明：

```text
The global shortcut is only used to open the Quick Add panel. TaskIsland does not record keyboard input or monitor typed content.
```

### 鼠标事件监听

用途：在悬浮岛拖拽结束后完成位置更新，或在点击外部区域时收起面板。

审核说明：

```text
Mouse event monitoring is used only for floating island interaction, such as ending a drag gesture or dismissing the task panel when the user clicks outside it. It is not used for analytics or tracking.
```

### taskisland:// URL Scheme

用途：支持 macOS 快捷指令、启动器或自动化工具打开快速新增、专注、完成和显示任务面板。

审核说明：

```text
The taskisland:// URL scheme is used for local automation workflows such as Shortcuts and launchers. It does not transmit data to a server.
```

### 登录启动

直接分发包曾使用 LaunchAgent 实现登录启动。Mac App Store 上传包不安装 LaunchAgent。

审核说明：

```text
The Mac App Store package does not install a LaunchAgent. Login-start behavior used by the direct-distribution package is not included in the App Store channel.
```

## App Privacy 复核

如果提交构建仍保持当前实现，可以按以下方向填写：

- 数据收集：开发者不收集此 App 的任何数据
- 跟踪：不用于跟踪
- 第三方广告：无
- 第三方统计：无
- 账号系统：无
- 云同步：无

提交前仍要以最终构建为准。如果后续加入联网同步、账号登录、崩溃统计、支付分析或广告 SDK，需要重新填写 App Privacy。
