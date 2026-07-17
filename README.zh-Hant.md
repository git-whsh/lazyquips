# Lazy Quips

[English](README.md) | 繁體中文 | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips 是一款原生 macOS 選單列 App，用於管理本機常用語或快捷用語，並快速複製需要的內容。

## 範圍

- macOS 14.0+
- 僅支援 Apple Silicon (`arm64`)
- 原生 SwiftUI App，並包含 AppKit 整合點
- 不含第三方程式碼依賴
- 不使用由開發者營運或自行託管的網路服務與 backend，也不提供帳號、AI、雲端同步、analytics、telemetry、自動貼上或輸入監控。Mac App Store 購買、回復購買與權益檢查由 Apple 透過 StoreKit 和 App Store 處理。

## 散布

`v1.0` 是歷史 `GPL-3.0-only` 原始碼快照；既有原始碼繼續受該歷史授權約束，已授予的權利不會撤回。從 `v1.1` 起，Lazy Quips 正式版本為閉源，僅透過 Mac App Store 或 TestFlight 散布，不再發布 `v1.1+` 原始碼快照或 GitHub DMG。

[從 Mac App Store 下載 Lazy Quips](https://apps.apple.com/app/id6783259528)

僅支援 Apple Silicon，macOS 14.0+。此公開 repository 只保留歷史 `v1.0` 原始碼，供檢視與 forks 使用；不提供官方 GitHub installer、DMG 或 checksum 下載。

建置歷史 `v1.0` 原始碼僅供檢視與 fork 開發；本機 source build 不是 Lazy Quips 正式版本。

## 隱私邊界

Lazy Quips 不會讀取目前輸入欄位、不會監控輸入內容、不會讀取既有剪貼簿內容，也不會上傳剪貼簿資料。

常用語或快捷用語與剪貼簿資料不會上傳；Apple 透過 StoreKit 和 App Store 處理購買、回復購買與權益檢查，並向 App 回傳購買結果與權益資訊。

只有在使用者明確選擇常用語或快捷用語後，App 才會寫入系統 pasteboard。只有在使用者點擊回饋聯絡方式，且 macOS 無法開啟外部聯絡 URL 時，App 才可能寫入 Daniel 的固定聯絡資訊。

## 歷史原始碼建置

本節僅適用於歷史公開 `v1.0` 原始碼與 forks。`v1.1+` 正式版本不公開原始碼；獲准的正式版本只透過 Mac App Store 或 TestFlight 散布。

如需在本機建置或測試，請在 macOS 14.0+ 使用 Xcode。歷史公開建置與測試命令列在 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)。這些命令會刻意停用 code signing，不會產生官方 release build。

## 授權

已經公開的 `v1.0` 原始碼繼續以 `GPL-3.0-only` 授權，已授予的權利不會撤回。請見歷史公開 [LICENSE](https://github.com/git-whsh/lazyquips/blob/main/LICENSE)。

`v1.1+` 正式版本為閉源，透過 Mac App Store 使用 Apple Standard EULA 散布，或透過 TestFlight 測試；它們不是新的 GPL 原始碼版本。

第三方品牌資產並非由 Lazy Quips 維護者以 GPL 授權。請見歷史公開 [NOTICE](https://github.com/git-whsh/lazyquips/blob/main/NOTICE)。

## 官方建置與 Forks

公開的 `v1.0` 原始碼不代表授權使用 Lazy Quips 商標、official bundle identifiers、signing identities，或 official publishing channels。

歷史公開 `v1.0` 快照使用 placeholder bundle identifiers，例如 `dev.lazyquips.public`。Official Lazy Quips distribution 保留 official bundle identifiers、Apple signing identities 與 App Store/TestFlight publishing rights。請見歷史公開 [TRADEMARKS.md](https://github.com/git-whsh/lazyquips/blob/main/TRADEMARKS.md)。

Forks 可以依 GPL 研究、修改、建置與散布歷史 `v1.0` 程式碼。公開散布修改版 binaries 的 fork，應使用自己的 app name、bundle identifiers、icons or branding、signing identity、update channel 與 support channel，讓使用者能夠分辨它與 official builds 的不同。Forks 不得暗示自己是 official Lazy Quips releases。

## Release Boundary

既有公開 repository 是歷史 `v1.0` GPL 原始碼管道，不提供官方安裝資產。`v1.1+` 正式版本只使用 Mac App Store 或 TestFlight；該管道不發布新的原始碼快照、Developer ID build 或 GitHub DMG。修改公開 repository、網站或既有 Release 資產，須另行授權遠端發布任務。

## 貢獻

歡迎為歷史公開 `v1.0` 快照提交 Pull requests，專案會以 best-effort 方式處理。Public Issues 與 Discussions 不作為 support intake 管道。沒有 service-level agreement，也沒有合併變更的義務。請見歷史公開 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)。
