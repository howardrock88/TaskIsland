# 任务岛

任务岛是一款本地优先的 macOS 悬浮任务工具。它把重要任务、提醒和专注计时放在屏幕顶部，用一个轻量的液态玻璃悬浮岛帮助用户在不切换 App 的情况下捕获、查看和推进任务。

![任务岛 16:9 宣传图](assets/posters/taskisland-poster-16x9.png)

[English README](README.en.md)

## 亮点

- **三态悬浮岛**：小胶囊显示高/中/低优先级数量；专注或提醒时切换为中等胶囊，显示任务标题、倒计时、暂停和停止；悬停展开后显示最多 3 条重点任务。
- **当前任务与专注**：用户可把任意任务设为当前任务，顶部专注栏和菜单栏会围绕它工作；开始专注后进入中等悬浮岛，支持暂停、继续和停止。
- **快速新增**：默认 `Control + Option + N` 打开快速新增面板，支持自然语言输入，例如 `明天 10点 发周报 #工作 !高 /30m`。
- **任务面板**：支持全部、今天、建议、高优、即将、无日期、标签、项目、已完成和回顾视图。
- **任务详情**：支持备注、任意截止时间、任意提醒时间、重复规则、项目、标签、子任务、预计专注分钟、推迟、设为当前。
- **可自定义外观**：支持暗夜玻璃模式、悬浮岛透明度、背景颜色、文字颜色、优先级颜色、顶部位置和拖拽摆放。
- **本地优先**：使用 SwiftData 本地存储，不依赖账号；支持 JSON、Markdown、CSV 导入导出。
- **系统集成**：支持 Apple 提醒事项导入/导出、本地通知、`taskisland://` URL Scheme、登录启动安装配置。
- **可打包安装**：提供 `.app`、`.pkg`、`.dmg` 打包脚本，可安装到 `/Applications/任务岛.app`。

## 界面展示

### 悬浮岛

![悬浮岛界面](assets/screenshots/01-floating-island.png)

收起态只显示高、中、低优先级数量；悬停后展开为更大的任务岛，显示最多 3 条重点任务，并提供快速新增、固定、完成和删除。进入专注或提醒状态时，悬浮岛会变成中等胶囊，直接展示任务标题、倒计时和专注控制。

### 任务面板

![任务面板](assets/screenshots/02-task-panel.png)

点击悬浮岛后进入完整任务面板。默认显示所有未完成任务，并保留当前任务/专注区、任务列表、视图切换、搜索和面板固定能力。

### 快速新增

![快速新增](assets/screenshots/03-quick-add.png)

快速新增支持自然语言输入，可识别日期、时间、优先级、标签和预计专注分钟。

### 任务详情

![任务详情](assets/screenshots/04-task-detail.png)

单条任务支持标题编辑、备注、截止时间、提醒时间、重复规则、项目、标签、子任务、推迟、设为当前和单独的专注分钟。

### 任务视图

![任务视图](assets/screenshots/05-task-views.png)

任务可以按全部、今天、建议、高优、即将、无日期、标签、项目、已完成和回顾查看。

### 设置：显示与专注

![显示与悬浮岛设置](assets/screenshots/06-settings-display-capsule.png)

设置里可以控制显示悬浮岛、菜单栏标题、暗夜模式、默认专注时长和优先级颜色。

### 设置：优先级与悬浮岛

![专注与优先级设置](assets/screenshots/07-settings-focus-priority.png)

支持高、中、低优先级颜色，以及悬浮岛透明度、背景颜色、文字颜色和顶部位置。

### 设置：快捷键与数据

![快捷键与数据设置](assets/screenshots/08-settings-shortcuts-data.png)

支持快速新增快捷键自定义、导出格式选择、刷新、导入、导出、Apple 提醒事项导入/导出、隐藏和退出。

## 系统要求

- macOS 26 或更新版本
- Xcode / Swift 6.2 工具链

## 运行

```sh
swift run TaskIsland
```

启动后：

- 点击顶部悬浮岛可打开任务面板。
- 鼠标悬停悬浮岛可查看任务预览。
- 默认 `Control + Option + N` 打开快速新增面板，也可以在设置里自定义为常见修饰键和字母/空格组合。
- 按 `Esc` 或点击关闭按钮可关闭快速新增面板。

## 打包

构建 `.app`：

```sh
chmod +x Scripts/package-app.sh
Scripts/package-app.sh
open .build/package/任务岛.app
```

构建 `.pkg` 安装包：

```sh
chmod +x Scripts/package-pkg.sh
Scripts/package-pkg.sh
open dist/TaskIsland-0.1.0.pkg
```

构建 `.dmg`：

```sh
chmod +x Scripts/package-dmg.sh
Scripts/package-dmg.sh
open dist/TaskIsland-0.1.0.dmg
```

`.pkg` 会把 `任务岛.app` 安装到 `/Applications`，注册系统应用索引，并在安装后启动应用。

## 检查

```sh
swift run TaskIslandChecks
```

检查脚本覆盖任务新增、完成、删除、循环、优先级、日期解析、专注计时、子任务、导入导出和 Todoist 风格 CSV 导入等规则。

## URL Scheme

可通过 macOS 快捷指令或其他启动器调用：

```text
taskisland://add?title=明天%2010点%20发周报%20%23工作%20!高%20/30m
taskisland://focus
taskisland://complete
taskisland://show
```

## 目录结构

```text
Sources/TaskIslandCore      核心任务模型、存储、解析、导入导出
Sources/TaskIsland          macOS App、悬浮岛、面板、快捷键、系统集成
Sources/TaskIslandChecks    轻量检查脚本
Resources                   应用图标
Scripts                     打包与 README 图片生成脚本
assets/posters              GitHub 展示海报
assets/screenshots          GitHub 界面截图
docs                        调研和项目资料
```

## 发布说明

当前版本是本地构建版，未接入 Apple Developer ID 正式签名和公证。分发给其他用户前，建议使用 Developer ID Application / Installer 证书签名，并通过 Apple Notary Service 公证。

## 许可

暂未声明开源许可证。除非后续添加 LICENSE 文件，否则保留所有权利。
