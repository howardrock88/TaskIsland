# TaskIsland

TaskIsland is a local-first floating task app for macOS. It keeps important tasks, reminders, and focus timing at the top of your desktop through a lightweight liquid-glass island, so you can capture, review, and move tasks forward without switching apps.

![TaskIsland 16:9 poster](assets/posters/taskisland-poster-16x9.png)

[中文 README](README.md)

## Highlights

- **Three island states**: Number Island shows high / medium / low priority counts; Focus Island shows the active task, countdown, pause, and stop; Action Island previews up to 3 important tasks with quick add, pin, complete, and delete controls.
- **Current task and focus**: mark any task as current, then use it from the focus card and menu bar. Starting focus moves the island into medium mode with pause, resume, and stop controls.
- **Quick add**: press the default `Control + Option + N` shortcut and type natural language such as `tomorrow 10:00 weekly report #work !high /30m`.
- **Task panel views**: All, Today, Suggestions, High Priority, Upcoming, No Date, Tags, Projects, Completed, and Review.
- **Rich task details**: notes, arbitrary due date, arbitrary reminder time, repeat rule, project, tags, estimated focus minutes, postpone, and “set as current”.
- **Custom appearance**: dark glass mode, island transparency, background color, text color, priority colors, top position, and drag placement.
- **Chinese / English UI**: switch between Chinese and English in Settings. The main UI, islands, quick add, app menu, notifications, and shortcut settings update immediately.
- **Local-first data**: SwiftData storage, no account required; JSON, Markdown, and CSV import / export.
- **macOS integration**: Apple Reminders import / export, local notifications, `taskisland://` URL Scheme, and installer login-start configuration.
- **Installable builds**: scripts generate `.app`, `.pkg`, and `.dmg` packages for `/Applications/任务岛.app`.

## Release Notes

### 0.1.14 - 2026-06-14

- Adjusted the main task panel background by removing the overly bright top-left gradient and radial highlight that could reduce icon and button readability.
- The main task panel now uses a more even same-color glass tint while still following the user's background color setting.

### 0.1.13 - 2026-06-14

- Fixed custom background colors applying to the three floating island states but not to the main task panel.
- The main task panel, section glass tint, and panel stroke now follow the same background color setting while preserving glass highlights and readability.

### 0.1.12 - 2026-06-14

- Fixed the main task panel corners not being fully clipped, preventing background color from showing between the rounded panel and the rectangular window bounds.
- The panel host layer now clips to the continuous rounded corner shape, and the glass background, highlights, and stroke are constrained to the same rounded region.

### 0.1.11 - 2026-06-14

- Adjusted the app icon scale inside the 1024×1024 canvas: the visible area is now 860×860 with 82px margins on each side for a more balanced Dock and Applications-folder appearance.

### 0.1.10 - 2026-06-14

- Fixed cases where a locally installed build could still show the old Dock icon; the app now applies the bundled latest icon when it starts.

### 0.1.9 - 2026-06-14

- Aligned the direct-distribution app icon with the latest App Store icon so the Dock, Applications folder, and installers use the same visual.
- Regenerated the installer icon source to avoid installed builds showing an older icon or cached icon variant.

### 0.1.8 - 2026-06-14

- Replaced the app icon with a cleaner glass tile and Number Island signal-dot style for better recognition in the Dock, small sizes, and App Store assets.
- Updated the icon source to a standard 1024×1024 image, which is now used for `.app`, `.dmg`, `.pkg`, and App Store asset generation.

### 0.1.7 - 2026-06-13

- Added an interface language setting with Chinese and English options; changes apply immediately.
- Localized the floating island, task panel, task rows, task details, quick add, menu bar, app menu, reminder notifications, and shortcut settings.
- Dates, focus duration, priorities, repeat rules, postpone options, and import / export messages now follow the selected language.
- Task content itself is not translated, so existing user data stays untouched.

### 0.1.6 - 2026-06-11

- Added a focus-completion attention state: when a focus timer finishes naturally, Focus Island stays visible until the user confirms with Done.
- Added a stronger focus-completion animation with full-width sweep light, flowing border highlights, and a pulsing heartbeat-style outline.
- Strengthened the completion sound to 5 notification chimes and fixed rapid replay cases where only 1-2 sounds were audible.
- Fixed a focus-completion transition where Focus Island could briefly shrink back to Number Island, leaving only the sound cue visible.
- Fixed previously focused tasks starting as immediately complete; restarting after Stop now begins a fresh round, while paused focus can still resume the current round.
- Simplified the completion interaction by removing the duplicate `×` button. The Done button now directly dismisses Focus Island without opening the task panel.

### 0.1.5 - 2026-06-07

- Fixed the distribution packaging flow: `.app` bundles are now signed and strictly verified after packaging, and `.dmg` / `.pkg` scripts no longer overwrite Developer ID signatures with ad-hoc signatures.
- Added Developer ID signing and Apple Notary Service environment variables for building Gatekeeper-ready public releases.
- Packaging now copies release binaries from explicit architecture directories and supports `TASKISLAND_ARCHS`, `TASKISLAND_MIN_MACOS`, and `TASKISLAND_PACKAGE_SUFFIX` for separate architecture packages.
- Fixed the `.pkg` post-install launch command to open `/Applications/任务岛.app` directly.

### 0.1.4 - 2026-06-04

- Refined the visual system while keeping the existing Number Island, Focus Island, and Action Island structure.
- Improved island glass highlights, visible edges, and task-row hierarchy, and removed the decorative highlight that could read as a stray diagonal line.
- Unified glass material, strokes, and shadow details across the task panel, settings panel, task rows, and buttons.
- Added the local rollback marker `visual-baseline-20260604-152102` for returning to the pre-refinement version.

### 0.1.3 - 2026-06-03

- Changed the completed-task section to stay collapsed by default, showing only the completed count and an expand control.
- Completed task rows now appear in place only after clicking Expand, keeping the normal task panel focused.
- Completed-task search results expand automatically, while the dedicated Completed view still shows the list directly.

### 0.1.2 - 2026-06-03

- Fixed the task panel empty state when only completed tasks remain.
- The All view now shows completed tasks after incomplete tasks, and search also matches completed tasks.
- Added a “View” action to the completed-task footer in other task views so users can jump directly to the Completed view.

### 0.1.1 - 2026-06-02

- Added a shared version file used by the `.app`, `.pkg`, and `.dmg` packaging scripts.
- Unified the three island state names across README copy and posters: Number Island, Focus Island, and Action Island.
- Switched README interface images to actual UI renders and removed subtask claims from public documentation.

### 0.1.0 - 2026-06-01

- First usable local build with the floating island, task panel, quick add, focus timer, reminders, import / export, and macOS packaging scripts.

## Versioning Policy

Every user-visible change to features, UI, documentation previews, or installers should update:

- The root `VERSION` file.
- The release notes in README.
- Fresh installer builds, with matching `.dmg` and `.pkg` files uploaded to GitHub Releases.

## Interface Tour

### Floating Island

![Floating island](assets/screenshots/01-floating-island.png)

TaskIsland has three desktop states: Number Island for high / medium / low priority counts, Focus Island for active focus or reminder tasks with countdown controls, and Action Island for hover or pinned task actions with up to 3 important tasks.

### Task Panel

![Task panel](assets/screenshots/02-task-panel.png)

Clicking the island opens the full task panel. It starts with all incomplete tasks and keeps current focus, task lists, view switching, search, and panel pinning in one place.

### Quick Add

![Quick add](assets/screenshots/03-quick-add.png)

Quick add supports natural-language input for dates, times, priorities, tags, and estimated focus minutes.

### Task Details

![Task details](assets/screenshots/04-task-detail.png)

Each task supports title editing, notes, due time, reminder time, repeat rule, project, tags, postponing, “set as current”, and per-task focus minutes.

### Task Views

![Task views](assets/screenshots/05-task-views.png)

Tasks can be viewed by All, Today, Suggestions, High Priority, Upcoming, No Date, Tags, Projects, Completed, and Review.

### Settings: Display and Focus

![Display and island settings](assets/screenshots/06-settings-display-capsule.png)

Settings cover the floating island toggle, menu bar title, dark mode, default focus duration, and priority colors.

### Settings: Priorities and Island

![Focus and priority settings](assets/screenshots/07-settings-focus-priority.png)

Configure high / medium / low priority colors, island transparency, background color, text color, and top placement.

### Settings: Shortcuts and Data

![Shortcut and data settings](assets/screenshots/08-settings-shortcuts-data.png)

Customize quick-add shortcuts, choose export formats, refresh, import, export, import / export Apple Reminders, hide, and quit.

## Requirements

- Apple Silicon: macOS 15 or later
- Intel: macOS 15 or later
- Xcode / Swift 6.2 toolchain

## Run

```sh
swift run TaskIsland
```

After launch:

- Click the floating island to open the task panel.
- Hover the island to preview tasks.
- Press the default `Control + Option + N` shortcut to open quick add. The shortcut can be customized with common modifier and letter / space combinations.
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
open dist/github/TaskIsland-0.1.14.pkg
```

Build the `.dmg` image:

```sh
chmod +x Scripts/package-dmg.sh
Scripts/package-dmg.sh
open dist/github/TaskIsland-0.1.14.dmg
```

The `.pkg` installer places `任务岛.app` in `/Applications`, registers it with LaunchServices / Spotlight, and starts the app after installation.

Local builds use an ad-hoc app signature by default, and `.pkg` installers are unsigned by default. That is suitable for development-machine testing only. Public distribution needs Developer ID signing and notarization, for example:

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

To build a separate Intel package:

```sh
TASKISLAND_ARCHS="x86_64" TASKISLAND_MIN_MACOS="15.0" TASKISLAND_PACKAGE_SUFFIX="-intel" Scripts/package-dmg.sh
TASKISLAND_ARCHS="x86_64" TASKISLAND_MIN_MACOS="15.0" TASKISLAND_PACKAGE_SUFFIX="-intel" Scripts/package-pkg.sh
```

The Mac App Store channel is kept separate from GitHub Release packages. App Store-specific files, submission notes, the local configuration template, and upload-package output are documented in [AppStore/README.md](AppStore/README.md).

## Checks

```sh
swift run TaskIslandChecks
```

The check target covers task creation, completion, deletion, recurrence, priority, date parsing, focus timing, import / export, and Todoist-style CSV import.

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
Scripts                     packaging and README image generation scripts
assets/posters              GitHub presentation posters
assets/screenshots          GitHub interface screenshots
docs                        research and project notes
AppStore                    Mac App Store channel configuration and submission notes
```

## Distribution Note

Local builds are not signed and notarized with Apple Developer ID, so Gatekeeper will block downloaded copies on other machines. Before distributing to end users, sign the app / installer with Developer ID certificates and submit the package to Apple Notary Service. The Mac App Store channel uses the separate `AppStore/` configuration and `dist/appstore/` output directory.

## License

No open-source license has been declared yet. All rights are reserved unless a LICENSE file is added later.
