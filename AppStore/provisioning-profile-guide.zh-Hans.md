# App Store Provisioning Profile 创建指南

当前只差这个文件就可以重新生成更正式的 Mac App Store 上传包。

## 你要拿到什么

最后需要下载一个 `.provisionprofile` 文件，并把它的本机路径填到：

```text
AppStore/submission.env
```

字段是：

```text
TASKISLAND_APPSTORE_PROVISIONING_PROFILE="/Users/yuxiao/Downloads/文件名.provisionprofile"
```

## 创建入口

打开：

https://developer.apple.com/account/resources/profiles/list

路径：

1. 左侧选择 `Profiles`
2. 点右上角或标题旁的 `+`
3. 进入创建 Profile 页面

## Profile 类型怎么选

选择 Distribution 分类下的 Mac App Store 相关选项。

页面文字可能显示为以下其中一种：

- `Mac App Store Connect`
- `Mac App Store`
- `App Store Connect`

不要选这些：

- `Mac Development`：这是开发调试用
- `Developer ID`：这是 App Store 以外直接分发用
- `Ad Hoc`：这不是 Mac App Store 正式提交路线

## App ID 怎么选

选择这个 App ID：

```text
com.yuxiao.TaskIsland
```

如果列表里看不到它，说明 Bundle ID 没有创建成功，或当前 Apple Developer 团队选错了。

当前团队应是：

```text
9PZ46S64H2
```

## 证书怎么选

选择应用签名证书，不是安装包签名证书：

```text
3rd Party Mac Developer Application: Xiao Yu (9PZ46S64H2)
```

你本机现在有两个同名应用签名证书。当前 `AppStore/submission.env` 使用的是这个 SHA-1 指纹：

```text
135BDFC94ED69E46F8EB625312F0553968045A73
```

如果 Apple Developer 页面显示多个同名证书，优先选择和这个指纹/创建日期对应的证书。脚本也已经加了校验：如果 profile 里选到的证书和本机签 App 的证书不一致，正式打包会停止。

不要选：

```text
3rd Party Mac Developer Installer: Xiao Yu (9PZ46S64H2)
```

Installer 证书只用于签 `.pkg`，不能放进 provisioning profile。

## Profile 名称

建议填：

```text
TaskIsland Mac App Store
```

## 下载后给我什么

下载完成后，把文件放在一个稳定位置，最好不要直接放在 Downloads 里长期使用。建议：

```text
/Users/yuxiao/Vibe Coding/TaskIsland/证书/TaskIsland_Mac_App_Store.provisionprofile
```

这个 `证书/` 目录已经被 `.gitignore` 忽略，不会误提交。

然后把这个完整路径发给我，我会继续做三件事：

1. 写入 `AppStore/submission.env`
2. 重新运行 App Store 自检
3. 重新生成带 `embedded.provisionprofile` 的上传包

如果你想自己一键完成，也可以运行：

```sh
Scripts/finalize-appstore-profile.sh "/完整路径/TaskIsland_Mac_App_Store.provisionprofile"
```

成功后的目标文件是：

```text
dist/appstore/TaskIsland-AppStore-0.1.7-b1.pkg
```

注意：`Scripts/package-appstore.sh` 会阻止在缺少 profile 的情况下生成正式上传包，避免误把未嵌入 profile 的测试包传到 Transporter。

## 自检时会看什么

我会确认：

- `.provisionprofile` 文件存在
- 文件可以被系统解析
- Profile 的 App ID 匹配 `com.yuxiao.TaskIsland`
- Profile 包含当前配置的 App 签名证书
- 打包后的 App 内有 `Contents/embedded.provisionprofile`
- `.pkg` 仍由 Mac Installer Distribution 证书签名
