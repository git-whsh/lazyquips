# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | 简体中文 | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips 是一款原生 macOS 菜单栏 App，用于管理本地短语并快速复制需要的内容。

## 范围

- macOS 14.0+
- 仅支持 Apple Silicon (`arm64`)
- 原生 SwiftUI App，并包含 AppKit 集成点
- 不含第三方代码依赖
- 不使用由开发者运营或自托管的网络服务与 backend，也不提供账号、AI、云同步、analytics、telemetry、自动粘贴或输入监控。Mac App Store 购买、恢复购买与权益检查由 Apple 通过 StoreKit 和 App Store 处理。

## 分发

`v1.0` 是历史 `GPL-3.0-only` 源码快照；既有源码继续受该历史许可证约束，已授予的权利不撤回。从 `v1.1` 起，Lazy Quips 正式版本闭源，仅通过 Mac App Store 或 TestFlight 分发，不再发布 `v1.1+` 源码快照或 GitHub DMG。

[从 Mac App Store 下载 Lazy Quips](https://apps.apple.com/app/id6783259528)

仅支持 Apple Silicon，macOS 14.0+。此公开 repository 只保留历史 `v1.0` 源码，供检查与 forks 使用；不提供官方 GitHub installer、DMG 或 checksum 下载。

构建历史 `v1.0` 源码仅供检查与 fork 开发；本地 source build 不是 Lazy Quips 正式版本。

## 隐私边界

Lazy Quips 不会读取当前输入框、不会监控输入内容、不会读取已有剪贴板内容，也不会上传剪贴板数据。

短语与剪贴板数据不会上传；Apple 通过 StoreKit 和 App Store 处理购买、恢复购买与权益检查，并向 App 返回购买结果与权益信息。

只有在用户明确选择短语后，App 才会写入系统 pasteboard。只有在用户点击反馈联系方式，且 macOS 无法打开外部联系 URL 时，App 才可能写入 Daniel 的固定联系信息。

## 历史源代码构建

本节仅适用于历史公开 `v1.0` 源码与 forks。`v1.1+` 正式版本不公开源码；获准的正式版本只通过 Mac App Store 或 TestFlight 分发。

如需在本地构建或测试，请在 macOS 14.0+ 使用 Xcode。历史公开构建与测试命令见 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)。这些命令会刻意停用 code signing，不会生成官方 release build。

## 许可证

已经公开的 `v1.0` 源码继续以 `GPL-3.0-only` 授权，已授予的权利不撤回。请见历史公开 [LICENSE](https://github.com/git-whsh/lazyquips/blob/main/LICENSE)。

`v1.1+` 正式版本闭源，通过 Mac App Store 使用 Apple Standard EULA 分发，或通过 TestFlight 测试；它们不是新的 GPL 源码版本。

第三方品牌资产并非由 Lazy Quips 维护者以 GPL 授权。请见历史公开 [NOTICE](https://github.com/git-whsh/lazyquips/blob/main/NOTICE)。

## 官方构建与 Forks

公开的 `v1.0` 源代码不代表授权使用 Lazy Quips 商标、official bundle identifiers、signing identities，或 official publishing channels。

历史公开 `v1.0` 快照使用 placeholder bundle identifiers，例如 `dev.lazyquips.public`。Official Lazy Quips distribution 保留 official bundle identifiers、Apple signing identities 与 App Store/TestFlight publishing rights。请见历史公开 [TRADEMARKS.md](https://github.com/git-whsh/lazyquips/blob/main/TRADEMARKS.md)。

Forks 可以依 GPL 研究、修改、构建与分发历史 `v1.0` 代码。公开分发修改版 binaries 的 fork，应使用自己的 app name、bundle identifiers、icons or branding、signing identity、update channel 与 support channel，让用户能够分辨它与 official builds 的不同。Forks 不得暗示自己是 official Lazy Quips releases。

## Release Boundary

既有公开 repository 是历史 `v1.0` GPL 源码渠道，不提供官方安装资产。`v1.1+` 正式版本只使用 Mac App Store 或 TestFlight；该渠道不发布新的源码快照、Developer ID build 或 GitHub DMG。修改公开 repository、网站或既有 Release 资产，须另行授权远端发布任务。

## 贡献

欢迎为历史公开 `v1.0` 快照提交 Pull requests，项目会以 best-effort 方式处理。Public Issues 与 Discussions 不作为 support intake 渠道。没有 service-level agreement，也没有合并变更的义务。请见历史公开 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)。
