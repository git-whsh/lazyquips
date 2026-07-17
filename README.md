# Lazy Quips

English | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

Lazy Quips is a native macOS menu bar app for managing and quickly copying local phrases.

## Scope

- macOS 14.0+
- Apple Silicon only (`arm64`)
- Native SwiftUI app with AppKit integration points
- No third-party code dependencies
- No developer-operated or self-hosted network service or backend; no account, AI, cloud sync, analytics, telemetry, automatic paste, or input monitoring. Mac App Store purchases, restores, and entitlement checks are handled by Apple through StoreKit and the App Store.

## Distribution

`v1.0` is the historical `GPL-3.0-only` source snapshot. Its existing source remains available under that historical license; the rights already granted are not revoked. Starting with `v1.1`, official Lazy Quips builds are closed-source and distributed only through the Mac App Store or TestFlight. No `v1.1+` source snapshot or GitHub DMG will be published.

[Download Lazy Quips from the Mac App Store](https://apps.apple.com/app/id6783259528)

Apple Silicon only, macOS 14.0+. This public repository preserves the historical `v1.0` source for inspection and forks; it does not provide an official GitHub installer, DMG, or checksum download.

Building the historical `v1.0` source is for inspection and fork development. A local source build is not an official Lazy Quips build.

## Privacy Boundary

Lazy Quips does not read the current input field, monitor typed content, read existing clipboard contents, or upload clipboard data.

Phrase and clipboard data are not uploaded. Apple processes purchases, restores, and entitlement checks through StoreKit and the App Store, and returns purchase results and entitlement information to the app.

The app writes to the system pasteboard only after the user explicitly chooses a phrase. It may also write Daniel's fixed contact detail only after the user clicks a feedback contact and macOS cannot open the external contact URL.

## Historical Source Build

This section applies only to the historical public `v1.0` source and forks. Official `v1.1+` source is not published; approved official builds are distributed through the Mac App Store or TestFlight.

To build or test locally, use Xcode on macOS 14.0+. The historical public build and test commands are in [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md). They intentionally disable code signing and do not produce an official release build.

## License

Source already published as `v1.0` remains licensed under `GPL-3.0-only`; its granted rights are not revoked. See the historical public [LICENSE](https://github.com/git-whsh/lazyquips/blob/main/LICENSE).

Official `v1.1+` builds are closed-source and distributed through the Mac App Store under the Apple Standard EULA, or through TestFlight for testing. They are not new GPL source releases.

Third-party brand assets are not licensed by the Lazy Quips maintainers under the GPL. See the historical public [NOTICE](https://github.com/git-whsh/lazyquips/blob/main/NOTICE).

## Official Builds and Forks

The public `v1.0` source code is not a grant to use Lazy Quips trademarks, official bundle identifiers, signing identities, or official publishing channels.

The historical public `v1.0` snapshot uses placeholder bundle identifiers such as `dev.lazyquips.public`. Official Lazy Quips distribution reserves the official bundle identifiers, Apple signing identities, and App Store/TestFlight publishing rights. See the historical public [TRADEMARKS.md](https://github.com/git-whsh/lazyquips/blob/main/TRADEMARKS.md).

Forks may study, modify, build, and distribute the historical `v1.0` code under the GPL. A fork that publicly distributes modified binaries should use its own app name, bundle identifiers, icons or branding, signing identity, update channel, and support channel so users can distinguish it from official builds. Forks must not imply that they are official Lazy Quips releases.

## Release Boundary

The existing public repository is the historical `v1.0` GPL source channel. It does not provide official installer assets. Official `v1.1+` builds use only the Mac App Store or TestFlight; no new source snapshot, Developer ID build, or GitHub DMG is part of that channel. Changing the public repository, website, or existing Release assets requires a separately authorized remote-release task.

## Contributions

Pull requests for the historical public `v1.0` snapshot are welcome on a best-effort basis. Public Issues and Discussions are not used for support intake. There is no service-level agreement and no obligation to merge changes. See the historical public [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md).
