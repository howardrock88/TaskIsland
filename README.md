# 任务岛

任务岛是一款本地优先的 macOS 悬浮任务工具。它把重要任务、提醒和专注计时放在屏幕顶部，用一个轻量的液态玻璃悬浮岛帮助用户在不切换 App 的情况下捕获、查看和推进任务。

![任务岛 16:9 宣传图](assets/posters/taskisland-poster-16x9.png)

[English README](README.en.md)

## 亮点

- **三态悬浮岛**：数字岛显示高/中/低优先级数量；专注岛显示当前任务、倒计时、暂停和停止；行动岛显示最多 3 条重点任务，并提供快速新增、固定、完成和删除。
- **当前任务与专注**：用户可把任意任务设为当前任务，顶部专注栏和菜单栏会围绕它工作；开始专注后进入中等悬浮岛，支持暂停、继续和停止。
- **快速新增**：默认 `Control + Option + N` 打开快速新增面板，支持自然语言输入，例如 `明天 10点 发周报 #工作 !高 /30m`。
- **任务面板**：支持全部、今天、建议、高优、即将、无日期、标签、项目、已完成和回顾视图。
- **任务详情**：支持备注、任意截止时间、任意提醒时间、重复规则、项目、标签、预计专注分钟、推迟、设为当前。
- **可自定义外观**：支持暗夜玻璃模式、悬浮岛透明度、背景颜色、文字颜色、优先级颜色、顶部位置和拖拽摆放。
- **中英文界面**：设置里可切换中文或 English，主要界面、悬浮岛、快速新增、系统菜单和通知提示会即时跟随。
- **本地优先**：使用 SwiftData 本地存储，不依赖账号；支持 JSON、Markdown、CSV 导入导出。
- **系统集成**：支持 Apple 提醒事项导入/导出、本地通知、`taskisland://` URL Scheme、登录启动安装配置。
- **可打包安装**：提供 `.app`、`.pkg`、`.dmg` 打包脚本，可安装到 `/Applications/任务岛.app`。

## 更新说明

### 0.1.12 - 2026-06-14

- 修复主任务面板四角没有完整裁切的问题，避免圆角和窗口直角之间露出背景色。
- 面板宿主层现在会按连续圆角裁切，主界面的玻璃背景、高光和描边也会统一限制在圆角区域内。

### 0.1.11 - 2026-06-14

- 调整应用图标在 1024×1024 画布中的显示比例：可见区域为 860×860，四边留白 82px，让 Dock 和应用程序列表里的图标观感更稳。

### 0.1.10 - 2026-06-14

- 修复本机安装后 Dock 仍可能显示旧图标的问题；程序启动时会主动使用应用包内的最新图标。

### 0.1.9 - 2026-06-14

- 将直接分发版应用图标对齐到 App Store 最新图标，保证 Dock、应用程序和安装包里的视觉一致。
- 重新生成安装包图标资源，避免本机安装后仍显示旧图标或旧缓存图标。

### 0.1.8 - 2026-06-14

- 更换应用图标为更简洁的玻璃底 + 数字岛信号点形式，提升 Dock、小尺寸图标和 App Store 图标的识别度。
- 图标源文件更新为标准 1024×1024 尺寸，后续 `.app`、`.dmg`、`.pkg` 和 App Store 素材都会使用这一版。

### 0.1.7 - 2026-06-13

- 新增界面语言设置，可在中文和 English 之间切换，切换后立即生效。
- 悬浮岛、任务面板、任务行、任务详情、快速新增、菜单栏、系统菜单、提醒通知和快捷键设置接入中英文文案。
- 日期、专注时长、优先级、重复规则、推迟选项、导入导出提示等常用文案会跟随语言显示。
- 任务内容本身不会被翻译，避免修改用户已有数据。

### 0.1.6 - 2026-06-11

- 新增专注结束提醒态：专注计时自然结束后，专注岛会保留在桌面上，直到用户点击“完成”确认。
- 新增专注完成动画：专注岛出现从左到右的扫光、流动高光边框和跳动脉冲线，提升到点提醒的可见性。
- 声音提醒增强为 5 次连续提示，并修复系统快速连播时只响 1-2 次的问题。
- 修复专注结束时专注岛先缩回数字岛、只听到声音但看不到动画的问题。
- 修复已专注过的任务再次开始时误判为立即完成的问题；停止后的再次开始会开启新一轮，暂停后的继续仍保留本轮进度。
- 简化专注完成交互：移除重复的 `×` 按钮，只保留“完成”确认按钮；点击后直接关闭专注岛，不再误打开任务面板。

### 0.1.5 - 2026-06-07

- 修复分发打包流程：`.app` 现在会在打包后签名并严格校验，`.dmg` / `.pkg` 不再把正式签名覆盖成 ad-hoc 签名。
- 新增 Developer ID 签名和 Apple Notary Service 公证环境变量，便于构建可通过 Gatekeeper 的公开分发包。
- 打包脚本改为从明确架构目录取 release 产物，并支持 `TASKISLAND_ARCHS`、`TASKISLAND_MIN_MACOS` 和 `TASKISLAND_PACKAGE_SUFFIX` 输出独立架构包。
- 修正 `.pkg` 安装后启动命令，改为直接打开 `/Applications/任务岛.app`。

### 0.1.4 - 2026-06-04

- 在保留数字岛、专注岛、行动岛三态结构的基础上收口视觉系统。
- 优化悬浮岛玻璃高光、边界和任务行层级，去掉容易被看成斜线的装饰高光。
- 统一任务面板、设置面板、任务行和按钮的玻璃材质、描边和阴影细节。
- 新增本地回退保护点 `visual-baseline-20260604-152102`，可回到本轮视觉优化前的版本。

### 0.1.3 - 2026-06-03

- 已完成任务区改为默认折叠，只显示已完成数量和展开按钮。
- 点击“展开”后才在原地显示已完成任务列表，避免普通任务面板被历史任务占满。
- 搜索已完成任务时会自动展开匹配结果；单独“完成”视图仍直接显示列表。

### 0.1.2 - 2026-06-03

- 修复任务面板只剩已完成任务时显示空状态的问题。
- “全部”视图现在会在未完成任务后显示已完成任务，搜索也会匹配已完成任务。
- 其他任务视图底部的已完成提示增加“查看”入口，可直接切到完成视图。

### 0.1.1 - 2026-06-02

- 建立统一版本文件，`.app`、`.pkg` 和 `.dmg` 打包脚本都会读取同一个版本号。
- README 和宣传海报统一三态命名：数字岛、专注岛、行动岛。
- README 界面展示图改为使用真实 UI 渲染截图，并移除未作为公开能力展示的子任务描述。

### 0.1.0 - 2026-06-01

- 第一个可用本地构建版，包含悬浮岛、任务面板、快速新增、专注计时、提醒、导入导出和 macOS 安装包脚本。

## 版本管理约定

每次对功能、界面、文档展示或安装包产生用户可见影响的变更，都需要同步完成：

- 更新根目录 `VERSION`。
- 在 README 的“更新说明”里新增对应版本记录。
- 重新生成安装包，并在 GitHub Release 上传对应版本的 `.dmg` 和 `.pkg`。

## 界面展示

### 悬浮岛

![悬浮岛界面](assets/screenshots/01-floating-island.png)

任务岛有三种桌面状态：数字岛只显示高、中、低优先级数量；专注岛在专注或提醒时展示任务标题、倒计时和专注控制；行动岛在悬停或固定展开后显示最多 3 条重点任务，并提供快速新增、固定、完成和删除。

### 任务面板

![任务面板](assets/screenshots/02-task-panel.png)

点击悬浮岛后进入完整任务面板。默认显示所有未完成任务，并保留当前任务/专注区、任务列表、视图切换、搜索和面板固定能力。

### 快速新增

![快速新增](assets/screenshots/03-quick-add.png)

快速新增支持自然语言输入，可识别日期、时间、优先级、标签和预计专注分钟。

### 任务详情

![任务详情](assets/screenshots/04-task-detail.png)

单条任务支持标题编辑、备注、截止时间、提醒时间、重复规则、项目、标签、推迟、设为当前和单独的专注分钟。

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

- Apple Silicon：macOS 15 或更新版本
- Intel：macOS 15 或更新版本
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
open dist/github/TaskIsland-0.1.12.pkg
```

构建 `.dmg`：

```sh
chmod +x Scripts/package-dmg.sh
Scripts/package-dmg.sh
open dist/github/TaskIsland-0.1.12.dmg
```

`.pkg` 会把 `任务岛.app` 安装到 `/Applications`，注册系统应用索引，并在安装后启动应用。

本地构建默认使用 ad-hoc app 签名，`.pkg` 默认不签名，适合开发机自测。公开分发给其他用户时需要 Developer ID 和公证，例如：

```sh
TASKISLAND_APP_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
TASKISLAND_DMG_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
TASKISLAND_NOTARY_PROFILE="taskisland-notary" \
Scripts/package-dmg.sh
```

```sh
TASKISLAND_APP_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
TASKISLAND_INSTALLER_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
TASKISLAND_NOTARY_PROFILE="taskisland-notary" \
Scripts/package-pkg.sh
```

单独构建 Intel 版本包时使用：

```sh
TASKISLAND_ARCHS="x86_64" TASKISLAND_MIN_MACOS="15.0" TASKISLAND_PACKAGE_SUFFIX="-intel" Scripts/package-dmg.sh
TASKISLAND_ARCHS="x86_64" TASKISLAND_MIN_MACOS="15.0" TASKISLAND_PACKAGE_SUFFIX="-intel" Scripts/package-pkg.sh
```

Mac App Store 渠道不和 GitHub Release 包混用。App Store 专用文件、提交说明、本地配置模板和上传包输出位置见 [AppStore/README.md](AppStore/README.md)。

## 检查

```sh
swift run TaskIslandChecks
```

检查脚本覆盖任务新增、完成、删除、循环、优先级、日期解析、专注计时、导入导出和 Todoist 风格 CSV 导入等规则。

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
AppStore                    Mac App Store 渠道配置和提交说明
```

## 发布说明

本地构建版未接入 Apple Developer ID 正式签名和公证，下载到其他机器后会被 Gatekeeper 拦截。分发给其他用户前，必须使用 Developer ID Application / Installer 证书签名，并通过 Apple Notary Service 公证。Mac App Store 渠道使用独立的 `AppStore/` 配置和 `dist/appstore/` 输出目录。

## 许可

暂未声明开源许可证。除非后续添加 LICENSE 文件，否则保留所有权利。
