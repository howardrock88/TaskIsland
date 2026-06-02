# 任务管理 App 竞品调研与 TaskIsland 功能机会

调研日期：2026-06-01  
对象范围：App Store 已上架任务管理产品、GitHub 开源任务/项目管理项目、当前 TaskIsland 本地代码功能。

## 1. 结论摘要

任务管理产品已经形成了一组非常稳定的“标配功能”：快速记录、列表/项目归类、优先级、日期和提醒、重复任务、子任务、今日视图、搜索过滤、跨设备同步、日历或时间线视图。商业产品更重视跨设备、自然语言输入、日历融合和团队协作；开源项目更重视自托管、数据主权、多视图、集成和可扩展。

TaskIsland 当前不适合直接追赶 Todoist、TickTick、OmniFocus 这类大而全产品。它最有差异化的地方是“macOS 桌面上始终可见的当前任务焦点层”：菜单栏入口、顶部悬浮岛、快速新增、悬浮预览、当前任务切换、本地优先。竞品普遍有 Today/Widget/菜单栏/快捷添加，但很少把“当前该做什么”做成一个常驻、轻量、可交互的桌面胶囊。

建议 TaskIsland 的产品方向是：保留小而快的本地优先定位，补齐个人任务管理最关键的缺口，并围绕“当下专注”做亮点。优先加日期/提醒/重复、今日计划、自然语言快速新增、子任务/备注面板、专注计时/时间记录和轻量时间块。暂时不要做重型团队协作、复杂权限、Gantt、完整 Kanban 或账号云服务。

## 2. App Store 代表产品

| 产品 | 定位 | 标配能力 | 亮点功能 | 对 TaskIsland 的启发 |
| --- | --- | --- | --- | --- |
| [Things 3](https://apps.apple.com/us/app/things-3/id904280696?mt=12) | Apple 生态里的高品质个人 GTD 工具 | To-do、项目、Area、Today/Upcoming、提醒、重复、标签、日历、Markdown、快捷录入、同步 | 结构清晰但不压迫；Quick Entry with Autofill 可从其他 App 抓取上下文；This Evening 降低当天计划压力 | TaskIsland 可以学习“轻量但完整”的分层：Inbox、Today、Projects/Areas 可晚一点做，先做 Today/Current |
| [Todoist](https://apps.apple.com/us/app/todoist-to-do-list-calendar/id585829637?mt=12) | 跨平台个人与轻团队任务管理 | 项目、区段、子任务、标签、优先级、重复任务、列表/看板/日历、评论、文件、团队共享 | 自然语言 Quick Add 很强；输入一句话即可识别日期、项目、标签和重复规则；生态覆盖设备、浏览器和邮件插件 | TaskIsland 的全局快捷新增很适合承载自然语言输入 |
| [TickTick](https://apps.apple.com/us/app/ticktick-to-do-list-calendar/id966085870?mt=12) | All-in-one 个人效率工具 | 任务、提醒、优先级、重复、清单、排序、跨端同步、日历、附件、协作 | 把任务、日历、番茄钟、习惯、倒计时放在一起；高级版有时间线/日历网格和多个提醒 | TaskIsland 可优先吸收“当前任务 + 番茄钟 + 习惯/重复”的组合，而不是一次做完整大平台 |
| [OmniFocus 4](https://apps.apple.com/us/app/omnifocus-4/id1542143627?platform=mac) | 专业用户/GTD 深度任务系统 | 项目、标签、日期、跨端同步、快速导航 | Perspectives 可按多个条件做自定义视图；Focus 可只看某个项目/文件夹；同步强调端到端加密 | TaskIsland 不宜复制复杂度，但可以做 3-5 个固定“智能视图”：今天、高优、等待、无日期、已完成 |
| [Microsoft To Do](https://apps.apple.com/us/app/microsoft-to-do/id1274495053?mt=12) | 免费、简单、Microsoft 365 生态 | 列表、My Day、建议、笔记、共享列表、重复日期/提醒、步骤、附件、Outlook 同步 | My Day + Suggestions 是很清晰的每日计划入口；与 Outlook/M365 自然连接 | TaskIsland 可以做“今日岛”：每天从未完成任务里挑选少量任务进入岛上 |
| [Structured](https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946) | 时间线式日计划工具 | Inbox、任务/日程/习惯、子任务、备注、跨端同步、Pomodoro、小组件 | 视觉时间线、AI 日程草稿、自动重排错过任务，特别强调 ADHD 友好和降低压迫感 | TaskIsland 可做迷你时间块：不是完整日历，而是在岛上显示“当前任务剩余时间/下一个时间块” |
| [Sorted³](https://apps.apple.com/us/app/sorted-calendar-notes-tasks/id1306893526) | Hyper-scheduling 日程化任务工具 | 任务、事件、备注、附件、时间线、重复、iCloud 同步、自然语言、Siri/URL Scheme | Auto Schedule、Magic Select、Time Ruler 让重排一天变轻松 | TaskIsland 可做“推迟 15 分钟/今天稍后/明天”这类轻重排操作 |
| [GoodTask](https://apps.apple.com/us/app/goodtask/id1143437985?mt=12) | Apple Reminders/Calendars 的增强前端 | Reminders/Calendar 同步、重复、列表/日/周/月/看板、智能列表、过滤、批量操作 | 不重建数据底座，直接增强 Apple Reminders；Quick Actions 和 Text Snippets 提高录入效率 | TaskIsland 可考虑做 Apple Reminders 可选同步，保持本地优先，但借系统生态获得 Siri/提醒能力 |

## 3. GitHub 开源项目样本

| 项目 | 定位 | 代表功能 | 特别亮点 | 对 TaskIsland 的启发 |
| --- | --- | --- | --- | --- |
| [Super Productivity](https://super-productivity.com/) / [GitHub](https://github.com/super-productivity/super-productivity) | 本地优先、开源、深度工作任务管理 | 快速新增、子任务、备注、日期、项目/标签/文件夹、Kanban/Eisenhower/列表、Pomodoro、时间跟踪、GitHub/Jira/GitLab/CalDAV、插件、导出 | 任务管理和“开始工作”结合得很紧：Focus Mode、时间记录、工作日志、无账号无追踪 | TaskIsland 最值得借鉴：从“展示任务”升级到“启动专注、记录完成、复盘一天” |
| [Vikunja](https://vikunja.io/features/) / [GitHub](https://github.com/go-vikunja/vikunja) | 自托管开源 Todo/项目管理 | 项目/子项目、团队共享、列表/Gantt/Table/Kanban、提醒、重复、子任务、Quick Add Magic、标签、过滤、优先级、分配、附件、任务关系、CalDAV、导入 | 一个任务对象可被多种视图复用；Quick Add Magic 支持输入时设置日期、标签、负责人等 | TaskIsland 可先建立更完整的 Task 数据模型，之后 UI 仍保持小 |
| [Plane](https://github.com/makeplane/plane) | 开源 Jira/Linear 替代 | Work Items、Cycles、Modules、Views、Pages、Analytics、自托管 | 面向团队研发流程，任务、文档、周期、分析一体化 | 暂不适合 TaskIsland 第一阶段；可借鉴 Views/Analytics 的轻量个人版 |
| [Focalboard](https://www.focalboard.com/) / [GitHub](https://github.com/mattermost-community/focalboard) | 开源 Trello/Asana/Notion 替代 | Kanban、表格、日历、Gallery、过滤/排序、保存视图、模板、评论、@mention、权限、自定义字段 | “同一数据，多种视图”加模板启动很快 | TaskIsland 不必做完整看板，但可加“保存筛选视图”和少量模板 |
| [AppFlowy](https://github.com/AppFlowy-IO/AppFlowy) | 开源 Notion 替代/AI 工作空间 | 项目、Wiki、团队、数据库、Kanban、AI、跨平台、自托管 | 把任务放进更大的知识/项目工作空间；强调数据控制 | TaskIsland 可以和笔记/链接结合，但不应变成 Notion |
| [WeKan](https://github.com/wekan/wekan) | 开源实时 Kanban | 看板、卡片、实时协作、自托管、多平台、多语言 | 个人和团队都可用，视觉化状态很直接 | 对 TaskIsland 的启发是“状态可视化”，不是复制看板 |
| [Kanboard](https://kanboard.org/) / [GitHub](https://github.com/kanboard/kanboard) | 极简开源 Kanban 项目管理 | WIP 限制、拖拽、搜索查询、子任务、Markdown、评论、文档、自动化动作、OAuth/LDAP | WIP limit 很适合防止任务过载；自动化动作减少重复操作 | TaskIsland 可做“岛上最多显示 1 个当前 + 2 个候选”，用产品规则限制过载 |
| [Tasks.org](https://tasks.org/) / [GitHub](https://github.com/tasks/tasks) | 开源 Android 待办/提醒 | CalDAV、Google Tasks、EteSync、DecSync、离线/自托管、标签、列表、无限层级子任务、过滤、位置提醒 | 开放协议和隐私很强；可与 Apple Reminders/Outlook/Thunderbird 等通过协议互通 | TaskIsland 未来同步优先考虑开放协议或 Apple Reminders，而不是先造账号系统 |

## 4. 共性功能归纳

成熟任务管理 App 的共性可以分成 8 层：

1. 捕获层：快速新增、快捷键、语音/分享扩展、邮件转任务、自然语言输入。
2. 任务层：标题、备注、完成状态、优先级、日期、提醒、重复、子任务、附件。
3. 组织层：Inbox、列表、项目、区域/文件夹、标签、智能过滤。
4. 计划层：Today、Upcoming、My Day、日历、时间线、自动排程、推迟/重排。
5. 执行层：当前任务、Focus Mode、Pomodoro、时间跟踪、进度提示。
6. 回顾层：已完成记录、工作日志、统计、项目进展、日报/周报。
7. 协作层：共享列表、负责人、评论、文件、权限、团队空间。
8. 生态层：跨端同步、系统提醒、日历、邮件、浏览器、Shortcuts、Siri、API、导入导出。

TaskIsland 当前覆盖了捕获层和执行层的一部分，但任务层、组织层、计划层、回顾层还比较薄。它的优势不在“功能数量”，而在“启动速度、桌面可见性和低干扰交互”。

## 5. TaskIsland 当前功能盘点

基于本地代码和 README，当前 TaskIsland 已具备：

- macOS 常驻应用形态，可出现在 Dock、应用列表和菜单栏；菜单栏可显示未完成数量或当前任务标题。
- 顶部常驻液态玻璃悬浮岛，包含小胶囊、专注/提醒中等胶囊、悬停展开态三种形态。
- 小胶囊显示高/中/低优先级数量；展开态显示最多 3 条重点任务，支持快速新增、固定、完成、删除；专注/提醒态显示任务标题、倒计时和暂停/停止。
- 任务面板默认显示所有未完成任务，避免未加入“今天”的任务被隐藏；支持固定、搜索、视图切换和按优先级分组。
- 任务详情支持标题编辑、备注、截止时间、提醒时间、重复规则、项目、标签、子任务、预计专注分钟、推迟、设为当前。
- 当前任务机制已经从自动轮转改为主动设置：用户在任务行里选择当前任务，顶部专注栏和菜单栏围绕当前任务工作。
- 专注模式支持开始、暂停、继续、停止、任务级预计分钟和全局默认专注分钟。
- 默认 `Control + Option + N` 快速新增，快捷键可自定义；快速新增支持日期、时间、优先级、标签、项目、重复和预计时长解析。
- 本地 SwiftData 存储，支持 JSON、Markdown、CSV 导入导出，并支持 Todoist 风格 CSV 导入。
- 支持 Apple 提醒事项导入/导出、本地通知、`taskisland://` URL Scheme。
- 设置项包括显示悬浮岛、菜单栏标题、暗夜玻璃、悬浮岛透明度、背景颜色、文字颜色、优先级颜色、顶部间距、拖拽位置和快捷键。
- 提供 `.app`、`.pkg`、`.dmg` 打包脚本，`.pkg` 会安装到 `/Applications/任务岛.app` 并注册系统应用索引。

## 6. TaskIsland 与竞品相同的功能

| 功能 | TaskIsland 当前状态 | 竞品常见状态 | 判断 |
| --- | --- | --- | --- |
| 快速新增 | 已有全局快捷键、面板内新增和自然语言解析 | Things/Todoist/TickTick/GoodTask 都强调快速录入 | 已具备实用基础 |
| 完成/删除任务 | 已有 | 所有任务 App 标配 | 已具备 |
| 优先级 | 高/中/低三档，可自定义颜色 | Todoist/TickTick/OmniFocus/Vikunja/GoodTask 常见 | 已具备且可视化不错 |
| 日期/提醒/重复 | 支持任意截止时间、提醒时间和基础重复规则 | 成熟任务 App 的核心能力 | 已补齐第一版 |
| 标签/项目/搜索 | 支持标签、项目、搜索和固定视图 | Todoist/OmniFocus/GoodTask/Vikunja 常见 | 已具备轻量版本 |
| 子任务/备注 | 支持备注和子任务 | Things/Todoist/TickTick/Vikunja 常见 | 已具备基础 |
| 当前任务/今日焦点 | 有主动设置当前任务、今天、建议、高优、即将等视图 | Microsoft To Do 的 My Day、Things Today、OmniFocus Focus 类似但形态不同 | 交互形态更桌面化 |
| 专注计时 | 支持当前任务专注、暂停、停止和时间累计 | TickTick、Structured、Super Productivity 常见 | 与悬浮岛结合是差异点 |
| 菜单栏/桌面轻入口 | 有菜单栏和悬浮岛 | 很多产品有小组件、菜单栏、快捷入口 | 已具备强差异形态 |
| 本地存储 | 有 SwiftData 本地优先 | 开源项目常见，商业产品多云同步 | 已具备基础隐私优势 |
| 导入/导出 | JSON、Markdown、CSV、Todoist CSV、Apple 提醒事项 | 本地优先工具常用来建立数据信任 | 已具备基础 |
| 外观设置 | 暗夜玻璃、透明度、背景色、文字色、优先级色、位置 | 各产品都有主题/图标/小组件定制 | 已具备较高可调性 |

## 7. TaskIsland 目前明显缺口

| 缺口 | 为什么重要 | 参考产品 |
| --- | --- | --- |
| 当前任务深度不够 | 当前任务已经能显示和启动专注，但还没有形成完整“焦点任务”工作流 | Super Productivity Focus Mode、OmniFocus Focus |
| 专注结束流程 | 目前有开始/暂停/停止，但缺少完成后继续、休息、选择下一项、记录回顾等闭环 | TickTick、Structured、Super Productivity |
| 提醒后的快速处理 | 到期后有系统通知和悬浮岛提醒，但还缺少稍后提醒、完成、打开详情等一键动作 | Microsoft To Do、GoodTask |
| 日历/时间块 | 已有日期和预计时长，但还没有把任务排入日程或时间线 | Structured、Sorted³、TickTick |
| 正式签名与公证 | 影响跨机器分发和用户安装信任 | macOS Developer ID 分发 |
| 跨设备同步 | 当前本地优先很好，但多设备用户仍需要 Apple Reminders、iCloud 或开放协议策略 | Things、GoodTask、Tasks.org |

## 8. TaskIsland 竞品没有或不突出的功能

TaskIsland 的稀缺点主要在桌面存在感和交互形态：

- 顶部常驻“灵动岛式”胶囊：不用打开主窗口即可看到任务压力、提醒和当前焦点。
- 三态悬浮岛：小胶囊看数量，中等胶囊处理专注/提醒，展开态处理最多 3 条重点任务。
- 悬停展开轻操作：最多 3 条重点任务 + 完成/删除/新增，不进入完整管理界面也能处理小任务。
- 当前任务入口：比 Today 列表更聚焦，允许用户主动指定“现在最重要的一件事”。
- 非激活悬浮面板：不打断当前应用，又能跨桌面/全屏可见。
- 本地优先、无账号：适合个人自用和隐私敏感用户。
- 视觉识别度高：Liquid Glass + 优先级颜色计数 + 自定义外观，产品记忆点比普通菜单栏 Todo 更强。

这些是 TaskIsland 最应该保住的“产品骨架”。新增功能时要服务于这个骨架，而不是把它淹没成普通任务列表。

## 9. 建议加入 TaskIsland 的亮点/实用功能

### P0：把“当前任务”做成真正的焦点机制

1. 当前任务常驻中等悬浮岛
   - 即使没有开始专注，也允许用户把当前任务显示在中等悬浮岛里。
   - 中等悬浮岛可以展示任务标题、预计时长、提醒时间和开始专注按钮。
   - 这样“设为当前”就从列表标签变成桌面焦点模式。

2. 完成当前任务后的下一步
   - 完成后不自动切换，而是轻量提示“选择下一个当前任务”。
   - 可给出高优、今天、即将到期三类候选。
   - 用户仍保留主动选择权，避免系统按顺序误判当前任务。

3. 提醒到期后的悬浮岛动作
   - 在中等悬浮岛上增加“完成”“稍后提醒”“打开详情”。
   - 提醒动画保留，但操作要尽量一眼可懂。

### P1：放大专注和回顾价值

4. 专注结束流程
   - 计时结束后提供完成、继续、休息、停止四个动作。
   - 记录专注时长并纳入每日回顾。
   - 保持中等悬浮岛，不把用户强行拉进完整面板。

5. 每日回顾增强
   - 汇总完成任务、推迟任务、专注时长和未完成高优任务。
   - 根据截止时间、优先级和预计分钟给出明日建议。
   - 本地生成即可，不必依赖 AI。

6. 轻量时间块
   - 给任务加预计时长，Today 视图生成一个很短的时间块列表。
   - 操作只保留“稍后 15 分钟”“今天晚点”“明天”。
   - 学 Structured/Sorted³ 的重排价值，但不要做复杂日历编辑器。

### P2：增强长期可用性

7. 正式签名和公证
   - Developer ID Application / Installer 签名。
   - Apple Notary Service 公证。
   - 为对外分发提供可信安装体验。

8. Apple Reminders 同步策略
   - 当前已有导入/导出，下一步可以考虑选择性同步。
   - 仍保留 SwiftData 本地优先，不强制绑定系统提醒。

9. Shortcuts / Raycast / Spotlight 入口
   - 已有 URL Scheme，可继续打磨常用动作。
   - 让新增、开始当前任务、完成当前任务变成更自然的系统级操作。

## 10. 不建议近期做的功能

- 完整团队协作、评论、负责人、权限系统：会改变产品复杂度和架构。
- 完整 Kanban/Gantt：开源项目已经很多，TaskIsland 的优势不在这里。
- 账号体系和自建云同步：成本高，短期不如 Apple Reminders/iCloud/导入导出实用。
- 大量附件管理：先支持链接和简单备注即可。
- 过度 AI 化：AI 可用于计划建议，但不应成为第一阶段核心卖点。

## 11. 推荐产品路线

### 阶段 1：已完成，达到可每天使用

- 增加 dueAt、reminderAt、repeatRule、tags、project/list、estimatedMinutes 字段。
- 快速新增支持日期/优先级/预计时长的基础解析。
- 增加 Today 视图和任务详情弹层。
- 岛上展示 Today 队列或全部重点任务，并支持专注/提醒中等胶囊。
- 支持导入导出、Apple 提醒事项、快捷键自定义和外观自定义。

### 阶段 2：把“当前任务”做成焦点工作流

- 当前任务可常驻中等悬浮岛。
- 完成当前任务后推荐下一项，而不是自动切换。
- 专注结束可完成、继续、休息或选择下一项。
- 回顾里强化当前任务和专注时长。

### 阶段 3：增强对外分发和生态

- Developer ID 正式签名和公证。
- Apple Reminders 可选同步。
- Shortcuts 支持：新增任务、开始当前任务、完成当前任务。
- Spotlight/Raycast 入口可选。

### 阶段 4：智能计划，但保持克制

- 根据截止时间、优先级、预计时长推荐今日任务。
- 未完成任务自动建议“稍后/明天/本周”。
- AI 只作为辅助，不替代用户选择。

## 12. 产品定位建议

一句话定位：

> TaskIsland 是一个本地优先的 macOS 桌面任务焦点工具，把“现在该做什么”常驻在屏幕顶部，并用最少操作完成记录、专注和推进。

不建议把宣传重点放在“功能最全的 Todo App”。更适合强调：

- 桌面常驻：不用切 App 也知道当前该做什么。
- 低干扰：悬浮岛轻操作，复杂编辑收进面板。
- 本地优先：无需账号，数据在本机。
- 快速捕获：全局快捷键记录想法，不打断当前工作。
- 专注推进：当前任务、计时、提醒、完成和回顾。

## 13. 资料来源

App Store / 官方页面：

- Things 3 App Store: https://apps.apple.com/us/app/things-3/id904280696?mt=12
- Todoist App Store: https://apps.apple.com/us/app/todoist-to-do-list-calendar/id585829637?mt=12
- TickTick App Store: https://apps.apple.com/us/app/ticktick-to-do-list-calendar/id966085870?mt=12
- OmniFocus 4 App Store: https://apps.apple.com/us/app/omnifocus-4/id1542143627?platform=mac
- Microsoft To Do App Store: https://apps.apple.com/us/app/microsoft-to-do/id1274495053?mt=12
- Structured App Store: https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946
- Sorted³ App Store: https://apps.apple.com/us/app/sorted-calendar-notes-tasks/id1306893526
- GoodTask App Store: https://apps.apple.com/us/app/goodtask/id1143437985?mt=12

开源项目：

- Super Productivity: https://super-productivity.com/ 和 https://github.com/super-productivity/super-productivity
- Vikunja: https://vikunja.io/features/ 和 https://github.com/go-vikunja/vikunja
- Plane: https://github.com/makeplane/plane
- Focalboard: https://www.focalboard.com/ 和 https://github.com/mattermost-community/focalboard
- AppFlowy: https://github.com/AppFlowy-IO/AppFlowy
- WeKan: https://github.com/wekan/wekan
- Kanboard: https://kanboard.org/ 和 https://github.com/kanboard/kanboard
- Tasks.org: https://tasks.org/ 和 https://github.com/tasks/tasks

TaskIsland 本地依据：

- README.md
- PLAN.md
- Sources/TaskIslandCore/TaskItem.swift
- Sources/TaskIslandCore/TaskStore.swift
- Sources/TaskIsland/Views/CapsuleIslandView.swift
- Sources/TaskIsland/Views/MenuBarWindowView.swift
- Sources/TaskIsland/Views/QuickAddView.swift
- Sources/TaskIsland/AppSettings.swift
- Sources/TaskIsland/IslandPanelController.swift
