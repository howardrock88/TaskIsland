# App Store 最终上传素材选择清单

Apple 当前规则：每个语言/显示尺寸至少 1 张截图、最多 10 张截图；每个语言/显示尺寸最多 3 条 App Preview。参考：

- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- App preview specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/

素材目录里可以保留备用图，但 App Store Connect 页面按本清单上传，避免超过数量上限。

## English (U.S.) 首发必传

### App Preview（1 条）

- `dist/appstore/assets/videos/en/taskisland-app-preview-en-1920x1080.mp4`

### Screenshots（5 张）

1. `dist/appstore/assets/screenshots/en-promo/01-islands-4k-2880x1800.jpg`
2. `dist/appstore/assets/screenshots/en-promo/02-quick-add-4k-2880x1800.jpg`
3. `dist/appstore/assets/screenshots/en-promo/03-task-panel-4k-2880x1800.jpg`
4. `dist/appstore/assets/screenshots/en-promo/04-settings-4k-2880x1800.jpg`
5. `dist/appstore/assets/screenshots/en-promo/05-brand-slogan-4k-2880x1800.jpg`

## 简体中文备用

### App Preview（1 条）

- `dist/appstore/assets/videos/zh-Hans/taskisland-app-preview-zh-Hans-1920x1080.mp4`

### 截图（10 张）

1. `dist/appstore/assets/screenshots/zh-Hans-promo/01-islands-4k-2880x1800.jpg`
2. `dist/appstore/assets/screenshots/zh-Hans-promo/02-quick-add-4k-2880x1800.jpg`
3. `dist/appstore/assets/screenshots/zh-Hans-promo/03-task-panel-4k-2880x1800.jpg`
4. `dist/appstore/assets/screenshots/zh-Hans-promo/04-settings-4k-2880x1800.jpg`
5. `dist/appstore/assets/screenshots/zh-Hans-promo/05-brand-slogan-4k-2880x1800.jpg`
6. `dist/appstore/assets/screenshots/zh-Hans/01-floating-island-1440x900.jpg`
7. `dist/appstore/assets/screenshots/zh-Hans/02-task-panel-1440x900.jpg`
8. `dist/appstore/assets/screenshots/zh-Hans/03-quick-add-1440x900.jpg`
9. `dist/appstore/assets/screenshots/zh-Hans/04-task-detail-1440x900.jpg`
10. `dist/appstore/assets/screenshots/zh-Hans/05-task-views-1440x900.jpg`

备用截图，不建议首轮上传，除非替换上面某张：

- `zh-Hans/06-settings-display-capsule-1440x900.jpg`
- `zh-Hans/07-settings-focus-priority-1440x900.jpg`
- `zh-Hans/08-settings-shortcuts-data-1440x900.jpg`

## 图标

如果 App Store Connect 要求手动上传 1024 图标：

- `dist/appstore/assets/icon/AppIcon-1024.png`
