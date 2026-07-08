# Contributing

Issues and pull requests are welcome on a best-effort basis. There is no service-level agreement and no obligation to accept or merge a change.

## Project Boundaries

Lazy Quips is a local-first macOS menu bar app for managing and copying saved phrases.

Current boundaries:

- No network features.
- No accounts.
- No AI or backend service.
- No cloud sync.
- No automatic paste.
- No input monitoring.
- No reading existing clipboard contents.
- No reading the current input field in other apps.

Changes that affect privacy, permissions, signing, release, data storage, or user-visible behavior need clear justification and focused tests.

## Development

Build:

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" build
```

Test:

```bash
xcodebuild -project lazyquips.xcodeproj -scheme lazyquips -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" test
```

The public development command disables signing and does not validate official release signing, notarization, TestFlight, App Store export, login item runtime registration, or sandbox runtime behavior.

## Pull Requests

Please keep pull requests small and focused. Avoid unrelated formatting, broad refactors, dependency additions, or release/signing changes.

Do not include secrets, private user data, real phrase libraries, signing files, provisioning profiles, certificates, App Store Connect keys, or release artifacts.

By submitting a contribution, you represent that you have the right to submit it and that it may be distributed by this project under GPL-3.0-only. Contributions do not grant rights to use Lazy Quips trademarks, official bundle identifiers, signing identities, release accounts, or official publishing channels.

## Forks and Official Identity

Forks that publicly distribute modified binaries should use their own app name, bundle identifiers, icons or branding, signing identity, update channel, and support channel so users can distinguish them from official Lazy Quips builds. Do not imply that a fork is an official Lazy Quips release.
