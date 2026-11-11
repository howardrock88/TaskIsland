# 出口合规填写说明

这份文件用于 App Store Connect 的 App Encryption / Export Compliance 问题。

## 当前代码侧结论

当前版本未发现以下能力：

- 自研加密算法
- 第三方加密库
- VPN、代理、隧道或网络安全产品能力
- 加密货币、钱包或密钥管理能力
- 密码管理器能力
- 自建服务器通信加密协议

`Info.plist` 已写入：

```text
ITSAppUsesNonExemptEncryption = false
```

## App Store Connect 填写方向

如果页面询问是否使用加密，按当前版本可选择“不使用非豁免加密”或同等含义选项。

如果页面询问是否需要上传加密文档，按当前版本通常不需要上传额外文档。

可备注：

```text
TaskIsland does not implement proprietary encryption, VPN, tunneling, cryptography, cryptocurrency, password management, or custom secure communication features. The app stores task data locally and does not communicate with a developer server in the current version.
```

## 官方参考

- Apple：Overview of export compliance
  https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/
- Apple：Determine and upload app encryption documentation
  https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/
- Apple：Export compliance documentation for encryption
  https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/

## 未来需要重填的情况

如果后续版本加入账号登录、云同步、HTTPS API、自建服务器、第三方 SDK、端到端加密、VPN、代理、钱包或密码管理功能，需要重新核对出口合规答案。
