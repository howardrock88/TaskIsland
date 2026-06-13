# App Store 付费协议、税务和银行信息指南

任务岛计划做一次性付费 App，所以 App Store Connect 必须完成付费协议、税务和银行信息。这个部分涉及真实身份、收款账户和法律协议，只能由你本人操作。

## 入口

打开：

https://appstoreconnect.apple.com/agreements

或在 App Store Connect 顶部/侧边进入：

```text
Business -> Agreements, Tax, and Banking
```

## 需要完成什么

至少需要完成：

```text
Paid Apps Agreement
Tax Forms
Bank Accounts
Contacts
```

如果页面里还有待处理协议，也要先处理到没有阻塞状态。

## Paid Apps Agreement

操作：

1. 找到 `Paid Apps` 或 `Paid Applications`
2. 点击 `View and Agree to Terms`
3. 阅读并同意协议
4. 按页面要求补全联系人、税务和银行信息

注意：

- 这是上架付费 App 的前置条件。
- 没完成前，即使 App 可以创建，也可能无法设置付费价格或正式销售。

## 银行账户

需要准备：

```text
收款人姓名
银行名称
银行账号
银行所在国家/地区
SWIFT/BIC 或页面要求的银行识别信息
开户地址/银行地址，按页面要求填写
```

建议使用你本人 Apple Developer 主体能对应的收款账户，避免姓名/主体不一致引起审核或付款问题。

## 税务信息

页面会根据你的开发者账号主体和国家/地区展示不同表格。个人开发者通常需要按真实情况填写个人税务信息。

常见注意点：

- 按真实身份和税务居民身份填写。
- 不确定的税务条款建议咨询专业人士。
- 税务信息会影响 Apple 代扣代缴和结算。

## 联系人

通常至少需要：

```text
Senior Management
Financial
Technical
Legal
Marketing
```

个人开发者可以按页面允许的方式使用本人信息。

## 完成后的状态

完成后，Agreements 页面应不再显示 Paid Apps Agreement 的待处理阻塞项。然后回到 App 的：

```text
Pricing and Availability
```

选择一次性付费价格档位，并设置销售国家/地区。

## 和当前上架策略的关系

当前建议：

```text
价格：一次性付费，低价档启动
地区：中国大陆以外先上架
中国大陆：等 ICP/App 备案完成后再开放
```

价格档位需要你最终确认。
