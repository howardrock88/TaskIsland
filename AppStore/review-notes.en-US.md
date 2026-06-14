# App Review Notes Draft

TaskIsland is a local-first macOS task manager. Most interactions happen through the floating island at the top of the screen and the task panel opened from it.

## Suggested Review Flow

1. Launch the app and click the floating island at the top of the screen to open the task panel.
2. Add a task and set priority, reminder time, due date, and focus minutes.
3. Click the focus button on a task row to start a focus countdown.
4. Test the pause and stop controls in the focus island.
5. Set a short focus duration if needed; when the countdown finishes, the focus island remains visible with a sweep highlight, pulsing border, and sound reminder until the user clicks Done.
6. In settings, switch Interface Language to Chinese or English and confirm that the main UI, floating island, and menu bar text update. User task content is not translated.
7. Adjust island opacity, background color, text color, and priority colors in settings.
8. To test Apple Reminders import/export, allow Reminders access in the system permission prompt and use the Apple Reminders import/export entry in settings.

## Permission Notes

- Apple Reminders access is used only for user-initiated import/export.
- Notification permission is used only for local task reminders.
- File access is used only for user-selected JSON, Markdown, or CSV import/export.

## Data Notes

- Task data is stored locally by default.
- No account login is required.
- The current version does not include cloud sync, advertising, or third-party analytics.

## Special Notes

- The `taskisland://` URL scheme is used for macOS Shortcuts or launcher workflows, including quick add, focus, complete, and show task panel actions.
- The global shortcut only opens the Quick Add panel and does not record keyboard input.
- The Mac App Store upload package does not install a LaunchAgent. The direct-distribution `.pkg` login-start behavior is not used for the App Store channel.

## Demo Data

No test account is required. Reviewers can create tasks directly in the app.
