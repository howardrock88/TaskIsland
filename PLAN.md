# Mac 菜单栏 + 灵动岛胶囊待办工具技术方案

## Summary
- 开发一个自用 macOS 26+ 原生菜单栏工具，工作名 `TaskIsland`，不走 App Store，第一版只做本地数据。
- 形态固定为：菜单栏入口 + 顶部常驻灵动岛胶囊 + 全局快捷添加。
- 技术栈：Swift 6.2、SwiftUI + AppKit、SwiftData、本地 `.app` 分发。需要安装 Xcode 26 SDK；当前机器只有 Command Line Tools，正式开发/打包建议补装 Xcode。
- 设计依据：Apple 官方推荐 `MenuBarExtra` 做常驻菜单栏工具；macOS 26 新视觉使用 Liquid Glass，SwiftUI 可用 `glassEffect`；图标使用 SF Symbols 7。

## Key Changes / Implementation
- 应用结构：
  - `@main` SwiftUI App，不显示 Dock 图标，`Info.plist` 设置 `LSUIElement=true`。
  - 主入口使用 `MenuBarExtra(...).menuBarExtraStyle(.window)`，菜单栏显示当前未完成数量和/或当前任务短标题。
  - 使用 AppKit `NSPanel` 实现顶部灵动岛胶囊：无边框、透明背景、非激活面板、`floating/statusBar` 级别，`canJoinAllSpaces` + `fullScreenAuxiliary`，尽量跨桌面和全屏可见。
- UI 设计：
  - 胶囊位于主屏顶部居中、菜单栏下方，默认高度 44-52pt，宽度 260-420pt，显示“当前任务 + 完成按钮 + 下一个按钮”。
  - 胶囊使用 Liquid Glass：SwiftUI `glassEffect(.regular.interactive(true), in: Capsule())`，文字用系统字体，图标用 SF Symbols。
  - 点击胶囊只展开轻量操作，不做复杂编辑；完整列表和设置放在菜单栏窗口，避免常驻层变吵。
  - 菜单栏窗口宽约 360pt，高约 480pt：顶部当前任务区，中间快捷输入框，下面未完成列表，底部设置/退出。
- 数据模型：
  - 本地 SwiftData：`TaskItem(id, title, notes, isCompleted, isCurrent, createdAt, updatedAt, completedAt, sortIndex)`。
  - 当前任务规则：优先显示 `isCurrent == true` 的未完成任务；没有则显示未完成列表第一项；全部完成时显示轻状态 “All done”。
  - v1 不接 Apple Reminders、不做同步、不做自然语言日期解析。
- 快捷添加：
  - 默认全局快捷键：`⌥ Space`，弹出居中/顶部快速输入框。
  - 输入标题后回车创建任务；如果当前没有任务，新任务自动成为当前任务。
  - `Esc` 取消并把焦点还给原应用。
  - 快捷键实现优先用成熟 Swift Package `KeyboardShortcuts`；如不引依赖，则用 Carbon `RegisterEventHotKey`。
- 设置项：
  - 开机启动、显示当前任务标题/仅显示数量、胶囊常驻开关、胶囊位置微调、快捷键录制。
  - 自用版默认不启用 sandbox；若未来上架再补 sandbox、权限说明和 Reminders entitlements。

## Test Plan
- 菜单栏：启动后无 Dock 图标；菜单栏图标可点击；任务数量随增删改实时更新。
- 胶囊：在普通窗口、多桌面、外接显示器、全屏应用下验证位置、层级、不会频繁抢焦点。
- 快捷添加：从浏览器/编辑器/终端中按 `⌥ Space`，添加任务后焦点回到原应用。
- 数据：重启 App 后任务仍在；完成、删除、设为当前任务后排序和当前任务规则正确。
- 视觉：浅色/深色模式、不同壁纸、不同菜单栏透明度下检查 Liquid Glass 可读性。
- 边界：菜单栏空间不足、刘海屏、自动隐藏菜单栏、无未完成任务、超长任务标题。

## Assumptions
- 目标系统锁定 macOS 26+，优先贴合最新版 macOS 视觉，不兼容旧系统。
- 第一版为个人使用，不做 App Store 审核、不做账号、不做云同步。
- 第一版核心价值是“随时看见当前该做什么”，不是完整项目管理工具。
- 自动寻找窗口空白区域暂不做；顶部胶囊和菜单栏先解决“不会被普通窗口盖住”的主要痛点。
