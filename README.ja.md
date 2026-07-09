# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | 日本語 | [한국어](README.ko.md)

Lazy Quips は、ローカルのフレーズを管理し、すばやくコピーするためのネイティブ macOS メニューバーアプリです。

## 対象範囲

- macOS 14.0+
- Apple Silicon 専用 (`arm64`)
- AppKit 連携ポイントを含むネイティブ SwiftUI アプリ
- サードパーティ製コード依存なし
- ネットワーク、アカウント、AI、クラウド同期、自動ペースト、入力監視なし

## ダウンロード

[macOS 版 Lazy Quips をダウンロード](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg)

Apple Silicon 専用、macOS 14.0+。これは公式 GitHub Releases 用の安定した DMG URL です。404 が返る場合、現在利用可能な公式 DMG リリースはありません。

DMG からインストールします。

1. `LazyQuips-arm64.dmg` を開きます。
2. DMG ウィンドウ内で `Lazy Quips.app` を `Applications` ショートカットへドラッグします。
3. DMG を取り出します。
4. Applications フォルダから Lazy Quips を起動します。

公式 DMG と見なされるのは、リポジトリ所有者が公開した GitHub Release に添付され、release checklist である Developer ID signing、Apple notarization、stapling、ダウンロード済みアセットの Gatekeeper verification を通過している場合のみです。

リリースノートとチェックサムは [latest GitHub Release](https://github.com/git-whsh/lazyquips/releases/latest) を確認してください。固定チェックサムアセット名は [`LazyQuips-arm64.dmg.sha256`](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg.sha256) です。

ソースからのビルドは、確認と開発のためのものです。ローカルの source build は、公式の署名済み DMG と同一ではありません。

## プライバシーの境界

Lazy Quips は、現在の入力フィールドの読み取り、入力内容の監視、既存のクリップボード内容の読み取り、クリップボードデータのアップロードを行いません。

このアプリがシステム pasteboard に書き込むのは、ユーザーが明示的にフレーズを選択した後だけです。また、ユーザーがフィードバック連絡先をクリックし、macOS が外部連絡先 URL を開けない場合に限り、Daniel の固定連絡先情報を書き込むことがあります。

## ビルド

macOS 14.0+ と Xcode が必要です。

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" build
```

## テスト

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" test
```

公開ビルドおよびテストコマンドでは、意図的に code signing を無効にしています。これらはソースのコンパイルと通常のテストのみを検証します。sandbox runtime behavior、login item registration、Developer ID signing、notarization、App Store export、TestFlight upload、または公式 release process は検証しません。

## ライセンス

ソースコードは `GPL-3.0-only` の下でライセンスされています。詳しくは [LICENSE](LICENSE) を参照してください。

サードパーティのブランドアセットは、Lazy Quips のメンテナーによって GPL の下でライセンスされているものではありません。詳しくは [NOTICE](NOTICE) を参照してください。

## 公式ビルドと Forks

公開ソースコードは、Lazy Quips の商標、official bundle identifiers、signing identities、または official publishing channels の使用を許可するものではありません。

公開ソーススナップショットでは、`dev.lazyquips.public` のような placeholder bundle identifiers を使用しています。Official Lazy Quips distribution では、official bundle identifiers、Apple signing identities、App Store/TestFlight distribution、Developer ID signing、notarization、GitHub Release publishing rights を留保します。詳しくは [TRADEMARKS.md](TRADEMARKS.md) を参照してください。

Forks は GPL の下でコードを調査、変更、ビルド、配布できます。変更済み binaries を公開配布する fork は、ユーザーが official builds と区別できるように、独自の app name、bundle identifiers、icons or branding、signing identity、update channel、support channel を使用するべきです。Forks は、それが official Lazy Quips releases であるかのように示唆してはなりません。

## Release Boundary

この公開 repository は、source review、ローカル開発、軽量なコラボレーションのためのものです。Official GitHub Release、App Store、TestFlight、Developer ID、notarization、DMG release processes では、ここに意図的に含めていない非公開の signing および release configuration を使用します。

Official GitHub Release assets は、安定した公開ファイル名 `LazyQuips-arm64.dmg` と `LazyQuips-arm64.dmg.sha256` を使用します。

Official binaries が GitHub Releases と Apple platforms の両方で提供される場合でも、GitHub source と release artifacts が公開 GPL 向けの配布チャネルであり、Apple platform builds は project owner が維持する利便性のためのチャネルです。

## 貢献

Pull requests は best-effort で歓迎します。Public Issues と Discussions はサポート受付には使用していません。service-level agreement はなく、変更を merge する義務もありません。詳しくは [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。
