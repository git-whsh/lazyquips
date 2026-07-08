import AppKit
import Carbon
import ServiceManagement
import SwiftData
import XCTest

final class LazyquipsTests: XCTestCase {
    func testPasteboardWriterWritesStringToUniquePasteboard() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let writer = PasteboardWriter(pasteboard: pasteboard)
        let text = "收到，我稍后确认后回复你。"

        XCTAssertTrue(writer.writeString(text))
        XCTAssertEqual(pasteboard.string(forType: .string), text)
    }

    func testContactActionControllerOpensExternalURLWithoutWritingPasteboard() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let controller = ContactActionController(
            opener: ExternalURLOpener { url in
                XCTAssertEqual(url.absoluteString, "mailto:daniel@whtobe.com")
                return true
            },
            pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
        )

        XCTAssertEqual(controller.perform(.email), .opened)
        XCTAssertNil(pasteboard.string(forType: .string))
    }

    func testContactActionControllerCopiesFallbackWhenExternalOpenFails() {
        let cases: [(ContactChannel, String)] = [
            (.email, "daniel@whtobe.com"),
            (.whatsApp, "+852 56421873"),
            (.telegram, "whtobe")
        ]

        for testCase in cases {
            let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
            let controller = ContactActionController(
                opener: ExternalURLOpener { _ in false },
                pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
            )

            XCTAssertEqual(controller.perform(testCase.0), .copied)
            XCTAssertEqual(pasteboard.string(forType: .string), testCase.1)
        }
    }

    func testContactActionControllerReportsFailureWhenFallbackCopyFails() {
        let controller = ContactActionController(
            opener: ExternalURLOpener { _ in false },
            pasteboardWriter: PasteboardWriter(writeString: { text in
                XCTAssertEqual(text, "daniel@whtobe.com")
                return false
            })
        )

        XCTAssertEqual(controller.perform(.email), .failed)
    }

    func testContactChannelsUseSystemSymbolsInsteadOfBundledBrandAssets() {
        let cases: [(ContactChannel, String, String)] = [
            (.email, "envelope.fill", "SettingsEmailIcon.imageset"),
            (.whatsApp, "message.fill", "SettingsWhatsAppIcon.imageset"),
            (.telegram, "paperplane.fill", "SettingsTelegramIcon.imageset")
        ]

        for testCase in cases {
            XCTAssertEqual(testCase.0.systemSymbolName, testCase.1)

            let relativeAssetPath = "lazyquips/Resources/Assets.xcassets/\(testCase.2)"
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: repositoryFileURL(relativeAssetPath).path),
                relativeAssetPath
            )
        }
    }

    func testContactIconsDoNotUseLocalURLHandlerAppIcons() throws {
        let settingsSource = try sourceFileContent("lazyquips/App/LaunchAtLoginSettingsView.swift")

        XCTAssertFalse(settingsSource.contains("ContactAppIconResolver"))
        XCTAssertFalse(settingsSource.contains("NSWorkspace.shared.urlForApplication(toOpen: url)"))
        XCTAssertFalse(settingsSource.contains("NSWorkspace.shared.icon(forFile: path)"))
        XCTAssertFalse(settingsSource.contains("Image(channel.assetName)"))
        XCTAssertFalse(settingsSource.contains(".renderingMode(.original)"))
        XCTAssertTrue(settingsSource.contains("Image(systemName: channel.systemSymbolName)"))
    }

    func testHotKeyControllerUsesShiftCommandC() {
        XCTAssertEqual(HotKeyController.shortcutKeyCode, UInt32(kVK_ANSI_C))
        XCTAssertEqual(HotKeyController.shortcutModifiers, UInt32(cmdKey | shiftKey))
    }

    func testHotKeyControllerRestartStopsBeforeRegisteringAgain() throws {
        let source = try sourceFileContent("lazyquips/App/HotKeyController.swift")

        XCTAssertTrue(source.contains("protocol HotKeyRegistering"))
        XCTAssertTrue(source.contains("func restart() -> Bool"))
        XCTAssertTrue(source.contains("func restart() -> Bool {\n        stop()\n        return start()\n    }"))
        XCTAssertTrue(source.contains("RegisterEventHotKey("))
        XCTAssertTrue(source.contains("GetApplicationEventTarget()"))
        XCTAssertTrue(source.contains(",\n            0,\n            &eventHotKey"))
        XCTAssertFalse(source.contains("kEventHotKeyExclusive"))
        XCTAssertFalse(source.contains("NSEvent.addGlobalMonitorForEvents"))
        XCTAssertFalse(source.contains("CGEventTapCreate"))
    }

    func testHotKeyRegistrationStatusStoreTracksAvailability() {
        let store = HotKeyRegistrationStatusStore()

        XCTAssertEqual(store.status, .unavailable)

        store.update(isAvailable: true)
        XCTAssertEqual(store.status, .available)

        store.update(isAvailable: false)
        XCTAssertEqual(store.status, .unavailable)
    }

    func testAppLanguageStoreDefaultsToTraditionalChineseOnlyForTraditionalChinesePreferredLanguages() {
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["zh-Hant-TW"]), .traditionalChinese)
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["zh-TW"]), .traditionalChinese)
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["zh-HK"]), .traditionalChinese)
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["zh-MO"]), .traditionalChinese)
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["en-US"]), .english)
        XCTAssertEqual(AppLanguageStore.defaultLanguage(for: ["zh-Hans-CN"]), .english)
    }

    func testAppLanguageStorePersistsExplicitSelection() {
        let suiteName = "dev.lazyquips.public.tests.language.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = AppLanguageStore(
            userDefaults: userDefaults,
            preferredLanguages: ["en-US"]
        )
        XCTAssertEqual(store.language, .english)

        store.select(.traditionalChinese)
        XCTAssertEqual(store.language, .traditionalChinese)

        let restoredStore = AppLanguageStore(
            userDefaults: userDefaults,
            preferredLanguages: ["en-US"]
        )
        XCTAssertEqual(restoredStore.language, .traditionalChinese)
    }

    func testAppAppearanceStoreDefaultsToAuto() {
        let suiteName = "dev.lazyquips.public.tests.appearance.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertEqual(AppAppearanceStore(userDefaults: userDefaults).appearance, .auto)

        userDefaults.set("unexpected", forKey: AppAppearanceStore.userDefaultsKey)
        XCTAssertEqual(AppAppearanceStore(userDefaults: userDefaults).appearance, .auto)
    }

    func testAppAppearanceStorePersistsExplicitSelection() {
        let suiteName = "dev.lazyquips.public.tests.appearance.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = AppAppearanceStore(userDefaults: userDefaults)
        XCTAssertEqual(store.appearance, .auto)

        for appearance in AppAppearance.allCases {
            store.select(appearance)
            XCTAssertEqual(store.appearance, appearance)
            XCTAssertEqual(AppAppearanceStore(userDefaults: userDefaults).appearance, appearance)
        }
    }

    func testAppAppearanceMapsToPreferredColorScheme() {
        XCTAssertNil(AppAppearance.auto.preferredColorScheme)
        XCTAssertEqual(AppAppearance.light.preferredColorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.preferredColorScheme, .dark)
    }

    func testAppStringsCoverAllKeysInBothLanguages() {
        for key in AppStringKey.allCases {
            XCTAssertTrue(AppStrings.hasText(for: key, language: .english), "\(key) missing English text")
            XCTAssertTrue(AppStrings.hasText(for: key, language: .traditionalChinese), "\(key) missing Traditional Chinese text")
        }

        XCTAssertEqual(AppStrings.text(.settings, language: .english), "Settings")
        XCTAssertEqual(AppStrings.text(.settings, language: .traditionalChinese), "設定")
        XCTAssertEqual(AppStrings.text(.appearance, language: .english), "Appearance")
        XCTAssertEqual(AppStrings.text(.appearance, language: .traditionalChinese), "外觀")
        XCTAssertEqual(AppStrings.text(.appearanceAuto, language: .english), "Auto")
        XCTAssertEqual(AppStrings.text(.appearanceAuto, language: .traditionalChinese), "自動")
        XCTAssertEqual(AppStrings.text(.appearanceLight, language: .english), "Light")
        XCTAssertEqual(AppStrings.text(.appearanceLight, language: .traditionalChinese), "淺色")
        XCTAssertEqual(AppStrings.text(.appearanceDark, language: .english), "Dark")
        XCTAssertEqual(AppStrings.text(.appearanceDark, language: .traditionalChinese), "深色")
        XCTAssertEqual(AppStrings.text(.openAtLogin, language: .traditionalChinese), "登入時開啟")
        XCTAssertEqual(AppStrings.text(.openAtLoginUnavailable, language: .english), "Login item is unavailable.")
        XCTAssertEqual(AppStrings.text(.contactCopied, language: .traditionalChinese), "已複製聯絡方式。")
    }

    func testLazyQuipsVisualStyleUsesCarbonCopyPurpleAndSharedShortcutPreview() {
        XCTAssertEqual(LazyQuipsVisualStyle.carbonCopyPurpleRed, 97.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.carbonCopyPurpleGreen, 85.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.carbonCopyPurpleBlue, 245.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundLightRed, 79.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundLightGreen, 70.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundLightBlue, 229.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundDarkRed, 215.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundDarkGreen, 211.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.accentForegroundDarkBlue, 255.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeReservedWidth, 86, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeTrailingPadding, 0, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeHorizontalPadding, 8, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeVerticalPadding, 6, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeIconTextSpacing, 4, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeShadowRadius, 14, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.copiedBadgeShadowYOffset, 6, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.phraseLibraryCopiedFeedbackDurationNanoseconds, 1_200_000_000)
        XCTAssertEqual(LazyQuipsVisualStyle.phrasePaletteCopiedFeedbackDurationNanoseconds, 900_000_000)
        XCTAssertEqual(LazyQuipsVisualStyle.toolbarControlCornerRadius, 10, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.toolbarControlFontSize, 13, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.toolbarControlShadowRadius, 20, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.toolbarControlShadowYOffset, 8, accuracy: 0.5)
        XCTAssertEqual(LazyQuipsVisualStyle.toolbarControlPressedOpacity, 0.72, accuracy: 0.01)

        XCTAssertEqual(PhraseShortcutPreview.columnWidth, 73, accuracy: 0.5)
        XCTAssertEqual(PhraseShortcutPreview.wrappingWidth, 64, accuracy: 0.5)
        XCTAssertEqual(PhraseShortcutPreview.maximumLineCount, 2)
    }

    func testLazyQuipsVisualStyleUsesSharedRowSelectionTokens() throws {
        let source = try sourceFileContent("lazyquips/App/LazyQuipsVisualStyle.swift")

        XCTAssertTrue(source.contains("static let rowSelectedBackground = carbonCopyPurple"))
        XCTAssertTrue(source.contains("static let rowHoverBackground = carbonCopyPurple.opacity(0.12)"))
        XCTAssertTrue(source.contains("static let rowBoundary = Color.primary.opacity(0.1)"))
        XCTAssertTrue(source.contains("struct LazyQuipsRowBoundaryOverlay: View"))
        XCTAssertTrue(source.contains(".fill(LazyQuipsVisualStyle.rowBoundary)"))
    }

    func testPhraseCopyFeedbackTimingUsesContextSpecificDurations() throws {
        let librarySource = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let settingsSource = try sourceFileContent("lazyquips/App/LaunchAtLoginSettingsView.swift")
        let librarySleepExpression = "Task.sleep(nanoseconds: LazyQuipsVisualStyle.phraseLibraryCopiedFeedbackDurationNanoseconds)"
        let paletteSleepExpression = "Task.sleep(nanoseconds: LazyQuipsVisualStyle.phrasePaletteCopiedFeedbackDurationNanoseconds)"

        XCTAssertEqual(librarySource.components(separatedBy: librarySleepExpression).count - 1, 1)
        XCTAssertEqual(paletteSource.components(separatedBy: paletteSleepExpression).count - 1, 2)
        XCTAssertFalse(librarySource.contains("Task.sleep(nanoseconds: LazyQuipsVisualStyle.copiedFeedbackDurationNanoseconds)"))
        XCTAssertFalse(paletteSource.contains("Task.sleep(nanoseconds: LazyQuipsVisualStyle.copiedFeedbackDurationNanoseconds)"))
        XCTAssertFalse(librarySource.contains("Task.sleep(nanoseconds: 1_200_000_000)"))
        XCTAssertFalse(paletteSource.contains("Task.sleep(nanoseconds: 1_200_000_000)"))
        XCTAssertFalse(paletteSource.contains("Task.sleep(nanoseconds: 550_000_000)"))
        XCTAssertTrue(settingsSource.contains("Task.sleep(nanoseconds: 1_800_000_000)"))
    }

    func testCopiedBadgeUsesOpaqueBackgroundAndProminentShadow() throws {
        let source = try sourceFileContent("lazyquips/App/LazyQuipsVisualStyle.swift")
        let backgroundRange = try XCTUnwrap(source.range(of: "static func copiedBadgeBackground"))
        let foregroundRange = try XCTUnwrap(source.range(of: "static func copiedBadgeForeground"))
        let backgroundSource = String(source[backgroundRange.lowerBound..<foregroundRange.lowerBound])

        XCTAssertTrue(backgroundSource.contains("Color.white"))
        XCTAssertTrue(backgroundSource.contains("Color.black"))
        XCTAssertFalse(backgroundSource.contains(".opacity"))
        XCTAssertTrue(source.contains("copiedBadgeShadowColor(for: colorScheme)"))
        XCTAssertTrue(source.contains("LazyQuipsVisualStyle.copiedBadgeShadowRadius"))
        XCTAssertTrue(source.contains("LazyQuipsVisualStyle.copiedBadgeShadowYOffset"))
    }

    func testToolbarControlsShareGlassReadySurfaceWithMaterialFallback() throws {
        let source = try sourceFileContent("lazyquips/App/LazyQuipsVisualStyle.swift")
        let buttonStyleRange = try XCTUnwrap(source.range(of: "struct LazyQuipsToolbarButtonStyle: ButtonStyle"))
        let glassGroupRange = try XCTUnwrap(source.range(of: "struct LazyQuipsToolbarGlassGroup<Content: View>: View"))
        let buttonStyleSource = String(source[buttonStyleRange.lowerBound..<glassGroupRange.lowerBound])

        XCTAssertTrue(source.contains("struct LazyQuipsToolbarButtonStyle: ButtonStyle"))
        XCTAssertTrue(source.contains("struct LazyQuipsToolbarGlassGroup<Content: View>: View"))
        XCTAssertTrue(source.contains("private struct LazyQuipsToolbarControlSurface: ViewModifier"))
        XCTAssertTrue(source.contains("func lazyQuipsToolbarControlSurface(usesLiquidGlass: Bool = false)"))
        XCTAssertTrue(source.contains("if #available(macOS 26.0, *)"))
        XCTAssertTrue(source.contains(".glassEffect(.regular, in: shape)"))
        XCTAssertTrue(source.contains(".background(.regularMaterial, in: shape)"))
        XCTAssertTrue(source.contains("GlassEffectContainer(spacing: spacing)"))
        XCTAssertTrue(source.contains("case utility"))
        XCTAssertTrue(source.contains("Color.secondary"))
        XCTAssertTrue(buttonStyleSource.contains(".contentShape(Rectangle())"))
    }

    func testCopiedBadgeKeepsSharedCheckmarkSpacingPaddingAndMotionContract() throws {
        let source = try sourceFileContent("lazyquips/App/LazyQuipsVisualStyle.swift")
        let badgeRange = try XCTUnwrap(source.range(of: "struct LazyQuipsCopiedBadge: View"))
        let shortcutRange = try XCTUnwrap(source.range(of: "private var transition: AnyTransition"))
        let badgeSource = String(source[badgeRange.lowerBound..<shortcutRange.lowerBound])

        XCTAssertTrue(badgeSource.contains("HStack(spacing: LazyQuipsVisualStyle.copiedBadgeIconTextSpacing)"))
        XCTAssertTrue(badgeSource.contains("LazyQuipsCheckmarkShape()"))
        XCTAssertTrue(badgeSource.contains(".trim(from: 0, to: accessibilityReduceMotion ? 1 : checkmarkProgress)"))
        XCTAssertTrue(badgeSource.contains("withAnimation(.easeOut(duration: 0.22))"))
        XCTAssertTrue(badgeSource.contains(".accessibilityHidden(true)"))
        XCTAssertTrue(badgeSource.contains(".padding(.horizontal, LazyQuipsVisualStyle.copiedBadgeHorizontalPadding)"))
        XCTAssertTrue(badgeSource.contains(".padding(.vertical, LazyQuipsVisualStyle.copiedBadgeVerticalPadding)"))
        XCTAssertTrue(badgeSource.contains(".accessibilityLabel(AppStrings.text(.copied, language: language))"))
        XCTAssertTrue(badgeSource.contains("accessibilityReduceMotion ? 1 : checkmarkProgress"))
        XCTAssertTrue(badgeSource.contains("guard !accessibilityReduceMotion else"))
        XCTAssertTrue(badgeSource.contains("checkmarkProgress = 1"))
        XCTAssertFalse(badgeSource.contains("symbolEffect"))
        XCTAssertFalse(badgeSource.contains("#available(macOS 26.0, *)"))
        XCTAssertTrue(badgeSource.contains("startCheckmarkAnimation"))
    }

    func testStatusMenuLayoutMatchesFigmaContractAndMouseTriggers() {
        XCTAssertEqual(StatusMenuLayout.defaultContentSize.width, 428, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.defaultContentSize.height, 712, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.width, StatusMenuLayout.defaultContentSize.width, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.maximumHeight, StatusMenuLayout.defaultContentSize.height, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.contentHorizontalPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.listHorizontalPadding, 0, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowLeadingPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowTrailingPadding, 8, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.toolbarTopPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.toolbarControlSpacing, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.toolbarControlHeight, 32, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.searchFieldWidth, 310, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.addButtonWidth, 58, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.toolbarSearchX, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.toolbarAddX, 350, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.headerTopPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.headerHorizontalPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.headerHeight, 36, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.shortcutColumnWidth, 73, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.shortcutColumnWidth, PhraseShortcutPreview.columnWidth, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.headerShortcutX, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.headerPhraseX, 93, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.minimumContentHeight, 160, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.maximumContentHeight, 552, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.sectionTitleLeadingPadding, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.sectionTitleHeight, 16, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowVerticalSpacing, 0, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.sectionBottomPadding, 18, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.sectionTitleX, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowTextX, 20, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.phraseTextX, 93, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowWidth, 428, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowHeight, 50, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.navigationReservedTrailingWidth, 25, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowVisualWidth, 403, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.phraseColumnWidth, 302, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.rowCopiedFeedbackTrailingPadding, 8, accuracy: 0.5)
        XCTAssertEqual(
            StatusMenuLayout.rowCopiedFeedbackTrailingPadding,
            StatusMenuLayout.rowTrailingPadding + LazyQuipsVisualStyle.copiedBadgeTrailingPadding,
            accuracy: 0.5
        )
        XCTAssertEqual(StatusMenuLayout.navigationTrailingPadding, 1, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.submenuWidth, 317, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.submenuLeadingPadding, 0, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.submenuTrailingPadding, 10, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.submenuVerticalPadding, 10, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.submenuTextWidth, 307, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.maximumPanelWidth, 745, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.maximumPanelWindowWidth, 801, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.panelWidth(hasSubmenu: false), 428, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.panelWidth(hasSubmenu: true), 745, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.defaultPanelWindowContentSize.width, 484, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.defaultPanelWindowContentSize.height, 744, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.surfaceCornerRadius, 16, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.chromePadding, 28, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.chromeTopPadding, 4, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.chromeShadowRadius, 18, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.chromeShadowYOffset, 8, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.panelAnchorGap, 2, accuracy: 0.5)
        let compactWindowSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.width, height: 600)
        )
        XCTAssertEqual(compactWindowSize.width, 484, accuracy: 0.5)
        XCTAssertEqual(compactWindowSize.height, 632, accuracy: 0.5)
        XCTAssertEqual(
            StatusMenuLayout.visibleContentSize(for: compactWindowSize).width,
            StatusMenuLayout.width,
            accuracy: 0.5
        )
        XCTAssertEqual(StatusMenuLayout.visibleContentSize(for: compactWindowSize).height, 600, accuracy: 0.5)
        XCTAssertEqual(
            StatusMenuLayout.visibleContentFrame(inWindowContentSize: compactWindowSize).minX,
            StatusMenuLayout.chromePadding,
            accuracy: 0.5
        )
        XCTAssertEqual(
            StatusMenuLayout.visibleContentFrame(inWindowContentSize: compactWindowSize).minY,
            StatusMenuLayout.chromePadding,
            accuracy: 0.5
        )
        XCTAssertEqual(StatusMenuLayout.submenuHoverDelayNanoseconds, 120_000_000)
        XCTAssertEqual(StatusMenuLayout.footerTopPadding, 10, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.footerBottomPadding, 26, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.footerHeight, 72, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.openMainWindowButtonWidth, 121, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.footerPlainButtonMinWidth, 64, accuracy: 0.5)
        XCTAssertEqual(StatusMenuLayout.footerPlainButtonHeight, StatusMenuLayout.toolbarControlHeight, accuracy: 0.5)
        XCTAssertTrue(StatusMenuLayout.statusItemMouseEvents.contains(.leftMouseUp))
        XCTAssertTrue(StatusMenuLayout.statusItemMouseEvents.contains(.rightMouseUp))
        XCTAssertFalse(StatusMenuLayout.statusItemMouseEvents.contains(.leftMouseDown))
    }

    func testStatusMenuActionsClosePaletteBeforeRunningCallback() {
        let cases: [(action: StatusMenuAction, event: String)] = [
            (.addPhrase, "add"),
            (.openSettings, "settings"),
            (.openMainWindow, "open"),
            (.quit, "quit")
        ]

        XCTAssertEqual(StatusMenuAction.allCases, cases.map(\.action))

        for testCase in cases {
            var events: [String] = []
            let dispatcher = StatusMenuActionDispatcher(
                closePalette: {
                    events.append("close")
                },
                onAddPhrase: {
                    events.append("add")
                },
                onOpenSettings: {
                    events.append("settings")
                },
                onOpenMainWindow: {
                    events.append("open")
                },
                onQuit: {
                    events.append("quit")
                }
            )

            dispatcher.perform(testCase.action)

            XCTAssertEqual(events, ["close", testCase.event])
        }
    }

    func testStatusMenuFooterItemsMatchFigmaOrderAndActions() {
        let items = StatusMenuFooterItem.items(language: .english)

        XCTAssertEqual(items.map(\.action), [.openSettings, .openMainWindow, .quit])
        XCTAssertEqual(items.map(\.title), ["Settings", "Open Lazy Quips", "Quit"])
        XCTAssertEqual(items.map(\.accessibilityIdentifier), [
            "lazyquips.palette.footer.settingsButton",
            "lazyquips.palette.footer.openMainWindowButton",
            "lazyquips.palette.footer.quitButton"
        ])
        XCTAssertEqual(items.map(\.buttonWidth), [nil, StatusMenuLayout.openMainWindowButtonWidth, nil])
    }

    func testStatusMenuFooterPlainButtonsUseStableHitTargets() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let styleRange = try XCTUnwrap(paletteSource.range(of: "private struct StatusMenuFooterButtonStyle"))
        let sectionRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteSectionView"))
        let styleSource = String(paletteSource[styleRange.lowerBound..<sectionRange.lowerBound])

        XCTAssertTrue(styleSource.contains("content.buttonStyle(.plain)"))
        XCTAssertTrue(styleSource.contains("StatusMenuLayout.footerPlainButtonMinWidth"))
        XCTAssertTrue(styleSource.contains("StatusMenuLayout.footerPlainButtonHeight"))
        XCTAssertTrue(styleSource.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(styleSource.contains("LazyQuipsToolbarButtonStyle("))
        XCTAssertTrue(styleSource.contains("usesLiquidGlass: true"))
    }

    func testStatusMenuToolbarUsesSharedControlSurfaceWithoutGlassOnSearchOrAdd() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let toolbarRange = try XCTUnwrap(paletteSource.range(of: "private func toolbar(snapshot: PhrasePaletteSnapshot)"))
        let headerRange = try XCTUnwrap(paletteSource.range(of: "private var header: some View"))
        let toolbarSource = String(paletteSource[toolbarRange.lowerBound..<headerRange.lowerBound])

        XCTAssertTrue(toolbarSource.contains("LazyQuipsToolbarButtonStyle("))
        XCTAssertTrue(toolbarSource.contains(".lazyQuipsToolbarControlSurface()"))
        XCTAssertTrue(toolbarSource.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(toolbarSource.contains(".simultaneousGesture(TapGesture().onEnded {"))
        XCTAssertTrue(toolbarSource.contains("isSearchFocused = true"))
        XCTAssertFalse(toolbarSource.contains("usesLiquidGlass: true"))
        XCTAssertFalse(paletteSource.contains("private struct PhrasePaletteToolbarButtonStyle"))
    }

    func testStatusMenuPreferredHeightAdaptsAndCapsAtMaximum() {
        XCTAssertEqual(
            StatusMenuLayout.preferredHeight(for: []),
            StatusMenuLayout.toolbarHeight
                + StatusMenuLayout.headerHeight
                + StatusMenuLayout.minimumContentHeight
                + StatusMenuLayout.footerHeight,
            accuracy: 0.5
        )

        let phrases = (0..<24).map { index in
            Phrase(shortcut: "item\(index)", body: "Phrase \(index)")
        }
        let sections = PhrasePaletteData.sections(
            for: "",
            phrases: phrases,
            usageStats: []
        )

        XCTAssertEqual(
            StatusMenuLayout.preferredHeight(for: sections),
            StatusMenuLayout.maximumHeight,
            accuracy: 0.5
        )
    }

    func testStatusMenuPreferredHeightUsesNaturalHeightBetweenMinimumAndMaximum() {
        let phrases = (0..<4).map { index in
            Phrase(shortcut: "item\(index)", body: "Phrase \(index)")
        }
        let rows = phrases.map { phrase in
            PhrasePaletteRow(
                id: PhrasePaletteRowID(sectionID: .all, phraseID: phrase.id),
                phrase: phrase,
                mayNeedSubmenu: PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(phrase.body)
            )
        }
        let sections = [
            PhrasePaletteSection(
                id: .all,
                title: "All",
                showsTitle: true,
                isSelectable: true,
                rows: rows
            )
        ]
        let naturalContentHeight = StatusMenuLayout.sectionTitleHeight
            + (CGFloat(rows.count) * StatusMenuLayout.rowHeight)
            + (CGFloat(rows.count - 1) * StatusMenuLayout.rowVerticalSpacing)
            + StatusMenuLayout.sectionBottomPadding
        let expectedHeight = StatusMenuLayout.toolbarHeight
            + StatusMenuLayout.headerHeight
            + naturalContentHeight
            + StatusMenuLayout.footerHeight

        XCTAssertGreaterThan(naturalContentHeight, StatusMenuLayout.minimumContentHeight)
        XCTAssertLessThan(naturalContentHeight, StatusMenuLayout.maximumContentHeight)
        XCTAssertEqual(
            StatusMenuLayout.preferredHeight(for: sections),
            expectedHeight,
            accuracy: 0.5
        )

        let hiddenTitleSections = [
            PhrasePaletteSection(
                id: .all,
                title: "All",
                showsTitle: false,
                isSelectable: true,
                rows: rows
            )
        ]
        XCTAssertEqual(
            StatusMenuLayout.preferredHeight(for: hiddenTitleSections),
            expectedHeight - StatusMenuLayout.sectionTitleHeight,
            accuracy: 0.5
        )
    }

    func testStatusMenuNavigationItemsTargetStarSectionAndAllRows() {
        let starred = Phrase(shortcut: "apple", body: "Starred phrase.", isStarred: true)
        let digit = Phrase(shortcut: "2fa", body: "Use the backup code.")
        let beta = Phrase(shortcut: "beta", body: "Plain phrase.")
        let phrases = [starred, digit, beta]
        let paletteSections = PhrasePaletteData.sections(
            for: "",
            phrases: phrases,
            usageStats: []
        )
        let displayedPhrases = PhrasePaletteData.displayedPhrases(
            for: "",
            phrases: phrases,
            usageStats: []
        )

        let items = PhrasePaletteNavigationItem.items(
            displayedPhrases: displayedPhrases,
            paletteSections: paletteSections,
            hasSearchText: false
        )

        XCTAssertEqual(items.map(\.title), ["Star", "0", "A", "B"])
        XCTAssertEqual(items.map(\.target), [
            .section(.starred),
            .row(PhrasePaletteRowID(sectionID: .all, phraseID: digit.id)),
            .row(PhrasePaletteRowID(sectionID: .all, phraseID: starred.id)),
            .row(PhrasePaletteRowID(sectionID: .all, phraseID: beta.id))
        ])
    }

    func testStatusMenuNavigationItemsTargetAllRowsDuringSearch() {
        let starred = Phrase(shortcut: "apple", body: "Starred phrase.", isStarred: true)
        let beta = Phrase(shortcut: "beta", body: "Plain phrase.")
        let phrases = [starred, beta]
        let paletteSections = PhrasePaletteData.sections(
            for: "apple",
            phrases: phrases,
            usageStats: []
        )
        let displayedPhrases = PhrasePaletteData.displayedPhrases(
            for: "apple",
            phrases: phrases,
            usageStats: []
        )

        let items = PhrasePaletteNavigationItem.items(
            displayedPhrases: displayedPhrases,
            paletteSections: paletteSections,
            hasSearchText: true
        )

        XCTAssertEqual(items.map(\.title), ["Star", "A"])
        XCTAssertEqual(items.map(\.target), [
            .row(PhrasePaletteRowID(sectionID: .all, phraseID: starred.id)),
            .row(PhrasePaletteRowID(sectionID: .all, phraseID: starred.id))
        ])
    }

    func testPhrasePaletteTextMetricsShowsSubmenuOnlyWhenPreviewExceedsTwoLines() {
        XCTAssertFalse(PhrasePaletteTextMetrics.needsSubmenu("Short phrase."))
        XCTAssertFalse(PhrasePaletteTextMetrics.needsSubmenu(""))
        XCTAssertFalse(PhrasePaletteTextMetrics.needsSubmenu("First line.\nSecond line."))
        XCTAssertFalse(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement("Short phrase."))
        XCTAssertFalse(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(""))
        XCTAssertTrue(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement("First line.\nSecond line."))

        let longBody = String(repeating: "必须联网搜索主流产品", count: 8)
        let threeLineBody = "First line.\nSecond line.\nThird line."
        let wrappedTwoLineBody = "First line.\n" + String(repeating: "A longer second line ", count: 8)

        XCTAssertTrue(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(longBody))
        XCTAssertTrue(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(threeLineBody))
        XCTAssertTrue(PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(wrappedTwoLineBody))
        XCTAssertTrue(PhrasePaletteTextMetrics.needsSubmenu(longBody))
        XCTAssertTrue(PhrasePaletteTextMetrics.needsSubmenu(threeLineBody))
        XCTAssertTrue(PhrasePaletteTextMetrics.needsSubmenu(wrappedTwoLineBody))
        XCTAssertGreaterThan(
            PhrasePaletteTextMetrics.submenuHeight(for: longBody),
            StatusMenuLayout.rowHeight
        )
        XCTAssertLessThanOrEqual(
            PhrasePaletteTextMetrics.submenuHeight(for: longBody),
            StatusMenuLayout.maximumHeight
        )

        let compactMenuHeight = StatusMenuLayout.toolbarHeight
            + StatusMenuLayout.headerHeight
            + StatusMenuLayout.minimumContentHeight
            + StatusMenuLayout.footerHeight

        XCTAssertLessThanOrEqual(
            PhrasePaletteTextMetrics.submenuHeight(for: longBody, menuHeight: compactMenuHeight),
            compactMenuHeight
        )
        XCTAssertLessThanOrEqual(
            PhrasePaletteTextMetrics.submenuBodyHeight(for: longBody, menuHeight: compactMenuHeight),
            compactMenuHeight
                - (StatusMenuLayout.submenuVerticalPadding * 2)
                - StatusMenuLayout.submenuShortcutHeight
                - StatusMenuLayout.submenuBodyTopPadding
        )
    }

    func testPhrasePaletteTextMetricsCacheInvalidatesWithContentRevision() {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let phrase = Phrase(
            shortcut: "body",
            body: "Short body.",
            updatedAt: updatedAt
        )
        let cache = PhrasePaletteTextMetrics.Cache()
        let initialBodyHeight = cache.submenuBodyHeight(for: phrase)

        XCTAssertFalse(cache.needsSubmenu(for: phrase))

        phrase.update(
            shortcut: "body",
            body: String(repeating: "Long submenu body segment ", count: 40),
            updatedAt: updatedAt
        )

        XCTAssertEqual(phrase.contentRevision, 1)
        XCTAssertTrue(cache.needsSubmenu(for: phrase))
        XCTAssertGreaterThan(cache.submenuBodyHeight(for: phrase), initialBodyHeight)
    }

    func testStatusMenuPanelPlacementReservesSubmenuSpaceBeforePanelExpands() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1_200, height: 900)
        let anchorRect = NSRect(x: 980, y: 850, width: 24, height: 22)
        let panelSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.width, height: 600)
        )

        let frame = StatusMenuPanelPlacement.panelFrame(
            anchorRect: anchorRect,
            contentSize: panelSize,
            reservedWidth: StatusMenuLayout.maximumPanelWidth,
            screenVisibleFrame: screenFrame
        )
        let visibleFrame = StatusMenuLayout.visibleContentFrame(inPanelFrame: frame)

        XCTAssertEqual(frame.minX, 399, accuracy: 0.5)
        XCTAssertEqual(visibleFrame.maxY, anchorRect.minY - StatusMenuLayout.panelAnchorGap, accuracy: 0.5)
        XCTAssertEqual(frame.width, StatusMenuLayout.defaultPanelWindowContentSize.width, accuracy: 0.5)
        XCTAssertEqual(frame.minX + StatusMenuLayout.maximumPanelWindowWidth, screenFrame.maxX, accuracy: 0.5)
        XCTAssertEqual(visibleFrame.width, StatusMenuLayout.width, accuracy: 0.5)
    }

    func testStatusMenuPanelPlacementDoesNotShiftWhenRightSideFits() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1_400, height: 900)
        let anchorRect = NSRect(x: 400, y: 850, width: 24, height: 22)
        let panelSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.width, height: 600)
        )

        let frame = StatusMenuPanelPlacement.panelFrame(
            anchorRect: anchorRect,
            contentSize: panelSize,
            reservedWidth: StatusMenuLayout.maximumPanelWidth,
            screenVisibleFrame: screenFrame
        )
        let visibleFrame = StatusMenuLayout.visibleContentFrame(inPanelFrame: frame)

        XCTAssertEqual(
            frame.minX,
            anchorRect.midX - (StatusMenuLayout.width / 2) - StatusMenuLayout.chromePadding,
            accuracy: 0.5
        )
        XCTAssertEqual(visibleFrame.minX, anchorRect.midX - (StatusMenuLayout.width / 2), accuracy: 0.5)
        XCTAssertEqual(frame.width, StatusMenuLayout.defaultPanelWindowContentSize.width, accuracy: 0.5)
    }

    func testStatusMenuPanelPlacementKeepsLeftEdgeOnNarrowScreens() {
        let screenFrame = NSRect(x: 0, y: 0, width: 700, height: 900)
        let anchorRect = NSRect(x: 260, y: 850, width: 24, height: 22)
        let panelSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.width, height: 600)
        )

        let frame = StatusMenuPanelPlacement.panelFrame(
            anchorRect: anchorRect,
            contentSize: panelSize,
            reservedWidth: StatusMenuLayout.maximumPanelWidth,
            screenVisibleFrame: screenFrame
        )

        XCTAssertEqual(frame.minX, screenFrame.minX, accuracy: 0.5)
        XCTAssertEqual(frame.width, StatusMenuLayout.defaultPanelWindowContentSize.width, accuracy: 0.5)
    }

    func testStatusMenuPanelPlacementKeepsVisibleTopLeadingWhenPanelExpands() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1_400, height: 900)
        let compactFrame = NSRect(
            x: 160,
            y: 200,
            width: StatusMenuLayout.defaultPanelWindowContentSize.width,
            height: StatusMenuLayout.panelWindowContentSize(
                for: CGSize(width: StatusMenuLayout.width, height: 600)
            ).height
        )
        let expandedSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.maximumPanelWidth, height: 600)
        )

        let expandedFrame = StatusMenuPanelPlacement.frameKeepingTopLeading(
            currentFrame: compactFrame,
            contentSize: expandedSize,
            screenVisibleFrame: screenFrame
        )

        XCTAssertEqual(
            StatusMenuLayout.visibleContentFrame(inPanelFrame: expandedFrame).minX,
            StatusMenuLayout.visibleContentFrame(inPanelFrame: compactFrame).minX,
            accuracy: 0.5
        )
        XCTAssertEqual(
            StatusMenuLayout.visibleContentFrame(inPanelFrame: expandedFrame).maxY,
            StatusMenuLayout.visibleContentFrame(inPanelFrame: compactFrame).maxY,
            accuracy: 0.5
        )
        XCTAssertEqual(expandedFrame.width, StatusMenuLayout.maximumPanelWindowWidth, accuracy: 0.5)
    }

    func testStatusMenuPanelHitTestingIgnoresChromePaddingAndTransparentSubmenuArea() {
        let contentSize = StatusMenuLayout.panelWindowContentSize(
            for: CGSize(width: StatusMenuLayout.maximumPanelWidth, height: 600)
        )
        let presentation = StatusMenuSubmenuPresentation(
            id: PhrasePaletteRowID(sectionID: .all, phraseID: UUID()),
            shortcut: "hello",
            body: "Long body",
            bodyHeight: 120,
            topOffset: 100,
            height: 200
        )

        XCTAssertTrue(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(
                    x: StatusMenuLayout.chromePadding + 20,
                    y: StatusMenuLayout.chromePadding + 20
                ),
                contentSize: contentSize,
                submenuPresentation: presentation
            )
        )
        XCTAssertTrue(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(
                    x: StatusMenuLayout.chromePadding + StatusMenuLayout.width + 20,
                    y: StatusMenuLayout.chromePadding + 350
                ),
                contentSize: contentSize,
                submenuPresentation: presentation
            )
        )
        XCTAssertFalse(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(
                    x: StatusMenuLayout.chromePadding + StatusMenuLayout.width + 20,
                    y: StatusMenuLayout.chromePadding + 550
                ),
                contentSize: contentSize,
                submenuPresentation: presentation
            )
        )
        XCTAssertFalse(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(
                    x: StatusMenuLayout.chromePadding + StatusMenuLayout.width + 20,
                    y: StatusMenuLayout.chromePadding + 100
                ),
                contentSize: contentSize,
                submenuPresentation: presentation
            )
        )
        XCTAssertFalse(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(
                    x: StatusMenuLayout.chromePadding + StatusMenuLayout.width + 20,
                    y: StatusMenuLayout.chromePadding + 350
                ),
                contentSize: contentSize,
                submenuPresentation: nil
            )
        )
        XCTAssertFalse(
            StatusMenuPanelHitTesting.containsVisibleSurface(
                point: NSPoint(x: 12, y: 12),
                contentSize: contentSize,
                submenuPresentation: presentation
            )
        )
    }

    func testStatusMenuPanelKeepsSubmenuInsideSameSwiftUIRoot() throws {
        let source = try sourceFileContent("lazyquips/App/StatusBarController.swift")
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")

        XCTAssertTrue(source.contains("StatusMenuPanelPlacement.panelFrame("))
        XCTAssertTrue(source.contains("StatusMenuPanelPlacement.frameKeepingTopLeading("))
        XCTAssertTrue(source.contains("StatusMenuPanelHitTesting.containsVisibleSurface("))
        XCTAssertTrue(paletteSource.contains("StatusMenuGlassSurfaceGroup"))
        XCTAssertTrue(paletteSource.contains("StatusMenuChromeSurface"))
        XCTAssertTrue(paletteSource.contains("StatusMenuChromeShape"))
        XCTAssertTrue(paletteSource.contains("StatusMenuLayout.chromePadding"))
        XCTAssertTrue(paletteSource.contains("StatusMenuLayout.chromeTopPadding"))
        XCTAssertTrue(paletteSource.contains("unifiedChromePath(mainRect: mainRect, submenuRect: submenuRect"))
        XCTAssertTrue(paletteSource.contains("path.addArc("))
        XCTAssertTrue(paletteSource.contains(".offset(x: StatusMenuLayout.width"))
        XCTAssertTrue(paletteSource.contains("width: StatusMenuLayout.maximumPanelWidth"))
        XCTAssertTrue(paletteSource.contains(".glassEffect(.regular, in: chromeShape)"))
        XCTAssertTrue(paletteSource.contains(".clipShape("))
        XCTAssertTrue(source.contains("panel.hasShadow = false"))
        XCTAssertTrue(paletteSource.contains("onSubmenuPresentationChange(activeSubmenuPresentation)"))
        XCTAssertTrue(paletteSource.contains("cancelSubmenuHover(closeActivePresentation: false)"))
        XCTAssertFalse(paletteSource.contains(
            "withAnimation(.easeInOut(duration: 0.12)) {\n            activeSubmenuPresentation = presentation"
        ))
        XCTAssertFalse(source.contains("NSPopover"))
        XCTAssertFalse(source.contains("StatusMenuSubmenuPlacement"))
        XCTAssertFalse(source.contains("addChildWindow"))
        XCTAssertFalse(paletteSource.contains("PhrasePaletteSubmenuPanelView"))
        XCTAssertFalse(paletteSource.contains("StatusMenuSurfaceStyle"))
        XCTAssertFalse(paletteSource.contains(".modifier(StatusMenuSurfaceStyle())"))
        XCTAssertFalse(paletteSource.contains("path.addRoundedRect(\n                in: submenuRect"))
        XCTAssertFalse(source.contains("didReserveSubmenuSpaceForCurrentPopover"))
        XCTAssertFalse(source.contains("setFrameOrigin(popoverOriginBeforeSubmenuReservation)"))
        XCTAssertFalse(source.contains("popoverOriginBeforeSubmenuReservation"))
    }

    func testStatusItemKeepsStableAutosaveNameAndOnlyRestoresHiddenState() throws {
        let source = try sourceFileContent("lazyquips/App/StatusBarController.swift")
        let createRange = try XCTUnwrap(source.range(of: "NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)"))
        let autosaveRange = try XCTUnwrap(source.range(of: "statusItem.autosaveName = StatusItemDefaults.autosaveName"))
        let visibleRestoreRange = try XCTUnwrap(source.range(of: "if !statusItem.isVisible {\n            statusItem.isVisible = true\n        }"))

        XCTAssertTrue(source.contains(#"static let autosaveName = "dev.lazyquips.public.statusItem""#))
        XCTAssertFalse(source.contains("NSStatusItem Preferred Position"))
        XCTAssertFalse(source.contains("seedInitialPreferredPositionIfNeeded"))
        XCTAssertFalse(source.contains("migrateLegacyRightmostPreferredPositionIfNeeded"))
        XCTAssertFalse(source.contains("private static let initialPreferredPosition = 0.0"))
        XCTAssertLessThan(createRange.lowerBound, autosaveRange.lowerBound)
        XCTAssertLessThan(autosaveRange.lowerBound, visibleRestoreRange.lowerBound)
    }

    func testStatusMenuReusesPaletteHostingControllerAndResetsPresentationState() throws {
        let source = try sourceFileContent("lazyquips/App/StatusBarController.swift")
        let appDelegateSource = try sourceFileContent("lazyquips/App/AppDelegate.swift")
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let refreshRange = try XCTUnwrap(source.range(of: "private func refreshPaletteContent()"))
        let updateRange = try XCTUnwrap(source.range(of: "private func updatePanelContentSize"))
        let refreshSource = String(source[refreshRange.lowerBound..<updateRange.lowerBound])
        let closeRange = try XCTUnwrap(source.range(of: "private func closePalette()"))
        let outsideClickRange = try XCTUnwrap(source.range(of: "private func startOutsideClickMonitor()"))
        let closeSource = String(source[closeRange.lowerBound..<outsideClickRange.lowerBound])
        let endPresentationRange = try XCTUnwrap(closeSource.range(of: "palettePresentationState.endPresentation()"))
        let orderOutRange = try XCTUnwrap(closeSource.range(of: "palettePanel?.orderOut(nil)"))
        let showRange = try XCTUnwrap(source.range(of: "private func showPalette()"))
        let refreshPaletteRange = try XCTUnwrap(source.range(of: "private func refreshPaletteContent()"))
        let showSource = String(source[showRange.lowerBound..<refreshPaletteRange.lowerBound])
        let noOpFrameRange = try XCTUnwrap(showSource.range(of: "if panel.frame.equalTo(panelFrame) {\n                    return\n                }"))
        let moveFrameRange = try XCTUnwrap(showSource.range(of: "panel.setFrameOrigin(panelFrame.origin)"))
        let resizeFrameRange = try XCTUnwrap(showSource.range(of: "panel.setFrame(panelFrame, display: false)"))

        XCTAssertTrue(source.contains("private let palettePresentationState = PhrasePalettePresentationState()"))
        XCTAssertTrue(source.contains("palettePresentationState.beginPresentation()"))
        XCTAssertTrue(source.contains("palettePresentationState.endPresentation()"))
        XCTAssertLessThan(endPresentationRange.lowerBound, orderOutRange.lowerBound)
        XCTAssertTrue(refreshSource.contains("guard panel.contentViewController == nil else"))
        XCTAssertTrue(refreshSource.contains("panel.contentViewController = NSHostingController("))
        XCTAssertTrue(refreshSource.contains("presentationState: palettePresentationState"))
        XCTAssertFalse(refreshSource.contains(".preferredColorScheme(appearanceStore.appearance.preferredColorScheme)"))
        XCTAssertTrue(source.contains("func prewarmPaletteContent()"))
        XCTAssertTrue(appDelegateSource.contains("statusBarController?.prewarmPaletteContent()"))
        XCTAssertTrue(appDelegateSource.contains("prewarmApplicationMenus()"))

        XCTAssertTrue(paletteSource.contains("final class PhrasePalettePresentationState: ObservableObject"))
        XCTAssertTrue(paletteSource.contains("@Published private(set) var dismissalID: PhrasePaletteDismissalID"))
        XCTAssertTrue(paletteSource.contains("struct PhrasePaletteDismissalID: Equatable"))
        XCTAssertTrue(paletteSource.contains("dismissalID = PhrasePaletteDismissalID(presentationID: presentationID)"))
        XCTAssertTrue(paletteSource.contains("func endPresentation()"))
        XCTAssertTrue(paletteSource.contains("@ObservedObject private var presentationState: PhrasePalettePresentationState"))
        XCTAssertTrue(paletteSource.contains(".onChange(of: presentationState.presentationID)"))
        XCTAssertTrue(paletteSource.contains(".onChange(of: presentationState.dismissalID)"))
        XCTAssertTrue(source.contains("override func cancelOperation(_ sender: Any?)"))
        XCTAssertTrue(source.contains("override func sendEvent(_ event: NSEvent)"))
        XCTAssertTrue(source.contains("event.type == .keyDown, event.keyCode == 53"))
        XCTAssertTrue(source.contains("panel.onCancelOperation = { [weak self] in"))
        XCTAssertTrue(paletteSource.contains("private func applyPresentationIfNeeded(_ presentationID: UUID)"))
        XCTAssertTrue(paletteSource.contains("private func resetForPresentation(presentationID: UUID)"))
        XCTAssertTrue(paletteSource.contains("private func resetAfterDismissal(for dismissalID: PhrasePaletteDismissalID)"))
        XCTAssertTrue(paletteSource.contains("guard appliedPresentationID == dismissalID.presentationID"))
        XCTAssertTrue(paletteSource.contains("private func resetAfterDismissal()"))
        XCTAssertTrue(paletteSource.contains("private func cancelTransientTasks()"))
        XCTAssertTrue(paletteSource.contains("feedbackTask = nil"))
        XCTAssertTrue(paletteSource.contains("closeAfterCopyTask = nil"))
        XCTAssertTrue(paletteSource.contains("submenuHoverTask = nil"))
        XCTAssertTrue(paletteSource.contains("submenuDismissTask = nil"))
        XCTAssertTrue(paletteSource.contains("let presentationID = presentationState.presentationID"))
        XCTAssertTrue(paletteSource.contains("let dismissalID = presentationState.dismissalID"))
        XCTAssertTrue(paletteSource.contains("presentationState.presentationID == presentationID"))
        XCTAssertTrue(paletteSource.contains("presentationState.dismissalID == dismissalID"))
        XCTAssertTrue(paletteSource.contains("private func clearTransientPresentationState()"))
        XCTAssertTrue(paletteSource.contains("private func scrollToTop(in snapshot: PhrasePaletteSnapshot, using proxy: ScrollViewProxy)"))
        XCTAssertTrue(paletteSource.contains("searchText = \"\""))
        XCTAssertTrue(paletteSource.contains("copiedRowID = nil"))
        XCTAssertTrue(paletteSource.contains("activeSubmenuPresentation = nil"))
        XCTAssertTrue(paletteSource.contains("submenuHoverState.cancel()"))
        XCTAssertTrue(paletteSource.contains("keyboardSubmenuRowID = nil"))
        XCTAssertFalse(paletteSource.contains("isSearchFocused = false"))
        XCTAssertTrue(paletteSource.contains("frozenSnapshotAfterCopy = nil"))
        XCTAssertFalse(paletteSource.contains("snapshotCache.invalidate()"))
        XCTAssertFalse(paletteSource.contains("func invalidate()"))
        XCTAssertTrue(paletteSource.contains("scrollToTop(in: snapshot, using: proxy)"))
        XCTAssertFalse(paletteSource.contains(".id(presentationState.presentationID)"))
        XCTAssertTrue(source.contains("panel.setFrame(panelFrame, display: false)"))
        XCTAssertLessThan(noOpFrameRange.lowerBound, moveFrameRange.lowerBound)
        XCTAssertLessThan(moveFrameRange.lowerBound, resizeFrameRange.lowerBound)
    }

    func testPhrasePalettePresentationStateSeparatesOpenAndCloseEvents() {
        let presentationState = PhrasePalettePresentationState()
        let initialPresentationID = presentationState.presentationID
        let initialDismissalID = presentationState.dismissalID

        presentationState.endPresentation()

        XCTAssertEqual(presentationState.presentationID, initialPresentationID)
        XCTAssertNotEqual(presentationState.dismissalID, initialDismissalID)
        XCTAssertEqual(presentationState.dismissalID.presentationID, initialPresentationID)

        presentationState.beginPresentation()
        let reopenedPresentationID = presentationState.presentationID

        XCTAssertNotEqual(reopenedPresentationID, initialPresentationID)
        XCTAssertEqual(presentationState.dismissalID.presentationID, initialPresentationID)

        presentationState.endPresentation()

        XCTAssertEqual(presentationState.dismissalID.presentationID, reopenedPresentationID)
    }

    func testPhrasePaletteSnapshotDerivesSearchSectionsRowsNavigationAndHeightTogether() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let snapshot = PhrasePaletteData.snapshot(
            for: "target",
            phrases: [plain, recent, starred, exact],
            usageStats: stats
        )

        XCTAssertTrue(snapshot.hasSearchText)
        XCTAssertEqual(snapshot.displayedPhrases.map(\.id), [exact.id, starred.id, recent.id, plain.id])
        XCTAssertEqual(snapshot.sections.map(\.id), [.all])
        XCTAssertEqual(snapshot.sections.map(\.showsTitle), [false])
        XCTAssertEqual(snapshot.selectableRows.map(\.phrase.id), snapshot.displayedPhrases.map(\.id))
        XCTAssertEqual(snapshot.selectableRowIDs, snapshot.selectableRows.map(\.id))
        for (index, row) in snapshot.selectableRows.enumerated() {
            XCTAssertEqual(snapshot.selectableRowByID[row.id]?.phrase.id, row.phrase.id)
            XCTAssertEqual(snapshot.selectableRowIndexByID[row.id], index)
        }
        XCTAssertEqual(snapshot.navigationItems.map(\.title), ["Star", "A", "B", "C", "T"])
        XCTAssertEqual(snapshot.navigationTitles, snapshot.navigationItems.map(\.title))
        XCTAssertEqual(
            snapshot.preferredContentHeight,
            StatusMenuLayout.preferredContentHeight(for: snapshot.sections),
            accuracy: 0.5
        )
        XCTAssertEqual(snapshot.preferredContentSize.width, StatusMenuLayout.width, accuracy: 0.5)
        XCTAssertEqual(snapshot.preferredHeight, StatusMenuLayout.preferredHeight(for: snapshot.sections), accuracy: 0.5)
        XCTAssertEqual(snapshot.preferredContentSize.height, snapshot.preferredHeight, accuracy: 0.5)
    }

    func testPhrasePaletteSnapshotCacheReusesSnapshotUntilInputsChange() {
        let phrase = Phrase(
            shortcut: "target",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let stats = PhraseUsageStats(
            phraseID: phrase.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_000_100),
            copyCount: 1
        )
        var buildCount = 0
        let cache = PhrasePaletteSnapshotCache { searchText, phrases, usageStats, sortedSearchIndexes in
            buildCount += 1
            return PhrasePaletteData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes
            )
        }

        _ = cache.snapshot(for: "target", phrases: [phrase], usageStats: [])
        _ = cache.snapshot(for: "target", phrases: [phrase], usageStats: [])

        XCTAssertEqual(buildCount, 1)

        _ = cache.snapshot(for: "body", phrases: [phrase], usageStats: [])

        XCTAssertEqual(buildCount, 2)

        _ = cache.snapshot(for: "body", phrases: [phrase], usageStats: [stats])
        _ = cache.snapshot(for: "body", phrases: [phrase], usageStats: [stats])

        XCTAssertEqual(buildCount, 3)

        phrase.update(
            shortcut: "target-updated",
            body: "Updated body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_200)
        )
        _ = cache.snapshot(for: "body", phrases: [phrase], usageStats: [stats])

        XCTAssertEqual(buildCount, 4)

        let other = Phrase(
            shortcut: "other",
            body: "Other body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_300)
        )
        _ = cache.snapshot(for: "body", phrases: [phrase, other], usageStats: [stats])

        XCTAssertEqual(buildCount, 5)

        phrase.setStarred(true, updatedAt: Date(timeIntervalSince1970: 1_700_000_400))
        _ = cache.snapshot(for: "body", phrases: [other, phrase], usageStats: [stats])

        XCTAssertEqual(buildCount, 6)

        stats.recordCopy(at: Date(timeIntervalSince1970: 1_700_000_500))
        _ = cache.snapshot(for: "body", phrases: [other, phrase], usageStats: [stats])

        XCTAssertEqual(buildCount, 7)
    }

    func testPhrasePaletteSnapshotCacheRefreshesBodyDerivedRowsWhenContentRevisionChanges() {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let phrase = Phrase(shortcut: "target", body: "Short body.", updatedAt: updatedAt)
        var buildCount = 0
        let cache = PhrasePaletteSnapshotCache { searchText, phrases, usageStats, sortedSearchIndexes in
            buildCount += 1
            return PhrasePaletteData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes
            )
        }

        let firstSnapshot = cache.snapshot(for: "", phrases: [phrase], usageStats: [])
        XCTAssertFalse(firstSnapshot.selectableRows.first?.mayNeedSubmenu ?? true)

        phrase.update(
            shortcut: "target",
            body: String(repeating: "Long body segment ", count: 80),
            updatedAt: updatedAt
        )
        let refreshedSnapshot = cache.snapshot(for: "", phrases: [phrase], usageStats: [])

        XCTAssertEqual(buildCount, 2)
        XCTAssertTrue(refreshedSnapshot.selectableRows.first?.mayNeedSubmenu ?? false)
    }

    func testPhrasePaletteSnapshotCacheSkipsSearchIndexesForEmptySearchText() {
        let beta = Phrase(
            shortcut: "beta",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let alpha = Phrase(
            shortcut: "alpha",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        var receivedSearchIndexCounts: [Int?] = []
        var receivedSortedSearchIndexIDs: [[UUID]?] = []
        let cache = PhrasePaletteSnapshotCache { searchText, phrases, usageStats, sortedSearchIndexes in
            receivedSearchIndexCounts.append(sortedSearchIndexes?.count)
            receivedSortedSearchIndexIDs.append(sortedSearchIndexes?.map(\.phrase.id))
            return PhrasePaletteData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes
            )
        }

        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "   ", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [])

        XCTAssertEqual(receivedSearchIndexCounts, [nil, nil, 2])
        XCTAssertEqual(receivedSortedSearchIndexIDs, [nil, nil, [alpha.id, beta.id]])
    }

    func testPhrasePaletteSnapshotCachePrewarmsSearchIndexesWithoutChangingEmptySnapshot() {
        let beta = Phrase(
            shortcut: "beta",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let alpha = Phrase(
            shortcut: "alpha",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        var indexBuildCount = 0
        let searchIndexCache = PhraseSearchIndexCache { phrase in
            indexBuildCount += 1
            return PhraseSearchIndex(phrase: phrase)
        }
        var receivedSortedSearchIndexIDs: [[UUID]?] = []
        let cache = PhrasePaletteSnapshotCache(searchIndexCache: searchIndexCache) { searchText, phrases, usageStats, sortedSearchIndexes in
            receivedSortedSearchIndexIDs.append(sortedSearchIndexes?.map(\.phrase.id))
            return PhrasePaletteData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes
            )
        }

        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [])
        XCTAssertEqual(indexBuildCount, 0)

        cache.prewarmSearchIndexes(for: [beta, alpha])
        XCTAssertEqual(indexBuildCount, 2)

        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [])

        XCTAssertEqual(indexBuildCount, 2)
        XCTAssertEqual(receivedSortedSearchIndexIDs, [nil, [alpha.id, beta.id]])
    }

    func testPhraseLibrarySnapshotCacheReusesSnapshotAndSkipsSearchIndexesForEmptySearchText() {
        let beta = Phrase(
            shortcut: "beta",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let alpha = Phrase(
            shortcut: "alpha",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let stats = PhraseUsageStats(
            phraseID: beta.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_000_100),
            copyCount: 1
        )
        var buildCount = 0
        var receivedSortedSearchIndexIDs: [[UUID]?] = []
        let cache = PhraseLibrarySnapshotCache { searchText, phrases, usageStats, sortedSearchIndexes, previewText in
            buildCount += 1
            receivedSortedSearchIndexIDs.append(sortedSearchIndexes?.map(\.phrase.id))
            return PhraseLibraryDisplayData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes,
                previewText: previewText
            )
        }

        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [stats])
        _ = cache.snapshot(for: "   ", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "   ", phrases: [beta, alpha], usageStats: [stats])
        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [])
        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [stats])

        XCTAssertEqual(buildCount, 4)
        XCTAssertEqual(receivedSortedSearchIndexIDs, [nil, nil, [alpha.id, beta.id], [alpha.id, beta.id]])
    }

    func testPhraseLibrarySnapshotCachePrewarmsSearchIndexesWithoutChangingEmptySnapshot() {
        let beta = Phrase(
            shortcut: "beta",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let alpha = Phrase(
            shortcut: "alpha",
            body: "Target body",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        var indexBuildCount = 0
        var receivedSortedSearchIndexIDs: [[UUID]?] = []
        let cache = PhraseLibrarySnapshotCache(
            makeSnapshot: { searchText, phrases, usageStats, sortedSearchIndexes, previewText in
                receivedSortedSearchIndexIDs.append(sortedSearchIndexes?.map(\.phrase.id))
                return PhraseLibraryDisplayData.snapshot(
                    for: searchText,
                    phrases: phrases,
                    usageStats: usageStats,
                    sortedSearchIndexes: sortedSearchIndexes,
                    previewText: previewText
                )
            },
            makeSearchIndex: { phrase in
                indexBuildCount += 1
                return PhraseSearchIndex(phrase: phrase)
            }
        )

        _ = cache.snapshot(for: "", phrases: [beta, alpha], usageStats: [])
        XCTAssertEqual(indexBuildCount, 0)

        cache.prewarmSearchIndexes(for: [beta, alpha])
        XCTAssertEqual(indexBuildCount, 2)

        _ = cache.snapshot(for: "target", phrases: [beta, alpha], usageStats: [])

        XCTAssertEqual(indexBuildCount, 2)
        XCTAssertEqual(receivedSortedSearchIndexIDs, [nil, [alpha.id, beta.id]])
    }

    func testPhraseLibrarySnapshotCacheRefreshesPreviewWhenContentRevisionChanges() {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let phrase = Phrase(shortcut: "target", body: "Original body.", updatedAt: updatedAt)
        var buildCount = 0
        var previewBuildCount = 0
        let cache = PhraseLibrarySnapshotCache(
            makeSnapshot: { searchText, phrases, usageStats, sortedSearchIndexes, previewText in
                buildCount += 1
                return PhraseLibraryDisplayData.snapshot(
                    for: searchText,
                    phrases: phrases,
                    usageStats: usageStats,
                    sortedSearchIndexes: sortedSearchIndexes,
                    previewText: previewText
                )
            },
            makePreviewText: { phrase in
                previewBuildCount += 1
                return PhraseBodyPreview.text(for: phrase.body)
            }
        )

        let firstSnapshot = cache.snapshot(for: "", phrases: [phrase], usageStats: [])
        let searchSnapshot = cache.snapshot(for: "target", phrases: [phrase], usageStats: [])
        XCTAssertEqual(firstSnapshot.selectableRows.first?.previewText, "Original body.")
        XCTAssertEqual(searchSnapshot.selectableRows.first?.previewText, "Original body.")
        XCTAssertEqual(previewBuildCount, 1)

        phrase.update(
            shortcut: "target",
            body: "Edited body.",
            updatedAt: updatedAt
        )
        let refreshedSnapshot = cache.snapshot(for: "", phrases: [phrase], usageStats: [])

        XCTAssertEqual(buildCount, 3)
        XCTAssertEqual(previewBuildCount, 2)
        XCTAssertEqual(refreshedSnapshot.selectableRows.first?.previewText, "Edited body.")
    }

    func testPhraseSearchIndexCacheReusesIndexesAcrossQueryAndRecentChanges() {
        let phrase = Phrase(
            shortcut: ";thanks",
            body: "谢谢，我稍后确认。",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let stats = PhraseUsageStats(
            phraseID: phrase.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_000_100),
            copyCount: 1
        )
        var buildCount = 0
        let indexCache = PhraseSearchIndexCache { phrase in
            buildCount += 1
            return PhraseSearchIndex(phrase: phrase)
        }

        let firstIndexes = indexCache.indexes(for: [phrase])
        _ = PhraseSearch.search("xiexie", inPreparedIndexes: firstIndexes, usageStats: [])
        _ = PhraseSearch.search("xx", inPreparedIndexes: indexCache.indexes(for: [phrase]), usageStats: [stats])

        XCTAssertEqual(buildCount, 1)

        stats.recordCopy(at: Date(timeIntervalSince1970: 1_700_000_200))
        _ = PhraseSearch.search("xiexie", inPreparedIndexes: indexCache.indexes(for: [phrase]), usageStats: [stats])

        XCTAssertEqual(buildCount, 1)

        phrase.setStarred(true, updatedAt: Date(timeIntervalSince1970: 1_700_000_300))
        _ = indexCache.indexes(for: [phrase])

        XCTAssertEqual(buildCount, 1)

        phrase.updateShortcut(";updated", updatedAt: Date(timeIntervalSince1970: 1_700_000_400))
        _ = indexCache.indexes(for: [phrase])

        XCTAssertEqual(buildCount, 2)

        phrase.update(
            shortcut: ";updated",
            body: "感谢，我稍后确认。",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_500)
        )
        _ = indexCache.indexes(for: [phrase])

        XCTAssertEqual(buildCount, 3)
    }

    func testPhraseSearchIndexCacheReusesSortedIndexesAcrossQueries() {
        let beta = Phrase(
            shortcut: "beta",
            body: "Beta target.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let alpha = Phrase(
            shortcut: "alpha",
            body: "Alpha target.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        var buildCount = 0
        let indexCache = PhraseSearchIndexCache { phrase in
            buildCount += 1
            return PhraseSearchIndex(phrase: phrase)
        }

        let sortedIndexes = indexCache.sortedIndexes(for: [beta, alpha])
        _ = PhraseSearch.search("target", inSortedPreparedIndexes: sortedIndexes, usageStats: [])
        _ = PhraseSearch.search("alpha", inSortedPreparedIndexes: indexCache.sortedIndexes(for: [beta, alpha]), usageStats: [])
        _ = indexCache.indexes(for: [beta, alpha])

        XCTAssertEqual(buildCount, 2)
        XCTAssertEqual(sortedIndexes.map(\.phrase.id), [alpha.id, beta.id])

        beta.updateShortcut("aardvark", updatedAt: Date(timeIntervalSince1970: 1_700_000_200))
        let resortedIndexes = indexCache.sortedIndexes(for: [beta, alpha])

        XCTAssertEqual(buildCount, 3)
        XCTAssertEqual(resortedIndexes.map(\.phrase.id), [beta.id, alpha.id])
    }

    func testPhraseSearchIndexCacheReusesUnchangedPhraseIndexesAfterSinglePhraseChange() {
        let changed = Phrase(
            shortcut: "alpha",
            body: "Original target.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let unchanged = Phrase(
            shortcut: "beta",
            body: "Stable target.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        var builtPhraseIDs: [UUID] = []
        let indexCache = PhraseSearchIndexCache { phrase in
            builtPhraseIDs.append(phrase.id)
            return PhraseSearchIndex(phrase: phrase)
        }

        _ = indexCache.sortedIndexes(for: [changed, unchanged])
        XCTAssertEqual(builtPhraseIDs, [changed.id, unchanged.id])

        changed.setStarred(true, updatedAt: Date(timeIntervalSince1970: 1_700_000_200))
        _ = indexCache.sortedIndexes(for: [changed, unchanged])
        XCTAssertEqual(builtPhraseIDs, [changed.id, unchanged.id])

        changed.update(
            shortcut: "alpha",
            body: "Edited target.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_200)
        )
        let editedIndexes = indexCache.sortedIndexes(for: [changed, unchanged])

        XCTAssertEqual(builtPhraseIDs, [changed.id, unchanged.id, changed.id])
        XCTAssertEqual(
            PhraseSearch.search("edited", inSortedPreparedIndexes: editedIndexes, usageStats: []).map(\.id),
            [changed.id]
        )
        XCTAssertTrue(
            PhraseSearch.search("original", inSortedPreparedIndexes: editedIndexes, usageStats: []).isEmpty
        )
    }

    func testPhraseSearchUsesLiveStarStateWithCachedPreparedIndexes() {
        let alpha = Phrase(shortcut: "alpha", body: "Shared target.")
        let beta = Phrase(shortcut: "beta", body: "Shared target.")
        var buildCount = 0
        let indexCache = PhraseSearchIndexCache { phrase in
            buildCount += 1
            return PhraseSearchIndex(phrase: phrase)
        }

        let sortedIndexes = indexCache.sortedIndexes(for: [alpha, beta])
        XCTAssertEqual(
            PhraseSearch.search("target", inSortedPreparedIndexes: sortedIndexes, usageStats: []).map(\.id),
            [alpha.id, beta.id]
        )

        beta.setStarred(true, updatedAt: Date(timeIntervalSince1970: 1_700_000_100))
        let reusedIndexes = indexCache.sortedIndexes(for: [alpha, beta])

        XCTAssertEqual(buildCount, 2)
        XCTAssertEqual(reusedIndexes.map(\.phrase.id), [alpha.id, beta.id])
        XCTAssertEqual(
            PhraseSearch.search("target", inSortedPreparedIndexes: reusedIndexes, usageStats: []).map(\.id),
            [beta.id, alpha.id]
        )
    }

    func testPhrasePaletteSnapshotCacheKeyAvoidsSortingOnCacheHitPath() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let cacheRange = try XCTUnwrap(paletteSource.range(of: "final class PhrasePaletteSnapshotCache"))
        let keyRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteSnapshotCacheKey"))
        let cacheSource = String(paletteSource[cacheRange.lowerBound..<keyRange.lowerBound])
        let phraseSignatureRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePalettePhraseSignature"))
        let keySource = String(paletteSource[keyRange.lowerBound..<phraseSignatureRange.lowerBound])
        let hitCheckRange = try XCTUnwrap(cacheSource.range(of: "cachedKey?.matches("))
        let nextKeyRange = try XCTUnwrap(cacheSource.range(of: "let nextKey = PhrasePaletteSnapshotCacheKey("))

        XCTAssertTrue(cacheSource.contains("private let searchIndexCache: PhraseSearchIndexCache"))
        XCTAssertTrue(cacheSource.contains("searchIndexCache: PhraseSearchIndexCache = PhraseSearchIndexCache()"))
        XCTAssertTrue(cacheSource.contains("self.searchIndexCache = searchIndexCache"))
        XCTAssertTrue(cacheSource.contains("searchIndexCache.sortedIndexes(for: phrases)"))
        XCTAssertTrue(cacheSource.contains("? nil"))
        XCTAssertLessThan(hitCheckRange.lowerBound, nextKeyRange.lowerBound)
        XCTAssertFalse(cacheSource.contains("if cachedKey == nextKey"))
        XCTAssertTrue(keySource.contains("func matches("))
        XCTAssertTrue(keySource.contains("signature.matches(phrase)"))
        XCTAssertTrue(keySource.contains("signature.matches(usageStats)"))
        XCTAssertTrue(keySource.contains("self.phrases = phrases.map(PhrasePalettePhraseSignature.init)"))
        XCTAssertTrue(keySource.contains("self.usageStats = usageStats.map(PhrasePaletteUsageStatsSignature.init)"))
        XCTAssertFalse(keySource.contains(".sorted"))
        XCTAssertFalse(keySource.contains("uuidString"))
    }

    func testPhrasePaletteSnapshotStoresRepeatedBodyDerivedMetadata() throws {
        let source = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let contentRange = try XCTUnwrap(source.range(of: "private func content(snapshot: PhrasePaletteSnapshot)"))
        let reporterRange = try XCTUnwrap(source.range(of: "private func submenuPresentationReporter("))
        let contentSource = String(source[contentRange.lowerBound..<reporterRange.lowerBound])
        let snapshotRange = try XCTUnwrap(source.range(of: "struct PhrasePaletteSnapshot"))
        let cacheRange = try XCTUnwrap(source.range(of: "final class PhrasePaletteSnapshotCache"))
        let snapshotSource = String(source[snapshotRange.lowerBound..<cacheRange.lowerBound])

        XCTAssertTrue(source.contains("selectableRowIDs: selectableRows.map(\\.id)"))
        XCTAssertTrue(source.contains("selectableRowByID: selectableRowByID"))
        XCTAssertTrue(source.contains("selectableRowIndexByID: selectableRowIndexByID"))
        XCTAssertTrue(source.contains("navigationTitles: navigationItems.map(\\.title)"))
        XCTAssertTrue(source.contains("preferredContentHeight: preferredContentHeight"))
        XCTAssertTrue(source.contains("preferredContentSize: CGSize(width: StatusMenuLayout.width, height: preferredHeight)"))
        XCTAssertTrue(contentSource.contains("PhraseIndexView(titles: snapshot.navigationTitles"))
        XCTAssertFalse(contentSource.contains("navigationItems.map"))
        XCTAssertTrue(snapshotSource.contains("let selectableRowIDs: [PhrasePaletteRowID]"))
        XCTAssertTrue(snapshotSource.contains("let selectableRowByID: [PhrasePaletteRowID: PhrasePaletteRow]"))
        XCTAssertTrue(snapshotSource.contains("let selectableRowIndexByID: [PhrasePaletteRowID: Int]"))
        XCTAssertTrue(snapshotSource.contains("let navigationTitles: [String]"))
        XCTAssertTrue(snapshotSource.contains("let preferredContentHeight: CGFloat"))
        XCTAssertTrue(snapshotSource.contains("let preferredHeight: CGFloat"))
        XCTAssertTrue(snapshotSource.contains("let preferredContentSize: CGSize"))
        XCTAssertFalse(snapshotSource.contains("var selectableRowIDs"))
        XCTAssertFalse(snapshotSource.contains("var preferredContentHeight"))
        XCTAssertFalse(snapshotSource.contains("var preferredHeight"))
        XCTAssertFalse(snapshotSource.contains("var preferredContentSize"))
    }

    func testPhrasePaletteSubmenuHoverStateRequiresActivationAndCancelsStaleRows() {
        let firstID = PhrasePaletteRowID(sectionID: .all, phraseID: UUID())
        let secondID = PhrasePaletteRowID(sectionID: .all, phraseID: UUID())
        var state = PhrasePaletteSubmenuHoverState()

        state.begin(rowID: firstID)

        XCTAssertEqual(state.pendingRowID, firstID)
        XCTAssertNil(state.activeRowID)

        state.activate(rowID: secondID)

        XCTAssertEqual(state.pendingRowID, firstID)
        XCTAssertNil(state.activeRowID)

        state.activate(rowID: firstID)

        XCTAssertNil(state.pendingRowID)
        XCTAssertEqual(state.activeRowID, firstID)

        state.end(rowID: secondID)

        XCTAssertEqual(state.activeRowID, firstID)

        state.end(rowID: firstID)

        XCTAssertNil(state.pendingRowID)
        XCTAssertNil(state.activeRowID)

        state.begin(rowID: firstID)
        state.activate(rowID: firstID)
        state.cancel()

        XCTAssertNil(state.pendingRowID)
        XCTAssertNil(state.activeRowID)
    }

    func testPhraseColumnHeadersMatchPhraseManagementContract() {
        let libraryHeaders = [
            PhraseColumnHeaderText.shortcut,
            PhraseColumnHeaderText.phrase
        ]
        let paletteDefaultHeaders = [
            PhraseColumnHeaderText.shortcut,
            PhraseColumnHeaderText.phrase
        ]
        let paletteSearchHeaders = [
            PhraseColumnHeaderText.shortcut,
            PhraseColumnHeaderText.phrase
        ]

        XCTAssertEqual(libraryHeaders, ["Shortcut", "Phrase"])
        XCTAssertEqual(paletteDefaultHeaders, ["Shortcut", "Phrase"])
        XCTAssertEqual(paletteSearchHeaders, ["Shortcut", "Phrase"])
    }

    func testAC027PrivacyBoundaryDoesNotUseClipboardReadersNetworkOrTypedInputMonitors() throws {
        let sources = try appSwiftSourceFiles()
        let allowedPasteboardWriterPath = "lazyquips/App/PasteboardWriter.swift"
        let forbiddenPatterns = [
            ForbiddenSourcePattern(
                pattern: #"NSPasteboard\.general"#,
                reason: "direct general pasteboard access must stay isolated in PasteboardWriter",
                allowedRelativePaths: [allowedPasteboardWriterPath]
            ),
            ForbiddenSourcePattern(
                pattern: #"NSPasteboard\s*=\s*\.general"#,
                reason: "default general pasteboard access must stay isolated in PasteboardWriter",
                allowedRelativePaths: [allowedPasteboardWriterPath]
            ),
            ForbiddenSourcePattern(
                pattern: #"\.clearContents\s*\("#,
                reason: "pasteboard writes must stay isolated in PasteboardWriter",
                allowedRelativePaths: [allowedPasteboardWriterPath]
            ),
            ForbiddenSourcePattern(
                pattern: #"\.setString\s*\("#,
                reason: "pasteboard writes must stay isolated in PasteboardWriter",
                allowedRelativePaths: [allowedPasteboardWriterPath]
            ),
            ForbiddenSourcePattern(
                pattern: #"\.string\s*\(\s*forType:"#,
                reason: "production code must not read existing pasteboard strings"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.readObjects\s*\("#,
                reason: "production code must not read existing pasteboard objects"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.pasteboardItems\b"#,
                reason: "production code must not inspect existing pasteboard items"
            ),
            ForbiddenSourcePattern(
                pattern: #"(NSPasteboard\.general|\bpasteboard)\.types\b"#,
                reason: "production code must not inspect existing pasteboard types"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.data\s*\(\s*forType:"#,
                reason: "production code must not read existing pasteboard data"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.propertyList\s*\(\s*forType:"#,
                reason: "production code must not read existing pasteboard property lists"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.availableType\s*\(\s*from:"#,
                reason: "production code must not inspect existing pasteboard types"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.canRead(Item|Object)\s*\("#,
                reason: "production code must not probe existing pasteboard readability"
            ),
            ForbiddenSourcePattern(
                pattern: #"\.changeCount\b"#,
                reason: "production code must not monitor pasteboard changes"
            ),
            ForbiddenSourcePattern(pattern: #"\bimport\s+Network\b"#, reason: "network framework is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bURLSession\b"#, reason: "network requests are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bURLRequest\b"#, reason: "network requests are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bNSURLConnection\b"#, reason: "network requests are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCFNetwork\b"#, reason: "network requests are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCFSocket\b"#, reason: "network sockets are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bNW(Connection|Listener|PathMonitor|Browser)\b"#, reason: "network APIs are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+WebKit\b"#, reason: "web views are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bWKWebView\b"#, reason: "web views are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+CloudKit\b"#, reason: "cloud sync is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCK(Container|Database|Record|SyncEngine)\b"#, reason: "CloudKit is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCloudKitDatabase\b"#, reason: "SwiftData CloudKit sync is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bcloudKitDatabase\s*:"#, reason: "SwiftData CloudKit sync is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bNSUbiquitousKeyValueStore\b"#, reason: "iCloud key-value sync is out of scope"),
            ForbiddenSourcePattern(pattern: #"\burl\s*\(\s*forUbiquityContainerIdentifier:"#, reason: "iCloud document container access is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+ScreenCaptureKit\b"#, reason: "screen recording is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bSC(Stream|ShareableContent|ContentFilter|StreamConfiguration|ScreenshotManager)\b"#, reason: "screen recording APIs are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCG(Request|Preflight)ScreenCaptureAccess\b"#, reason: "screen recording permission is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+AVFoundation\b"#, reason: "camera and microphone access are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bAVCapture(Device|Session|Input|Output)\b"#, reason: "camera and microphone capture APIs are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+Contacts\b"#, reason: "contacts access is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCN(Contact|ContactStore)\b"#, reason: "contacts access is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+EventKit\b"#, reason: "calendar and reminders access are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bEK(EventStore|Event|Reminder)\b"#, reason: "calendar and reminders access are out of scope"),
            ForbiddenSourcePattern(pattern: #"\bimport\s+CoreLocation\b"#, reason: "location access is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bCLLocationManager\b"#, reason: "location access is out of scope"),
            ForbiddenSourcePattern(pattern: #"\b(CGEventTapCreate|CGEvent\.tapCreate|CGEventMaskBit)\b"#, reason: "event taps would monitor typed content"),
            ForbiddenSourcePattern(pattern: #"\bkCGEvent(KeyDown|KeyUp|FlagsChanged)\b"#, reason: "key event taps would monitor typed content"),
            ForbiddenSourcePattern(pattern: #"\bCG(Request|Preflight)ListenEventAccess\b"#, reason: "input monitoring permission is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bAX(IsProcessTrusted(WithOptions)?|UIElement(Create(SystemWide|Application)?|Copy(Attribute(Value|Names)|ParameterizedAttributeValue)|SetAttributeValue)|Observer(Create|AddNotification|RemoveNotification)|Value)\b"#, reason: "reading current input UI is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bkAX(FocusedUIElement|SelectedText|Value)Attribute\b"#, reason: "reading current input UI is out of scope"),
            ForbiddenSourcePattern(pattern: #"\bIOHID(Manager|EventSystem)\b"#, reason: "low-level input monitoring is out of scope"),
            ForbiddenSourcePattern(pattern: #"(?s)NSEvent\.add(Global|Local)MonitorForEvents\s*\(.*?matching:\s*(\[[^\]]*\.(keyDown|keyUp|flagsChanged)|\.(keyDown|keyUp|flagsChanged))"#, reason: "keyboard event monitors would monitor typed content")
        ]

        let violations = sources.flatMap { source in
            forbiddenPatterns.compactMap { forbiddenPattern -> String? in
                guard !forbiddenPattern.allowedRelativePaths.contains(source.relativePath),
                      source.content.range(of: forbiddenPattern.pattern, options: .regularExpression) != nil
                else {
                    return nil
                }

                return "\(source.relativePath): \(forbiddenPattern.reason)"
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "AC-027 privacy boundary violations:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testAppearancePreferenceUsesSharedSwiftUIRootInjectionOnly() throws {
        let appDelegateSource = try sourceFileContent("lazyquips/App/AppDelegate.swift")
        XCTAssertTrue(appDelegateSource.contains("let appearanceStore: AppAppearanceStore"))
        XCTAssertTrue(appDelegateSource.contains("appearanceStore: appearanceStore"))

        let phraseLibrarySource = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        XCTAssertTrue(phraseLibrarySource.contains("@ObservedObject private var appearanceStore: AppAppearanceStore"))
        XCTAssertTrue(phraseLibrarySource.contains(".preferredColorScheme(appearanceStore.appearance.preferredColorScheme)"))
        XCTAssertTrue(phraseLibrarySource.contains("SettingsOverlayView"))
        XCTAssertTrue(phraseLibrarySource.contains("settingsOverlay"))
        XCTAssertTrue(phraseLibrarySource.contains(".disabled(isModalOverlayPresented)"))
        XCTAssertTrue(phraseLibrarySource.contains(".accessibilityHidden(isModalOverlayPresented)"))
        XCTAssertTrue(phraseLibrarySource.contains("actionErrorKey"))
        XCTAssertTrue(phraseLibrarySource.contains(".transition(.opacity)\n                    .accessibilityHidden(isModalOverlayPresented)"))

        let settingsSource = try sourceFileContent("lazyquips/App/LaunchAtLoginSettingsView.swift")
        XCTAssertTrue(settingsSource.contains("struct SettingsContentView: View"))
        XCTAssertTrue(settingsSource.contains("@ObservedObject var appearanceStore: AppAppearanceStore"))
        XCTAssertTrue(settingsSource.contains(".preferredColorScheme(appearanceStore.appearance.preferredColorScheme)"))

        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        XCTAssertTrue(paletteSource.contains("@ObservedObject private var appearanceStore: AppAppearanceStore"))
        XCTAssertTrue(paletteSource.contains(".preferredColorScheme(appearanceStore.appearance.preferredColorScheme)"))

        let statusBarSource = try sourceFileContent("lazyquips/App/StatusBarController.swift")
        XCTAssertTrue(statusBarSource.contains("private let appearanceStore: AppAppearanceStore"))
        XCTAssertTrue(statusBarSource.contains("appearanceStore: appearanceStore"))
        XCTAssertTrue(statusBarSource.contains("palettePresentationState.beginPresentation()"))
        XCTAssertTrue(statusBarSource.contains("panel.makeKeyAndOrderFront(nil)"))
        XCTAssertFalse(statusBarSource.contains(".preferredColorScheme(appearanceStore.appearance.preferredColorScheme)"))

        for source in try appSwiftSourceFiles() {
            XCTAssertFalse(source.content.contains("NSApp.appearance"), source.relativePath)
            XCTAssertFalse(source.content.contains("NSPopover.appearance"), source.relativePath)
            XCTAssertFalse(source.content.contains(#"environment(\.colorScheme"#), source.relativePath)
        }
    }

    func testInMemorySwiftDataStoresPhraseAndUsageStats() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Phrase.self,
            PhraseUsageStats.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let phraseID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let copiedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let phrase = Phrase(
            id: phraseID,
            shortcut: "  THANKS  ",
            body: "Thanks, I will check and get back to you.",
            isStarred: true,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let usageStats = PhraseUsageStats(
            phraseID: phraseID,
            lastCopiedAt: copiedAt,
            copyCount: 2
        )

        context.insert(phrase)
        context.insert(usageStats)
        try context.save()

        let phrases = try context.fetch(FetchDescriptor<Phrase>())
        let stats = try context.fetch(FetchDescriptor<PhraseUsageStats>())

        XCTAssertEqual(phrases.count, 1)
        XCTAssertEqual(phrases.first?.id, phraseID)
        XCTAssertEqual(phrases.first?.shortcut, "  THANKS  ")
        XCTAssertEqual(phrases.first?.normalizedShortcut, "thanks")
        XCTAssertEqual(phrases.first?.body, "Thanks, I will check and get back to you.")
        XCTAssertEqual(phrases.first?.isStarred, true)
        XCTAssertEqual(phrases.first?.createdAt, createdAt)
        XCTAssertEqual(phrases.first?.updatedAt, createdAt)
        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.first?.phraseID, phraseID)
        XCTAssertEqual(stats.first?.lastCopiedAt, copiedAt)
        XCTAssertEqual(stats.first?.copyCount, 2)
    }

    func testPhraseUpdateShortcutKeepsNormalizedShortcutInSync() {
        let phrase = Phrase(shortcut: "Thanks", body: "Thanks.")
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_200)

        phrase.updateShortcut("  ＡＧＨ  ", updatedAt: updatedAt)

        XCTAssertEqual(phrase.shortcut, "  ＡＧＨ  ")
        XCTAssertEqual(phrase.normalizedShortcut, "agh")
        XCTAssertEqual(phrase.updatedAt, updatedAt)
    }

    func testPhraseContentRevisionTracksPhraseContentOnly() {
        let phrase = Phrase(shortcut: "Thanks", body: "Thanks.")

        XCTAssertEqual(phrase.contentRevision, 0)

        phrase.setStarred(true, updatedAt: Date(timeIntervalSince1970: 1_700_000_100))
        XCTAssertEqual(phrase.contentRevision, 0)

        phrase.updateShortcut("Thanks", updatedAt: Date(timeIntervalSince1970: 1_700_000_200))
        XCTAssertEqual(phrase.contentRevision, 0)

        phrase.updateShortcut("Followup", updatedAt: Date(timeIntervalSince1970: 1_700_000_300))
        XCTAssertEqual(phrase.contentRevision, 1)

        phrase.update(
            shortcut: "Followup",
            body: "Thanks.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_400)
        )
        XCTAssertEqual(phrase.contentRevision, 1)

        phrase.update(
            shortcut: "Followup",
            body: "Edited body.",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_400)
        )
        XCTAssertEqual(phrase.contentRevision, 2)
    }

    func testPhraseValidatorTrimsInputAndRejectsInvalidShortcuts() throws {
        let existingID = UUID()
        let existingPhrase = Phrase(
            id: existingID,
            shortcut: "Thanks",
            body: "Thanks, I will check."
        )
        let validator = PhraseValidator()

        let validated = try validator.validate(
            shortcut: "  thanks  ",
            body: "\nUpdated body.  ",
            existingPhrases: [existingPhrase],
            editingPhraseID: existingID
        )

        XCTAssertEqual(validated.shortcut, "thanks")
        XCTAssertEqual(validated.normalizedShortcut, "thanks")
        XCTAssertEqual(validated.body, "\nUpdated body.  ")

        XCTAssertThrowsError(
            try validator.validate(shortcut: "   ", body: "Body", existingPhrases: [])
        ) { error in
            XCTAssertEqual(error as? PhraseValidationError, .shortcutRequired)
        }

        XCTAssertThrowsError(
            try validator.validate(shortcut: "agh", body: " \n ", existingPhrases: [])
        ) { error in
            XCTAssertEqual(error as? PhraseValidationError, .bodyRequired)
        }

        XCTAssertThrowsError(
            try validator.validate(
                shortcut: " ＴＨＡＮＫＳ ",
                body: "Duplicate body.",
                existingPhrases: [existingPhrase]
            )
        ) { error in
            XCTAssertEqual(error as? PhraseValidationError, .duplicateShortcut)
        }
    }

    func testPhraseValidationErrorsExposeUserFacingMessages() throws {
        let existingID = UUID()
        let existingPhrase = Phrase(
            id: existingID,
            shortcut: "agh",
            body: "A gentle heads-up."
        )
        let validator = PhraseValidator()

        for shortcut in ["", "   "] {
            XCTAssertThrowsError(
                try validator.validate(shortcut: shortcut, body: "Body", existingPhrases: [])
            ) { error in
                let validationError = error as? PhraseValidationError
                XCTAssertEqual(validationError, .shortcutRequired)
                XCTAssertEqual(validationError?.userFacingMessage, "Shortcut is required.")
            }
        }

        for body in ["", " \n "] {
            XCTAssertThrowsError(
                try validator.validate(shortcut: "agh", body: body, existingPhrases: [])
            ) { error in
                let validationError = error as? PhraseValidationError
                XCTAssertEqual(validationError, .bodyRequired)
                XCTAssertEqual(validationError?.userFacingMessage, "Phrase is required.")
            }
        }

        for duplicateShortcut in ["AGH", " ＡＧＨ "] {
            XCTAssertThrowsError(
                try validator.validate(
                    shortcut: duplicateShortcut,
                    body: "Duplicate body.",
                    existingPhrases: [existingPhrase]
                )
            ) { error in
                let validationError = error as? PhraseValidationError
                XCTAssertEqual(validationError, .duplicateShortcut)
                XCTAssertEqual(validationError?.userFacingMessage, "Shortcut already exists.")
            }
        }

        let validated = try validator.validate(
            shortcut: " AGH ",
            body: "Edited body.",
            existingPhrases: [existingPhrase],
            editingPhraseID: existingID
        )

        XCTAssertEqual(validated.shortcut, "AGH")
        XCTAssertEqual(validated.normalizedShortcut, "agh")
        XCTAssertEqual(validated.body, "Edited body.")
    }

    func testPhraseValidatorPreservesLongMultilineBody() throws {
        let body = (1...120)
            .map { "Line \($0): thanks, I will check and get back to you." }
            .joined(separator: "\n")
        let validator = PhraseValidator()

        let validated = try validator.validate(
            shortcut: "long",
            body: body,
            existingPhrases: []
        )

        XCTAssertEqual(validated.body, body)
    }

    func testPhraseRepositoryAddsEditsStarsDeletesAndCleansUsageStats() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let createdAt = Date(timeIntervalSince1970: 1_700_001_000)
        let editedAt = Date(timeIntervalSince1970: 1_700_001_100)
        let starredAt = Date(timeIntervalSince1970: 1_700_001_200)
        let copiedAt = Date(timeIntervalSince1970: 1_700_001_300)

        let phrase = try repository.add(
            shortcut: "  Thanks  ",
            body: "\nThanks, I will check. ",
            now: createdAt
        )

        XCTAssertEqual(phrase.shortcut, "Thanks")
        XCTAssertEqual(phrase.normalizedShortcut, "thanks")
        XCTAssertEqual(phrase.body, "\nThanks, I will check. ")
        XCTAssertEqual(phrase.createdAt, createdAt)
        XCTAssertEqual(phrase.updatedAt, createdAt)

        try repository.edit(
            phrase,
            shortcut: " ＡＧＨ ",
            body: "A gentle heads-up.",
            now: editedAt
        )

        XCTAssertEqual(phrase.shortcut, "ＡＧＨ")
        XCTAssertEqual(phrase.normalizedShortcut, "agh")
        XCTAssertEqual(phrase.body, "A gentle heads-up.")
        XCTAssertEqual(phrase.createdAt, createdAt)
        XCTAssertEqual(phrase.updatedAt, editedAt)

        try repository.star(phrase, now: starredAt)
        XCTAssertTrue(phrase.isStarred)
        XCTAssertEqual(phrase.updatedAt, starredAt)

        let stats = try repository.recordCopy(of: phrase, at: copiedAt)
        XCTAssertEqual(stats.phraseID, phrase.id)
        XCTAssertEqual(stats.copyCount, 1)
        XCTAssertEqual(stats.lastCopiedAt, copiedAt)

        try repository.delete(phrase)

        XCTAssertEqual(try context.fetch(FetchDescriptor<Phrase>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<PhraseUsageStats>()).count, 0)
    }

    func testPhraseRepositoryPreservesLongMultilineBodiesAcrossAddAndEdit() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let originalBody = (1...120)
            .map { "Original line \($0): thanks, I will check and get back to you." }
            .joined(separator: "\n")
        let editedBody = originalBody + "\nhttps://example.com/lazy-quips?copy=full"

        let phrase = try repository.add(shortcut: "long", body: originalBody)
        XCTAssertEqual(phrase.body, originalBody)

        try repository.edit(phrase, shortcut: "long", body: editedBody)

        let fetchedPhrase = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertEqual(fetchedPhrase.body, editedBody)
    }

    func testAddedPhraseAppearsInLibraryAndPaletteDataFromSameStore() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let phrase = try repository.add(
            shortcut: "ac009-sync",
            body: "AC-009 same store body result.",
            now: Date(timeIntervalSince1970: 1_700_001_400)
        )

        let phrases = try repository.fetchAll()
        let usageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let unfilteredLibrarySections = PhraseGrouping.sections(for: PhraseSearch.search("", in: phrases))
        let librarySections = PhraseGrouping.sections(for: PhraseSearch.search("ac009", in: phrases))

        XCTAssertEqual(phrases.map(\.id), [phrase.id])
        XCTAssertTrue(unfilteredLibrarySections.flatMap(\.phrases).contains { $0.id == phrase.id })
        XCTAssertTrue(librarySections.flatMap(\.phrases).contains { $0.id == phrase.id })
        XCTAssertTrue(usageStats.isEmpty)

        for searchText in ["ac009", "same store"] {
            let paletteSections = PhrasePaletteData.sections(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats
            )
            let selectableRows = PhrasePaletteData.selectableRows(in: paletteSections)
            let allRows = paletteSections.first { $0.id == .all }?.rows ?? []

            XCTAssertFalse(paletteSections.contains { $0.id == .recent })
            XCTAssertTrue(selectableRows.contains { $0.phrase.id == phrase.id })
            XCTAssertTrue(allRows.contains { $0.phrase.id == phrase.id })
        }
    }

    func testEditedAndDeletedPhraseUpdateLibraryAndPaletteDataFromSameStore() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let phrase = try repository.add(
            shortcut: "ac010-original",
            body: "Original body includes oldtoken.",
            now: Date(timeIntervalSince1970: 1_700_001_500)
        )

        try repository.recordCopy(of: phrase, at: Date(timeIntervalSince1970: 1_700_001_600))
        try repository.edit(
            phrase,
            shortcut: "ac010-edited",
            body: "Edited body includes newtoken.",
            now: Date(timeIntervalSince1970: 1_700_001_700)
        )

        let editedPhrases = try repository.fetchAll()
        let editedUsageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())

        XCTAssertEqual(editedPhrases.map(\.id), [phrase.id])
        XCTAssertEqual(editedUsageStats.map(\.phraseID), [phrase.id])

        for searchText in ["ac010-edited", "newtoken"] {
            let librarySections = PhraseGrouping.sections(for: PhraseSearch.search(searchText, in: editedPhrases))
            let paletteSections = PhrasePaletteData.sections(
                for: searchText,
                phrases: editedPhrases,
                usageStats: editedUsageStats
            )
            let selectableRows = PhrasePaletteData.selectableRows(in: paletteSections)

            XCTAssertTrue(librarySections.flatMap(\.phrases).contains { $0.id == phrase.id })
            XCTAssertTrue(selectableRows.contains { $0.phrase.id == phrase.id })
        }

        for searchText in ["ac010-original", "oldtoken"] {
            let librarySections = PhraseGrouping.sections(for: PhraseSearch.search(searchText, in: editedPhrases))
            let paletteSections = PhrasePaletteData.sections(
                for: searchText,
                phrases: editedPhrases,
                usageStats: editedUsageStats
            )

            XCTAssertTrue(librarySections.flatMap(\.phrases).isEmpty)
            XCTAssertTrue(PhrasePaletteData.selectableRows(in: paletteSections).isEmpty)
        }

        try repository.delete(phrase)

        let deletedPhrases = try repository.fetchAll()
        let deletedUsageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let librarySectionsAfterDelete = PhraseGrouping.sections(for: PhraseSearch.search("", in: deletedPhrases))
        let paletteSectionsAfterDelete = PhrasePaletteData.sections(
            for: "",
            phrases: deletedPhrases,
            usageStats: deletedUsageStats
        )

        XCTAssertTrue(librarySectionsAfterDelete.isEmpty)
        XCTAssertTrue(PhrasePaletteData.selectableRows(in: paletteSectionsAfterDelete).isEmpty)
        XCTAssertTrue(deletedUsageStats.isEmpty)
    }

    func testStarredPhraseUpdatesLibraryAndPaletteDataFromSameStore() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let phrase = try repository.add(
            shortcut: "apple",
            body: "Apple phrase.",
            now: Date(timeIntervalSince1970: 1_700_001_800)
        )

        let initialPhrases = try repository.fetchAll()
        let initialUsageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let initialLibrarySections = PhraseGrouping.sections(for: PhraseSearch.search("", in: initialPhrases))
        let initialPaletteSections = PhrasePaletteData.sections(
            for: "",
            phrases: initialPhrases,
            usageStats: initialUsageStats
        )

        XCTAssertFalse(initialLibrarySections.contains { $0.id == .starred })
        XCTAssertEqual(initialLibrarySections.first { $0.id == .letter("A") }?.phrases.map(\.id), [phrase.id])
        XCTAssertFalse(initialPaletteSections.contains { $0.id == .starred })
        XCTAssertEqual(initialPaletteSections.first { $0.id == .all }?.rows.map(\.phrase.id), [phrase.id])

        try repository.star(phrase, now: Date(timeIntervalSince1970: 1_700_001_900))

        let starredPhrases = try repository.fetchAll()
        let starredUsageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let starredLibrarySections = PhraseGrouping.sections(for: PhraseSearch.search("", in: starredPhrases))
        let starredPaletteSections = PhrasePaletteData.sections(
            for: "",
            phrases: starredPhrases,
            usageStats: starredUsageStats
        )

        XCTAssertEqual(starredLibrarySections.first { $0.id == .starred }?.phrases.map(\.id), [phrase.id])
        XCTAssertEqual(starredLibrarySections.first { $0.id == .letter("A") }?.phrases.map(\.id), [phrase.id])
        XCTAssertEqual(starredPaletteSections.first { $0.id == .starred }?.rows.map(\.phrase.id), [phrase.id])
        XCTAssertEqual(starredPaletteSections.first { $0.id == .all }?.rows.map(\.phrase.id), [phrase.id])

        try repository.unstar(phrase, now: Date(timeIntervalSince1970: 1_700_002_000))

        let unstarredPhrases = try repository.fetchAll()
        let unstarredUsageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let unstarredLibrarySections = PhraseGrouping.sections(for: PhraseSearch.search("", in: unstarredPhrases))
        let unstarredPaletteSections = PhrasePaletteData.sections(
            for: "",
            phrases: unstarredPhrases,
            usageStats: unstarredUsageStats
        )

        XCTAssertFalse(unstarredLibrarySections.contains { $0.id == .starred })
        XCTAssertEqual(unstarredLibrarySections.first { $0.id == .letter("A") }?.phrases.map(\.id), [phrase.id])
        XCTAssertFalse(unstarredPaletteSections.contains { $0.id == .starred })
        XCTAssertEqual(unstarredPaletteSections.first { $0.id == .all }?.rows.map(\.phrase.id), [phrase.id])
    }

    func testPhraseRepositoryRecordsCopyStatsAndReturnsRecentPhrases() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let first = try repository.add(shortcut: "first", body: "First body.")
        let second = try repository.add(shortcut: "second", body: "Second body.")
        let third = try repository.add(shortcut: "third", body: "Third body.")
        let firstCopiedAt = Date(timeIntervalSince1970: 1_700_002_000)
        let thirdCopiedAt = Date(timeIntervalSince1970: 1_700_002_100)
        let secondCopiedAt = Date(timeIntervalSince1970: 1_700_002_200)
        let firstCopiedAgainAt = Date(timeIntervalSince1970: 1_700_002_300)

        let firstStats = try repository.recordCopy(of: first, at: firstCopiedAt)
        try repository.recordCopy(of: third, at: thirdCopiedAt)
        try repository.recordCopy(of: second, at: secondCopiedAt)
        let firstStatsAgain = try repository.recordCopy(of: first, at: firstCopiedAgainAt)

        XCTAssertEqual(firstStats.id, firstStatsAgain.id)
        XCTAssertEqual(firstStatsAgain.copyCount, 2)
        XCTAssertEqual(firstStatsAgain.lastCopiedAt, firstCopiedAgainAt)

        let recent = try repository.recent(limit: 2)

        XCTAssertEqual(recent.map(\.phrase.id), [first.id, second.id])
        XCTAssertEqual(recent.map(\.stats.copyCount), [2, 1])
        XCTAssertTrue(try repository.recent(limit: 0).isEmpty)
    }

    func testRecentReflectsEditedPhraseAndRemovesDeletedPhrase() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let first = try repository.add(shortcut: "first", body: "First body.")
        let second = try repository.add(shortcut: "second", body: "Second body.")

        try repository.recordCopy(of: second, at: Date(timeIntervalSince1970: 1_700_004_000))
        try repository.recordCopy(of: first, at: Date(timeIntervalSince1970: 1_700_004_100))
        try repository.edit(first, shortcut: "first", body: "Updated first body.")

        let editedRecent = try repository.recent(limit: 2)
        XCTAssertEqual(editedRecent.map(\.phrase.id), [first.id, second.id])
        XCTAssertEqual(editedRecent.first?.phrase.body, "Updated first body.")

        try repository.delete(first)

        let remainingRecent = try repository.recent(limit: 2)
        XCTAssertEqual(remainingRecent.map(\.phrase.id), [second.id])
    }

    func testPhraseRepositoryRecentDeduplicatesUsageStatsByPhraseID() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let first = try repository.add(shortcut: "first", body: "First body.")
        let second = try repository.add(shortcut: "second", body: "Second body.")
        let olderFirstStats = PhraseUsageStats(
            phraseID: first.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_004_000),
            copyCount: 1
        )
        let secondStats = PhraseUsageStats(
            phraseID: second.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_004_100),
            copyCount: 1
        )
        let newerFirstStats = PhraseUsageStats(
            phraseID: first.id,
            lastCopiedAt: Date(timeIntervalSince1970: 1_700_004_200),
            copyCount: 4
        )

        context.insert(olderFirstStats)
        context.insert(secondStats)
        context.insert(newerFirstStats)
        try context.save()

        let recent = try repository.recent(limit: 2)

        XCTAssertEqual(recent.map(\.phrase.id), [first.id, second.id])
        XCTAssertEqual(recent.first?.stats.id, newerFirstStats.id)

        let copiedAt = Date(timeIntervalSince1970: 1_700_004_300)
        let updatedStats = try repository.recordCopy(of: first, at: copiedAt)
        let firstStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
            .filter { $0.phraseID == first.id }

        XCTAssertEqual(updatedStats.id, newerFirstStats.id)
        XCTAssertEqual(updatedStats.lastCopiedAt, copiedAt)
        XCTAssertEqual(updatedStats.copyCount, 5)
        XCTAssertEqual(firstStats.map(\.id), [newerFirstStats.id])
    }

    func testPhraseRepositoryRecordCopyFetchesOnlyTargetUsageStats() throws {
        let repositorySource = try sourceFileContent("lazyquips/App/Phrases/PhraseRepository.swift")
        let recordCopyRange = try XCTUnwrap(repositorySource.range(of: "func recordCopy(of phrase: Phrase"))
        let recentRange = try XCTUnwrap(repositorySource.range(of: "func recent(limit: Int = 2)"))
        let recordCopySource = String(repositorySource[recordCopyRange.lowerBound..<recentRange.lowerBound])

        XCTAssertTrue(recordCopySource.contains("try fetchUsageStats(for: phrase.id)"))
        XCTAssertTrue(repositorySource.contains("private func fetchUsageStats(for phraseID: UUID) throws -> [PhraseUsageStats]"))
        XCTAssertTrue(repositorySource.contains("FetchDescriptor<PhraseUsageStats>(\n                predicate: #Predicate"))
        XCTAssertTrue(repositorySource.contains("stats.phraseID == phraseID"))
        XCTAssertFalse(recordCopySource.contains("try fetchUsageStats().filter"))
    }

    func testPhrasePaletteSectionsMakeRecentRowsKeyboardSelectable() {
        let latest = Phrase(shortcut: "latest", body: "Latest body.")
        let older = Phrase(shortcut: "older", body: "Older body.")
        let untracked = Phrase(shortcut: "plain", body: "Plain body.")
        let stats = [
            PhraseUsageStats(
                phraseID: older.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_005_000)
            ),
            PhraseUsageStats(
                phraseID: latest.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_005_100)
            )
        ]

        let sections = PhrasePaletteData.sections(
            for: "",
            phrases: [untracked, older, latest],
            usageStats: stats
        )
        let selectableRows = PhrasePaletteData.selectableRows(in: sections)

        XCTAssertEqual(sections.first?.id, .recent)
        XCTAssertEqual(sections.first?.showsTitle, false)
        XCTAssertEqual(sections.first?.isSelectable, true)
        XCTAssertEqual(sections.first?.rows.map(\.phrase.id), [latest.id, older.id])
        XCTAssertEqual(
            selectableRows.first?.id,
            PhrasePaletteRowID(sectionID: .recent, phraseID: latest.id)
        )
    }

    func testPhrasePaletteSelectionDefaultsToFirstSelectableRow() {
        let rows = makePaletteRows([
            Phrase(shortcut: "first", body: "First body."),
            Phrase(shortcut: "second", body: "Second body.")
        ])
        let rowByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })

        XCTAssertEqual(
            PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: nil,
                selectableRows: rows,
                selectableRowByID: rowByID
            ),
            rows.first?.id
        )
    }

    func testPhrasePaletteSelectionMovesWithinSelectableRows() {
        let rows = makePaletteRows([
            Phrase(shortcut: "first", body: "First body."),
            Phrase(shortcut: "second", body: "Second body."),
            Phrase(shortcut: "third", body: "Third body.")
        ])
        let rowByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        let rowIndexByID = Dictionary(
            uniqueKeysWithValues: rows.enumerated().map { ($0.element.id, $0.offset) }
        )

        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[0].id,
                offset: 1,
                selectableRows: rows,
                selectableRowByID: rowByID,
                selectableRowIndexByID: rowIndexByID
            ),
            rows[1].id
        )
        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[2].id,
                offset: -1,
                selectableRows: rows,
                selectableRowByID: rowByID,
                selectableRowIndexByID: rowIndexByID
            ),
            rows[1].id
        )
    }

    func testPhrasePaletteSelectionMovementClampsAtEdges() {
        let rows = makePaletteRows([
            Phrase(shortcut: "first", body: "First body."),
            Phrase(shortcut: "second", body: "Second body."),
            Phrase(shortcut: "third", body: "Third body.")
        ])
        let rowByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        let rowIndexByID = Dictionary(
            uniqueKeysWithValues: rows.enumerated().map { ($0.element.id, $0.offset) }
        )

        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[0].id,
                offset: -1,
                selectableRows: rows,
                selectableRowByID: rowByID,
                selectableRowIndexByID: rowIndexByID
            ),
            rows[0].id
        )
        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[2].id,
                offset: 1,
                selectableRows: rows,
                selectableRowByID: rowByID,
                selectableRowIndexByID: rowIndexByID
            ),
            rows[2].id
        )
        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[1].id,
                offset: 10,
                selectableRows: rows,
                selectableRowByID: rowByID,
                selectableRowIndexByID: rowIndexByID
            ),
            rows[2].id
        )
    }

    func testPhrasePaletteSelectionAfterRowsChangeKeepsExistingSelection() {
        let rows = makePaletteRows([
            Phrase(shortcut: "first", body: "First body."),
            Phrase(shortcut: "second", body: "Second body."),
            Phrase(shortcut: "third", body: "Third body.")
        ])
        let changedRows = [rows[2], rows[1], rows[0]]
        let changedRowsByID = Dictionary(uniqueKeysWithValues: changedRows.map { ($0.id, $0) })

        XCTAssertEqual(
            PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: rows[1].id,
                selectableRows: changedRows,
                selectableRowByID: changedRowsByID
            ),
            rows[1].id
        )
    }

    func testPhrasePaletteSelectionFallsBackToFirstOrNilWhenCurrentDisappears() {
        let rows = makePaletteRows([
            Phrase(shortcut: "first", body: "First body."),
            Phrase(shortcut: "second", body: "Second body."),
            Phrase(shortcut: "third", body: "Third body.")
        ])
        let remainingRows = [rows[0], rows[2]]
        let remainingRowsByID = Dictionary(uniqueKeysWithValues: remainingRows.map { ($0.id, $0) })
        let remainingRowIndexesByID = Dictionary(
            uniqueKeysWithValues: remainingRows.enumerated().map { ($0.element.id, $0.offset) }
        )

        XCTAssertEqual(
            PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: rows[1].id,
                selectableRows: remainingRows,
                selectableRowByID: remainingRowsByID
            ),
            rows[0].id
        )
        XCTAssertEqual(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[1].id,
                offset: 1,
                selectableRows: remainingRows,
                selectableRowByID: remainingRowsByID,
                selectableRowIndexByID: remainingRowIndexesByID
            ),
            rows[0].id
        )
        XCTAssertNil(
            PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: rows[1].id,
                selectableRows: []
            )
        )
        XCTAssertNil(
            PhrasePaletteData.selectionByMoving(
                currentSelection: rows[1].id,
                offset: 1,
                selectableRows: []
            )
        )
    }

    func testPhrasePaletteSearchNoResultHasNoSelectableRowsOrRecent() {
        let phrase = Phrase(shortcut: "thanks", body: "Thanks, I will check.")
        let stats = [
            PhraseUsageStats(
                phraseID: phrase.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let sections = PhrasePaletteData.sections(
            for: "zzzz-no-match",
            phrases: [phrase],
            usageStats: stats
        )

        XCTAssertTrue(sections.isEmpty)
        XCTAssertTrue(PhrasePaletteData.selectableRows(in: sections).isEmpty)
    }

    func testPhrasePaletteWhitespaceSearchRestoresRecentStarAndAllSections() {
        let plain = Phrase(shortcut: "plain", body: "Plain body.")
        let recent = Phrase(shortcut: "recent", body: "Recent body.")
        let starred = Phrase(shortcut: "starred", body: "Starred body.", isStarred: true)
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_200)
            )
        ]
        let phrases = [plain, recent, starred]
        let emptySections = PhrasePaletteData.sections(
            for: "",
            phrases: phrases,
            usageStats: stats
        )

        let whitespaceSections = PhrasePaletteData.sections(
            for: " \n\t ",
            phrases: phrases,
            usageStats: stats
        )

        XCTAssertEqual(whitespaceSections.map(\.id), emptySections.map(\.id))
        XCTAssertEqual(
            whitespaceSections.map { $0.rows.map(\.phrase.id) },
            emptySections.map { $0.rows.map(\.phrase.id) }
        )
        XCTAssertEqual(whitespaceSections.map(\.id), [.recent, .starred, .all])
        XCTAssertEqual(whitespaceSections.map(\.showsTitle), [false, true, true])
        XCTAssertEqual(
            whitespaceSections.first { $0.id == .recent }?.rows.map(\.phrase.id),
            [recent.id]
        )
        XCTAssertEqual(
            whitespaceSections.first { $0.id == .starred }?.rows.map(\.phrase.id),
            [starred.id]
        )
        XCTAssertEqual(
            whitespaceSections.first { $0.id == .all }?.rows.map(\.phrase.id),
            [plain.id, recent.id, starred.id]
        )
    }

    func testPhrasePaletteSnapshotRowLookupKeepsDuplicatePhraseRowsDistinct() {
        let repeated = Phrase(shortcut: "starred", body: "Starred recent body.", isStarred: true)
        let stats = [
            PhraseUsageStats(
                phraseID: repeated.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_200)
            )
        ]
        let snapshot = PhrasePaletteData.snapshot(
            for: "",
            phrases: [repeated],
            usageStats: stats
        )
        let recentRowID = PhrasePaletteRowID(sectionID: .recent, phraseID: repeated.id)
        let starredRowID = PhrasePaletteRowID(sectionID: .starred, phraseID: repeated.id)
        let allRowID = PhrasePaletteRowID(sectionID: .all, phraseID: repeated.id)

        XCTAssertEqual(snapshot.selectableRowIDs, [recentRowID, starredRowID, allRowID])
        XCTAssertEqual(snapshot.selectableRowByID[recentRowID]?.id, recentRowID)
        XCTAssertEqual(snapshot.selectableRowByID[starredRowID]?.id, starredRowID)
        XCTAssertEqual(snapshot.selectableRowByID[allRowID]?.id, allRowID)
        XCTAssertEqual(snapshot.selectableRowIndexByID[recentRowID], 0)
        XCTAssertEqual(snapshot.selectableRowIndexByID[starredRowID], 1)
        XCTAssertEqual(snapshot.selectableRowIndexByID[allRowID], 2)
        XCTAssertEqual(Set(snapshot.selectableRowByID.keys), Set(snapshot.selectableRowIDs))
    }

    func testPhrasePaletteTrimmedSearchHidesRecentAndStarSections() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_300)
            )
        ]
        let phrases = [plain, recent, starred, exact]
        let sharedRank = PhraseSearch.search(
            "target",
            in: phrases,
            usageStats: stats
        )

        let sections = PhrasePaletteData.sections(
            for: " target \n",
            phrases: phrases,
            usageStats: stats
        )
        let selectableRows = PhrasePaletteData.selectableRows(in: sections)

        XCTAssertEqual(sections.map(\.id), [.all])
        XCTAssertEqual(sections.map(\.showsTitle), [false])
        XCTAssertFalse(sections.contains { $0.id == .recent })
        XCTAssertFalse(sections.contains { $0.id == .starred })
        XCTAssertEqual(selectableRows.map(\.phrase.id), sharedRank.map(\.id))
        XCTAssertEqual(selectableRows.map(\.phrase.id), [exact.id, starred.id, recent.id, plain.id])
    }

    func testPhraseEmptyStateTextDistinguishesEmptyLibraryNoResultsAndFallback() {
        XCTAssertEqual(
            PhraseEmptyStateText.title(isEmptyLibrary: true, hasSearchText: false),
            "No phrases yet."
        )
        XCTAssertEqual(
            PhraseEmptyStateText.title(isEmptyLibrary: false, hasSearchText: true),
            "No results."
        )
        XCTAssertEqual(
            PhraseEmptyStateText.title(isEmptyLibrary: false, hasSearchText: false),
            "No phrases."
        )
    }

    func testPhraseLibrarySearchNoResultProducesEmptySections() {
        let phrase = Phrase(shortcut: "thanks", body: "Thanks, I will check.")
        let snapshot = PhraseLibraryDisplayData.snapshot(
            for: "zzzz-no-match",
            phrases: [phrase],
            usageStats: []
        )

        XCTAssertTrue(snapshot.hasSearchText)
        XCTAssertTrue(snapshot.displayedPhrases.isEmpty)
        XCTAssertTrue(snapshot.sections.isEmpty)
        XCTAssertTrue(snapshot.selectableRows.isEmpty)
        XCTAssertTrue(snapshot.indexTitles.isEmpty)
        XCTAssertEqual(
            PhraseEmptyStateText.title(isEmptyLibrary: false, hasSearchText: true),
            "No results."
        )
    }

    func testPhraseLibraryNonEmptySearchUsesGlobalAllRankMatchingPopoverReference() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]
        let phrases = [plain, recent, starred, exact]

        let sharedRank = PhraseSearch.search(
            "target",
            in: phrases,
            usageStats: stats
        )
        let popoverSnapshot = PhrasePaletteData.snapshot(
            for: "target",
            phrases: phrases,
            usageStats: stats
        )
        let librarySnapshot = PhraseLibraryDisplayData.snapshot(
            for: "target",
            phrases: phrases,
            usageStats: stats
        )

        XCTAssertEqual(sharedRank.map(\.id), [exact.id, starred.id, recent.id, plain.id])
        XCTAssertEqual(popoverSnapshot.sections.map(\.id), [.all])
        XCTAssertEqual(popoverSnapshot.sections.map(\.showsTitle), [false])
        XCTAssertEqual(popoverSnapshot.selectableRows.map(\.phrase.id), sharedRank.map(\.id))
        XCTAssertEqual(popoverSnapshot.selectableRows.first?.phrase.id, exact.id)
        XCTAssertTrue(librarySnapshot.hasSearchText)
        XCTAssertEqual(librarySnapshot.displayedPhrases.map(\.id), sharedRank.map(\.id))
        XCTAssertEqual(librarySnapshot.sections.map(\.id), [.all])
        XCTAssertEqual(librarySnapshot.sections.map(\.showsTitle), [false])
        XCTAssertEqual(librarySnapshot.selectableRows.map(\.id.sectionID), [.all, .all, .all, .all])
        XCTAssertEqual(librarySnapshot.selectableRows.map(\.phrase.id), sharedRank.map(\.id))
        XCTAssertEqual(librarySnapshot.selectableRowIDs, librarySnapshot.selectableRows.map(\.id))
        for row in librarySnapshot.selectableRows {
            XCTAssertEqual(librarySnapshot.selectableRowByID[row.id]?.phrase.id, row.phrase.id)
        }
        XCTAssertEqual(librarySnapshot.selectableRows.first?.phrase.id, exact.id)
        XCTAssertTrue(librarySnapshot.indexTitles.isEmpty)
    }

    func testPhraseLibrarySearchSelectionKeepsValidRowAndFallsBackWhenMissing() {
        let first = Phrase(shortcut: "alpha", body: "First target.")
        let second = Phrase(shortcut: "beta", body: "Second target.")
        let rows = PhraseLibraryDisplayData.rows(
            in: PhraseGrouping.sections(for: [first, second])
        )
        let rowByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        let currentSelection = PhraseLibraryRowID(sectionID: .letter("B"), phraseID: second.id)

        XCTAssertEqual(
            PhraseLibrarySelection.selectionAfterRowsChange(
                currentSelection: currentSelection,
                selectableRows: rows,
                selectableRowByID: rowByID
            ),
            currentSelection
        )
        XCTAssertEqual(
            PhraseLibrarySelection.selectionAfterRowsChange(
                currentSelection: PhraseLibraryRowID(sectionID: .letter("Z"), phraseID: UUID()),
                selectableRows: rows,
                selectableRowByID: rowByID
            ),
            rows.first?.id
        )
        XCTAssertNil(
            PhraseLibrarySelection.selectionAfterRowsChange(
                currentSelection: currentSelection,
                selectableRows: []
            )
        )
    }

    func testPhraseLibrarySearchSubmitUsesSelectedVisibleRowOrNoOpsForEmptyRows() {
        let first = Phrase(shortcut: "alpha", body: "First target.")
        let second = Phrase(shortcut: "beta", body: "Second target.")
        let rows = PhraseLibraryDisplayData.rows(
            in: PhraseGrouping.sections(for: [first, second])
        )
        let rowByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        let secondRowID = PhraseLibraryRowID(sectionID: .letter("B"), phraseID: second.id)

        XCTAssertEqual(
            PhraseLibrarySelection.selectedRowForSubmit(
                currentSelection: secondRowID,
                selectableRows: rows,
                selectableRowByID: rowByID
            )?.id,
            secondRowID
        )
        XCTAssertEqual(
            PhraseLibrarySelection.selectedRowForSubmit(
                currentSelection: PhraseLibraryRowID(sectionID: .letter("Z"), phraseID: UUID()),
                selectableRows: rows,
                selectableRowByID: rowByID
            )?.id,
            rows.first?.id
        )
        XCTAssertEqual(
            PhraseLibrarySelection.selectedRowForSubmit(
                currentSelection: nil,
                selectableRows: rows
            )?.id,
            rows.first?.id
        )
        XCTAssertNil(
            PhraseLibrarySelection.selectedRowForSubmit(
                currentSelection: secondRowID,
                selectableRows: []
            )
        )
    }

    func testPhraseLibraryWhitespaceSearchRestoresFullGroupedList() {
        let starred = Phrase(shortcut: "apple", body: "Starred phrase.", isStarred: true)
        let digit = Phrase(shortcut: "2fa", body: "Use the backup code.")
        let target = Phrase(shortcut: "target", body: "Trimmed query target.")
        let symbol = Phrase(shortcut: "#followup", body: "Follow up tomorrow.")
        let phrases = [symbol, digit, target, starred]
        let emptySnapshot = PhraseLibraryDisplayData.snapshot(
            for: "",
            phrases: phrases,
            usageStats: []
        )
        let whitespaceSnapshot = PhraseLibraryDisplayData.snapshot(
            for: " \n\t ",
            phrases: phrases,
            usageStats: []
        )
        let trimmedSnapshot = PhraseLibraryDisplayData.snapshot(
            for: " target \n",
            phrases: phrases,
            usageStats: []
        )
        let exactSnapshot = PhraseLibraryDisplayData.snapshot(
            for: "target",
            phrases: phrases,
            usageStats: []
        )
        let sections = whitespaceSnapshot.sections

        XCTAssertEqual(whitespaceSnapshot.displayedPhrases.map(\.id), emptySnapshot.displayedPhrases.map(\.id))
        XCTAssertFalse(whitespaceSnapshot.hasSearchText)
        XCTAssertEqual(sections.map(\.title), ["Star", "0-9", "A", "T", "#"])
        XCTAssertEqual(sections.map(\.showsTitle), [true, true, true, true, true])
        XCTAssertEqual(
            sections.first { $0.title == "Star" }?.rows.map(\.phrase.id),
            [starred.id]
        )
        XCTAssertEqual(
            sections.first { $0.title == "A" }?.rows.map(\.phrase.id),
            [starred.id]
        )
        XCTAssertEqual(whitespaceSnapshot.indexTitles, ["Star", "0", "A", "T", "#"])
        XCTAssertEqual(whitespaceSnapshot.selectableRows.map(\.phrase.id), [
            starred.id,
            digit.id,
            starred.id,
            target.id,
            symbol.id
        ])
        XCTAssertEqual(trimmedSnapshot.displayedPhrases.map(\.id), exactSnapshot.displayedPhrases.map(\.id))
        XCTAssertEqual(trimmedSnapshot.displayedPhrases.map(\.id), [target.id])
        XCTAssertEqual(trimmedSnapshot.sections.map(\.id), [.all])
        XCTAssertTrue(trimmedSnapshot.indexTitles.isEmpty)
    }

    func testPhrasePaletteSearchHidesRecentSection() {
        let phrase = Phrase(shortcut: "thanks", body: "Thanks, I will check.")
        let stats = [
            PhraseUsageStats(
                phraseID: phrase.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_100)
            )
        ]

        let sections = PhrasePaletteData.sections(
            for: "tha",
            phrases: [phrase],
            usageStats: stats
        )

        XCTAssertFalse(sections.contains { $0.id == .recent })
        XCTAssertEqual(sections.last?.id, .all)
        XCTAssertEqual(sections.last?.rows.map(\.phrase.id), [phrase.id])
    }

    func testPhrasePaletteRecentKeepsOnlyLatestTwoAndIgnoresDeletedPhraseStats() {
        let newest = Phrase(shortcut: "newest", body: "Newest body.")
        let middle = Phrase(shortcut: "middle", body: "Middle body.")
        let oldest = Phrase(shortcut: "oldest", body: "Oldest body.")
        let deletedPhraseID = UUID()
        let stats = [
            PhraseUsageStats(
                phraseID: oldest.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            ),
            PhraseUsageStats(
                phraseID: middle.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_100)
            ),
            PhraseUsageStats(
                phraseID: newest.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_200)
            ),
            PhraseUsageStats(
                phraseID: deletedPhraseID,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_300)
            )
        ]

        let recent = PhrasePaletteData.recentPhrases(
            in: [oldest, middle, newest],
            usageStats: stats
        )

        XCTAssertEqual(recent.map(\.id), [newest.id, middle.id])
    }

    func testPhrasePaletteRecentDeduplicatesUsageStatsByPhraseID() {
        let first = Phrase(shortcut: "first", body: "First body.")
        let second = Phrase(shortcut: "second", body: "Second body.")
        let stats = [
            PhraseUsageStats(
                phraseID: first.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            ),
            PhraseUsageStats(
                phraseID: second.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_100)
            ),
            PhraseUsageStats(
                phraseID: first.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_200)
            )
        ]

        let recent = PhrasePaletteData.recentPhrases(
            in: [first, second],
            usageStats: stats
        )
        let sections = PhrasePaletteData.sections(
            for: "",
            phrases: [first, second],
            usageStats: stats
        )
        let recentRows = sections.first { $0.id == .recent }?.rows ?? []

        XCTAssertEqual(recent.map(\.id), [first.id, second.id])
        XCTAssertEqual(recentRows.map(\.phrase.id), [first.id, second.id])
    }

    func testPhrasePaletteEmptySearchSnapshotReusesSortedDisplayedPhrasesForRecent() {
        let beta = Phrase(shortcut: "beta", body: "Beta body.")
        let alpha = Phrase(shortcut: "alpha", body: "Alpha body.", isStarred: true)
        let stats = [
            PhraseUsageStats(
                phraseID: beta.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            ),
            PhraseUsageStats(
                phraseID: alpha.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let snapshot = PhrasePaletteData.snapshot(
            for: "",
            phrases: [beta, alpha],
            usageStats: stats
        )

        XCTAssertEqual(snapshot.sections.map(\.id), [.recent, .starred, .all])
        XCTAssertEqual(snapshot.sections.first { $0.id == .recent }?.rows.map(\.phrase.id), [alpha.id, beta.id])
        XCTAssertEqual(snapshot.sections.first { $0.id == .starred }?.rows.map(\.phrase.id), [alpha.id])
        XCTAssertEqual(snapshot.sections.first { $0.id == .all }?.rows.map(\.phrase.id), [alpha.id, beta.id])
        XCTAssertEqual(snapshot.displayedPhrases.map(\.id), [alpha.id, beta.id])
    }

    func testPhrasePaletteSnapshotReusesDisplayedPhraseOrderForRecentContract() throws {
        let source = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let sectionsRange = try XCTUnwrap(source.range(of: "private static func sections(\n        displayedPhrases: [Phrase],"))
        let selectableRowsRange = try XCTUnwrap(source.range(of: "static func selectableRows(in sections: [PhrasePaletteSection])"))
        let sectionsSource = String(source[sectionsRange.lowerBound..<selectableRowsRange.lowerBound])
        let navigationItemsRange = try XCTUnwrap(source.range(of: "static func items(\n        displayedPhrases: [Phrase],"))
        let rowBoundsRange = try XCTUnwrap(source.range(of: "struct PhrasePaletteRowBoundsKey"))
        let navigationItemsSource = String(source[navigationItemsRange.lowerBound..<rowBoundsRange.lowerBound])

        XCTAssertTrue(sectionsSource.contains("recentPhrases(inSortedPhrases: displayedPhrases, usageStats: usageStats)"))
        XCTAssertFalse(sectionsSource.contains("recentPhrases(in: phrases, usageStats: usageStats)"))
        XCTAssertFalse(sectionsSource.contains("sortedPhrases(phrases)"))
        XCTAssertTrue(navigationItemsSource.contains("preservingInputOrder: true"))
        XCTAssertFalse(navigationItemsSource.contains("preservingInputOrder: hasSearchText"))
    }

    func testPhrasePaletteSearchAddsStarredAndRecentWeightAfterMatchQuality() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let results = PhrasePaletteData.displayedPhrases(
            for: "target",
            phrases: [plain, recent, starred, exact],
            usageStats: stats
        )

        XCTAssertEqual(results.map(\.id), [exact.id, starred.id, recent.id, plain.id])
    }

    func testPhraseSearchWithUsageStatsAddsStarredAndRecentWeightAfterMatchQuality() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let sharedSearchResults = PhraseSearch.search(
            "target",
            in: [plain, recent, starred, exact],
            usageStats: stats
        )
        let paletteResults = PhrasePaletteData.displayedPhrases(
            for: "target",
            phrases: [plain, recent, starred, exact],
            usageStats: stats
        )

        XCTAssertEqual(sharedSearchResults.map(\.id), [exact.id, starred.id, recent.id, plain.id])
        XCTAssertEqual(paletteResults.map(\.id), sharedSearchResults.map(\.id))
    }

    func testPaletteSearchSelectableRowsFollowSharedSearchRank() {
        let exact = Phrase(shortcut: "target", body: "Exact shortcut wins.")
        let starred = Phrase(shortcut: "bbb", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "ccc", body: "target body")
        let plain = Phrase(shortcut: "aaa", body: "target body")
        let stats = [
            PhraseUsageStats(
                phraseID: recent.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]
        let sharedRank = PhraseSearch.search(
            "target",
            in: [plain, recent, starred, exact],
            usageStats: stats
        )
        let sections = PhrasePaletteData.sections(
            for: "target",
            phrases: [plain, recent, starred, exact],
            usageStats: stats
        )
        let selectableRows = PhrasePaletteData.selectableRows(in: sections)

        XCTAssertEqual(sections.map(\.id), [.all])
        XCTAssertEqual(selectableRows.map(\.phrase.id), sharedRank.map(\.id))
        XCTAssertEqual(selectableRows.first?.phrase.id, exact.id)
    }

    func testCopyingPaletteSelectedRowWritesPhraseBodyAndUpdatesRecentForNextSnapshot() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let selected = try repository.add(shortcut: "target", body: "Selected body wins.")
        let decoy = try repository.add(shortcut: "plain", body: "target body decoy.")
        let currentPopoverSnapshot = PhrasePaletteData.snapshot(
            for: "",
            phrases: try repository.fetchAll(),
            usageStats: []
        )
        let sections = PhrasePaletteData.sections(
            for: "target",
            phrases: try repository.fetchAll(),
            usageStats: []
        )
        let selectedRow = try XCTUnwrap(PhrasePaletteData.selectableRows(in: sections).first)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let controller = PhraseCopyController(
            repository: repository,
            pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
        )
        let copiedAt = Date(timeIntervalSince1970: 1_700_006_500)

        XCTAssertEqual(selectedRow.phrase.id, selected.id)
        XCTAssertNotEqual(selectedRow.phrase.id, decoy.id)
        XCTAssertEqual(controller.copy(selectedRow.phrase, at: copiedAt), .copied)

        XCTAssertEqual(pasteboard.string(forType: .string), selected.body)

        let recent = try repository.recent(limit: 2)
        XCTAssertEqual(recent.map(\.phrase.id), [selected.id])
        XCTAssertEqual(recent.first?.phrase.body, selected.body)
        XCTAssertEqual(recent.first?.stats.lastCopiedAt, copiedAt)

        let usageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let updatedSections = PhrasePaletteData.sections(
            for: "",
            phrases: try repository.fetchAll(),
            usageStats: usageStats
        )
        let nextOpenSnapshot = PhrasePaletteData.snapshot(
            for: "",
            phrases: try repository.fetchAll(),
            usageStats: usageStats
        )
        let recentRows = updatedSections.first { $0.id == .recent }?.rows ?? []

        XCTAssertEqual(updatedSections.first?.id, .recent)
        XCTAssertEqual(recentRows.map(\.phrase.id), [selected.id])
        XCTAssertEqual(nextOpenSnapshot.sections.first?.id, .recent)
        XCTAssertEqual(
            nextOpenSnapshot.selectableRows.first?.id,
            PhrasePaletteRowID(sectionID: .recent, phraseID: selected.id)
        )
        XCTAssertEqual(
            PhrasePaletteData.selectableRows(in: updatedSections).first?.id,
            PhrasePaletteRowID(sectionID: .recent, phraseID: selected.id)
        )
        XCTAssertFalse(currentPopoverSnapshot.sections.contains { $0.id == .recent })
        XCTAssertEqual(currentPopoverSnapshot.sections.first?.id, .all)
        XCTAssertEqual(
            currentPopoverSnapshot.selectableRows.first?.id,
            PhrasePaletteRowID(sectionID: .all, phraseID: decoy.id)
        )
    }

    func testPhraseCopyControllerWritesPhraseBodyAndRecordsRecentAfterSuccess() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let phrase = try repository.add(shortcut: "thanks", body: "Thanks, I will check.")
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let controller = PhraseCopyController(
            repository: repository,
            pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
        )
        let copiedAt = Date(timeIntervalSince1970: 1_700_003_000)

        XCTAssertEqual(controller.copy(phrase, at: copiedAt), .copied)

        XCTAssertEqual(pasteboard.string(forType: .string), phrase.body)

        let recent = try repository.recent(limit: 1)
        XCTAssertEqual(recent.map(\.phrase.id), [phrase.id])
        XCTAssertEqual(recent.first?.stats.copyCount, 1)
        XCTAssertEqual(recent.first?.stats.lastCopiedAt, copiedAt)
    }

    func testPhraseCopyControllerWritesFullLongMultilineBody() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let body = (1...120)
            .map { "Copied line \($0): thanks, I will check and get back to you." }
            .joined(separator: "\n")
        let phrase = try repository.add(shortcut: "long-copy", body: body)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let controller = PhraseCopyController(
            repository: repository,
            pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
        )

        XCTAssertEqual(controller.copy(phrase), .copied)

        XCTAssertEqual(pasteboard.string(forType: .string), body)
    }

    func testCopiedPhrasesUpdatePaletteRecentFromSameStore() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let first = try repository.add(shortcut: "first", body: "First body.")
        let second = try repository.add(shortcut: "second", body: "Second body.")
        let third = try repository.add(shortcut: "third", body: "Third body.")
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("dev.lazyquips.public.tests.\(UUID().uuidString)"))
        let controller = PhraseCopyController(
            repository: repository,
            pasteboardWriter: PasteboardWriter(pasteboard: pasteboard)
        )

        XCTAssertEqual(
            controller.copy(first, at: Date(timeIntervalSince1970: 1_700_007_000)),
            .copied
        )
        XCTAssertEqual(
            controller.copy(second, at: Date(timeIntervalSince1970: 1_700_007_100)),
            .copied
        )
        XCTAssertEqual(
            controller.copy(third, at: Date(timeIntervalSince1970: 1_700_007_200)),
            .copied
        )

        XCTAssertEqual(pasteboard.string(forType: .string), third.body)

        let phrases = try repository.fetchAll()
        let usageStats = try context.fetch(FetchDescriptor<PhraseUsageStats>())
        let paletteSections = PhrasePaletteData.sections(
            for: "",
            phrases: phrases,
            usageStats: usageStats
        )
        let recentRows = paletteSections.first { $0.id == .recent }?.rows ?? []
        let allRows = paletteSections.first { $0.id == .all }?.rows ?? []

        XCTAssertEqual(paletteSections.first?.id, .recent)
        XCTAssertEqual(recentRows.map(\.phrase.id), [third.id, second.id])
        XCTAssertEqual(allRows.map(\.phrase.id), [first.id, second.id, third.id])
    }

    func testPhraseCopyControllerDoesNotRecordRecentWhenWriteFails() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let phrase = try repository.add(shortcut: "later", body: "I will reply later.")
        var attemptedWrite: String?
        let controller = PhraseCopyController(repository: repository) { string in
            attemptedWrite = string
            return false
        }

        XCTAssertEqual(controller.copy(phrase), .failedToWrite)

        XCTAssertEqual(attemptedWrite, phrase.body)
        XCTAssertTrue(try repository.recent().isEmpty)
    }

    func testPhraseCopyControllerReportsCopiedWhenRecentRecordFails() {
        let phrase = Phrase(shortcut: "partial", body: "This text reached the pasteboard.")
        let copiedAt = Date(timeIntervalSince1970: 1_700_008_000)
        var attemptedWrite: String?
        var attemptedRecord: (phraseID: UUID, date: Date)?
        let controller = PhraseCopyController(
            writeString: { string in
                attemptedWrite = string
                return true
            },
            recordCopy: { phrase, date in
                attemptedRecord = (phrase.id, date)
                throw NSError(domain: "LazyquipsTests", code: 1)
            }
        )

        let result = controller.copy(phrase, at: copiedAt)

        XCTAssertEqual(result, .copiedWithoutRecent)
        XCTAssertTrue(result.didCopy)
        XCTAssertEqual(attemptedWrite, phrase.body)
        XCTAssertEqual(attemptedRecord?.phraseID, phrase.id)
        XCTAssertEqual(attemptedRecord?.date, copiedAt)
    }

    func testPhraseGroupingKeepsStarredPhraseInOriginalSection() {
        let starred = Phrase(shortcut: "apple", body: "Starred phrase.", isStarred: true)
        let earlierA = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        let digit = Phrase(shortcut: "1intro", body: "Intro.")
        let letter = Phrase(shortcut: "banana", body: "Banana.")
        let symbol = Phrase(shortcut: "#note", body: "Note.")
        let chinese = Phrase(shortcut: "中文", body: "Chinese shortcut.")

        let sections = PhraseGrouping.sections(for: [starred, earlierA, digit, letter, symbol, chinese])

        XCTAssertEqual(sections.map(\.title), ["Star", "0-9", "A", "B", "#"])
        XCTAssertEqual(PhraseGrouping.indexTitles(for: sections), ["Star", "0", "A", "B", "#"])
        XCTAssertEqual(PhraseGrouping.indexTitles(for: sections, includeStarred: false), ["0", "A", "B", "#"])
        XCTAssertEqual(sections[0].phrases.map(\.id), [starred.id])
        XCTAssertEqual(sections[2].phrases.map(\.id), [earlierA.id, starred.id])
        XCTAssertEqual(sections[4].phrases.map(\.id), [symbol.id, chinese.id])
    }

    func testPhraseLibraryCopiedFeedbackTargetsSpecificDuplicateDisplayRow() {
        let starred = Phrase(shortcut: "apple", body: "Starred phrase.", isStarred: true)
        let sections = PhraseGrouping.sections(for: [starred])
        let rows = PhraseLibraryDisplayData.rows(in: sections)
        let copiedRowID = PhraseLibraryRowID(sectionID: .starred, phraseID: starred.id)

        XCTAssertEqual(rows.map(\.id), [
            PhraseLibraryRowID(sectionID: .starred, phraseID: starred.id),
            PhraseLibraryRowID(sectionID: .letter("A"), phraseID: starred.id)
        ])

        let copiedRows = rows.filter { $0.id == copiedRowID }
        let originalGroupRows = rows.filter { $0.id.sectionID == .letter("A") }

        XCTAssertEqual(copiedRows.map(\.phrase.id), [starred.id])
        XCTAssertEqual(originalGroupRows.map(\.phrase.id), [starred.id])
        XCTAssertNotEqual(copiedRows.first?.id, originalGroupRows.first?.id)
        XCTAssertEqual(
            rows.map(\.id.accessibilityIdentifier),
            [
                "lazyquips.library.row.starred.\(starred.id.uuidString)",
                "lazyquips.library.row.letter-a.\(starred.id.uuidString)"
            ]
        )
    }

    func testPhraseBodyPreviewFoldsWhitespaceForLibraryRowPreview() {
        XCTAssertEqual(
            PhraseBodyPreview.text(for: "OK\nImportant follow-up   starts here."),
            "OK Important follow-up starts here."
        )
        XCTAssertEqual(
            PhraseBodyPreview.text(for: "  First\tline\r\nSecond\n\nline  "),
            "First line Second line"
        )
    }

    func testPhraseLibrarySnapshotPrecomputesRowPreviewText() {
        let phrase = Phrase(shortcut: "long", body: "First line\n\nSecond   line")
        let snapshot = PhraseLibraryDisplayData.snapshot(
            for: "",
            phrases: [phrase],
            usageStats: []
        )

        XCTAssertEqual(snapshot.selectableRows.map(\.previewText), ["First line Second line"])
        XCTAssertEqual(snapshot.sections.flatMap(\.rows).map(\.previewText), ["First line Second line"])
    }

    func testPhraseLibrarySnapshotStoresFullPhraseLookupMetadata() {
        let visible = Phrase(shortcut: "alpha", body: "Visible search result")
        let hiddenBySearch = Phrase(shortcut: "beta", body: "Hidden by current query")
        let snapshot = PhraseLibraryDisplayData.snapshot(
            for: "alpha",
            phrases: [visible, hiddenBySearch],
            usageStats: []
        )

        XCTAssertEqual(snapshot.displayedPhrases.map(\.id), [visible.id])
        XCTAssertEqual(snapshot.phraseIDs, Set([visible.id, hiddenBySearch.id]))
        XCTAssertTrue(snapshot.phraseByID[visible.id] === visible)
        XCTAssertTrue(snapshot.phraseByID[hiddenBySearch.id] === hiddenBySearch)
    }

    func testPhraseContextMenuItemsMatchStarStateAndActionOrder() {
        let plain = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        let starred = Phrase(shortcut: "vip", body: "Priority response.", isStarred: true)
        let plainItems = PhraseContextMenuItem.items(for: plain)
        let starredItems = PhraseContextMenuItem.items(for: starred)

        XCTAssertEqual(plainItems.map(\.action), [.toggleStar, .edit, .delete])
        XCTAssertEqual(plainItems.map(\.title), ["Star", "Edit", "Delete"])
        XCTAssertEqual(plainItems.map(\.systemImage), ["star", "pencil", "trash"])
        XCTAssertEqual(plainItems.map(\.isDestructive), [false, false, true])
        XCTAssertEqual(plainItems.map(\.hasLeadingSeparator), [false, true, false])
        XCTAssertEqual(plainItems.map(\.accessibilityIdentifier), [
            "lazyquips.library.context.starButton",
            "lazyquips.library.context.editButton",
            "lazyquips.library.context.deleteButton"
        ])

        XCTAssertEqual(starredItems.map(\.action), [.toggleStar, .edit, .delete])
        XCTAssertEqual(starredItems.map(\.title), ["Unstar", "Edit", "Delete"])
        XCTAssertEqual(starredItems.map(\.systemImage), ["star.slash", "pencil", "trash"])
        XCTAssertEqual(starredItems.map(\.isDestructive), [false, false, true])
        XCTAssertEqual(starredItems.map(\.hasLeadingSeparator), [false, true, false])
        XCTAssertEqual(starredItems.map(\.accessibilityIdentifier), [
            "lazyquips.library.context.unstarButton",
            "lazyquips.library.context.editButton",
            "lazyquips.library.context.deleteButton"
        ])
    }

    func testStarAndUnstarSymbolsAvoidFilledVariants() throws {
        let filledStarSymbol = "star" + ".fill"
        let filledUnstarSymbol = "star.slash" + ".fill"

        for source in try appSwiftSourceFiles() {
            XCTAssertFalse(source.content.contains(filledStarSymbol), source.relativePath)
            XCTAssertFalse(source.content.contains(filledUnstarSymbol), source.relativePath)
        }
    }

    func testPhraseEditorPresentationUsesBlankAddAndCurrentEditValues() {
        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        let phraseByID = [phrase.id: phrase]

        let addPresentation = PhraseEditorPresentation.make(
            for: .add,
            phraseByID: phraseByID
        )
        let editPresentation = PhraseEditorPresentation.make(
            for: .edit(phrase.id),
            phraseByID: phraseByID
        )
        let missingEditPresentation = PhraseEditorPresentation.make(
            for: .edit(UUID()),
            phraseByID: phraseByID
        )

        XCTAssertEqual(addPresentation?.kind, .add)
        XCTAssertEqual(addPresentation?.id, "add")
        XCTAssertEqual(addPresentation?.title, "Add")
        XCTAssertEqual(addPresentation?.initialShortcut, "")
        XCTAssertEqual(addPresentation?.initialBody, "")

        XCTAssertEqual(editPresentation?.kind, .edit(phrase.id))
        XCTAssertEqual(editPresentation?.id, "edit-\(phrase.id.uuidString)")
        XCTAssertEqual(editPresentation?.title, "Edit")
        XCTAssertEqual(editPresentation?.initialShortcut, phrase.shortcut)
        XCTAssertEqual(editPresentation?.initialBody, phrase.body)

        XCTAssertNil(missingEditPresentation)
        XCTAssertNil(PhraseEditorPresentation.make(for: nil, phraseByID: phraseByID))
    }

    func testPhraseLibraryToolbarLayoutMatchesHomePageFigmaPositions() {
        XCTAssertEqual(PhraseLibraryLayout.windowWidth, 800, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.windowHeight, 600, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarHorizontalPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarControlSpacing, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarSearchX, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.searchFieldWidth, 626, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.searchFieldHeight, 32, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarAddX, 666, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.addButtonWidth, 58, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarSettingsX, 744, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.settingsButtonWidth, 36, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarControlHeight, 32, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.toolbarWidth, 800, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.listTopPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.listBottomPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.rowTextLeadingPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.rowContentTrailingPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.rowCopiedFeedbackTrailingPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.rowBodyTrailingPadding(isCopied: false), 20, accuracy: 0.5)
        XCTAssertEqual(PhraseLibraryLayout.rowBodyTrailingPadding(isCopied: true), 106, accuracy: 0.5)
        XCTAssertEqual(
            PhraseLibraryLayout.rowCopiedFeedbackTrailingPadding,
            PhraseLibraryLayout.rowContentTrailingPadding + LazyQuipsVisualStyle.copiedBadgeTrailingPadding,
            accuracy: 0.5
        )
    }

    func testPhraseLibraryToolbarUsesSharedGlassReadyControls() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let toolbarRange = try XCTUnwrap(source.range(of: "private func toolbar(snapshot: PhraseLibrarySnapshot) -> some View"))
        let editorOverlayRange = try XCTUnwrap(source.range(of: "private func editorOverlay(snapshot: PhraseLibrarySnapshot)"))
        let toolbarSource = String(source[toolbarRange.lowerBound..<editorOverlayRange.lowerBound])

        XCTAssertTrue(toolbarSource.contains("LazyQuipsToolbarGlassGroup(spacing: PhraseLibraryLayout.toolbarControlSpacing)"))
        XCTAssertTrue(toolbarSource.contains("LazyQuipsToolbarButtonStyle("))
        XCTAssertTrue(toolbarSource.contains("tone: .utility"))
        XCTAssertTrue(toolbarSource.contains("usesLiquidGlass: true"))
        XCTAssertTrue(toolbarSource.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(toolbarSource.contains(".simultaneousGesture(TapGesture().onEnded {"))
        XCTAssertTrue(toolbarSource.contains("isSearchFocused = true"))
        XCTAssertTrue(source.contains(".lazyQuipsToolbarControlSurface(usesLiquidGlass: true)"))
        XCTAssertFalse(source.contains("private struct PhraseToolbarButtonStyle"))
    }

    func testPhraseLibrarySearchFocusUsesFocusStateAndCommandFContract() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let appSource = try sourceFileContent("lazyquips/App/LazyquipsApp.swift")
        let searchFieldRange = try XCTUnwrap(source.range(of: "private struct PhraseSearchField"))
        let phraseListRange = try XCTUnwrap(source.range(of: "private struct PhraseListView"))
        let searchFieldSource = String(source[searchFieldRange.lowerBound..<phraseListRange.lowerBound])

        XCTAssertTrue(source.contains("@FocusState private var isSearchFocused: Bool"))
        XCTAssertTrue(source.contains("focusSearchField(for: state.searchFocusRequest)"))
        XCTAssertTrue(source.contains(".onChange(of: state.searchFocusRequest)"))
        XCTAssertTrue(source.contains("private func focusSearchField(for request: UUID)"))
        XCTAssertTrue(source.contains("DispatchQueue.main.async"))
        XCTAssertTrue(source.contains("guard state.searchFocusRequest == request, !isModalOverlayPresented else"))
        XCTAssertTrue(source.contains("isSearchFocused = true"))
        XCTAssertTrue(source.contains("isFocused: $isSearchFocused"))
        XCTAssertTrue(searchFieldSource.contains("@FocusState.Binding var isFocused: Bool"))
        XCTAssertTrue(searchFieldSource.contains(".focused($isFocused)"))
        XCTAssertTrue(searchFieldSource.contains(".accessibilityIdentifier(\"lazyquips.library.searchField\")"))

        XCTAssertTrue(appSource.contains("CommandGroup(after: .textEditing)"))
        XCTAssertTrue(appSource.contains("Button(AppStrings.text(.search, language: appDelegate.languageStore.language))"))
        XCTAssertTrue(appSource.contains("appDelegate.focusMainWindowSearch()"))
        XCTAssertTrue(appSource.contains(".keyboardShortcut(\"f\", modifiers: .command)"))
        XCTAssertFalse(source.contains("NSEvent.addLocalMonitorForEvents"))
        XCTAssertFalse(source.contains("NSEvent.addGlobalMonitorForEvents"))
    }

    func testPhraseLibrarySearchFieldSubmitCopiesSelectedSearchResultContract() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let searchFieldRange = try XCTUnwrap(source.range(of: "private struct PhraseSearchField"))
        let phraseListRange = try XCTUnwrap(source.range(of: "private struct PhraseListView"))
        let searchFieldSource = String(source[searchFieldRange.lowerBound..<phraseListRange.lowerBound])
        let searchChangeRange = try XCTUnwrap(source.range(of: ".onChange(of: searchText)"))
        let selectableRowsChangeRange = try XCTUnwrap(source.range(of: ".onChange(of: snapshot.selectableRowIDs)"))
        let phraseIDsChangeRange = try XCTUnwrap(source.range(of: ".onChange(of: snapshot.phraseIDs)"))
        let searchChangeSource = String(source[searchChangeRange.lowerBound..<selectableRowsChangeRange.lowerBound])
        let selectableRowsChangeSource = String(source[selectableRowsChangeRange.lowerBound..<phraseIDsChangeRange.lowerBound])

        XCTAssertTrue(source.contains("@State private var snapshotCache = PhraseLibrarySnapshotCache()"))
        XCTAssertTrue(source.contains("private func currentSnapshot() -> PhraseLibrarySnapshot"))
        XCTAssertTrue(source.contains(".onAppear {"))
        XCTAssertTrue(source.contains("refreshSearchSelection(resetToFirst: false, in: snapshot)"))
        XCTAssertTrue(source.contains("focusSearchField(for: state.searchFocusRequest)"))
        XCTAssertTrue(source.contains(".onChange(of: searchText)"))
        XCTAssertTrue(searchChangeSource.contains("refreshSearchSelection(resetToFirst: true, in: snapshot)"))
        XCTAssertFalse(searchChangeSource.contains("currentSnapshot()"))
        XCTAssertTrue(source.contains(".onChange(of: snapshot.selectableRowIDs)"))
        XCTAssertTrue(selectableRowsChangeSource.contains("refreshSearchSelection(resetToFirst: false, in: snapshot)"))
        XCTAssertFalse(selectableRowsChangeSource.contains("currentSnapshot()"))
        XCTAssertTrue(source.contains("toolbar(snapshot: snapshot)"))
        XCTAssertTrue(source.contains("private func toolbar(snapshot: PhraseLibrarySnapshot) -> some View"))
        XCTAssertTrue(source.contains("onSubmit: { copySelectedPhrase(in: snapshot) }"))
        XCTAssertTrue(source.contains("private func copySelectedPhrase(in snapshot: PhraseLibrarySnapshot)"))
        XCTAssertTrue(source.contains("!isModalOverlayPresented,"))
        XCTAssertTrue(source.contains("PhraseLibrarySelection.selectedRowForSubmit("))
        XCTAssertTrue(source.contains("currentSelection: selectedRowID"))
        XCTAssertTrue(source.contains("selectableRows: snapshot.selectableRows"))
        XCTAssertTrue(source.contains("selectableRowByID: snapshot.selectableRowByID"))
        XCTAssertTrue(source.contains("copyPhrase(row)"))
        XCTAssertTrue(source.contains("enum PhraseLibrarySelection"))
        XCTAssertTrue(source.contains("PhraseLibrarySelection.selectionAfterRowsChange("))
        XCTAssertTrue(searchFieldSource.contains("let onSubmit: () -> Void"))
        XCTAssertTrue(searchFieldSource.contains(".onSubmit(onSubmit)"))
        XCTAssertFalse(source.contains("guard hasSearchText,"))
        XCTAssertFalse(source.contains("NSEvent.addLocalMonitorForEvents"))
        XCTAssertFalse(source.contains("NSEvent.addGlobalMonitorForEvents"))
    }

    func testPhraseLibrarySnapshotCacheContractUsesSharedPreparedSearchIndexes() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let cacheRange = try XCTUnwrap(source.range(of: "final class PhraseLibrarySnapshotCache"))
        let keyRange = try XCTUnwrap(source.range(of: "private struct PhraseLibrarySnapshotCacheKey"))
        let cacheSource = String(source[cacheRange.lowerBound..<keyRange.lowerBound])
        let viewRange = try XCTUnwrap(source.range(of: "struct PhraseLibraryView: View"))
        let rowIDRange = try XCTUnwrap(source.range(of: "struct PhraseLibraryRowID"))
        let viewSource = String(source[viewRange.lowerBound..<rowIDRange.lowerBound])

        XCTAssertTrue(source.contains("struct PhraseLibrarySnapshot"))
        XCTAssertTrue(source.contains("PhraseGroupID.all.title"))
        XCTAssertTrue(source.contains("case .all"))
        XCTAssertTrue(source.contains("id: .all"))
        XCTAssertTrue(source.contains("hasSearchText ?"))
        XCTAssertTrue(source.contains("PhraseGrouping.sections(for: displayedPhrases, preservingInputOrder: true)"))
        XCTAssertTrue(cacheSource.contains("private let searchIndexCache: PhraseSearchIndexCache"))
        XCTAssertTrue(cacheSource.contains("searchIndexCache.sortedIndexes(for: phrases)"))
        XCTAssertTrue(cacheSource.contains("searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty"))
        XCTAssertTrue(cacheSource.contains("? nil"))
        XCTAssertTrue(cacheSource.contains(": searchIndexCache.sortedIndexes(for: phrases)"))
        let hitCheckRange = try XCTUnwrap(cacheSource.range(of: "cachedKey?.matches("))
        let nextKeyRange = try XCTUnwrap(cacheSource.range(of: "let nextKey = PhraseLibrarySnapshotCacheKey("))
        XCTAssertLessThan(hitCheckRange.lowerBound, nextKeyRange.lowerBound)
        XCTAssertFalse(cacheSource.contains("if cachedKey == nextKey"))
        XCTAssertTrue(viewSource.contains("let snapshot = currentSnapshot()"))
        XCTAssertTrue(viewSource.contains("editorOverlay(snapshot: snapshot)"))
        XCTAssertTrue(viewSource.contains("snapshot.sections"))
        XCTAssertTrue(viewSource.contains("snapshot.indexTitles"))
        XCTAssertTrue(viewSource.contains("snapshot.selectableRows"))
        XCTAssertTrue(viewSource.contains("snapshot.selectableRowIDs"))
        XCTAssertTrue(viewSource.contains(".onChange(of: snapshot.phraseIDs)"))
        XCTAssertTrue(viewSource.contains("phraseByID: snapshot.phraseByID"))
        XCTAssertTrue(viewSource.contains("currentSnapshot().phraseByID[phraseID]"))
        XCTAssertTrue(source.contains("let phraseByID = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, $0) })"))
        XCTAssertTrue(source.contains("phraseIDs: Set(phraseByID.keys)"))
        XCTAssertTrue(source.contains("phraseByID: phraseByID"))
        XCTAssertTrue(source.contains("selectableRowIDs: selectableRows.map(\\.id)"))
        XCTAssertTrue(source.contains("selectableRowByID: selectableRowByID"))
        XCTAssertTrue(source.contains("let phraseIDs: Set<UUID>"))
        XCTAssertTrue(source.contains("let phraseByID: [UUID: Phrase]"))
        XCTAssertTrue(source.contains("let selectableRowIDs: [PhraseLibraryRowID]"))
        XCTAssertTrue(source.contains("let selectableRowByID: [PhraseLibraryRowID: PhraseLibraryRow]"))
        XCTAssertFalse(source.contains(".onChange(of: phrases.map(\\.id))"))
        XCTAssertFalse(source.contains("PhraseEditorPresentation.make(\n            for: state.editorMode,\n            phrases: phrases"))
        XCTAssertFalse(source.contains("var selectableRowIDs"))
        XCTAssertFalse(viewSource.contains("PhraseSearch.search(searchText, in: phrases"))
        XCTAssertFalse(viewSource.contains("PhraseGrouping.sections(for: displayedPhrases"))
        XCTAssertFalse(viewSource.contains("PhraseLibraryDisplayData.rows(in: sections)"))
    }

    func testPhraseLibraryPrewarmsSearchIndexesAfterDataIsAvailable() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let bodyRange = try XCTUnwrap(source.range(of: "var body: some View"))
        let snapshotRange = try XCTUnwrap(source.range(of: "struct PhraseLibrarySnapshot"))
        let viewSource = String(source[bodyRange.lowerBound..<snapshotRange.lowerBound])
        let scheduleRange = try XCTUnwrap(viewSource.range(of: "private func scheduleSearchIndexPrewarm(for phrases: [Phrase])"))
        let currentSnapshotRange = try XCTUnwrap(viewSource.range(of: "private func currentSnapshot() -> PhraseLibrarySnapshot"))
        let scheduleSource = String(viewSource[scheduleRange.lowerBound..<currentSnapshotRange.lowerBound])

        XCTAssertTrue(source.contains("@State private var searchIndexPrewarmTask: Task<Void, Never>?"))
        XCTAssertTrue(source.contains("let searchIndexPrewarmSignature = phrases.map(PhraseLibrarySearchIndexPrewarmSignature.init)"))
        XCTAssertTrue(viewSource.contains("scheduleSearchIndexPrewarm(for: phrases)"))
        XCTAssertTrue(viewSource.contains(".onChange(of: searchIndexPrewarmSignature)"))
        XCTAssertTrue(scheduleSource.contains("searchIndexPrewarmTask?.cancel()"))
        XCTAssertTrue(scheduleSource.contains("Task { @MainActor in"))
        XCTAssertTrue(scheduleSource.contains("Task.sleep(nanoseconds: 200_000_000)"))
        XCTAssertTrue(scheduleSource.contains("snapshotCache.prewarmSearchIndexes(for: phrases)"))
        XCTAssertFalse(scheduleSource.contains("snapshotCache.snapshot("))
        XCTAssertTrue(source.contains("struct PhraseLibrarySearchIndexPrewarmSignature: Equatable"))
        XCTAssertTrue(source.contains("func prewarmSearchIndexes(for phrases: [Phrase])"))
        XCTAssertTrue(source.contains("_ = searchIndexCache.sortedIndexes(for: phrases)"))
    }

    func testPhraseEditorLayoutMatchesAddEditFigmaContract() throws {
        XCTAssertEqual(PhraseEditorLayout.cardWidth, 440, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.minimumCardHeight, 327, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.cardHeight, PhraseEditorLayout.minimumCardHeight, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.verticalMargin, 40, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.maximumCardHeight, 520, accuracy: 0.5)
        XCTAssertEqual(
            PhraseEditorLayout.maximumCardHeight(forContainerHeight: PhraseLibraryLayout.windowHeight),
            520,
            accuracy: 0.5
        )
        XCTAssertEqual(
            PhraseEditorLayout.maximumCardHeight(forContainerHeight: 760),
            680,
            accuracy: 0.5
        )
        XCTAssertEqual(PhraseEditorLayout.contentPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.cardX, 180, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.cardY, 136.5, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.cardY(forHeight: PhraseEditorLayout.maximumCardHeight), 40, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.contentX, 200, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.titleY, 156.5, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.contentWidth, 400, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.fieldSeparatorWidth, 400, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.titleFontSize, 16, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.modalTextFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.labelFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.fieldFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.errorFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerButtonFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.sameGroupSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.sectionSpacing, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.relatedInlineSpacing, 8, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.titleBottomPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.labelSpacing, 8, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.textFieldBottomPadding, 4, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.shortcutBottomPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.errorTopPadding, 10, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.bodyFieldMinimumHeight, 64, accuracy: 0.5)
        XCTAssertGreaterThan(PhraseEditorLayout.bodyFieldMaximumHeight, PhraseEditorLayout.bodyFieldMinimumHeight)
        XCTAssertEqual(PhraseEditorLayout.footerButtonHorizontalPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerButtonVerticalPadding, 6, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerButtonCornerRadius, 7, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerButtonHeight, 30, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerButtonSpacing, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.footerTopPadding, 20, accuracy: 0.5)
        XCTAssertEqual(PhraseEditorLayout.overlayDimmingOpacity, 0.2, accuracy: 0.01)

        let shortBody = "Short phrase."
        let mediumBody = String(repeating: "This line should grow the editor height. ", count: 12)
        let longBody = String(repeating: "This line should eventually scroll inside the editor. ", count: 120)

        XCTAssertEqual(
            PhraseEditorLayout.bodyFieldHeight(for: shortBody),
            PhraseEditorLayout.bodyFieldMinimumHeight,
            accuracy: 0.5
        )
        XCTAssertEqual(
            PhraseEditorLayout.cardHeight(for: shortBody),
            PhraseEditorLayout.minimumCardHeight,
            accuracy: 0.5
        )
        XCTAssertGreaterThan(
            PhraseEditorLayout.bodyFieldHeight(for: mediumBody),
            PhraseEditorLayout.bodyFieldHeight(for: shortBody)
        )
        XCTAssertGreaterThan(
            PhraseEditorLayout.cardHeight(for: mediumBody),
            PhraseEditorLayout.minimumCardHeight
        )
        XCTAssertEqual(
            PhraseEditorLayout.bodyFieldHeight(for: longBody),
            PhraseEditorLayout.bodyFieldMaximumHeight,
            accuracy: 0.5
        )
        XCTAssertEqual(
            PhraseEditorLayout.cardHeight(for: longBody),
            PhraseEditorLayout.maximumCardHeight,
            accuracy: 0.5
        )
        XCTAssertEqual(
            PhraseEditorLayout.cardHeight(for: longBody, containerHeight: 760),
            680,
            accuracy: 0.5
        )

        let source = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let overlayRange = try XCTUnwrap(source.range(of: "private struct PhraseEditorOverlay: View"))
        let saveRange = try XCTUnwrap(source.range(of: "    private func save()"))
        let overlaySource = String(source[overlayRange.lowerBound..<saveRange.lowerBound])
        let dividerCount = overlaySource.components(separatedBy: "Divider()").count - 1

        XCTAssertEqual(dividerCount, 1)
        XCTAssertTrue(overlaySource.contains("GeometryReader"))
        XCTAssertTrue(overlaySource.contains("overlayContent(containerHeight: proxy.size.height)"))
        XCTAssertTrue(overlaySource.contains("PlainShortcutTextField("))
        XCTAssertTrue(overlaySource.contains("focusRequest: shortcutFocusRequest"))
        XCTAssertTrue(overlaySource.contains("requestShortcutFocus()"))
        XCTAssertTrue(overlaySource.contains(".frame(width: PhraseEditorLayout.fieldSeparatorWidth, height: PhraseEditorLayout.shortcutFieldHeight)"))
        XCTAssertTrue(overlaySource.contains(".accessibilityIdentifier(\"lazyquips.library.editor.shortcutField\")"))
        XCTAssertTrue(overlaySource.contains("PlainPhraseTextEditor("))
        XCTAssertTrue(overlaySource.contains(".frame(width: PhraseEditorLayout.fieldSeparatorWidth, height: bodyFieldHeight)"))
        XCTAssertTrue(overlaySource.contains(".accessibilityIdentifier(\"lazyquips.library.editor.phraseField\")"))
        XCTAssertFalse(overlaySource.contains("TextField(\"\", text: $shortcut)"))
        XCTAssertFalse(overlaySource.contains("@FocusState private var focusedField"))
        XCTAssertFalse(overlaySource.contains(".focused($focusedField"))
        XCTAssertTrue(overlaySource.contains("PhraseEditorLayout.errorFontSize"))
        XCTAssertTrue(overlaySource.contains("PhraseEditorFooterButtonStyle(prominence: .standard)"))
        XCTAssertTrue(overlaySource.contains("PhraseEditorFooterButtonStyle(prominence: .primary)"))
        XCTAssertTrue(overlaySource.contains(".accessibilityLabel(cancelTitle)"))
        XCTAssertTrue(overlaySource.contains(".accessibilityLabel(okTitle)"))
        XCTAssertTrue(overlaySource.contains("height: cardHeight"))
        XCTAssertFalse(overlaySource.contains("height: PhraseEditorLayout.cardHeight"))
        XCTAssertFalse(overlaySource.contains("PhraseEditorLayout.footerButtonWidth"))
        XCTAssertFalse(overlaySource.contains(".buttonStyle(.borderedProminent)"))
        XCTAssertFalse(overlaySource.contains(".font(.caption)"))
        XCTAssertFalse(overlaySource.contains("dividerHorizontalBleed"))

        let buttonStyleRange = try XCTUnwrap(source.range(of: "private struct PhraseEditorFooterButtonStyle"))
        let indexLayoutRange = try XCTUnwrap(source.range(of: "enum PhraseIndexLayout"))
        let buttonStyleSource = String(source[buttonStyleRange.lowerBound..<indexLayoutRange.lowerBound])
        let shortcutFieldRange = try XCTUnwrap(source.range(of: "private struct PlainShortcutTextField"))
        let textEditorRange = try XCTUnwrap(source.range(of: "private struct PlainPhraseTextEditor"))
        let overlayStructRange = try XCTUnwrap(source.range(of: "private struct PhraseEditorOverlay: View"))
        XCTAssertTrue(buttonStyleSource.contains("PhraseEditorLayout.footerButtonFontSize"))
        XCTAssertTrue(buttonStyleSource.contains(".font(.system(size: PhraseEditorLayout.footerButtonFontSize))"))
        XCTAssertFalse(buttonStyleSource.contains("weight: .medium"))
        XCTAssertFalse(buttonStyleSource.contains("weight: .bold"))
        XCTAssertTrue(buttonStyleSource.contains("PhraseEditorLayout.modalTextLineHeight"))
        XCTAssertTrue(buttonStyleSource.contains("PhraseEditorLayout.footerButtonHorizontalPadding"))
        XCTAssertTrue(buttonStyleSource.contains("PhraseEditorLayout.footerButtonVerticalPadding"))
        XCTAssertTrue(buttonStyleSource.contains("PhraseEditorLayout.footerButtonCornerRadius"))

        let shortcutFieldSource = String(source[shortcutFieldRange.lowerBound..<textEditorRange.lowerBound])
        let textEditorSource = String(source[textEditorRange.lowerBound..<overlayStructRange.lowerBound])

        XCTAssertTrue(shortcutFieldSource.contains("NSViewRepresentable"))
        XCTAssertTrue(shortcutFieldSource.contains("NSTextField"))
        XCTAssertTrue(shortcutFieldSource.contains("NSTextFieldDelegate"))
        XCTAssertTrue(shortcutFieldSource.contains("PlainShortcutTextFieldCell"))
        XCTAssertTrue(shortcutFieldSource.contains("cell = PlainShortcutTextFieldCell(textCell: \"\")"))
        XCTAssertTrue(shortcutFieldSource.contains("drawingRect(forBounds"))
        XCTAssertTrue(shortcutFieldSource.contains("edit("))
        XCTAssertTrue(shortcutFieldSource.contains("select("))
        XCTAssertTrue(shortcutFieldSource.contains("rect.maxY - textHeight"))
        XCTAssertTrue(shortcutFieldSource.contains("controlTextDidChange"))
        XCTAssertTrue(shortcutFieldSource.contains("window?.makeFirstResponder(textField)"))
        XCTAssertTrue(shortcutFieldSource.contains("isBordered = false"))
        XCTAssertTrue(shortcutFieldSource.contains("drawsBackground = false"))
        XCTAssertTrue(shortcutFieldSource.contains("focusRingType = .none"))
        XCTAssertTrue(shortcutFieldSource.contains(".labelColor"))
        XCTAssertTrue(shortcutFieldSource.contains("usesSingleLineMode = true"))
        XCTAssertTrue(shortcutFieldSource.contains("maximumNumberOfLines = 1"))
        XCTAssertTrue(shortcutFieldSource.contains("hasMarkedText()"))
        XCTAssertTrue(shortcutFieldSource.contains("insertNewline"))
        XCTAssertTrue(shortcutFieldSource.contains("cancelOperation"))
        XCTAssertTrue(textEditorSource.contains("FocusingTextScrollView"))
        XCTAssertTrue(textEditorSource.contains("window?.makeFirstResponder(textView)"))
        XCTAssertTrue(textEditorSource.contains("updateDocumentSize(textView, in: scrollView)"))
    }

    func testSettingsContentLayoutMatchesMainWindowOverlayContract() throws {
        XCTAssertEqual(SettingsContentLayout.cardWidth, 440, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.cardCornerRadius, 24, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.cardShadowRadius, 28, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.cardShadowYOffset, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.overlayDimmingOpacity, 0.2, accuracy: 0.01)
        XCTAssertEqual(SettingsContentLayout.overlayBreathingPadding, 24, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contentPadding, 20, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contentWidth, 400, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.sameGroupSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.sectionSpacing, 20, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.relatedInlineSpacing, 6, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.rowHeight, 60, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.rowTrailingColumnWidth, 260, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.rowContentSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.dividerWidth, 400, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.settingsTitleFontSize, 16, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.modalTextFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.sectionTitleFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.rowTitleFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.bodyFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.controlFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.inlineMessageFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.inlineMessageSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.titleBottomPadding, 20, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.danielStackSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.appearancePickerWidth, 172, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.languagePickerWidth, 132, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.shortcutCapsuleWidth, 84, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.shortcutCapsuleHeight, 28, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.shortcutIssueMessageMaxWidth, 166, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.launchAtLoginMessageMaxWidth, 198, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.openAtLoginToggleWidth, 52, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonSpacing, 10, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonNarrowWidth, 112, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonWideWidth, 134, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonWidth(for: .email), 112, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonWidth(for: .whatsApp), 134, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonWidth(for: .telegram), 134, accuracy: 0.5)
        XCTAssertEqual(
            SettingsContentLayout.contactButtonWidth(for: .email)
                + SettingsContentLayout.contactButtonWidth(for: .whatsApp)
                + SettingsContentLayout.contactButtonWidth(for: .telegram)
                + SettingsContentLayout.contactButtonSpacing * 2,
            SettingsContentLayout.contentWidth,
            accuracy: 0.5
        )
        XCTAssertEqual(SettingsContentLayout.contactButtonHeight, 42, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonHorizontalPadding, 6, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonInnerSpacing, 6, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactLabelArrowSpacing, 2, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactButtonCornerRadius, 8, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactIconSize, 30, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactIconCornerRadius, 8, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.symbolFontSize, 14, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactSpacerMinLength, 4, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.contactFeedbackHeight, 18, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.closeButtonSize, 24, accuracy: 0.5)
        XCTAssertEqual(SettingsContentLayout.closeButtonInset, 14, accuracy: 0.5)

        let settingsSource = try sourceFileContent("lazyquips/App/LaunchAtLoginSettingsView.swift")
        let overlayRange = try XCTUnwrap(settingsSource.range(of: "struct SettingsOverlayView: View"))
        let contentRange = try XCTUnwrap(settingsSource.range(of: "struct SettingsContentView: View"))
        let rowRange = try XCTUnwrap(settingsSource.range(of: "private struct SettingsRow"))
        let overlaySource = String(settingsSource[overlayRange.lowerBound..<contentRange.lowerBound])
        let contentSource = String(settingsSource[contentRange.lowerBound..<rowRange.lowerBound])
        let appearanceRange = try XCTUnwrap(settingsSource.range(of: "private var appearanceRow: some View"))
        let appearanceSelectionRange = try XCTUnwrap(settingsSource.range(of: "private var appearanceSelection"))
        let appearanceSource = String(settingsSource[appearanceRange.lowerBound..<appearanceSelectionRange.lowerBound])
        let languageRange = try XCTUnwrap(settingsSource.range(of: "private var languageRow: some View"))
        let languageSelectionRange = try XCTUnwrap(settingsSource.range(of: "private var languageSelection"))
        let languageSource = String(settingsSource[languageRange.lowerBound..<languageSelectionRange.lowerBound])
        let shortcutRange = try XCTUnwrap(settingsSource.range(of: "private var shortcutRow: some View"))
        let shortcutMessageRange = try XCTUnwrap(settingsSource.range(of: "private var shortcutIssueMessage"))
        let shortcutSource = String(settingsSource[shortcutRange.lowerBound..<shortcutMessageRange.lowerBound])
        let openAtLoginRange = try XCTUnwrap(settingsSource.range(of: "private var openAtLoginRow: some View"))
        let launchAtLoginMessageRange = try XCTUnwrap(settingsSource.range(of: "private var launchAtLoginMessage: String?"))
        let openAtLoginSource = String(settingsSource[openAtLoginRange.lowerBound..<launchAtLoginMessageRange.lowerBound])
        let danielRange = try XCTUnwrap(settingsSource.range(of: "private var danielSection: some View"))
        let updateRange = try XCTUnwrap(settingsSource.range(of: "private func updateLaunchAtLogin"))
        let launchAtLoginMessageSource = String(settingsSource[launchAtLoginMessageRange.lowerBound..<danielRange.lowerBound])
        let danielSource = String(settingsSource[contentRange.lowerBound..<updateRange.lowerBound])
        let buttonRange = try XCTUnwrap(settingsSource.range(of: "private struct ContactChannelButton"))
        let rowSource = String(settingsSource[rowRange.lowerBound..<buttonRange.lowerBound])
        let buttonSource = String(settingsSource[buttonRange.lowerBound...])

        XCTAssertTrue(overlaySource.contains("DimmingScrim(opacity: SettingsContentLayout.overlayDimmingOpacity)"))
        XCTAssertTrue(overlaySource.contains("dismissScrim"))
        XCTAssertTrue(overlaySource.contains(".accessibilityHidden(true)"))
        XCTAssertTrue(overlaySource.contains("closeButton"))
        XCTAssertTrue(overlaySource.contains("@FocusState private var isCloseButtonFocused"))
        XCTAssertTrue(overlaySource.contains(".contentShape("))
        XCTAssertTrue(overlaySource.contains(".onTapGesture {}"))
        XCTAssertTrue(overlaySource.contains(".focused($isCloseButtonFocused)"))
        XCTAssertTrue(overlaySource.contains("SettingsContentLayout.overlayBreathingPadding"))
        XCTAssertTrue(overlaySource.contains("SettingsContentLayout.closeButtonInset"))
        XCTAssertTrue(overlaySource.contains("SettingsContentLayout.symbolFontSize"))
        XCTAssertTrue(overlaySource.contains("onExitCommand(perform: onDismiss)"))
        XCTAssertFalse(contentSource.contains("Spacer(minLength: 0)"))
        XCTAssertFalse(contentSource.contains("cancelButton"))
        XCTAssertFalse(contentSource.contains("okButton"))
        XCTAssertFalse(contentSource.contains("footer"))
        XCTAssertTrue(contentSource.contains(".tint(LazyQuipsVisualStyle.carbonCopyPurple)"))
        XCTAssertTrue(contentSource.contains(".frame(width: SettingsContentLayout.cardWidth)"))
        XCTAssertTrue(contentSource.contains(".font(.system(size: SettingsContentLayout.controlFontSize))"))
        XCTAssertTrue(contentSource.contains("SettingsContentLayout.titleBottomPadding"))
        let appearanceFixedSizeRange = try XCTUnwrap(appearanceSource.range(of: ".fixedSize()"))
        let appearanceFrameRange = try XCTUnwrap(
            appearanceSource.range(of: ".frame(width: SettingsContentLayout.appearancePickerWidth, alignment: .trailing)")
        )
        XCTAssertLessThan(appearanceFixedSizeRange.lowerBound, appearanceFrameRange.lowerBound)
        XCTAssertTrue(appearanceSource.contains(".controlSize(.regular)"))
        XCTAssertFalse(appearanceSource.contains(".controlSize(.small)"))
        let languageFixedSizeRange = try XCTUnwrap(languageSource.range(of: ".fixedSize()"))
        let languageFrameRange = try XCTUnwrap(
            languageSource.range(of: ".frame(width: SettingsContentLayout.languagePickerWidth, alignment: .trailing)")
        )
        XCTAssertLessThan(languageFixedSizeRange.lowerBound, languageFrameRange.lowerBound)
        XCTAssertTrue(languageSource.contains(".controlSize(.regular)"))
        XCTAssertFalse(languageSource.contains(".controlSize(.small)"))
        XCTAssertTrue(shortcutSource.contains("shortcutIssueMessage"))
        XCTAssertTrue(shortcutSource.contains("SettingsContentLayout.inlineMessageSpacing"))
        XCTAssertTrue(shortcutSource.contains("SettingsContentLayout.inlineMessageFontSize"))
        XCTAssertTrue(shortcutSource.contains("SettingsContentLayout.shortcutIssueMessageMaxWidth"))
        XCTAssertTrue(shortcutSource.contains(".lineLimit(2)"))
        XCTAssertTrue(shortcutSource.contains(".multilineTextAlignment(.trailing)"))
        XCTAssertTrue(shortcutSource.contains("SettingsContentLayout.shortcutCapsuleWidth"))
        XCTAssertTrue(shortcutSource.contains("SettingsContentLayout.shortcutCapsuleHeight"))
        XCTAssertFalse(shortcutSource.contains("shortcutStatusText"))
        XCTAssertFalse(shortcutSource.contains("shortcutStatusColor"))
        XCTAssertTrue(openAtLoginSource.contains("launchAtLoginMessageContent(message)"))
        XCTAssertTrue(openAtLoginSource.contains("SettingsContentLayout.inlineMessageSpacing"))
        XCTAssertTrue(openAtLoginSource.contains("SettingsContentLayout.launchAtLoginMessageMaxWidth"))
        XCTAssertTrue(openAtLoginSource.contains(".lineLimit(2)"))
        XCTAssertTrue(openAtLoginSource.contains(".multilineTextAlignment(.trailing)"))
        XCTAssertTrue(openAtLoginSource.contains("SettingsContentLayout.openAtLoginToggleWidth"))
        let openAtLoginToggleFixedSizeRange = try XCTUnwrap(openAtLoginSource.range(of: ".fixedSize()"))
        let openAtLoginToggleFrameRange = try XCTUnwrap(
            openAtLoginSource.range(
                of: ".frame(width: SettingsContentLayout.openAtLoginToggleWidth, alignment: .trailing)"
            )
        )
        XCTAssertLessThan(openAtLoginToggleFixedSizeRange.lowerBound, openAtLoginToggleFrameRange.lowerBound)
        XCTAssertTrue(openAtLoginSource.contains(".controlSize(.regular)"))
        XCTAssertFalse(openAtLoginSource.contains(".controlSize(.small)"))
        XCTAssertTrue(openAtLoginSource.contains("errorKey == nil && displayState == .requiresApproval"))
        let launchAtLoginErrorRange = try XCTUnwrap(launchAtLoginMessageSource.range(of: "if let errorKey"))
        let launchAtLoginApprovalRange = try XCTUnwrap(
            launchAtLoginMessageSource.range(of: "case .requiresApproval:")
        )
        XCTAssertLessThan(launchAtLoginErrorRange.lowerBound, launchAtLoginApprovalRange.lowerBound)
        XCTAssertFalse(launchAtLoginMessageSource.contains(".openAtLoginOn"))
        XCTAssertFalse(launchAtLoginMessageSource.contains(".openAtLoginOff"))
        XCTAssertFalse(danielSource.contains(".font(.system(size: 16"))
        XCTAssertTrue(danielSource.contains(".font(.system(size: SettingsContentLayout.sectionTitleFontSize))"))
        XCTAssertFalse(danielSource.contains("sectionTitleFontSize, weight: .semibold"))
        XCTAssertTrue(danielSource.contains("SettingsContentLayout.sectionTitleFontSize"))
        XCTAssertTrue(danielSource.contains("SettingsContentLayout.bodyFontSize"))
        XCTAssertTrue(danielSource.contains("SettingsContentLayout.danielStackSpacing"))
        XCTAssertTrue(danielSource.contains("SettingsContentLayout.contactButtonSpacing"))
        XCTAssertTrue(danielSource.contains("SettingsContentLayout.contactFeedbackHeight"))
        XCTAssertTrue(danielSource.contains(".frame(width: SettingsContentLayout.contentWidth"))
        XCTAssertTrue(rowSource.contains("HStack(alignment: .center, spacing: SettingsContentLayout.rowContentSpacing)"))
        XCTAssertTrue(rowSource.contains(".frame(maxWidth: .infinity, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains("width: SettingsContentLayout.rowTrailingColumnWidth"))
        XCTAssertTrue(rowSource.contains("width: SettingsContentLayout.contentWidth"))
        XCTAssertTrue(rowSource.contains("height: SettingsContentLayout.rowHeight"))
        XCTAssertFalse(rowSource.contains("Spacer()"))
        XCTAssertFalse(buttonSource.contains("Color.green"))
        XCTAssertFalse(buttonSource.contains(".fill(Color.green)"))
        XCTAssertFalse(buttonSource.contains("iconResolver"))
        XCTAssertFalse(buttonSource.contains("Image(nsImage:"))
        XCTAssertFalse(buttonSource.contains("Image(channel.assetName)"))
        XCTAssertFalse(buttonSource.contains(".renderingMode(.original)"))
        XCTAssertTrue(buttonSource.contains("Image(systemName: channel.systemSymbolName)"))
        XCTAssertTrue(buttonSource.contains("SettingsContentLayout.contactSpacerMinLength"))
        XCTAssertTrue(buttonSource.contains("SettingsContentLayout.contactButtonWidth(for: channel)"))
        XCTAssertTrue(buttonSource.contains("SettingsContentLayout.contactLabelArrowSpacing"))
        XCTAssertTrue(buttonSource.contains(".fixedSize(horizontal: true, vertical: false)"))
        XCTAssertTrue(buttonSource.contains(".layoutPriority(1)"))
        XCTAssertTrue(buttonSource.contains("SettingsContentLayout.contactButtonHorizontalPadding"))
        XCTAssertTrue(buttonSource.contains("SettingsContentLayout.contactButtonCornerRadius"))
        XCTAssertTrue(buttonSource.contains("SettingsContactButtonStyle"))
        XCTAssertTrue(buttonSource.contains("LazyQuipsVisualStyle.carbonCopyPurple.opacity(0.14)"))
        XCTAssertTrue(buttonSource.contains("LazyQuipsVisualStyle.carbonCopyPurple.opacity(0.32)"))
        XCTAssertFalse(buttonSource.contains("Color(nsColor: .controlAccentColor)"))
        XCTAssertTrue(buttonSource.contains(".onHover"))
        XCTAssertFalse(buttonSource.contains("contactArrowFontSize"))
    }

    func testPhraseLibraryIndexLayoutKeepsFullNavigationVisible() {
        XCTAssertEqual(PhraseIndexLayout.itemWidth, 19, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.itemHeight, 14, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.hitWidth, 24, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.hitHeight, PhraseIndexLayout.itemHeight, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.verticalSpacing, 1, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.itemFontSize, 12, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.libraryTrailingSpacing, 13, accuracy: 0.5)
        XCTAssertEqual(PhraseIndexLayout.libraryReservedTrailingWidth, 37, accuracy: 0.5)
        XCTAssertLessThanOrEqual(
            PhraseIndexLayout.stackHeight(forItemCount: 29),
            StatusMenuLayout.maximumContentHeight
        )

        let minimumMainWindowIndexViewportHeight = PhraseLibraryLayout.windowHeight
            - 20
            - PhraseLibraryLayout.toolbarControlHeight
            - PhraseLibraryLayout.listTopPadding
            - PhraseLibraryLayout.listBottomPadding
            - 16
            - PhraseLibraryLayout.toolbarControlHeight
        XCTAssertLessThanOrEqual(
            PhraseIndexLayout.stackHeight(forItemCount: 29),
            minimumMainWindowIndexViewportHeight
        )
    }

    func testPhraseLibraryIndexIsCenteredInListViewport() throws {
        let librarySource = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let phraseListCallRange = try XCTUnwrap(librarySource.range(of: "PhraseListView("))
        let disabledRange = try XCTUnwrap(librarySource.range(of: ".disabled(isModalOverlayPresented)"))
        let mainListSource = String(librarySource[phraseListCallRange.lowerBound..<disabledRange.lowerBound])
        let listViewRange = try XCTUnwrap(librarySource.range(of: "private struct PhraseListView: View"))
        let hiderRange = try XCTUnwrap(librarySource.range(of: "private struct NativeScrollIndicatorHider"))
        let listViewSource = String(librarySource[listViewRange.lowerBound..<hiderRange.lowerBound])
        let scrollViewRange = try XCTUnwrap(listViewSource.range(of: "ScrollView {"))
        let indexViewRange = try XCTUnwrap(listViewSource.range(of: "PhraseIndexView(titles: indexTitles"))
        let scrollViewSource = String(listViewSource[scrollViewRange.lowerBound..<indexViewRange.lowerBound])

        XCTAssertTrue(mainListSource.contains(".padding(.top, PhraseLibraryLayout.listTopPadding)"))
        XCTAssertTrue(mainListSource.contains(".padding(.bottom, PhraseLibraryLayout.listBottomPadding)"))
        XCTAssertFalse(mainListSource.contains(".padding(.horizontal"))
        XCTAssertTrue(listViewSource.contains("ZStack(alignment: .trailing)"))
        XCTAssertFalse(listViewSource.contains("HStack(alignment: .top"))
        XCTAssertLessThan(scrollViewRange.lowerBound, indexViewRange.lowerBound)
        XCTAssertTrue(listViewSource.contains(".frame(width: PhraseShortcutPreview.columnWidth, alignment: .leading)"))
        XCTAssertTrue(listViewSource.contains(".padding(.leading, PhraseLibraryLayout.rowTextLeadingPadding)"))
        XCTAssertTrue(listViewSource.contains(".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)"))
        XCTAssertTrue(scrollViewSource.contains(".padding(.trailing, PhraseIndexLayout.libraryReservedTrailingWidth)"))
    }

    func testPhraseLibraryRowAndIndexHitTargetsMatchVisualIntent() throws {
        let librarySource = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let rowRange = try XCTUnwrap(librarySource.range(of: "private struct PhraseRowView: View"))
        let contextMenuRange = try XCTUnwrap(librarySource.range(of: "private struct PhraseContextMenu: View"))
        let rowSource = String(librarySource[rowRange.lowerBound..<contextMenuRange.lowerBound])
        let indexRange = try XCTUnwrap(librarySource.range(of: "struct PhraseIndexView: View"))
        let emptyStateRange = try XCTUnwrap(librarySource.range(of: "private struct PhraseEmptyStateView"))
        let indexSource = String(librarySource[indexRange.lowerBound..<emptyStateRange.lowerBound])

        XCTAssertEqual(PhraseLibraryLayout.rowHeight, StatusMenuLayout.rowHeight, accuracy: 0.5)
        XCTAssertTrue(rowSource.contains(".frame(height: PhraseLibraryLayout.rowHeight)"))
        XCTAssertTrue(rowSource.contains(".frame(maxWidth: .infinity, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains(".padding(.leading, PhraseLibraryLayout.rowTextLeadingPadding)"))
        XCTAssertTrue(rowSource.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(rowSource.contains(".onTapGesture(perform: onCopy)"))
        XCTAssertTrue(rowSource.contains(".contextMenu"))
        XCTAssertTrue(rowSource.contains("ZStack(alignment: .trailing)"))
        XCTAssertTrue(rowSource.contains("Rectangle()"))
        XCTAssertTrue(rowSource.contains("let isSelected: Bool"))
        XCTAssertTrue(rowSource.contains("if isSelected || isHovered"))
        XCTAssertFalse(rowSource.contains(".padding(.vertical, 2)"))
        XCTAssertTrue(rowSource.contains(".foregroundStyle(isSelected ? .white : .primary)"))
        XCTAssertTrue(rowSource.contains("LazyQuipsVisualStyle.rowSelectedBackground"))
        XCTAssertTrue(rowSource.contains("LazyQuipsVisualStyle.rowHoverBackground"))
        XCTAssertTrue(rowSource.contains("LazyQuipsRowBoundaryOverlay()"))
        XCTAssertFalse(librarySource.contains("PhraseShortcutPreview.text(for:"))
        XCTAssertTrue(rowSource.contains("Text(phrase.shortcut)"))
        XCTAssertTrue(rowSource.contains(".lineLimit(PhraseShortcutPreview.maximumLineCount)"))
        XCTAssertTrue(rowSource.contains(".truncationMode(.tail)"))
        XCTAssertTrue(rowSource.contains(".frame(width: PhraseShortcutPreview.wrappingWidth, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains(".frame(width: PhraseShortcutPreview.columnWidth, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains("Text(previewText)"))
        XCTAssertTrue(librarySource.contains("previewText: (Phrase) -> String = { PhraseBodyPreview.text(for: $0.body) }"))
        XCTAssertTrue(librarySource.contains("previewText: previewText(phrase)"))
        XCTAssertFalse(rowSource.contains("PhraseBodyPreview.text(for: phrase.body)"))
        XCTAssertTrue(rowSource.contains(".lineLimit(2)"))
        XCTAssertFalse(rowSource.contains("Text(phrase.body)"))
        XCTAssertTrue(rowSource.contains("LazyQuipsCopiedBadge(language: language)"))
        XCTAssertTrue(rowSource.contains("PhraseLibraryLayout.rowBodyTrailingPadding(isCopied: isCopied)"))
        XCTAssertTrue(rowSource.contains("PhraseLibraryLayout.rowCopiedFeedbackTrailingPadding"))
        XCTAssertTrue(rowSource.contains("accessibilityReduceMotion"))
        XCTAssertFalse(rowSource.contains(".padding(.horizontal, 0)"))
        XCTAssertFalse(rowSource.contains(".opacity(isCopied ? 0 : 1)"))
        XCTAssertTrue(librarySource.contains("private func setCopiedRowID(_ rowID: PhraseLibraryRowID?)"))
        XCTAssertTrue(librarySource.contains("@State private var selectedRowID: PhraseLibraryRowID?"))
        XCTAssertTrue(librarySource.contains("selectedRowID: selectedRowID"))
        XCTAssertTrue(librarySource.contains("isSelected: selectedRowID == row.id"))
        XCTAssertTrue(librarySource.contains("private func setFeedbackRowID(_ rowID: PhraseLibraryRowID?)"))
        XCTAssertTrue(librarySource.contains("selectedRowID = rowID"))
        XCTAssertTrue(librarySource.contains("setFeedbackRowID(nil)"))
        XCTAssertFalse(rowSource.contains("RoundedRectangle(cornerRadius: 6)"))
        XCTAssertTrue(indexSource.contains("hitTargetLabel(title)"))
        XCTAssertTrue(indexSource.contains("PhraseIndexLayout.hitWidth"))
        XCTAssertTrue(indexSource.contains("PhraseIndexLayout.hitHeight"))
        XCTAssertTrue(indexSource.contains(".contentShape(Rectangle())"))
    }

    func testPhrasePaletteRowsUseExplicitRectangularHitShape() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let rowRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteRowView: View"))
        let emptyStateRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteEmptyStateView"))
        let rowSource = String(paletteSource[rowRange.lowerBound..<emptyStateRange.lowerBound])
        let phraseBodyRange = try XCTUnwrap(rowSource.range(of: "Text(row.phrase.body)"))
        let rowContentPaddingRange = try XCTUnwrap(rowSource.range(of: ".padding(.leading, StatusMenuLayout.rowLeadingPadding)"))
        let phraseBodySource = String(rowSource[phraseBodyRange.lowerBound..<rowContentPaddingRange.lowerBound])

        XCTAssertTrue(rowSource.contains(".frame(width: StatusMenuLayout.rowWidth, height: StatusMenuLayout.rowHeight, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains("width: StatusMenuLayout.rowVisualWidth"))
        XCTAssertTrue(rowSource.contains(".buttonStyle(.plain)"))
        XCTAssertTrue(rowSource.contains(".contentShape(Rectangle())"))
        XCTAssertFalse(paletteSource.contains("PhraseShortcutPreview.text(for:"))
        XCTAssertTrue(rowSource.contains("Text(row.phrase.shortcut)"))
        XCTAssertTrue(rowSource.contains(".lineLimit(PhraseShortcutPreview.maximumLineCount)"))
        XCTAssertTrue(rowSource.contains(".truncationMode(.tail)"))
        XCTAssertTrue(rowSource.contains(".frame(width: PhraseShortcutPreview.wrappingWidth, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains(".frame(width: StatusMenuLayout.shortcutColumnWidth, alignment: .leading)"))
        XCTAssertTrue(rowSource.contains("LazyQuipsCopiedBadge(language: language)"))
        XCTAssertTrue(rowSource.contains(".padding(.trailing, StatusMenuLayout.rowCopiedFeedbackTrailingPadding)"))
        XCTAssertTrue(rowSource.contains("LazyQuipsVisualStyle.rowSelectedBackground"))
        XCTAssertTrue(rowSource.contains("LazyQuipsVisualStyle.rowHoverBackground"))
        XCTAssertTrue(rowSource.contains("LazyQuipsRowBoundaryOverlay()"))
        XCTAssertTrue(rowSource.contains("accessibilityReduceMotion"))
        XCTAssertFalse(phraseBodySource.contains(".padding(.trailing"))
        XCTAssertFalse(phraseBodySource.contains("copiedBadgeReservedWidth"))
        XCTAssertTrue(rowSource.contains("StatusMenuLayout.rowCopiedFeedbackTrailingPadding"))
        XCTAssertTrue(paletteSource.contains("private func setCopiedRowID(_ rowID: PhrasePaletteRowID?)"))
    }

    func testPhrasePaletteFreezesVisibleSnapshotAfterCopyUntilClose() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let bodyRange = try XCTUnwrap(paletteSource.range(of: "var body: some View"))
        let dataRange = try XCTUnwrap(paletteSource.range(of: "enum PhrasePaletteData"))
        let viewSource = String(paletteSource[bodyRange.lowerBound..<dataRange.lowerBound])
        let searchChangeRange = try XCTUnwrap(viewSource.range(of: ".onChange(of: searchText)"))
        let selectableRowsChangeRange = try XCTUnwrap(viewSource.range(of: ".onChange(of: snapshot.selectableRowIDs)"))
        let searchChangeSource = String(viewSource[searchChangeRange.lowerBound..<selectableRowsChangeRange.lowerBound])

        XCTAssertTrue(paletteSource.contains("@State private var frozenSnapshotAfterCopy: PhrasePaletteSnapshot?"))
        XCTAssertTrue(paletteSource.contains("@State private var snapshotCache = PhrasePaletteSnapshotCache()"))
        XCTAssertTrue(paletteSource.contains("@State private var textMetricsCache = PhrasePaletteTextMetrics.Cache()"))
        XCTAssertTrue(viewSource.contains("let snapshot = currentSnapshot()"))
        XCTAssertTrue(viewSource.contains("private func currentSnapshot() -> PhrasePaletteSnapshot"))
        XCTAssertTrue(viewSource.contains("if let frozenSnapshotAfterCopy"))
        XCTAssertTrue(viewSource.contains("return snapshotCache.snapshot("))
        XCTAssertTrue(viewSource.contains("copyPhrase(row, snapshot: snapshot)"))
        XCTAssertTrue(viewSource.contains("frozenSnapshotAfterCopy = snapshot"))
        XCTAssertTrue(viewSource.contains("guard frozenSnapshotAfterCopy == nil else"))
        XCTAssertTrue(searchChangeSource.contains("selectFirstResult(in: snapshot, showsKeyboardSubmenu: snapshot.hasSearchText)"))
        XCTAssertFalse(searchChangeSource.contains("snapshotCache.snapshot("))
        XCTAssertTrue(viewSource.contains("frozenSnapshotAfterCopy = nil"))
        XCTAssertFalse(viewSource.contains("snapshotCache.invalidate()"))
        XCTAssertFalse(paletteSource.contains("func invalidate()"))
    }

    func testPhrasePalettePrewarmsSearchIndexesAfterDataIsAvailable() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let bodyRange = try XCTUnwrap(paletteSource.range(of: "var body: some View"))
        let dataRange = try XCTUnwrap(paletteSource.range(of: "enum PhrasePaletteData"))
        let viewSource = String(paletteSource[bodyRange.lowerBound..<dataRange.lowerBound])
        let scheduleRange = try XCTUnwrap(viewSource.range(of: "private func scheduleSearchIndexPrewarm(for phrases: [Phrase])"))
        let resetRange = try XCTUnwrap(viewSource.range(of: "private func applyPresentationIfNeeded"))
        let scheduleSource = String(viewSource[scheduleRange.lowerBound..<resetRange.lowerBound])

        XCTAssertTrue(paletteSource.contains("@State private var searchIndexPrewarmTask: Task<Void, Never>?"))
        XCTAssertTrue(paletteSource.contains("let searchIndexPrewarmSignature = phrases.map(PhrasePaletteSearchIndexPrewarmSignature.init)"))
        XCTAssertTrue(viewSource.contains("scheduleSearchIndexPrewarm(for: phrases)"))
        XCTAssertTrue(viewSource.contains(".onChange(of: searchIndexPrewarmSignature)"))
        XCTAssertTrue(scheduleSource.contains("searchIndexPrewarmTask?.cancel()"))
        XCTAssertTrue(scheduleSource.contains("Task { @MainActor in"))
        XCTAssertTrue(scheduleSource.contains("Task.sleep(nanoseconds: 200_000_000)"))
        XCTAssertTrue(scheduleSource.contains("snapshotCache.prewarmSearchIndexes(for: phrases)"))
        XCTAssertFalse(scheduleSource.contains("snapshotCache.snapshot("))
        XCTAssertTrue(paletteSource.contains("struct PhrasePaletteSearchIndexPrewarmSignature: Equatable"))
        XCTAssertTrue(paletteSource.contains("func prewarmSearchIndexes(for phrases: [Phrase])"))
        XCTAssertTrue(paletteSource.contains("_ = searchIndexCache.sortedIndexes(for: phrases)"))
    }

    func testPhrasePaletteSkipsDelayedHoverWorkForRowsWithoutSubmenu() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let makeRowsRange = try XCTUnwrap(paletteSource.range(of: "private static func makeRows("))
        let sectionIDRange = try XCTUnwrap(paletteSource.range(of: "enum PhrasePaletteSectionID"))
        let makeRowsSource = String(paletteSource[makeRowsRange.lowerBound..<sectionIDRange.lowerBound])
        let hoverRange = try XCTUnwrap(paletteSource.range(of: "private func scheduleSubmenuHover(for row: PhrasePaletteRow)"))
        let endHoverRange = try XCTUnwrap(paletteSource.range(of: "private func endSubmenuHover(rowID: PhrasePaletteRowID)"))
        let hoverSource = String(paletteSource[hoverRange.lowerBound..<endHoverRange.lowerBound])
        let keyboardRange = try XCTUnwrap(paletteSource.range(of: "private func updateKeyboardSubmenu("))
        let notifyRange = try XCTUnwrap(paletteSource.range(of: "private func notifyPreferredContentSize"))
        let keyboardSource = String(paletteSource[keyboardRange.lowerBound..<notifyRange.lowerBound])

        XCTAssertTrue(paletteSource.contains("let mayNeedSubmenu: Bool"))
        XCTAssertTrue(makeRowsSource.contains("mayNeedSubmenu: PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(phrase.body)"))
        XCTAssertFalse(makeRowsSource.contains("PhrasePaletteTextMetrics.needsSubmenu(phrase.body)"))
        XCTAssertTrue(hoverSource.contains("guard row.mayNeedSubmenu else"))
        XCTAssertTrue(hoverSource.contains("cancelSubmenuHover()"))
        XCTAssertTrue(hoverSource.contains("let phrase = row.phrase"))
        XCTAssertTrue(hoverSource.contains("textMetricsCache.needsSubmenu(for: phrase)"))
        XCTAssertTrue(hoverSource.contains("submenuHoverState.end(rowID: rowID)"))
        XCTAssertTrue(keyboardSource.contains("let row = snapshot.selectableRowByID[rowID]"))
        XCTAssertTrue(keyboardSource.contains("row.mayNeedSubmenu"))
        XCTAssertTrue(keyboardSource.contains("textMetricsCache.needsSubmenu(for: row.phrase)"))
    }

    func testPhrasePaletteTextMetricsCacheUsesLightweightPhraseRevisionKeys() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let cacheRange = try XCTUnwrap(paletteSource.range(of: "final class Cache"))
        let footerActionRange = try XCTUnwrap(paletteSource.range(of: "enum StatusMenuFooterAction"))
        let cacheSource = String(paletteSource[cacheRange.lowerBound..<footerActionRange.lowerBound])

        XCTAssertTrue(cacheSource.contains("let phraseID: UUID"))
        XCTAssertTrue(cacheSource.contains("let contentRevision: Int"))
        XCTAssertTrue(cacheSource.contains("func needsSubmenu(for phrase: Phrase)"))
        XCTAssertTrue(cacheSource.contains("func submenuBodyHeight(\n            for phrase: Phrase"))
        XCTAssertTrue(cacheSource.contains("phraseID: phrase.id"))
        XCTAssertTrue(cacheSource.contains("contentRevision: phrase.contentRevision"))
        XCTAssertTrue(cacheSource.contains("PhrasePaletteTextMetrics.submenuBodyHeight(for: phrase.body"))
        XCTAssertFalse(cacheSource.contains("let text: String"))
        XCTAssertFalse(cacheSource.contains("BodyHeightKey(text:"))
        XCTAssertFalse(cacheSource.contains("LineCountKey(text:"))
    }

    func testPerformanceSignpostsCoverCoreLatencyPathsWithoutUserContentPayloads() throws {
        let sourceByPath = [
            "lazyquips/App/AppDelegate.swift": try sourceFileContent("lazyquips/App/AppDelegate.swift"),
            "lazyquips/App/StatusBarController.swift": try sourceFileContent("lazyquips/App/StatusBarController.swift"),
            "lazyquips/App/Phrases/PhraseSearch.swift": try sourceFileContent("lazyquips/App/Phrases/PhraseSearch.swift"),
            "lazyquips/App/Phrases/PhraseSearchIndex.swift": try sourceFileContent("lazyquips/App/Phrases/PhraseSearchIndex.swift"),
            "lazyquips/App/Phrases/UI/PhraseLibraryView.swift": try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift"),
            "lazyquips/App/QuickRepliesView.swift": try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        ]
        let appSource = try XCTUnwrap(sourceByPath["lazyquips/App/AppDelegate.swift"])

        XCTAssertTrue(appSource.contains("enum LazyQuipsPerformanceSignpost"))
        XCTAssertTrue(appSource.contains("OSLog("))
        XCTAssertEqual(appSource.components(separatedBy: "os_signpost(").count - 1, 2)
        XCTAssertTrue(appSource.contains("os_signpost(.begin, log: log, name: name, signpostID: signpostID)"))
        XCTAssertTrue(appSource.contains("os_signpost(.end, log: log, name: name, signpostID: signpostID)"))

        for (path, source) in sourceByPath where path != "lazyquips/App/AppDelegate.swift" {
            XCTAssertFalse(source.contains("os_signpost("), path)
        }

        let expectedSignposts = [
            ("lazyquips/App/AppDelegate.swift", "MainWindow.Open"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Prewarm"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open.Prepare"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open.PresentationReset"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open.Frame"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open.OrderFront"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Open.Monitors"),
            ("lazyquips/App/StatusBarController.swift", "Popover.RefreshContent"),
            ("lazyquips/App/StatusBarController.swift", "Popover.Close"),
            ("lazyquips/App/Phrases/UI/PhraseLibraryView.swift", "MainWindow.Snapshot"),
            ("lazyquips/App/QuickRepliesView.swift", "Palette.Snapshot"),
            ("lazyquips/App/Phrases/PhraseSearch.swift", "Search.Query"),
            ("lazyquips/App/Phrases/PhraseSearchIndex.swift", "Search.IndexBuild"),
            ("lazyquips/App/Phrases/PhraseSearchIndex.swift", "Search.IndexSort"),
            ("lazyquips/App/Phrases/UI/PhraseLibraryView.swift", "Selection.Update"),
            ("lazyquips/App/QuickRepliesView.swift", "Selection.Update"),
            ("lazyquips/App/Phrases/UI/PhraseLibraryView.swift", "Selection.Submit"),
            ("lazyquips/App/QuickRepliesView.swift", "Selection.Submit")
        ]

        for (path, signpostName) in expectedSignposts {
            let source = try XCTUnwrap(sourceByPath[path])
            XCTAssertTrue(
                source.contains("LazyQuipsPerformanceSignpost.interval(\"\(signpostName)\")"),
                "\(path) should contain \(signpostName)"
            )
        }
        let searchIndexSource = try XCTUnwrap(sourceByPath["lazyquips/App/Phrases/PhraseSearchIndex.swift"])
        XCTAssertEqual(searchIndexSource.components(separatedBy: "\"Search.IndexBuild\"").count - 1, 1)
        XCTAssertEqual(searchIndexSource.components(separatedBy: "\"Search.IndexSort\"").count - 1, 1)

        let forbiddenPayloadTokens = ["searchText", "query", "shortcut", "body", "phrase.id", "phraseID", "UUID"]
        for (path, source) in sourceByPath {
            for line in source.split(separator: "\n").map(String.init)
                where line.contains("LazyQuipsPerformanceSignpost.interval(") {
                XCTAssertTrue(line.contains("LazyQuipsPerformanceSignpost.interval(\""), "\(path): \(line)")
                for token in forbiddenPayloadTokens {
                    XCTAssertFalse(line.contains(token), "\(path): \(line)")
                }
            }
        }
    }

    func testPhrasePaletteRowBoundsPreferenceOnlyReportsActiveSubmenuRow() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let viewRange = try XCTUnwrap(paletteSource.range(of: "struct QuickRepliesView: View"))
        let dataRange = try XCTUnwrap(paletteSource.range(of: "enum PhrasePaletteData"))
        let viewSource = String(paletteSource[viewRange.lowerBound..<dataRange.lowerBound])
        let sectionRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteSectionView: View"))
        let rowRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteRowView: View"))
        let sectionSource = String(paletteSource[sectionRange.lowerBound..<rowRange.lowerBound])
        let emptyStateRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteEmptyStateView"))
        let rowSource = String(paletteSource[rowRange.lowerBound..<emptyStateRange.lowerBound])

        XCTAssertTrue(viewSource.contains("private var activeSubmenuAnchorRowID: PhrasePaletteRowID?"))
        XCTAssertTrue(viewSource.contains("submenuHoverState.activeRowID ?? keyboardSubmenuRowID"))
        XCTAssertTrue(viewSource.contains("activeSubmenuAnchorRowID: activeSubmenuAnchorRowID"))
        XCTAssertTrue(sectionSource.contains("let activeSubmenuAnchorRowID: PhrasePaletteRowID?"))
        XCTAssertTrue(sectionSource.contains("activeSubmenuAnchorRowID: activeSubmenuAnchorRowID"))
        XCTAssertTrue(rowSource.contains("let activeSubmenuAnchorRowID: PhrasePaletteRowID?"))
        XCTAssertTrue(rowSource.contains(".anchorPreference(key: PhrasePaletteRowBoundsKey.self, value: .bounds)"))
        XCTAssertTrue(rowSource.contains("row.mayNeedSubmenu && row.id == activeSubmenuAnchorRowID ? [row.id: anchor] : [:]"))
    }

    func testPhrasePaletteSubmenuShortcutUsesBoldTitleWeight() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let submenuRange = try XCTUnwrap(paletteSource.range(of: "struct PhrasePaletteSubmenuView: View"))
        let submenuSource = String(paletteSource[submenuRange.lowerBound...])

        XCTAssertTrue(submenuSource.contains("Text(presentation.shortcut)"))
        XCTAssertTrue(submenuSource.contains(".font(.system(size: 14, weight: .bold))"))
        XCTAssertTrue(submenuSource.contains("Text(presentation.body)"))
        XCTAssertFalse(submenuSource.contains("Text(presentation.body)\n                    .font(.system(size: 14, weight: .bold))"))
    }

    func testPhrasePaletteStarredSectionUsesSymbolHeader() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let sectionRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteSectionView: View"))
        let rowRange = try XCTUnwrap(paletteSource.range(of: "private struct PhrasePaletteRowView: View"))
        let sectionSource = String(paletteSource[sectionRange.lowerBound..<rowRange.lowerBound])

        XCTAssertTrue(sectionSource.contains("Image(systemName: \"star\")"))
        XCTAssertTrue(sectionSource.contains(".accessibilityLabel(AppStrings.text(.star, language: language))"))
        XCTAssertFalse(sectionSource.contains("return AppStrings.text(.star, language: language)"))
    }

    func testPhrasePaletteAndLibraryHideVisibleScrollIndicators() throws {
        let paletteSource = try sourceFileContent("lazyquips/App/QuickRepliesView.swift")
        let librarySource = try sourceFileContent("lazyquips/App/Phrases/UI/PhraseLibraryView.swift")
        let hiderRange = try XCTUnwrap(librarySource.range(of: "private struct NativeScrollIndicatorHider"))
        let extensionRange = try XCTUnwrap(librarySource.range(of: "extension View"))
        let hiderSource = String(librarySource[hiderRange.lowerBound..<extensionRange.lowerBound])

        XCTAssertTrue(paletteSource.contains(".lazyQuipsScrollIndicatorsHidden()"))
        XCTAssertTrue(librarySource.contains(".lazyQuipsScrollIndicatorsHidden()"))
        XCTAssertTrue(librarySource.contains("scrollView.hasVerticalScroller = false"))
        XCTAssertTrue(librarySource.contains("scrollView.hasHorizontalScroller = false"))
        XCTAssertTrue(librarySource.contains("scrollView.autohidesScrollers = true"))
        XCTAssertTrue(librarySource.contains("scrollView.scrollerStyle = .overlay"))
        XCTAssertTrue(librarySource.contains("scrollView.verticalScroller = nil"))
        XCTAssertTrue(librarySource.contains("scrollView.horizontalScroller = nil"))
        XCTAssertTrue(librarySource.contains("retryDelays"))
        XCTAssertTrue(librarySource.contains("asyncAfter(deadline: .now() + delay)"))
        XCTAssertTrue(librarySource.contains("matchingDescendantScrollView(for: view)"))
        XCTAssertTrue(librarySource.contains("matchScore(for: lhs"))
        XCTAssertTrue(librarySource.contains("guard matchScore(for: scrollView, markerFrame: markerFrame) > 0 else"))
        XCTAssertTrue(hiderSource.contains("func makeCoordinator() -> Coordinator"))
        XCTAssertTrue(hiderSource.contains("private weak var cachedScrollView: NSScrollView?"))
        XCTAssertTrue(hiderSource.contains("private var isRetryScheduled = false"))
        XCTAssertTrue(hiderSource.contains("if let cachedScrollView"))
        XCTAssertTrue(hiderSource.contains("NativeScrollIndicatorHider.configureScrollIndicatorsHidden(cachedScrollView)"))
        XCTAssertTrue(hiderSource.contains("if let scrollView = NativeScrollIndicatorHider.configure(from: view)"))
        XCTAssertTrue(hiderSource.contains("guard !isRetryScheduled else"))
        XCTAssertTrue(hiderSource.contains("return scrollView"))
        XCTAssertFalse(librarySource.contains("firstDescendantScrollView"))
        XCTAssertFalse(paletteSource.contains("ScrollView(.horizontal"))
        XCTAssertFalse(paletteSource.contains("Axis.Set.horizontal"))
        XCTAssertFalse(paletteSource.contains(".scrollIndicators(.automatic)"))
        XCTAssertFalse(librarySource.contains(".scrollIndicators(.automatic)"))
    }

    func testPhraseGroupingCanPreserveSearchRankWithinSections() throws {
        let starred = Phrase(shortcut: "apple", body: "target body", isStarred: true)
        let recent = Phrase(shortcut: "apricot", body: "target body")
        let plain = Phrase(shortcut: "agh", body: "target body")
        let digit = Phrase(shortcut: "1target", body: "target body")
        let symbol = Phrase(shortcut: "#target", body: "target body")
        let source = try sourceFileContent("lazyquips/App/Phrases/PhraseGrouping.swift")
        let orderedRange = try XCTUnwrap(source.range(of: "private static func ordered("))
        let sourceEndRange = try XCTUnwrap(source.range(of: "private struct IndexedPhrase"))
        let orderedSource = String(source[orderedRange.lowerBound..<sourceEndRange.lowerBound])
        let sections = PhraseGrouping.sections(
            for: [starred, recent, plain, digit, symbol],
            preservingInputOrder: true
        )

        XCTAssertEqual(sections.map(\.title), ["Star", "0-9", "A", "#"])
        XCTAssertEqual(sections.first { $0.id == .starred }?.phrases.map(\.id), [starred.id])
        XCTAssertEqual(sections.first { $0.id == .letter("A") }?.phrases.map(\.id), [starred.id, recent.id, plain.id])
        XCTAssertEqual(sections.first { $0.id == .digits }?.phrases.map(\.id), [digit.id])
        XCTAssertEqual(sections.first { $0.id == .symbols }?.phrases.map(\.id), [symbol.id])
        XCTAssertTrue(orderedSource.contains("if preservingInputOrder {\n            return indexedPhrases.map(\\.phrase)\n        }"))
        XCTAssertFalse(orderedSource.contains(".sorted { $0.index < $1.index }"))
    }

    func testPhraseSearchMatchesShortcutBodyPinyinInitialsAndTypos() {
        let shortcutPhrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        let englishPhrase = Phrase(shortcut: "thanks", body: "Thanks, I will check and get back to you.")
        let chineseThanks = Phrase(shortcut: "cn-thanks", body: "谢谢，我稍后确认。")
        let chineseReminder = Phrase(shortcut: "reminder", body: "感谢你的提醒。")
        let phrases = [shortcutPhrase, englishPhrase, chineseThanks, chineseReminder]

        XCTAssertEqual(PhraseSearch.search("ag", in: phrases).first?.id, shortcutPhrase.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "thnaks", in: phrases).first?.phrase.id, englishPhrase.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "thnaks", in: phrases).first?.matchKind, .shortcutTypo)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "谢谢", in: phrases).first?.phrase.id, chineseThanks.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xiexie", in: phrases).first?.phrase.id, chineseThanks.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xx", in: phrases).first?.phrase.id, chineseThanks.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xieixe", in: phrases).first?.phrase.id, chineseThanks.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xieixe", in: phrases).first?.matchKind, .pinyinTypo)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "ganxie", in: phrases).first?.phrase.id, chineseReminder.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "gx", in: phrases).first?.phrase.id, chineseReminder.id)
        XCTAssertTrue(PhraseSearch.search("zzzz-no-match", in: phrases).isEmpty)
    }

    func testPhraseSearchPreparedIndexesMatchDirectSearchResults() {
        let accented = Phrase(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            shortcut: "é",
            body: "Accent shortcut"
        )
        let plainAccentPeer = Phrase(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
            shortcut: "e",
            body: "Plain shortcut"
        )
        let shortcutTypo = Phrase(shortcut: ";thanks", body: "Shortcut typo should win.")
        let starredBodyTypo = Phrase(shortcut: "aaa", body: "Thanks starred body.", isStarred: true)
        let recentBodyTypo = Phrase(shortcut: "bbb", body: "Thanks recent body.")
        let chineseThanks = Phrase(shortcut: "cn-thanks", body: "谢谢，我稍后确认。")
        let phrases = [accented, recentBodyTypo, chineseThanks, shortcutTypo, plainAccentPeer, starredBodyTypo]
        let usageStats = [
            PhraseUsageStats(
                phraseID: recentBodyTypo.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]
        let indexes = phrases.map(PhraseSearchIndex.init)
        let sortedIndexes = PhraseSearch.sortedPreparedIndexes(indexes)

        for query in ["", "   ", "thnaks", "xiexie", "xx", "谢谢", "e"] {
            let directSearchIDs = PhraseSearch.search(query, in: phrases, usageStats: usageStats).map(\.id)

            XCTAssertEqual(
                directSearchIDs,
                PhraseSearch.search(query, inPreparedIndexes: indexes, usageStats: usageStats).map(\.id),
                "prepared search should match direct search for query: \(query)"
            )
            XCTAssertEqual(
                directSearchIDs,
                PhraseSearch.search(query, inSortedPreparedIndexes: sortedIndexes, usageStats: usageStats).map(\.id),
                "sorted prepared search should match direct search for query: \(query)"
            )
        }

        for query in ["", "thnaks", "xiexie", "xx"] {
            let directResults = PhraseSearch.rankedResults(for: query, in: phrases).map {
                "\($0.phrase.id.uuidString)|\($0.matchKind.rawValue)|\($0.editDistance ?? -1)|\($0.matchPriority)"
            }
            let preparedResults = PhraseSearch.rankedResults(for: query, in: indexes).map {
                "\($0.phrase.id.uuidString)|\($0.matchKind.rawValue)|\($0.editDistance ?? -1)|\($0.matchPriority)"
            }
            XCTAssertEqual(
                directResults,
                preparedResults,
                "prepared ranked results should match direct ranked results for query: \(query)"
            )
        }
    }

    func testPhraseSearchKeepsHigherPriorityMatchWithinSamePhrase() {
        let phrase = Phrase(shortcut: ";thanks", body: "Body also contains thnaks exactly.")
        let result = PhraseSearch.rankedResults(for: "thnaks", in: [phrase]).first

        XCTAssertEqual(result?.phrase.id, phrase.id)
        XCTAssertEqual(result?.matchKind, .shortcutTypo)
    }

    func testPhraseSearchBestMatchShortCircuitsHigherPriorityMatches() throws {
        let source = try sourceFileContent("lazyquips/App/Phrases/PhraseSearch.swift")
        let bestMatchRange = try XCTUnwrap(source.range(of: "private static func bestMatch(for query: String, in index: PhraseSearchIndex)"))
        let typoDistanceRange = try XCTUnwrap(source.range(of: "private static func typoDistance(from query: String, toAnyOf tokens: [String])"))
        let bestMatchSource = String(source[bestMatchRange.lowerBound..<typoDistanceRange.lowerBound])
        let shortcutExactRange = try XCTUnwrap(bestMatchSource.range(of: "matchKind: .shortcutExact"))
        let shortcutTypoRange = try XCTUnwrap(bestMatchSource.range(of: "matchKind: .shortcutTypo"))
        let bodyContainsRange = try XCTUnwrap(bestMatchSource.range(of: "index.foldedBody.contains(query)"))
        let pinyinFullRange = try XCTUnwrap(bestMatchSource.range(of: "index.pinyinFull.contains(query)"))

        XCTAssertFalse(bestMatchSource.contains("var matches"))
        XCTAssertFalse(bestMatchSource.contains("matches.append"))
        XCTAssertFalse(bestMatchSource.contains("matches.min"))
        XCTAssertLessThan(shortcutExactRange.lowerBound, bodyContainsRange.lowerBound)
        XCTAssertLessThan(shortcutTypoRange.lowerBound, bodyContainsRange.lowerBound)
        XCTAssertLessThan(bodyContainsRange.lowerBound, pinyinFullRange.lowerBound)
    }

    func testPhraseSearchTreatsSymbolPrefixedShortcutTypoAsShortcutTypo() {
        for shortcut in [";thanks", "/thanks"] {
            let phrase = Phrase(shortcut: shortcut, body: "Shortcut typo should win.")
            let result = PhraseSearch.rankedResults(for: "thnaks", in: [phrase]).first

            XCTAssertEqual(result?.phrase.id, phrase.id)
            XCTAssertEqual(result?.matchKind, .shortcutTypo)
        }
    }

    func testPhraseSearchTreatsSymbolPrefixedShortcutQueryTypoAsShortcutTypo() {
        for (shortcut, query) in [(";thanks", ";thnaks"), ("/thanks", "/thnaks")] {
            let phrase = Phrase(shortcut: shortcut, body: "Shortcut typo should win.")
            let result = PhraseSearch.rankedResults(for: query, in: [phrase]).first

            XCTAssertEqual(result?.phrase.id, phrase.id)
            XCTAssertEqual(result?.matchKind, .shortcutTypo)
        }
    }

    func testPhraseSearchPrefersMatchingSymbolPrefixForShortcutTypoQuery() {
        let semicolonShortcut = Phrase(shortcut: ";thanks", body: "Semicolon shortcut should win.")
        let slashShortcut = Phrase(shortcut: "/thanks", body: "Slash shortcut should not steal semicolon query.")
        let results = PhraseSearch.rankedResults(for: ";thnaks", in: [slashShortcut, semicolonShortcut])

        XCTAssertEqual(results.first?.phrase.id, semicolonShortcut.id)
        XCTAssertEqual(results.first?.matchKind, .shortcutTypo)
    }

    func testPhraseSearchWithUsageStatsKeepsMatchingSymbolPrefixAheadOfStarredRecentShortcutTypo() {
        let semicolonShortcut = Phrase(shortcut: ";thanks", body: "Semicolon shortcut should win.")
        let slashShortcut = Phrase(shortcut: "/thanks", body: "Starred recent slash shortcut should not steal semicolon query.", isStarred: true)
        let stats = [
            PhraseUsageStats(
                phraseID: slashShortcut.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_100)
            )
        ]

        let results = PhraseSearch.search(
            ";thnaks",
            in: [slashShortcut, semicolonShortcut],
            usageStats: stats
        )

        XCTAssertEqual(results.first?.id, semicolonShortcut.id)
    }

    func testPhraseSearchTreatsFullHyphenatedShortcutQueryTypoAsShortcutTypo() {
        let phrase = Phrase(shortcut: "cn-thanks", body: "Shortcut typo should win.")
        let result = PhraseSearch.rankedResults(for: "cn-thnaks", in: [phrase]).first

        XCTAssertEqual(result?.phrase.id, phrase.id)
        XCTAssertEqual(result?.matchKind, .shortcutTypo)
    }

    func testPhraseSearchDoesNotLetNamespacedSymbolShortcutTokenStealPlainShortcutTypo() {
        let plainShortcut = Phrase(shortcut: ";thanks", body: "Plain shortcut should win.")
        let namespacedShortcut = Phrase(shortcut: ";cn-thanks", body: "Namespaced shortcut should not steal plain typo.")
        let results = PhraseSearch.rankedResults(for: "thnaks", in: [namespacedShortcut, plainShortcut])
        let namespacedResult = results.first { $0.phrase.id == namespacedShortcut.id }

        XCTAssertEqual(results.first?.phrase.id, plainShortcut.id)
        XCTAssertEqual(results.first?.matchKind, .shortcutTypo)
        XCTAssertEqual(namespacedResult?.matchKind, .bodyTokenTypo)
    }

    func testPhraseSearchRanksSymbolPrefixedShortcutTypoBeforeBodyTokenTypo() {
        let shortcutTypo = Phrase(shortcut: ";thanks", body: "Shortcut typo should win.")
        let bodyTypo = Phrase(shortcut: "aaa", body: "Thanks, I will check.")
        let results = PhraseSearch.rankedResults(for: "thnaks", in: [bodyTypo, shortcutTypo])

        XCTAssertEqual(results.map(\.phrase.id), [shortcutTypo.id, bodyTypo.id])
        XCTAssertEqual(results.map(\.matchKind), [.shortcutTypo, .bodyTokenTypo])
    }

    func testPhraseSearchRanksSymbolPrefixedShortcutTypoBeforePinyinTypo() {
        let shortcutTypo = Phrase(shortcut: "/xiexie", body: "Shortcut typo should win.")
        let pinyinTypo = Phrase(shortcut: "plain", body: "谢谢，我稍后确认。")
        let results = PhraseSearch.rankedResults(for: "xieixe", in: [pinyinTypo, shortcutTypo])

        XCTAssertEqual(results.map(\.phrase.id), [shortcutTypo.id, pinyinTypo.id])
        XCTAssertEqual(results.map(\.matchKind), [.shortcutTypo, .pinyinTypo])
    }

    func testPhraseSearchWithUsageStatsKeepsSymbolPrefixedShortcutTypoAheadOfStarredRecentBodyFuzzy() {
        let shortcutTypo = Phrase(shortcut: ";thanks", body: "Shortcut typo should win.")
        let starredBodyTypo = Phrase(shortcut: "aaa", body: "Thanks starred body.", isStarred: true)
        let recentBodyTypo = Phrase(shortcut: "bbb", body: "Thanks recent body.")
        let stats = [
            PhraseUsageStats(
                phraseID: recentBodyTypo.id,
                lastCopiedAt: Date(timeIntervalSince1970: 1_700_006_000)
            )
        ]

        let results = PhraseSearch.search(
            "thnaks",
            in: [starredBodyTypo, recentBodyTypo, shortcutTypo],
            usageStats: stats
        )

        XCTAssertEqual(results.map(\.id), [shortcutTypo.id, starredBodyTypo.id, recentBodyTypo.id])
    }

    func testPhraseSearchMatchesChineseShortcutPinyinInitialsAndTypos() {
        let chineseShortcut = Phrase(shortcut: "谢谢", body: "Shortcut pinyin only.")
        let decoy = Phrase(shortcut: "plain", body: "Thanks body.")
        let phrases = [decoy, chineseShortcut]

        XCTAssertEqual(PhraseSearch.rankedResults(for: "谢谢", in: phrases).first?.phrase.id, chineseShortcut.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "谢谢", in: phrases).first?.matchKind, .shortcutExact)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xiexie", in: phrases).first?.phrase.id, chineseShortcut.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xiexie", in: phrases).first?.matchKind, .pinyinFull)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xx", in: phrases).first?.phrase.id, chineseShortcut.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xx", in: phrases).first?.matchKind, .pinyinInitials)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xieixe", in: phrases).first?.phrase.id, chineseShortcut.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "xieixe", in: phrases).first?.matchKind, .pinyinTypo)
    }

    func testPhraseSearchDoesNotCreatePinyinMatchesFromPlainEnglishText() {
        let englishBody = Phrase(shortcut: "reply", body: "Thanks, I will check and get back to you.")
        let phrases = [englishBody]

        XCTAssertTrue(PhraseSearch.rankedResults(for: "tiwc", in: phrases).isEmpty)
        XCTAssertTrue(PhraseSearch.rankedResults(for: "thanksiwill", in: phrases).isEmpty)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "thanks", in: phrases).first?.phrase.id, englishBody.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "thnaks", in: phrases).first?.phrase.id, englishBody.id)
        XCTAssertEqual(PhraseSearch.rankedResults(for: "thnaks", in: phrases).first?.matchKind, .bodyTokenTypo)
    }

    func testPhraseLibraryWindowStateTracksAddIntent() {
        let state = PhraseLibraryWindowState()

        XCTAssertNil(state.editorMode)
        XCTAssertFalse(state.isSettingsPresented)

        state.openAdd()
        XCTAssertEqual(state.editorMode, .add)
        XCTAssertFalse(state.isSettingsPresented)

        state.dismissEditor()
        XCTAssertNil(state.editorMode)

        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        state.openEdit(phrase)
        XCTAssertEqual(state.editorMode, .edit(phrase.id))
        XCTAssertFalse(state.isSettingsPresented)

        state.openAdd()
        XCTAssertEqual(state.editorMode, .add)

        state.dismissEditor()
        XCTAssertNil(state.editorMode)
    }

    func testPhraseLibraryWindowStatePresentsSettingsOverlayOnlyWithoutActiveEditor() {
        let state = PhraseLibraryWindowState()
        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")

        state.openSettings()
        XCTAssertTrue(state.isSettingsPresented)
        XCTAssertNil(state.editorMode)

        state.openAdd()
        XCTAssertEqual(state.editorMode, .add)
        XCTAssertFalse(state.isSettingsPresented)

        state.openSettingsIfNoActiveEditor()
        XCTAssertEqual(state.editorMode, .add)
        XCTAssertFalse(state.isSettingsPresented)

        state.dismissEditor()
        state.openEdit(phrase)
        state.openSettingsIfNoActiveEditor()
        XCTAssertEqual(state.editorMode, .edit(phrase.id))
        XCTAssertFalse(state.isSettingsPresented)

        state.dismissEditor()
        state.openSettingsIfNoActiveEditor()
        XCTAssertTrue(state.isSettingsPresented)

        state.dismissSettings()
        XCTAssertFalse(state.isSettingsPresented)
    }

    func testPhraseLibraryWindowStatePresentsSingleEditorOverlay() {
        let state = PhraseLibraryWindowState()
        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")

        state.openAdd()
        state.openEdit(phrase)

        XCTAssertEqual(state.editorMode, .edit(phrase.id))

        state.openAdd()

        XCTAssertEqual(state.editorMode, .add)

        state.dismissEditor()
        XCTAssertNil(state.editorMode)
    }

    func testExternalAddIntentDoesNotOverrideActiveEditor() {
        let state = PhraseLibraryWindowState()
        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")

        state.openAdd()
        state.openAddIfNoActiveEditor()
        XCTAssertEqual(state.editorMode, .add)

        state.dismissEditor()
        state.openEdit(phrase)
        state.openAddIfNoActiveEditor()
        XCTAssertEqual(state.editorMode, .edit(phrase.id))

        state.dismissEditor()
        state.openAddIfNoActiveEditor()
        XCTAssertEqual(state.editorMode, .add)
    }

    func testPhraseLibraryWindowStateRequestsSearchFocusOnlyWithoutActiveOverlay() {
        let state = PhraseLibraryWindowState()
        let initialRequest = state.searchFocusRequest

        state.requestSearchFocusIfNoActiveOverlay()
        let firstRequest = state.searchFocusRequest
        XCTAssertNotEqual(firstRequest, initialRequest)

        state.openAdd()
        state.requestSearchFocusIfNoActiveOverlay()
        XCTAssertEqual(state.searchFocusRequest, firstRequest)

        state.dismissEditor()
        state.requestSearchFocusIfNoActiveOverlay()
        let secondRequest = state.searchFocusRequest
        XCTAssertNotEqual(secondRequest, firstRequest)

        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        state.openEdit(phrase)
        state.requestSearchFocusIfNoActiveOverlay()
        XCTAssertEqual(state.searchFocusRequest, secondRequest)

        state.dismissEditor()
        state.openSettings()
        state.requestSearchFocusIfNoActiveOverlay()
        XCTAssertEqual(state.searchFocusRequest, secondRequest)

        state.dismissSettings()
        state.requestSearchFocusIfNoActiveOverlay()
        XCTAssertNotEqual(state.searchFocusRequest, secondRequest)
    }

    @MainActor
    func testAppDelegateSupportsDefaultAppLaunchInitializer() {
        let appDelegate = AppDelegate()

        XCTAssertNil(appDelegate.modelContainer)
        XCTAssertEqual(appDelegate.launchPolicy.intent, LazyQuipsLaunchIntent())
        XCTAssertNil(appDelegate.phraseLibraryWindowState)
        XCTAssertNil(appDelegate.mainWindowController)
    }

    @MainActor
    func testAppLaunchPolicyShowsMainWindowForUserLaunchOnly() {
        let userIntent = LazyQuipsLaunchIntent(openedURLs: [], currentAppleEvent: nil)
        let unrelatedURLIntent = LazyQuipsLaunchIntent(openedURLs: [
            URL(string: "lazyquips://open")!
        ], currentAppleEvent: nil)
        let loginIntent = LazyQuipsLaunchIntent(openedURLs: [
            URL(string: "lazyquips://launch-at-login")!
        ], currentAppleEvent: nil)
        let appleEventLoginIntent = LazyQuipsLaunchIntent(
            openedURLs: [],
            currentAppleEvent: makeGetURLEvent("lazyquips://launch-at-login")
        )

        XCTAssertEqual(userIntent, .userInitiated)
        XCTAssertEqual(unrelatedURLIntent, .userInitiated)
        XCTAssertEqual(loginIntent, .loginItem)
        XCTAssertEqual(appleEventLoginIntent, .loginItem)
        XCTAssertTrue(LazyQuipsLaunchPolicy(intent: userIntent).shouldShowMainWindowAfterLaunch)
        XCTAssertTrue(
            LazyQuipsLaunchPolicy(intent: unrelatedURLIntent).shouldShowMainWindowAfterLaunch
        )
        XCTAssertFalse(LazyQuipsLaunchPolicy(intent: loginIntent).shouldShowMainWindowAfterLaunch)
        XCTAssertFalse(
            LazyQuipsLaunchPolicy(intent: appleEventLoginIntent).shouldShowMainWindowAfterLaunch
        )
    }

    @MainActor
    func testAppDelegateLaunchPolicyKeepsLoginLaunchWindowSuppressedAndUserLaunchVisible() {
        let loginLaunchDelegate = AppDelegate(
            modelContainer: nil,
            launchPolicy: LazyQuipsLaunchPolicy(intent: .loginItem)
        )
        let userLaunchDelegate = AppDelegate(
            modelContainer: nil,
            launchPolicy: LazyQuipsLaunchPolicy(intent: .userInitiated)
        )

        XCTAssertFalse(loginLaunchDelegate.launchPolicy.shouldShowMainWindowAfterLaunch)
        XCTAssertTrue(userLaunchDelegate.launchPolicy.shouldShowMainWindowAfterLaunch)
    }

    func testLaunchAtLoginControllerUsesHelperLoginItemIdentifier() throws {
        XCTAssertEqual(
            LaunchAtLoginController.loginItemIdentifier,
            "dev.lazyquips.public.login-helper"
        )

        let source = try sourceFileContent(
            "lazyquips/App/LaunchAtLoginController.swift"
        )

        XCTAssertTrue(source.contains("SMAppService.loginItem"))
        XCTAssertTrue(source.contains("identifier:"))
        XCTAssertTrue(source.contains("LaunchAtLoginController.loginItemIdentifier"))
        XCTAssertFalse(source.contains("SMAppService.mainApp"))
    }

    func testLaunchAtLoginControllerMapsServiceStatus() {
        let cases: [(SMAppService.Status, LaunchAtLoginDisplayState)] = [
            (.notRegistered, .disabled),
            (.enabled, .enabled),
            (.requiresApproval, .requiresApproval),
            (.notFound, .unavailable)
        ]

        for testCase in cases {
            let controller = LaunchAtLoginController {
                LaunchAtLoginService(
                    status: { testCase.0 },
                    register: {},
                    unregister: {}
                )
            }

            XCTAssertEqual(controller.currentState(), testCase.1)
        }
    }

    func testLaunchAtLoginControllerAvoidsRedundantRegisterAndUnregister() throws {
        var registerCount = 0
        var unregisterCount = 0
        let enabledController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .enabled },
                register: { registerCount += 1 },
                unregister: { unregisterCount += 1 }
            )
        }

        try enabledController.setEnabled(true)

        XCTAssertEqual(registerCount, 0)
        XCTAssertEqual(unregisterCount, 0)

        let disabledController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .notRegistered },
                register: { registerCount += 1 },
                unregister: { unregisterCount += 1 }
            )
        }

        try disabledController.setEnabled(false)

        XCTAssertEqual(registerCount, 0)
        XCTAssertEqual(unregisterCount, 0)
    }

    func testLaunchAtLoginControllerEnsureEnabledSilentlyRegistersOnlyWhenNotRegistered() {
        let cases: [(SMAppService.Status, Int)] = [
            (.notRegistered, 1),
            (.enabled, 0),
            (.requiresApproval, 0),
            (.notFound, 0)
        ]

        for testCase in cases {
            var registerCount = 0
            var unregisterCount = 0
            let controller = LaunchAtLoginController {
                LaunchAtLoginService(
                    status: { testCase.0 },
                    register: { registerCount += 1 },
                    unregister: { unregisterCount += 1 }
                )
            }

            controller.ensureEnabledSilently()

            XCTAssertEqual(registerCount, testCase.1)
            XCTAssertEqual(unregisterCount, 0)
        }
    }

    func testLaunchAtLoginControllerEnsureEnabledSilentlySuppressesRegisterError() {
        let expectedError = NSError(domain: "LazyquipsTests", code: 19)
        let controller = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .notRegistered },
                register: { throw expectedError },
                unregister: {}
            )
        }

        controller.ensureEnabledSilently()
    }

    func testLaunchAtLoginControllerRegistersAndUnregistersThroughService() throws {
        var registerCount = 0
        var unregisterCount = 0
        let controller = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .notRegistered },
                register: { registerCount += 1 },
                unregister: { unregisterCount += 1 }
            )
        }

        try controller.setEnabled(true)

        XCTAssertEqual(registerCount, 1)
        XCTAssertEqual(unregisterCount, 0)

        let enabledController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .enabled },
                register: { registerCount += 1 },
                unregister: { unregisterCount += 1 }
            )
        }

        try enabledController.setEnabled(false)

        XCTAssertEqual(registerCount, 1)
        XCTAssertEqual(unregisterCount, 1)
    }

    func testAppDelegateAutoRegistrationRunsAtLaunchButStaysOutOfReopen() throws {
        let source = try sourceFileContent("lazyquips/App/AppDelegate.swift")
        let finishLaunchingRange = try XCTUnwrap(source.range(of: "func applicationDidFinishLaunching"))
        let willTerminateRange = try XCTUnwrap(source.range(of: "func applicationWillTerminate"))
        let finishLaunchingSource = String(source[finishLaunchingRange.lowerBound..<willTerminateRange.lowerBound])
        let reopenRange = try XCTUnwrap(source.range(of: "func applicationShouldHandleReopen"))
        let lastWindowRange = try XCTUnwrap(source.range(of: "func applicationShouldTerminateAfterLastWindowClosed"))
        let reopenSource = String(source[reopenRange.lowerBound..<lastWindowRange.lowerBound])
        let ensureRange = try XCTUnwrap(source.range(of: "private func ensureLaunchAtLoginEnabledForUserOpen"))
        let urlHandlerRange = try XCTUnwrap(source.range(of: "private func installLaunchAtLoginURLHandler"))
        let ensureSource = String(source[ensureRange.lowerBound..<urlHandlerRange.lowerBound])

        XCTAssertTrue(source.contains("launchAtLoginController: LaunchAtLoginController = .shared"))
        XCTAssertTrue(source.contains("makeHotKeyController: @escaping HotKeyControllerFactory"))
        XCTAssertTrue(finishLaunchingSource.contains("ensureLaunchAtLoginEnabledForUserOpen()"))
        XCTAssertTrue(finishLaunchingSource.contains("hotKeyStatusStore.update(isAvailable: hotKeyController.start())"))
        XCTAssertFalse(reopenSource.contains("ensureLaunchAtLoginEnabledForUserOpen()"))
        XCTAssertTrue(reopenSource.contains("retryGlobalHotKeyRegistration()"))
        XCTAssertTrue(ensureSource.contains("guard launchPolicy.intent == .userInitiated else"))
        XCTAssertTrue(ensureSource.contains("launchAtLoginController.ensureEnabledSilently()"))
        XCTAssertTrue(ensureSource.contains("hotKeyStatusStore.update(isAvailable: hotKeyController.restart())"))
    }

    @MainActor
    func testAppDelegateReopenDoesNotQueryLaunchAtLoginService() {
        var statusCount = 0
        var registerCount = 0
        let launchAtLoginController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: {
                    statusCount += 1
                    return .notRegistered
                },
                register: {
                    registerCount += 1
                },
                unregister: {}
            )
        }
        let appDelegate = AppDelegate(
            modelContainer: nil,
            applicationActivation: noOpApplicationActivationClient(),
            launchAtLoginController: launchAtLoginController
        )

        _ = appDelegate.applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)

        XCTAssertEqual(statusCount, 0)
        XCTAssertEqual(registerCount, 0)
    }

    func testLaunchAtLoginControllerPropagatesServiceErrors() {
        let expectedError = NSError(domain: "LazyquipsTests", code: 7)
        let registerController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .notRegistered },
                register: { throw expectedError },
                unregister: {}
            )
        }

        XCTAssertThrowsError(try registerController.setEnabled(true)) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }

        let unregisterController = LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .enabled },
                register: {},
                unregister: { throw expectedError }
            )
        }

        XCTAssertThrowsError(try unregisterController.setEnabled(false)) { error in
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    @MainActor
    func testAppDelegateLaunchAtLoginURLEventSuppressesMainWindow() {
        let appDelegate = AppDelegate(
            modelContainer: nil,
            launchPolicy: LazyQuipsLaunchPolicy(intent: .userInitiated)
        )

        appDelegate.application(
            NSApplication.shared,
            open: [URL(string: "lazyquips://launch-at-login")!]
        )

        XCTAssertFalse(appDelegate.launchPolicy.shouldShowMainWindowAfterLaunch)
        XCTAssertNil(appDelegate.mainWindowController)
    }

    @MainActor
    func testAppDelegateLaunchAtLoginAppleEventSuppressesMainWindow() {
        let appDelegate = AppDelegate(
            modelContainer: nil,
            launchPolicy: LazyQuipsLaunchPolicy(intent: .userInitiated)
        )

        appDelegate.handleLaunchURLAppleEvent(
            makeGetURLEvent("lazyquips://launch-at-login"),
            withReplyEvent: NSAppleEventDescriptor.null()
        )

        XCTAssertFalse(appDelegate.launchPolicy.shouldShowMainWindowAfterLaunch)
        XCTAssertNil(appDelegate.mainWindowController)
    }

    func testLoginHelperOpensLaunchAtLoginURL() throws {
        let source = try sourceFileContent(
            "lazyquips/LoginHelper/LazyQuipsLoginHelper.swift"
        )

        XCTAssertTrue(source.contains("NSWorkspace.shared.open("))
        XCTAssertTrue(source.contains("[launchAtLoginURL]"))
        XCTAssertTrue(source.contains("withApplicationAt: mainAppURL"))
        XCTAssertTrue(source.contains("LazyQuipsLaunchConfiguration.launchReasonURLScheme"))
        XCTAssertTrue(source.contains("LazyQuipsLaunchConfiguration.launchAtLoginURLHost"))
        XCTAssertFalse(source.contains("configuration.environment"))
        XCTAssertFalse(source.contains("configuration.arguments"))
        XCTAssertTrue(source.contains("NSApp.terminate(nil)"))
    }

    func testLoginHelperProjectConfigurationEmbedsSandboxedLoginItem() throws {
        let project = try sourceFileContent("lazyquips.xcodeproj/project.pbxproj")

        XCTAssertTrue(project.contains("LazyQuipsLoginHelper"))
        XCTAssertTrue(project.contains("Embed Login Items"))
        XCTAssertTrue(project.contains("dstPath = \"Contents/Library/LoginItems\";"))
        XCTAssertTrue(project.contains("CodeSignOnCopy"))
        XCTAssertTrue(project.contains(
            "PRODUCT_BUNDLE_IDENTIFIER = \"\(LaunchAtLoginController.loginItemIdentifier)\";"
        ))
        XCTAssertTrue(project.contains(
            "CODE_SIGN_ENTITLEMENTS = lazyquips/LoginHelper/lazyquipsLoginHelper.entitlements;"
        ))

        let helperInfo = try plistDictionary("lazyquips/LoginHelper/Info.plist")
        XCTAssertEqual(helperInfo["CFBundleIdentifier"] as? String, "$(PRODUCT_BUNDLE_IDENTIFIER)")
        XCTAssertEqual(helperInfo["LSUIElement"] as? Bool, true)

        let appInfo = try plistDictionary("lazyquips/Resources/Info.plist")
        let urlTypes = try XCTUnwrap(appInfo["CFBundleURLTypes"] as? [[String: Any]])
        let urlSchemes = try XCTUnwrap(urlTypes.first?["CFBundleURLSchemes"] as? [String])
        XCTAssertTrue(urlSchemes.contains(LazyQuipsLaunchConfiguration.launchReasonURLScheme))

        let helperEntitlements = try plistDictionary(
            "lazyquips/LoginHelper/lazyquipsLoginHelper.entitlements"
        )
        XCTAssertEqual(helperEntitlements["com.apple.security.app-sandbox"] as? Bool, true)
    }

    func testMainAppInfoPlistKeepsLSUIElementEnabled() throws {
        let appInfo = try plistDictionary("lazyquips/Resources/Info.plist")

        XCTAssertEqual(appInfo["LSUIElement"] as? Bool, true)
    }

    @MainActor
    func testAppDelegateMainWindowShowsDockWhileOpenAndHidesDockAfterClose() throws {
        var activationPolicies: [NSApplication.ActivationPolicy.RawValue] = []
        var activateCount = 0
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: ApplicationActivationClient(
                setActivationPolicy: { policy in
                    activationPolicies.append(policy.rawValue)
                    return true
                },
                activateIgnoringOtherApps: {
                    activateCount += 1
                }
            )
        )

        appDelegate.showMainWindow()

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }

        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.regular.rawValue])
        XCTAssertEqual(activateCount, 1)

        activationPolicies.removeAll()
        activateCount = 0

        appDelegate.showMainWindow()

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.regular.rawValue])
        XCTAssertEqual(activateCount, 1)

        activationPolicies.removeAll()
        activateCount = 0

        appDelegate.mainWindowController?.close()

        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.accessory.rawValue])
        XCTAssertEqual(activateCount, 0)
        XCTAssertNil(appDelegate.phraseLibraryWindowState)
        XCTAssertNil(appDelegate.mainWindowController)
    }

    @MainActor
    func testAppDelegateMainWindowReusesSingleWindowAndPreservesActiveEditorIntent() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient()
        )

        appDelegate.showMainWindow()

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }

        let firstWindow = try XCTUnwrap(firstWindowController.window)
        let contentSize = try XCTUnwrap(firstWindow.contentView?.frame.size)

        XCTAssertEqual(firstWindow.title, "Lazy Quips")
        XCTAssertEqual(contentSize.width, 800, accuracy: 0.5)
        XCTAssertEqual(contentSize.height, 600, accuracy: 0.5)
        XCTAssertEqual(firstWindow.minSize.width, 800, accuracy: 0.5)
        XCTAssertEqual(firstWindow.minSize.height, 600, accuracy: 0.5)

        appDelegate.showMainWindow()

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)

        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)

        appDelegate.showMainWindow(openAdd: true)

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(windowState.editorMode, .add)

        windowState.dismissEditor()

        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        windowState.openEdit(phrase)

        appDelegate.showMainWindow(openAdd: true)

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(windowState.editorMode, .edit(phrase.id))
    }

    @MainActor
    func testAppDelegateRoutesMainWindowSearchFocusIntentWithoutOverridingOverlays() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient()
        )

        appDelegate.showMainWindow()

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }
        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)
        let firstRequest = windowState.searchFocusRequest

        appDelegate.focusMainWindowSearch()

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        let commandFRequest = windowState.searchFocusRequest
        XCTAssertNotEqual(commandFRequest, firstRequest)

        windowState.openAdd()
        appDelegate.focusMainWindowSearch()
        XCTAssertEqual(windowState.searchFocusRequest, commandFRequest)
        XCTAssertEqual(windowState.editorMode, .add)

        windowState.dismissEditor()
        appDelegate.showSettings()
        appDelegate.focusMainWindowSearch()
        XCTAssertEqual(windowState.searchFocusRequest, commandFRequest)
        XCTAssertTrue(windowState.isSettingsPresented)

        windowState.dismissSettings()
        appDelegate.focusMainWindowSearch()
        XCTAssertNotEqual(windowState.searchFocusRequest, commandFRequest)
    }

    @MainActor
    func testAppDelegateShowSettingsOpensMainWindowSettingsOverlay() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient()
        )

        appDelegate.showSettings()

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }
        let firstWindow = try XCTUnwrap(firstWindowController.window)
        let contentSize = try XCTUnwrap(firstWindow.contentView?.frame.size)
        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)

        XCTAssertEqual(firstWindow.title, "Lazy Quips")
        XCTAssertEqual(contentSize.width, 800, accuracy: 0.5)
        XCTAssertEqual(contentSize.height, 600, accuracy: 0.5)
        XCTAssertTrue(windowState.isSettingsPresented)
        XCTAssertNil(windowState.editorMode)

        appDelegate.showSettings()

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertTrue(windowState.isSettingsPresented)

        windowState.dismissSettings()
        appDelegate.showMainWindow(openAdd: true)

        XCTAssertEqual(windowState.editorMode, .add)
        XCTAssertFalse(windowState.isSettingsPresented)

        appDelegate.showSettings()

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(windowState.editorMode, .add)
        XCTAssertFalse(windowState.isSettingsPresented)

        windowState.dismissEditor()
        appDelegate.showSettings()

        XCTAssertTrue(windowState.isSettingsPresented)
    }

    @MainActor
    func testAppDelegateKeepsDockIconWhileSettingsOverlayMainWindowIsOpen() throws {
        var activationPolicies: [NSApplication.ActivationPolicy.RawValue] = []
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: ApplicationActivationClient(
                setActivationPolicy: { policy in
                    activationPolicies.append(policy.rawValue)
                    return true
                },
                activateIgnoringOtherApps: {}
            )
        )

        appDelegate.showSettings()
        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.regular.rawValue])
        XCTAssertNotNil(appDelegate.mainWindowController)
        XCTAssertTrue(try XCTUnwrap(appDelegate.phraseLibraryWindowState).isSettingsPresented)

        activationPolicies.removeAll()
        appDelegate.mainWindowController?.close()

        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.accessory.rawValue])
        XCTAssertNil(appDelegate.mainWindowController)
        XCTAssertNil(appDelegate.phraseLibraryWindowState)

        activationPolicies.removeAll()
        appDelegate.showSettings()
        appDelegate.showMainWindow()

        let mainWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }

        XCTAssertEqual(
            activationPolicies,
            [
                NSApplication.ActivationPolicy.regular.rawValue,
                NSApplication.ActivationPolicy.regular.rawValue
            ]
        )

        activationPolicies.removeAll()
        mainWindowController.close()

        XCTAssertEqual(activationPolicies, [NSApplication.ActivationPolicy.accessory.rawValue])
        XCTAssertNil(appDelegate.mainWindowController)
        XCTAssertNil(appDelegate.phraseLibraryWindowState)
    }

    @MainActor
    func testStatusMenuAddActionOpensMainWindowAddFlow() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient()
        )
        var events: [String] = []
        let dispatcher = StatusMenuActionDispatcher(
            closePalette: {
                events.append("close")
            },
            onAddPhrase: {
                events.append("add")
                appDelegate.showMainWindow(openAdd: true)
            },
            onOpenSettings: {
                XCTFail("Settings should not run for Add action")
            },
            onOpenMainWindow: {
                XCTFail("Open main window should not run for Add action")
            },
            onQuit: {
                XCTFail("Quit should not run for Add action")
            }
        )

        dispatcher.perform(.addPhrase)

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }
        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)

        XCTAssertEqual(events, ["close", "add"])
        XCTAssertEqual(windowState.editorMode, .add)

        dispatcher.perform(.addPhrase)

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(windowState.editorMode, .add)
        XCTAssertEqual(events, ["close", "add", "close", "add"])
    }

    @MainActor
    func testStatusMenuOpenMainWindowActionReusesWindowWithoutChangingActiveEditor() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient()
        )
        var events: [String] = []
        let dispatcher = StatusMenuActionDispatcher(
            closePalette: {
                events.append("close")
            },
            onAddPhrase: {
                XCTFail("Add should not run for Open Lazy Quips action")
            },
            onOpenSettings: {
                XCTFail("Settings should not run for Open Lazy Quips action")
            },
            onOpenMainWindow: {
                events.append("open")
                appDelegate.showMainWindow()
            },
            onQuit: {
                XCTFail("Quit should not run for Open Lazy Quips action")
            }
        )

        dispatcher.perform(.openMainWindow)

        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }
        let firstWindow = try XCTUnwrap(firstWindowController.window)
        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)

        XCTAssertEqual(events, ["close", "open"])
        XCTAssertEqual(firstWindow.title, "Lazy Quips")
        XCTAssertNil(windowState.editorMode)

        dispatcher.perform(.openMainWindow)

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertNil(windowState.editorMode)
        XCTAssertEqual(events, ["close", "open", "close", "open"])

        let phrase = Phrase(shortcut: "agh", body: "A gentle heads-up.")
        windowState.openEdit(phrase)

        dispatcher.perform(.openMainWindow)

        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
        XCTAssertEqual(windowState.editorMode, .edit(phrase.id))
        XCTAssertEqual(events, ["close", "open", "close", "open", "close", "open"])
    }

    @MainActor
    func testAppDelegateReopenOpensAndReusesMainWindow() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient(),
            launchAtLoginController: noOpLaunchAtLoginController()
        )

        XCTAssertNil(appDelegate.mainWindowController)

        let shouldHandleInitialReopen = appDelegate.applicationShouldHandleReopen(
            NSApp,
            hasVisibleWindows: false
        )
        let firstWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        defer {
            appDelegate.mainWindowController?.close()
        }

        XCTAssertFalse(shouldHandleInitialReopen)
        XCTAssertEqual(firstWindowController.window?.title, "Lazy Quips")

        let shouldHandleSecondReopen = appDelegate.applicationShouldHandleReopen(
            NSApp,
            hasVisibleWindows: true
        )

        XCTAssertFalse(shouldHandleSecondReopen)
        XCTAssertTrue(appDelegate.mainWindowController === firstWindowController)
    }

    @MainActor
    func testAppDelegateReopenFocusesMainWindowWithSettingsOverlay() throws {
        let appDelegate = AppDelegate(
            modelContainer: try makeInMemoryModelContainer(),
            applicationActivation: noOpApplicationActivationClient(),
            launchAtLoginController: noOpLaunchAtLoginController()
        )

        appDelegate.showSettings()

        let mainWindowController = try XCTUnwrap(appDelegate.mainWindowController)
        let windowState = try XCTUnwrap(appDelegate.phraseLibraryWindowState)
        defer {
            appDelegate.mainWindowController?.close()
        }

        let shouldHandleReopen = appDelegate.applicationShouldHandleReopen(
            NSApp,
            hasVisibleWindows: true
        )

        XCTAssertFalse(shouldHandleReopen)
        XCTAssertTrue(appDelegate.mainWindowController === mainWindowController)
        XCTAssertTrue(windowState.isSettingsPresented)
    }

    func testCancelingAddOrEditDismissesEditorWithoutMutatingPhraseData() throws {
        let context = try makeInMemoryModelContext()
        let repository = PhraseRepository(context: context)
        let state = PhraseLibraryWindowState()
        let createdAt = Date(timeIntervalSince1970: 1_700_008_000)
        let phrase = try repository.add(
            shortcut: "original",
            body: "Original body.",
            isStarred: true,
            now: createdAt
        )
        let snapshot = (
            id: phrase.id,
            shortcut: phrase.shortcut,
            normalizedShortcut: phrase.normalizedShortcut,
            body: phrase.body,
            isStarred: phrase.isStarred,
            createdAt: phrase.createdAt,
            updatedAt: phrase.updatedAt
        )

        state.openAdd()
        state.dismissEditor()

        XCTAssertNil(state.editorMode)
        XCTAssertEqual(try repository.fetchAll().map(\.id), [snapshot.id])

        state.openEdit(phrase)
        state.dismissEditor()

        let fetchedPhrase = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertNil(state.editorMode)
        XCTAssertEqual(fetchedPhrase.id, snapshot.id)
        XCTAssertEqual(fetchedPhrase.shortcut, snapshot.shortcut)
        XCTAssertEqual(fetchedPhrase.normalizedShortcut, snapshot.normalizedShortcut)
        XCTAssertEqual(fetchedPhrase.body, snapshot.body)
        XCTAssertEqual(fetchedPhrase.isStarred, snapshot.isStarred)
        XCTAssertEqual(fetchedPhrase.createdAt, snapshot.createdAt)
        XCTAssertEqual(fetchedPhrase.updatedAt, snapshot.updatedAt)
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Phrase.self,
            PhraseUsageStats.self,
            configurations: configuration
        )
    }

    private func makeInMemoryModelContext() throws -> ModelContext {
        ModelContext(try makeInMemoryModelContainer())
    }

    private func testLanguageStore(
        language: AppLanguage = .english,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AppLanguageStore {
        let suiteName = "dev.lazyquips.public.tests.language.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create test UserDefaults", file: file, line: line)
            return AppLanguageStore(preferredLanguages: ["en-US"])
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        let store = AppLanguageStore(
            userDefaults: userDefaults,
            preferredLanguages: ["en-US"]
        )
        store.select(language)
        return store
    }

    private func noOpApplicationActivationClient() -> ApplicationActivationClient {
        ApplicationActivationClient(
            setActivationPolicy: { _ in true },
            activateIgnoringOtherApps: {}
        )
    }

    private func noOpLaunchAtLoginController() -> LaunchAtLoginController {
        LaunchAtLoginController {
            LaunchAtLoginService(
                status: { .enabled },
                register: {},
                unregister: {}
            )
        }
    }

    private func makeGetURLEvent(_ urlString: String) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kInternetEventClass),
            eventID: AEEventID(kAEGetURL),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setParam(
            NSAppleEventDescriptor(string: urlString),
            forKeyword: AEKeyword(keyDirectObject)
        )
        return event
    }

    private func makePaletteRows(
        _ phrases: [Phrase],
        sectionID: PhrasePaletteSectionID = .all
    ) -> [PhrasePaletteRow] {
        phrases.map { phrase in
            PhrasePaletteRow(
                id: PhrasePaletteRowID(sectionID: sectionID, phraseID: phrase.id),
                phrase: phrase,
                mayNeedSubmenu: PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(phrase.body)
            )
        }
    }

    private func appSwiftSourceFiles() throws -> [SourceFile] {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()
        let appRoot = repositoryRoot
            .appendingPathComponent("lazyquips")
            .appendingPathComponent("App")
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(
            at: appRoot,
            includingPropertiesForKeys: nil
        ))
        let sourceURLs = enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.path < $1.path }

        return try sourceURLs.map { url in
            let pathComponents = url.pathComponents
            let appRootIndex = try XCTUnwrap(
                pathComponents.indices.first { index in
                    index + 1 < pathComponents.count &&
                        pathComponents[index] == "lazyquips" &&
                        pathComponents[index + 1] == "App"
                }
            )
            let relativePath = pathComponents[appRootIndex...].joined(separator: "/")

            return SourceFile(
                relativePath: relativePath,
                content: try String(contentsOf: url, encoding: .utf8)
            )
        }
    }

    private func sourceFileContent(_ relativePath: String) throws -> String {
        let sourceURL = repositoryFileURL(relativePath)

        return try String(contentsOf: sourceURL, encoding: .utf8)
    }

    private func plistDictionary(_ relativePath: String) throws -> [String: Any] {
        let data = try Data(contentsOf: repositoryFileURL(relativePath))
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

        return try XCTUnwrap(plist as? [String: Any])
    }

    private func repositoryFileURL(_ relativePath: String) -> URL {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()

        return repositoryRoot.appendingPathComponent(relativePath)
    }

    private struct SourceFile {
        let relativePath: String
        let content: String
    }

    private struct ForbiddenSourcePattern {
        let pattern: String
        let reason: String
        let allowedRelativePaths: Set<String>

        init(
            pattern: String,
            reason: String,
            allowedRelativePaths: Set<String> = []
        ) {
            self.pattern = pattern
            self.reason = reason
            self.allowedRelativePaths = allowedRelativePaths
        }
    }
}
