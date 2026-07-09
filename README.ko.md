# Lazy Quips

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md) | 한국어

Lazy Quips는 로컬 문구를 관리하고 빠르게 복사하기 위한 네이티브 macOS 메뉴 막대 앱입니다.

## 범위

- macOS 14.0+
- Apple Silicon 전용 (`arm64`)
- AppKit 연동 지점을 포함한 네이티브 SwiftUI 앱
- 서드파티 코드 의존성 없음
- 네트워크, 계정, AI, 클라우드 동기화, 자동 붙여넣기, 입력 모니터링 없음

## 다운로드

[macOS용 Lazy Quips 다운로드](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg)

Apple Silicon 전용, macOS 14.0+. 이 URL은 공식 GitHub Releases용 안정 DMG URL입니다. 404가 반환되면 현재 사용할 수 있는 공식 DMG 릴리스가 없다는 뜻입니다.

DMG에서 설치합니다.

1. `LazyQuips-arm64.dmg`를 엽니다.
2. DMG 창에서 `Lazy Quips.app`을 `Applications` 바로가기로 드래그합니다.
3. DMG를 추출 해제합니다.
4. Applications 폴더에서 Lazy Quips를 실행합니다.

공식 DMG로 인정되는 경우는 리포지토리 소유자가 게시한 GitHub Release에 첨부되어 있고, release checklist인 Developer ID signing, Apple notarization, stapling, 다운로드된 asset의 Gatekeeper verification을 통과한 경우뿐입니다.

릴리스 노트와 체크섬은 [latest GitHub Release](https://github.com/git-whsh/lazyquips/releases/latest)에서 확인하세요. 고정 checksum asset 이름은 [`LazyQuips-arm64.dmg.sha256`](https://github.com/git-whsh/lazyquips/releases/latest/download/LazyQuips-arm64.dmg.sha256)입니다.

소스에서 빌드하는 것은 검토와 개발을 위한 용도입니다. 로컬 source build는 공식 서명 DMG와 동일하지 않습니다.

## 개인정보 보호 경계

Lazy Quips는 현재 입력 필드를 읽거나, 입력한 내용을 모니터링하거나, 기존 클립보드 내용을 읽거나, 클립보드 데이터를 업로드하지 않습니다.

앱은 사용자가 명시적으로 문구를 선택한 뒤에만 시스템 pasteboard에 씁니다. 또한 사용자가 피드백 연락처를 클릭했지만 macOS가 외부 연락처 URL을 열 수 없는 경우에만 Daniel의 고정 연락처 정보를 쓸 수 있습니다.

## 소스 빌드

이 섹션은 소스 코드를 검토하거나 fork한 저장소에서 개발하려는 사용자를 위한 것입니다. Lazy Quips를 일반적으로 사용하려는 경우 다운로드 섹션에서 공식 DMG를 설치하세요.

로컬에서는 macOS 14.0+의 Xcode로 build/test를 실행할 수 있습니다. 서명 없이 실행하는 자세한 build/test 명령은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요. 이 명령은 code signing을 비활성화하며 official release build를 생성하지 않습니다.

## 라이선스

소스 코드는 `GPL-3.0-only`에 따라 라이선스됩니다. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.

서드파티 브랜드 asset은 Lazy Quips maintainers가 GPL에 따라 라이선스하는 것이 아닙니다. 자세한 내용은 [NOTICE](NOTICE)를 참조하세요.

## 공식 빌드와 Forks

공개 소스 코드는 Lazy Quips trademarks, official bundle identifiers, signing identities 또는 official publishing channels 사용 권한을 부여하지 않습니다.

공개 소스 스냅샷은 `dev.lazyquips.public` 같은 placeholder bundle identifiers를 사용합니다. Official Lazy Quips distribution은 official bundle identifiers, Apple signing identities, App Store/TestFlight distribution, Developer ID signing, notarization, GitHub Release publishing rights를 보유합니다. 자세한 내용은 [TRADEMARKS.md](TRADEMARKS.md)를 참조하세요.

Forks는 GPL에 따라 코드를 살펴보고, 수정하고, 빌드하고, 배포할 수 있습니다. 수정된 binaries를 공개 배포하는 fork는 사용자가 official builds와 구분할 수 있도록 자체 app name, bundle identifiers, icons or branding, signing identity, update channel, support channel을 사용해야 합니다. Forks는 자신이 official Lazy Quips releases인 것처럼 암시해서는 안 됩니다.

## Release Boundary

이 공개 repository는 source review, 로컬 개발, 가벼운 협업을 위한 것입니다. Official GitHub Release, App Store, TestFlight, Developer ID, notarization, DMG release processes는 여기에 의도적으로 포함하지 않은 비공개 signing 및 release configuration을 사용합니다.

Official GitHub Release assets는 안정적인 공개 파일명 `LazyQuips-arm64.dmg` 및 `LazyQuips-arm64.dmg.sha256`를 사용합니다.

Official binaries가 GitHub Releases와 Apple platforms 양쪽에서 제공되더라도, GitHub source 및 release artifacts는 공개 GPL 지향 배포 채널로 유지되며, Apple platform builds는 project owner가 유지하는 편의 채널입니다.

## 기여

Pull requests는 best-effort 기준으로 환영합니다. Public Issues 및 Discussions는 지원 접수 채널로 사용하지 않습니다. service-level agreement는 없으며 변경 사항을 merge할 의무도 없습니다. 자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.
