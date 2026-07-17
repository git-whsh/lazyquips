# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | 한국어

Lazy Quips는 로컬 문구를 관리하고 빠르게 복사하기 위한 네이티브 macOS 메뉴 막대 앱입니다.

## 범위

- macOS 14.0+
- Apple Silicon 전용 (`arm64`)
- AppKit 연동 지점을 포함한 네이티브 SwiftUI 앱
- 서드파티 코드 의존성 없음
- 개발자가 운영하거나 자체 호스팅하는 네트워크 서비스나 백엔드는 없으며, 계정, AI, 클라우드 동기화, 분석, 텔레메트리, 자동 붙여넣기 또는 입력 모니터링도 없습니다. Mac App Store 구매, 구매 복원 및 사용 권한 확인은 Apple이 StoreKit과 App Store를 통해 처리합니다.

## 배포

`v1.0`은 `GPL-3.0-only`로 공개된 과거 소스 스냅샷입니다. 기존 소스에는 이 과거 라이선스가 계속 적용되며, 이미 부여된 권리는 철회되지 않습니다. `v1.1`부터 공식 Lazy Quips 빌드는 비공개 소스이며 Mac App Store 또는 TestFlight로만 배포됩니다. `v1.1+` 소스 스냅샷이나 GitHub DMG는 공개하지 않습니다.

[Mac App Store에서 Lazy Quips 다운로드](https://apps.apple.com/app/id6783259528)

Apple Silicon 전용, macOS 14.0+. 이 공개 repository는 검토와 fork 개발을 위한 과거 `v1.0` 소스만 보관합니다. 공식 GitHub installer, DMG 또는 checksum 다운로드는 제공하지 않습니다.

과거 `v1.0` 소스에서 빌드하는 것은 검토와 fork 개발을 위한 용도입니다. 로컬 source build는 공식 Lazy Quips 빌드가 아닙니다.

## 개인정보 보호 경계

Lazy Quips는 현재 입력 필드를 읽거나, 입력한 내용을 모니터링하거나, 기존 클립보드 내용을 읽거나, 클립보드 데이터를 업로드하지 않습니다.

문구 및 클립보드 데이터는 업로드되지 않습니다. Apple은 StoreKit과 App Store를 통해 구매, 구매 복원 및 사용 권한 확인을 처리하고 구매 결과와 사용 권한 정보를 앱에 반환합니다.

앱은 사용자가 명시적으로 문구를 선택한 뒤에만 시스템 pasteboard에 씁니다. 또한 사용자가 피드백 연락처를 클릭했지만 macOS가 외부 연락처 URL을 열 수 없는 경우에만 Daniel의 고정 연락처 정보를 쓸 수 있습니다.

## 과거 소스 빌드

이 섹션은 공개된 과거 `v1.0` 소스 및 forks에만 적용됩니다. 공식 `v1.1+` 소스는 공개하지 않으며, 승인된 공식 빌드는 Mac App Store 또는 TestFlight로 배포합니다.

로컬에서는 macOS 14.0+의 Xcode로 build/test를 실행할 수 있습니다. 과거 공개 build/test 명령은 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)를 참고하세요. 이 명령은 code signing을 비활성화하며 official release build를 생성하지 않습니다.

## 라이선스

`v1.0`으로 이미 공개된 소스에는 `GPL-3.0-only`가 계속 적용되며, 이미 부여된 권리는 철회되지 않습니다. 과거 공개 [LICENSE](https://github.com/git-whsh/lazyquips/blob/main/LICENSE)를 참조하세요.

공식 `v1.1+` 빌드는 비공개 소스이며 Apple Standard EULA에 따라 Mac App Store로 배포하거나 테스트를 위해 TestFlight로 배포합니다. 이 빌드는 새로운 GPL 소스 릴리스가 아닙니다.

서드파티 브랜드 asset은 Lazy Quips maintainers가 GPL에 따라 라이선스하는 것이 아닙니다. 과거 공개 [NOTICE](https://github.com/git-whsh/lazyquips/blob/main/NOTICE)를 참조하세요.

## 공식 빌드와 Forks

공개된 `v1.0` 소스 코드는 Lazy Quips trademarks, official bundle identifiers, signing identities 또는 official publishing channels 사용 권한을 부여하지 않습니다.

과거 공개 `v1.0` 스냅샷은 `dev.lazyquips.public` 같은 placeholder bundle identifiers를 사용합니다. Official Lazy Quips distribution은 official bundle identifiers, Apple signing identities 및 App Store/TestFlight publishing rights를 보유합니다. 과거 공개 [TRADEMARKS.md](https://github.com/git-whsh/lazyquips/blob/main/TRADEMARKS.md)를 참조하세요.

Forks는 GPL에 따라 과거 `v1.0` 코드를 살펴보고, 수정하고, 빌드하고, 배포할 수 있습니다. 수정된 binaries를 공개 배포하는 fork는 사용자가 official builds와 구분할 수 있도록 자체 app name, bundle identifiers, icons or branding, signing identity, update channel, support channel을 사용해야 합니다. Forks는 자신이 official Lazy Quips releases인 것처럼 암시해서는 안 됩니다.

## Release Boundary

기존 공개 repository는 과거 `v1.0` GPL 소스 채널이며 공식 installer asset을 제공하지 않습니다. 공식 `v1.1+` 빌드는 Mac App Store 또는 TestFlight만 사용하며, 이 채널에는 새로운 소스 스냅샷, Developer ID build 또는 GitHub DMG를 공개하지 않습니다. 공개 repository, 웹사이트 또는 기존 Release assets를 변경하려면 별도 승인을 받은 remote-release task가 필요합니다.

## 기여

과거 공개 `v1.0` 스냅샷에 대한 Pull requests는 best-effort 기준으로 환영합니다. Public Issues 및 Discussions는 지원 접수 채널로 사용하지 않습니다. service-level agreement는 없으며 변경 사항을 merge할 의무도 없습니다. 과거 공개 [CONTRIBUTING.md](https://github.com/git-whsh/lazyquips/blob/main/CONTRIBUTING.md)를 참조하세요.
