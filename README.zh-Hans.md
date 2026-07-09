# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | 简体中文 | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips 是一款原生 macOS 菜单栏 App，用于管理本地短语并快速复制需要的内容。

## 范围

- macOS 14.0+
- 仅支持 Apple Silicon (`arm64`)
- 原生 SwiftUI App，并包含 AppKit 集成点
- 不含第三方代码依赖
- 不使用网络、账号、AI、云同步、自动粘贴或输入监控

## 下载

[下载 macOS 版 Lazy Quips](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg)

仅支持 Apple Silicon，macOS 14.0+。这是 official GitHub Releases 使用的稳定 DMG URL。如果返回 404，表示目前没有可用的 official DMG release。

从 DMG 安装：

1. 打开 `LazyQuips-arm64.dmg`。
2. 将 `Lazy Quips.app` 拖到 DMG 窗口中的 `Applications` 快捷方式。
3. 推出 DMG。
4. 从 Applications 文件夹启动 Lazy Quips。

DMG 只有在由 repository owner 附加到已发布的 GitHub Release，并通过 release checklist：Developer ID signing、Apple notarization、stapling，以及下载资产的 Gatekeeper verification 后，才是 official DMG。

请查看 [latest GitHub Release](https://github.com/git-whsh/lazyquips/releases/latest) 获取 release notes 与 checksums。固定的 checksum asset 名称是 [`LazyQuips-arm64.dmg.sha256`](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg.sha256)。

从源代码构建仅供检查与开发。本地 source build 不等同于官方签名的 DMG。

## 隐私边界

Lazy Quips 不会读取当前输入框、不会监控输入内容、不会读取已有剪贴板内容，也不会上传剪贴板数据。

只有在用户明确选择短语后，App 才会写入系统 pasteboard。只有在用户点击反馈联系方式，且 macOS 无法打开外部联系 URL 时，App 才可能写入 Daniel 的固定联系信息。

## 源代码构建

本节仅供审阅源代码与 fork 开发使用。普通用户只需从“下载”部分安装官方 DMG。

如需在本地构建或测试，请在 macOS 14.0+ 使用 Xcode。详细的未签名构建与测试命令见 [CONTRIBUTING.md](CONTRIBUTING.md)。这些命令会刻意停用 code signing，不会生成官方 release build。

## 许可证

源代码以 `GPL-3.0-only` 授权。请见 [LICENSE](LICENSE)。

第三方品牌资产并非由 Lazy Quips 维护者以 GPL 授权。请见 [NOTICE](NOTICE)。

## 官方构建与 Forks

公开源代码不代表授权使用 Lazy Quips 商标、official bundle identifiers、signing identities，或 official publishing channels。

公开源代码快照使用 placeholder bundle identifiers，例如 `dev.lazyquips.public`。Official Lazy Quips distribution 保留 official bundle identifiers、Apple signing identities、App Store/TestFlight distribution、Developer ID signing、notarization，以及 GitHub Release publishing rights。请见 [TRADEMARKS.md](TRADEMARKS.md)。

Forks 可以依 GPL 研究、修改、构建与分发代码。公开分发修改版 binaries 的 fork，应使用自己的 app name、bundle identifiers、icons or branding、signing identity、update channel 与 support channel，让用户能够分辨它与 official builds 的不同。Forks 不得暗示自己是 official Lazy Quips releases。

## Release Boundary

此公开 repository 用于 source review、本地开发与轻量协作。Official GitHub Release、App Store、TestFlight、Developer ID、notarization 与 DMG release processes 使用私有 signing 与 release configuration，这些配置刻意不包含在此 repository 中。

Official GitHub Release assets 使用稳定的公开文件名：`LazyQuips-arm64.dmg` 与 `LazyQuips-arm64.dmg.sha256`。

如果 official binaries 同时通过 GitHub Releases 与 Apple platforms 提供，GitHub source 与 release artifacts 仍是面向 GPL 的公开分发渠道，而 Apple platform builds 则是由 project owner 维护的便利渠道。

## 贡献

欢迎提交 Pull requests，项目会以 best-effort 方式处理。Public Issues 与 Discussions 不作为 support intake 渠道。没有 service-level agreement，也没有合并变更的义务。请见 [CONTRIBUTING.md](CONTRIBUTING.md)。
