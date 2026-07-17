# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | 日本語 | [한국어](README.ko.md)

Lazy Quips は、ローカルのフレーズを管理し、すばやくコピーするためのネイティブ macOS メニューバーアプリです。

## 対象範囲

- macOS 14.0+
- Apple Silicon 専用 (`arm64`)
- AppKit 連携ポイントを含むネイティブ SwiftUI アプリ
- サードパーティ製コード依存なし
- 開発者が運用またはセルフホストするネットワークサービスやバックエンドはなく、アカウント、AI、クラウド同期、分析、テレメトリ、自動ペースト、入力監視もありません。Mac App Store での購入、購入の復元、利用権の確認は、Apple が StoreKit と App Store を通じて処理します。

## 配布

`v1.0` は、`GPL-3.0-only` で公開された履歴版ソーススナップショットです。既存のソースには引き続きこの履歴ライセンスが適用され、付与済みの権利は取り消されません。`v1.1` 以降の公式 Lazy Quips ビルドはクローズドソースで、Mac App Store または TestFlight のみから配布します。`v1.1+` のソーススナップショットや GitHub DMG は公開しません。

[Mac App Store から Lazy Quips をダウンロード](https://apps.apple.com/app/id6783259528)

Apple Silicon 専用、macOS 14.0+。この公開 repository は、確認や fork 開発のために履歴版 `v1.0` ソースのみを保持します。公式の GitHub installer、DMG、checksum ダウンロードは提供しません。

履歴版 `v1.0` ソースからのビルドは、確認と fork 開発のためのものです。ローカルの source build は公式 Lazy Quips ビルドではありません。

## プライバシーの境界

Lazy Quips は、現在の入力フィールドの読み取り、入力内容の監視、既存のクリップボード内容の読み取り、クリップボードデータのアップロードを行いません。

フレーズおよびクリップボードのデータはアップロードされません。Apple は StoreKit と App Store を通じて購入、購入の復元、利用権の確認を処理し、購入結果と利用権の情報をアプリに返します。

このアプリがシステム pasteboard に書き込むのは、ユーザーが明示的にフレーズを選択した後だけです。また、ユーザーがフィードバック連絡先をクリックし、macOS が外部連絡先 URL を開けない場合に限り、Daniel の固定連絡先情報を書き込むことがあります。

## 履歴版ソースからのビルド

このセクションは、公開済みの履歴版 `v1.0` ソースと forks にのみ適用されます。公式 `v1.1+` ソースは公開されません。承認済みの公式ビルドは Mac App Store または TestFlight を通じて配布されます。

ローカルでは macOS 14.0+ の Xcode で build/test を実行できます。履歴版の公開 build/test コマンドは [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md) を参照してください。これらのコマンドは code signing を無効にしており、official release build は生成しません。

## ライセンス

`v1.0` として公開済みのソースには引き続き `GPL-3.0-only` が適用され、付与済みの権利は取り消されません。履歴版の公開 [LICENSE](https://github.com/git-whsh/lazyquips/blob/main/LICENSE) を参照してください。

公式 `v1.1+` ビルドはクローズドソースで、Apple Standard EULA の下で Mac App Store から、またはテスト用に TestFlight から配布されます。これらは新しい GPL ソースリリースではありません。

サードパーティのブランドアセットは、Lazy Quips のメンテナーによって GPL の下でライセンスされているものではありません。履歴版の公開 [NOTICE](https://github.com/git-whsh/lazyquips/blob/main/NOTICE) を参照してください。

## 公式ビルドと Forks

公開済みの `v1.0` ソースコードは、Lazy Quips の商標、official bundle identifiers、signing identities、または official publishing channels の使用を許可するものではありません。

履歴版の公開 `v1.0` スナップショットでは、`dev.lazyquips.public` のような placeholder bundle identifiers を使用しています。Official Lazy Quips distribution では、official bundle identifiers、Apple signing identities、App Store/TestFlight publishing rights を留保します。履歴版の公開 [TRADEMARKS.md](https://github.com/git-whsh/lazyquips/blob/main/TRADEMARKS.md) を参照してください。

Forks は GPL の下で履歴版 `v1.0` コードを調査、変更、ビルド、配布できます。変更済み binaries を公開配布する fork は、ユーザーが official builds と区別できるように、独自の app name、bundle identifiers、icons or branding、signing identity、update channel、support channel を使用するべきです。Forks は、それが official Lazy Quips releases であるかのように示唆してはなりません。

## Release Boundary

既存の公開 repository は、履歴版 `v1.0` の GPL ソースチャネルです。公式 installer asset は提供しません。公式 `v1.1+` ビルドは Mac App Store または TestFlight のみを使用し、このチャネルでは新しいソーススナップショット、Developer ID build、GitHub DMG を公開しません。公開 repository、Web サイト、既存の Release assets を変更するには、別途承認された remote-release task が必要です。

## 貢献

履歴版の公開 `v1.0` スナップショットへの Pull requests は best-effort で歓迎します。Public Issues と Discussions はサポート受付には使用していません。service-level agreement はなく、変更を merge する義務もありません。履歴版の公開 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md) を参照してください。
