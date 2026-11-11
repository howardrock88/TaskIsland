# 拿到 profile 后一键收尾

这份文件用于你从 Apple Developer 下载 App Store provisioning profile 之后，把本地上架包一次性收尾。

## 使用方式

下载 `.provisionprofile` 后运行：

```sh
Scripts/finalize-appstore-profile.sh "/完整路径/TaskIsland_Mac_App_Store.provisionprofile"
```

推荐先把文件放到：

```text
/Users/yuxiao/Vibe Coding/TaskIsland/证书/TaskIsland_Mac_App_Store.provisionprofile
```

也可以直接把 Downloads 里的文件路径传进去，脚本会复制到 `证书/` 目录。

## 脚本会自动做什么

1. 解析 provisioning profile。
2. 检查 App ID 是否匹配 `com.yuxiao.TaskIsland`。
3. 复制 profile 到 `证书/` 目录。
4. 写入 `AppStore/submission.env`。
5. 运行 App Store 自检。
6. 生成正式 `.pkg` 上传包。
7. 运行 `Scripts/verify-appstore-package.sh` 做最终上传包校验。
8. 重新生成 App Store 上传资料包。

## 成功后得到什么

正式上传包：

```text
dist/appstore/TaskIsland-AppStore-1.0-b1.pkg
```

完整上传资料包：

```text
dist/appstore/upload-kit/TaskIsland-AppStore-1.0-b1-upload-kit.zip
```

其中 `.pkg` 用于 Transporter；`.zip` 是给你自己上传商品页素材、文案和留档用的完整资料包。
