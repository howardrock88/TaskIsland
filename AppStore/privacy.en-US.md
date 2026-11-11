# App Privacy Preparation Draft

This file prepares the English App Store privacy notes. Before final submission, confirm that the submitted build does not include analytics, crash reporting, cloud sync, advertising SDKs, accounts, or remote services.

## Current Product Assessment

TaskIsland is currently local-first:

- No account login is required.
- Task data is stored locally on the user's Mac by default.
- File import/export happens only after the user selects files.
- Apple Reminders access is requested only when the user imports from or exports to Apple Reminders.
- Local notifications are used for task reminders.
- The current build does not include ads, third-party analytics, remote cloud sync, or built-in payments.

If the submitted build still matches this behavior, the App Privacy questionnaire can be prepared in the direction of "Data Not Collected." In Apple's terminology, local storage on the user's device is not the same as data collected by the developer.

## Confirm Before Submission

- No third-party analytics service is included.
- No crash log collection service is included.
- Tasks, tags, reminder times, imported files, and Apple Reminders content are not uploaded to developer servers.
- No advertising SDK is included.
- No account system is included.
- No cloud sync is included.
- The app does not collect device identifiers, precise location, contacts, health, financial, or browsing data.

If future versions add cloud sync, accounts, analytics, crash reporting, or in-app purchases, the privacy answers must be updated.

## Permission Usage

### Apple Reminders

Purpose: Allows users to explicitly import unfinished Apple Reminders into TaskIsland or export TaskIsland tasks to Apple Reminders.

Not used for: Uploading reminders content or reading reminders without permission.

### Local Notifications

Purpose: Shows local system notifications when a user-configured task reminder time arrives.

Not used for: Sending notification content to developer servers.

### File Access

Purpose: Lets users explicitly import or export JSON, Markdown, or CSV files.

Not used for: Scanning the user's disk or accessing files that the user did not select.

