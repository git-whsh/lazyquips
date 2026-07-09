# Lazy Quips

[English](README.md) | 繁體中文 | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips 是一款原生 macOS 選單列 App，用於管理本機短語並快速複製需要的內容。

## 範圍

- macOS 14.0+
- 僅支援 Apple Silicon (`arm64`)
- 原生 SwiftUI App，並包含 AppKit 整合點
- 不含第三方程式碼依賴
- 不使用網路、帳號、AI、雲端同步、自動貼上或輸入監控

## 下載

[下載 macOS 版 Lazy Quips](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg)

僅支援 Apple Silicon，macOS 14.0+。這是 official GitHub Releases 使用的穩定 DMG URL。如果回傳 404，表示目前沒有可用的 official DMG release。

從 DMG 安裝：

1. 開啟 `LazyQuips-arm64.dmg`。
2. 將 `Lazy Quips.app` 拖到 DMG 視窗中的 `Applications` 捷徑。
3. 退出 DMG。
4. 從 Applications 資料夾啟動 Lazy Quips。

DMG 只有在由 repository owner 附加到已發布的 GitHub Release，並通過 release checklist：Developer ID signing、Apple notarization、stapling，以及下載資產的 Gatekeeper verification 後，才是 official DMG。

請查看 [latest GitHub Release](https://github.com/git-whsh/lazyquips/releases/latest) 取得 release notes 與 checksums。固定的 checksum asset 名稱是 [`LazyQuips-arm64.dmg.sha256`](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg.sha256)。

從原始碼建置僅供檢視與開發。本機 source build 不等同於官方簽署的 DMG。

## 隱私邊界

Lazy Quips 不會讀取目前輸入欄位、不會監控輸入內容、不會讀取既有剪貼簿內容，也不會上傳剪貼簿資料。

只有在使用者明確選擇短語後，App 才會寫入系統 pasteboard。只有在使用者點擊回饋聯絡方式，且 macOS 無法開啟外部聯絡 URL 時，App 才可能寫入 Daniel 的固定聯絡資訊。

## 建置

需要 macOS 14.0+ 與 Xcode。

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" build
```

## 測試

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" test
```

公開的 build 與 test 命令會刻意停用 code signing。它們只驗證原始碼編譯與一般測試；不會驗證 sandbox runtime behavior、login item registration、Developer ID signing、notarization、App Store export、TestFlight upload，或任何 official release process。

## 授權

原始碼以 `GPL-3.0-only` 授權。請見 [LICENSE](LICENSE)。

第三方品牌資產並非由 Lazy Quips 維護者以 GPL 授權。請見 [NOTICE](NOTICE)。

## 官方建置與 Forks

公開原始碼不代表授權使用 Lazy Quips 商標、official bundle identifiers、signing identities，或 official publishing channels。

公開原始碼快照使用 placeholder bundle identifiers，例如 `dev.lazyquips.public`。Official Lazy Quips distribution 保留 official bundle identifiers、Apple signing identities、App Store/TestFlight distribution、Developer ID signing、notarization，以及 GitHub Release publishing rights。請見 [TRADEMARKS.md](TRADEMARKS.md)。

Forks 可以依 GPL 研究、修改、建置與散布程式碼。公開散布修改版 binaries 的 fork，應使用自己的 app name、bundle identifiers、icons or branding、signing identity、update channel 與 support channel，讓使用者能夠分辨它與 official builds 的不同。Forks 不得暗示自己是 official Lazy Quips releases。

## Release Boundary

此公開 repository 用於 source review、本機開發與輕量協作。Official GitHub Release、App Store、TestFlight、Developer ID、notarization 與 DMG release processes 使用私有 signing 與 release configuration，這些設定刻意不包含在此 repository 中。

Official GitHub Release assets 使用穩定的公開檔名：`LazyQuips-arm64.dmg` 與 `LazyQuips-arm64.dmg.sha256`。

如果 official binaries 同時透過 GitHub Releases 與 Apple platforms 提供，GitHub source 與 release artifacts 仍是面向 GPL 的公開散布通道，而 Apple platform builds 則是由 project owner 維護的便利通道。

## 貢獻

歡迎提交 Pull requests，專案會以 best-effort 方式處理。Public Issues 與 Discussions 不作為 support intake 管道。沒有 service-level agreement，也沒有合併變更的義務。請見 [CONTRIBUTING.md](CONTRIBUTING.md)。
