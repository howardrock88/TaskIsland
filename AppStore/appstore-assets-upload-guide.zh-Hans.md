# App Store 素材上传指南

这份文件用于 App Store Connect 的截图和图标上传。

## 素材位置

```text
dist/appstore/assets/
```

如果 `dist/app-store-promo-assets/` 里重新放入了新的中英文视频和图片，运行：

```sh
Scripts/prepare-appstore-assets.sh
```

这个脚本会先生成基础真实界面截图和图标，再自动调用：

```sh
Scripts/prepare-appstore-promo-assets.sh
```

把 16:9 的宣传关键帧转换成 16:10 的 Mac App Store 截图，并把中英文视频复制到统一上传目录。

当前已有三类素材：

- 8 张简体中文真实界面截图，尺寸 `1440x900`
- 5 张简体中文宣传关键帧截图，尺寸 `2880x1800`
- 5 张英文宣传关键帧截图，尺寸 `2880x1800`
- 1 条简体中文 App Preview 视频，尺寸 `1920x1080`，约 20 秒
- 1 条英文 App Preview 视频，尺寸 `1920x1080`，约 20 秒
- 1 张图标预览，尺寸 `1024x1024`

上传资料包里还会自动生成一份素材清单：

```text
metadata/asset-manifest.md
```

实际上传时请优先按最终选择清单操作，避免超过 Apple 的截图数量上限：

```text
AppStore/appstore-upload-selection.zh-Hans.md
```

## 推荐上传方案

如果 App Store Connect 允许你上传 App Preview 视频，建议每个语言先上传视频，再上传截图。每个语言/显示尺寸截图最多 10 张，App Preview 最多 3 条。

### 简体中文

App Preview：

```text
dist/appstore/assets/videos/zh-Hans/taskisland-app-preview-zh-Hans-1920x1080.mp4
```

截图建议优先使用新宣传关键帧版，因为画面更适合商品页首屏：

1. `dist/appstore/assets/screenshots/zh-Hans-promo/01-islands-4k-2880x1800.jpg`
   - 展示数字岛、专注岛和行动岛。
2. `dist/appstore/assets/screenshots/zh-Hans-promo/02-quick-add-4k-2880x1800.jpg`
   - 展示快速新增任务。
3. `dist/appstore/assets/screenshots/zh-Hans-promo/03-task-panel-4k-2880x1800.jpg`
   - 展示任务面板和优先级工作流。
4. `dist/appstore/assets/screenshots/zh-Hans-promo/04-settings-4k-2880x1800.jpg`
   - 展示设置和个性化。
5. `dist/appstore/assets/screenshots/zh-Hans-promo/05-brand-slogan-4k-2880x1800.jpg`
   - 展示 App 图标、名称和标语。

如果 App Store Connect 希望看到更多真实界面细节，可以继续补充原始真实截图，但简体中文首轮总数不要超过 10 张：

6. `dist/appstore/assets/screenshots/zh-Hans/01-floating-island-1440x900.jpg`
   - 展示任务岛核心形态：悬浮岛、任务数量和桌面常驻感。
7. `dist/appstore/assets/screenshots/zh-Hans/02-task-panel-1440x900.jpg`
   - 展示任务面板和任务列表，是用户理解产品的主图。
8. `dist/appstore/assets/screenshots/zh-Hans/03-quick-add-1440x900.jpg`
   - 展示快速新增任务流程。
9. `dist/appstore/assets/screenshots/zh-Hans/04-task-detail-1440x900.jpg`
   - 展示任务详情、提醒、截止时间和专注设置。
10. `dist/appstore/assets/screenshots/zh-Hans/05-task-views-1440x900.jpg`
   - 展示今天、高优、即将、标签、项目等视图。
以下 3 张作为备用图，不建议首轮上传，除非替换上面某张：

- `dist/appstore/assets/screenshots/zh-Hans/06-settings-display-capsule-1440x900.jpg`
  - 展示悬浮岛外观设置。
- `dist/appstore/assets/screenshots/zh-Hans/07-settings-focus-priority-1440x900.jpg`
  - 展示专注和优先级颜色设置。
- `dist/appstore/assets/screenshots/zh-Hans/08-settings-shortcuts-data-1440x900.jpg`
  - 展示快捷操作、导入导出和提醒事项集成。

### English (U.S.)

App Preview：

```text
dist/appstore/assets/videos/en/taskisland-app-preview-en-1920x1080.mp4
```

截图上传顺序：

1. `dist/appstore/assets/screenshots/en-promo/01-islands-4k-2880x1800.jpg`
2. `dist/appstore/assets/screenshots/en-promo/02-quick-add-4k-2880x1800.jpg`
3. `dist/appstore/assets/screenshots/en-promo/03-task-panel-4k-2880x1800.jpg`
4. `dist/appstore/assets/screenshots/en-promo/04-settings-4k-2880x1800.jpg`
5. `dist/appstore/assets/screenshots/en-promo/05-brand-slogan-4k-2880x1800.jpg`

## 图标

如果 App Store Connect 要求上传 1024 图标，使用：

```text
dist/appstore/assets/icon/AppIcon-1024.png
```

如果 App Store Connect 自动从构建包读取图标，则不需要额外上传。

## 注意事项

- 新宣传图原始文件在 `dist/app-store-promo-assets/images/`，是 `3840x2160` 的 16:9 关键帧。
- App Store 可上传版已经转换到 `dist/appstore/assets/screenshots/`，是 `2880x1800` 的 16:10 JPEG。
- 两条视频原始文件在 `dist/app-store-promo-assets/videos/`，上传副本已经放到 `dist/appstore/assets/videos/`。
- `Scripts/check-appstore-readiness.sh` 会检查截图比例，也会在本机有 `ffprobe` 时检查视频尺寸和时长。
- 中国大陆地区暂不开放时，截图里不要出现备案号、官网备案页等未完成内容。
- 截图应展示真实 App UI，不建议使用过度营销文字覆盖。
