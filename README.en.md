# TaskIsland

TaskIsland is a local-first floating task app for macOS. It keeps the question “what should I do now?” visible at the top of your desktop through a lightweight liquid-glass island for priorities, current task focus, and quick actions.

![TaskIsland 16:9 poster](assets/posters/taskisland-poster-16x9.png)

[中文 README](README.md)

## Highlights

- **Floating task island**: collapsed mode shows high / medium / low priority counts; hover mode previews up to 3 tasks.
- **Current task and focus**: the task panel highlights the current task or active focus session, with one-click start / pause.
- **Quick add**: open a global quick-add panel and type natural language such as `tomorrow 10:00 weekly report #work !high /30m`.
- **Task panel views**: All, Today, Suggestions, High Priority, Upcoming, No Date, Tags, Projects, Completed, and Review.
- **Rich task details**: notes, arbitrary due date, arbitrary reminder time, repeat rule, project, tags, subtasks, estimated focus minutes, postpone, and “set as current”.
- **Custom appearance**: dark glass mode, island transparency, background color, text color, priority colors, and top position.
- **Local-first data**: SwiftData storage, no account required; JSON, Markdown, and CSV import / export.
- **macOS integration**: Apple Reminders import / export, local notifications, `taskisland://` URL Scheme, and installer login-start configuration.
- **Installable builds**: scripts generate `.app`, `.pkg`, and `.dmg` packages for `/Applications/任务岛.app`.

## Preview

| 16:9 poster | 3:4 portrait poster |
| --- | --- |
| ![16:9 poster](assets/posters/taskisland-poster-16x9.png) | ![3:4 poster](assets/posters/taskisland-poster-3x4.png) |

## Requirements

- macOS 26 or later
- Xcode / Swift 6.2 toolchain

## Run

```sh
swift run TaskIsland
```

After launch:

- Click the floating island to open the task panel.
- Hover the island to preview tasks.
- Press the default `Option + Q` shortcut to open quick add. The shortcut is customizable in Settings.
- Press `Esc` or the close button to dismiss quick add.

## Build

Build the `.app` bundle:

```sh
chmod +x Scripts/package-app.sh
Scripts/package-app.sh
open .build/package/任务岛.app
```

Build the `.pkg` installer:

```sh
chmod +x Scripts/package-pkg.sh
Scripts/package-pkg.sh
open dist/TaskIsland-0.1.0.pkg
```

Build the `.dmg` image:

```sh
chmod +x Scripts/package-dmg.sh
Scripts/package-dmg.sh
open dist/TaskIsland-0.1.0.dmg
```

The `.pkg` installer places `任务岛.app` in `/Applications`, registers it with LaunchServices / Spotlight, and starts the app after installation.

## Checks

```sh
swift run TaskIslandChecks
```

The check target covers task creation, completion, deletion, recurrence, priority, date parsing, focus timing, subtasks, import / export, and Todoist-style CSV import.

## URL Scheme

TaskIsland can be called from macOS Shortcuts or launchers:

```text
taskisland://add?title=tomorrow%2010:00%20weekly%20report%20%23work%20!high%20/30m
taskisland://focus
taskisland://complete
taskisland://show
```

## Project Layout

```text
Sources/TaskIslandCore      task model, storage, parsing, import / export
Sources/TaskIsland          macOS app, island, panels, shortcuts, integrations
Sources/TaskIslandChecks    lightweight validation target
Resources                   app icon
Scripts                     packaging and poster generation scripts
assets/posters              GitHub presentation posters
docs                        research and project notes
```

## Distribution Note

This build is not yet signed and notarized with Apple Developer ID. Before distributing to end users, sign the app / installer with Developer ID certificates and submit the package to Apple Notary Service.

## License

No open-source license has been declared yet. All rights are reserved unless a LICENSE file is added later.
