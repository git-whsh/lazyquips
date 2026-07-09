# Lazy Quips

English | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips is a native macOS menu bar app for managing and quickly copying local phrases.

## Scope

- macOS 14.0+
- Apple Silicon only (`arm64`)
- Native SwiftUI app with AppKit integration points
- No third-party code dependencies
- No network, account, AI, cloud sync, automatic paste, or input monitoring

## Download

[Download Lazy Quips for macOS](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg)

Apple Silicon only, macOS 14.0+. This is the stable DMG URL for official GitHub Releases. If it returns 404, no official DMG release is currently available.

Install it from the DMG:

1. Open `LazyQuips-arm64.dmg`.
2. Drag `Lazy Quips.app` to the `Applications` shortcut in the DMG window.
3. Eject the DMG.
4. Launch Lazy Quips from the Applications folder.

An official DMG is official only when it is attached to a published GitHub Release by the repository owner and has passed the release checklist: Developer ID signing, Apple notarization, stapling, and Gatekeeper verification of the downloaded asset.

See the [latest GitHub Release](https://github.com/git-whsh/lazyquips/releases/latest) for release notes and checksums. The fixed checksum asset name is [`LazyQuips-arm64.dmg.sha256`](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg.sha256).

Building from source is for inspection and development. A local source build is not the same as the official signed DMG.

## Privacy Boundary

Lazy Quips does not read the current input field, monitor typed content, read existing clipboard contents, or upload clipboard data.

The app writes to the system pasteboard only after the user explicitly chooses a phrase. It may also write Daniel's fixed contact detail only after the user clicks a feedback contact and macOS cannot open the external contact URL.

## Build

Requires macOS 14.0+ and Xcode.

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" build
```

## Test

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" test
```

The public build and test commands intentionally disable code signing. They verify source compilation and ordinary tests only; they do not validate sandbox runtime behavior, login item registration, Developer ID signing, notarization, App Store export, TestFlight upload, or any official release process.

## License

The source code is licensed under `GPL-3.0-only`. See [LICENSE](LICENSE).

Third-party brand assets are not licensed by the Lazy Quips maintainers under the GPL. See [NOTICE](NOTICE).

## Official Builds and Forks

The public source code is not a grant to use Lazy Quips trademarks, official bundle identifiers, signing identities, or official publishing channels.

The public source snapshot uses placeholder bundle identifiers such as `dev.lazyquips.public`. Official Lazy Quips distribution reserves the official bundle identifiers, Apple signing identities, App Store/TestFlight distribution, Developer ID signing, notarization, and GitHub Release publishing rights. See [TRADEMARKS.md](TRADEMARKS.md).

Forks may study, modify, build, and distribute the code under the GPL. A fork that publicly distributes modified binaries should use its own app name, bundle identifiers, icons or branding, signing identity, update channel, and support channel so users can distinguish it from official builds. Forks must not imply that they are official Lazy Quips releases.

## Release Boundary

This public repository is for source review, local development, and lightweight collaboration. Official GitHub Release, App Store, TestFlight, Developer ID, notarization, and DMG release processes use private signing and release configuration that is intentionally not included here.

Official GitHub Release assets use stable public filenames: `LazyQuips-arm64.dmg` and `LazyQuips-arm64.dmg.sha256`.

If official binaries are offered through both GitHub Releases and Apple platforms, GitHub source and release artifacts remain the public GPL-oriented distribution channel, while Apple platform builds are a convenience channel maintained by the project owner.

## Contributions

Pull requests are welcome on a best-effort basis. Public Issues and Discussions are not used for support intake. There is no service-level agreement and no obligation to merge changes. See [CONTRIBUTING.md](CONTRIBUTING.md).
