import AppKit
import Combine
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .traditionalChinese:
            return "繁體中文"
        }
    }
}

final class AppLanguageStore: ObservableObject {
    static let userDefaultsKey = "lazyquips.settings.language"
    static let shared = AppLanguageStore()

    @Published private(set) var language: AppLanguage

    private let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults = .standard,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        self.userDefaults = userDefaults

        if let storedValue = userDefaults.string(forKey: Self.userDefaultsKey),
           let storedLanguage = AppLanguage(rawValue: storedValue) {
            language = storedLanguage
        } else {
            language = Self.defaultLanguage(for: preferredLanguages)
        }
    }

    func select(_ language: AppLanguage) {
        userDefaults.set(language.rawValue, forKey: Self.userDefaultsKey)
        self.language = language
    }

    static func defaultLanguage(for preferredLanguages: [String]) -> AppLanguage {
        guard let firstLanguage = preferredLanguages.first?.lowercased() else {
            return .english
        }

        if firstLanguage == "zh-hant"
            || firstLanguage.hasPrefix("zh-hant-")
            || firstLanguage == "zh-tw"
            || firstLanguage == "zh-hk"
            || firstLanguage == "zh-mo" {
            return .traditionalChinese
        }

        return .english
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String {
        rawValue
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var titleKey: AppStringKey {
        switch self {
        case .auto:
            return .appearanceAuto
        case .light:
            return .appearanceLight
        case .dark:
            return .appearanceDark
        }
    }
}

final class AppAppearanceStore: ObservableObject {
    static let userDefaultsKey = "lazyquips.settings.appearance"
    static let shared = AppAppearanceStore()

    @Published private(set) var appearance: AppAppearance

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let storedValue = userDefaults.string(forKey: Self.userDefaultsKey),
           let storedAppearance = AppAppearance(rawValue: storedValue) {
            appearance = storedAppearance
        } else {
            appearance = .auto
        }
    }

    func select(_ appearance: AppAppearance) {
        userDefaults.set(appearance.rawValue, forKey: Self.userDefaultsKey)
        self.appearance = appearance
    }
}

enum AppStringKey: CaseIterable {
    case add
    case all
    case appearance
    case appearanceAuto
    case appearanceLight
    case appearanceDark
    case appShortcutConflictHint
    case appShortcutValue
    case appShortcuts
    case cancel
    case close
    case contactCopied
    case copied
    case daniel
    case danielDescription
    case delete
    case deleteFailed
    case duplicateShortcut
    case edit
    case email
    case language
    case noPhrases
    case noPhrasesYet
    case noResults
    case ok
    case openAtLogin
    case openAtLoginError
    case openAtLoginUnavailable
    case openAtLoginUserAction
    case openLazyQuips
    case paletteSearchPlaceholder
    case phrase
    case phraseRequired
    case quit
    case recent
    case saveFailed
    case search
    case settings
    case shortcut
    case shortcutRequired
    case star
    case telegram
    case unstar
    case updateFailed
    case whatsApp
}

enum AppStrings {
    static func text(_ key: AppStringKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishText(key)
        case .traditionalChinese:
            return traditionalChineseText(key)
        }
    }

    static func hasText(for key: AppStringKey, language: AppLanguage) -> Bool {
        !text(key, language: language).isEmpty
    }

    private static func englishText(_ key: AppStringKey) -> String {
        switch key {
        case .add:
            return "Add"
        case .all:
            return "All"
        case .appearance:
            return "Appearance"
        case .appearanceAuto:
            return "Auto"
        case .appearanceLight:
            return "Light"
        case .appearanceDark:
            return "Dark"
        case .appShortcutConflictHint:
            return "Check macOS or another app's shortcut settings."
        case .appShortcutValue:
            return "⌘ + ⇧ + C"
        case .appShortcuts:
            return "App Shortcuts"
        case .cancel:
            return "Cancel"
        case .close:
            return "Close"
        case .contactCopied:
            return "Contact copied."
        case .copied:
            return "Copied"
        case .daniel:
            return "Daniel"
        case .danielDescription:
            return "Have feedback or ideas? Reach out to Daniel to report a bug, request a feature, or share anything else."
        case .delete:
            return "Delete"
        case .deleteFailed:
            return "Delete failed."
        case .duplicateShortcut:
            return "Shortcut already exists."
        case .edit:
            return "Edit"
        case .email:
            return "Email"
        case .language:
            return "Language"
        case .noPhrases:
            return "No phrases."
        case .noPhrasesYet:
            return "No phrases yet."
        case .noResults:
            return "No results."
        case .ok:
            return "OK"
        case .openAtLogin:
            return "Open at Login"
        case .openAtLoginError:
            return "Could not update Open at Login."
        case .openAtLoginUnavailable:
            return "Login item is unavailable."
        case .openAtLoginUserAction:
            return "Check Login Items in System Settings."
        case .openLazyQuips:
            return "Open Lazy Quips"
        case .paletteSearchPlaceholder:
            return "Input shortcut and press Enter"
        case .phrase:
            return "Phrase"
        case .phraseRequired:
            return "Phrase is required."
        case .quit:
            return "Quit"
        case .recent:
            return "Recent"
        case .saveFailed:
            return "Save failed."
        case .search:
            return "Search"
        case .settings:
            return "Settings"
        case .shortcut:
            return "Shortcut"
        case .shortcutRequired:
            return "Shortcut is required."
        case .star:
            return "Star"
        case .telegram:
            return "Telegram"
        case .unstar:
            return "Unstar"
        case .updateFailed:
            return "Update failed."
        case .whatsApp:
            return "WhatsApp"
        }
    }

    private static func traditionalChineseText(_ key: AppStringKey) -> String {
        switch key {
        case .add:
            return "新增"
        case .all:
            return "全部"
        case .appearance:
            return "外觀"
        case .appearanceAuto:
            return "自動"
        case .appearanceLight:
            return "淺色"
        case .appearanceDark:
            return "深色"
        case .appShortcutConflictHint:
            return "請檢查 macOS 或其他 App 的快捷鍵設定。"
        case .appShortcutValue:
            return "⌘ + ⇧ + C"
        case .appShortcuts:
            return "App 快捷鍵"
        case .cancel:
            return "取消"
        case .close:
            return "關閉"
        case .contactCopied:
            return "已複製聯絡方式。"
        case .copied:
            return "已複製"
        case .daniel:
            return "Daniel"
        case .danielDescription:
            return "有回饋或想法？聯絡 Daniel 回報錯誤、提出功能建議或分享其他內容。"
        case .delete:
            return "刪除"
        case .deleteFailed:
            return "刪除失敗。"
        case .duplicateShortcut:
            return "快捷字已存在。"
        case .edit:
            return "編輯"
        case .email:
            return "電郵"
        case .language:
            return "語言"
        case .noPhrases:
            return "沒有短語。"
        case .noPhrasesYet:
            return "尚無短語。"
        case .noResults:
            return "沒有結果。"
        case .ok:
            return "確定"
        case .openAtLogin:
            return "登入時開啟"
        case .openAtLoginError:
            return "無法更新登入時開啟設定。"
        case .openAtLoginUnavailable:
            return "登入項目不可用。"
        case .openAtLoginUserAction:
            return "請前往系統設定的登入項目檢查。"
        case .openLazyQuips:
            return "打開 Lazy Quips"
        case .paletteSearchPlaceholder:
            return "輸入快捷字後按 Enter"
        case .phrase:
            return "短語"
        case .phraseRequired:
            return "請輸入短語。"
        case .quit:
            return "結束"
        case .recent:
            return "最近"
        case .saveFailed:
            return "儲存失敗。"
        case .search:
            return "搜尋"
        case .settings:
            return "設定"
        case .shortcut:
            return "快捷字"
        case .shortcutRequired:
            return "請輸入快捷字。"
        case .star:
            return "星標"
        case .telegram:
            return "Telegram"
        case .unstar:
            return "取消星標"
        case .updateFailed:
            return "更新失敗。"
        case .whatsApp:
            return "WhatsApp"
        }
    }
}

enum ContactChannel: CaseIterable {
    case email
    case whatsApp
    case telegram

    var fallbackText: String {
        switch self {
        case .email:
            return "daniel@whtobe.com"
        case .whatsApp:
            return "+852 56421873"
        case .telegram:
            return "whtobe"
        }
    }

    var url: URL {
        switch self {
        case .email:
            return URL(string: "mailto:daniel@whtobe.com")!
        case .whatsApp:
            return URL(string: "whatsapp://send?phone=85256421873")!
        case .telegram:
            return URL(string: "tg://resolve?domain=whtobe")!
        }
    }

    var titleKey: AppStringKey {
        switch self {
        case .email:
            return .email
        case .whatsApp:
            return .whatsApp
        case .telegram:
            return .telegram
        }
    }

    var systemSymbolName: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .whatsApp:
            return "message.fill"
        case .telegram:
            return "paperplane.fill"
        }
    }
}

enum ContactActionResult: Equatable {
    case opened
    case copied
    case failed
}

struct ExternalURLOpener {
    let open: (URL) -> Bool

    static let live = ExternalURLOpener { url in
        NSWorkspace.shared.open(url)
    }
}

struct ContactActionController {
    let opener: ExternalURLOpener
    let pasteboardWriter: PasteboardWriter

    init(
        opener: ExternalURLOpener = .live,
        pasteboardWriter: PasteboardWriter = PasteboardWriter()
    ) {
        self.opener = opener
        self.pasteboardWriter = pasteboardWriter
    }

    func perform(_ channel: ContactChannel) -> ContactActionResult {
        if opener.open(channel.url) {
            return .opened
        }

        return pasteboardWriter.writeString(channel.fallbackText) ? .copied : .failed
    }
}

enum SettingsContentLayout {
    static let cardWidth: CGFloat = 440
    static let cardCornerRadius: CGFloat = 24
    static let cardShadowRadius: CGFloat = 28
    static let cardShadowYOffset: CGFloat = 14
    static let overlayDimmingOpacity: Double = 0.2
    static let overlayBreathingPadding: CGFloat = 24
    static let contentPadding: CGFloat = 20
    static let sameGroupSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 20
    static let relatedInlineSpacing: CGFloat = 6
    static let rowHeight: CGFloat = 60
    static let settingsTitleFontSize: CGFloat = 16
    static let modalTextFontSize: CGFloat = 14
    static let sectionTitleFontSize: CGFloat = modalTextFontSize
    static let rowTitleFontSize: CGFloat = modalTextFontSize
    static let bodyFontSize: CGFloat = modalTextFontSize
    static let controlFontSize: CGFloat = modalTextFontSize
    static let inlineMessageFontSize: CGFloat = modalTextFontSize
    static let rowTrailingColumnWidth: CGFloat = 260
    static let rowContentSpacing: CGFloat = sameGroupSpacing
    static let titleBottomPadding: CGFloat = sectionSpacing
    static let appearancePickerWidth: CGFloat = 172
    static let languagePickerWidth: CGFloat = 132
    static let shortcutCapsuleWidth: CGFloat = 84
    static let shortcutCapsuleHeight: CGFloat = 28
    static let openAtLoginToggleWidth: CGFloat = 52
    static let inlineMessageSpacing: CGFloat = sameGroupSpacing
    static let danielStackSpacing: CGFloat = sameGroupSpacing
    static let contactButtonSpacing: CGFloat = sameGroupSpacing
    static let contactButtonHeight: CGFloat = 42
    static let contactButtonNarrowWidth: CGFloat = 112
    static let contactButtonWideWidth: CGFloat = 134
    static let contactButtonHorizontalPadding: CGFloat = relatedInlineSpacing
    static let contactButtonInnerSpacing: CGFloat = relatedInlineSpacing
    static let contactLabelArrowSpacing: CGFloat = 2
    static let contactButtonCornerRadius: CGFloat = 8
    static let contactIconSize: CGFloat = 30
    static let contactIconCornerRadius: CGFloat = 8
    static let symbolFontSize: CGFloat = modalTextFontSize
    static let contactSpacerMinLength: CGFloat = 4
    static let contactFeedbackHeight: CGFloat = 18
    static let closeButtonSize: CGFloat = 24
    static let closeButtonInset: CGFloat = 14

    static var contentWidth: CGFloat {
        cardWidth - contentPadding * 2
    }

    static var dividerWidth: CGFloat {
        contentWidth
    }

    static var shortcutIssueMessageMaxWidth: CGFloat {
        rowTrailingColumnWidth - shortcutCapsuleWidth - inlineMessageSpacing
    }

    static var launchAtLoginMessageMaxWidth: CGFloat {
        rowTrailingColumnWidth - openAtLoginToggleWidth - inlineMessageSpacing
    }

    static func contactButtonWidth(for channel: ContactChannel) -> CGFloat {
        switch channel {
        case .email:
            return contactButtonNarrowWidth
        case .whatsApp, .telegram:
            return contactButtonWideWidth
        }
    }
}

struct DimmingScrim: View {
    let opacity: Double

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(opacity))
            .modifier(DimmingScrimGlassModifier(opacity: opacity))
            .ignoresSafeArea()
    }
}

private struct DimmingScrimGlassModifier: ViewModifier {
    let opacity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(.black.opacity(opacity)), in: Rectangle())
        } else {
            content.background(.regularMaterial)
        }
    }
}

struct SettingsOverlayView: View {
    @ObservedObject var appearanceStore: AppAppearanceStore
    @ObservedObject var languageStore: AppLanguageStore
    @ObservedObject var hotKeyStatusStore: HotKeyRegistrationStatusStore

    @FocusState private var isCloseButtonFocused: Bool

    let onDismiss: () -> Void

    private var language: AppLanguage {
        languageStore.language
    }

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                DimmingScrim(opacity: SettingsContentLayout.overlayDimmingOpacity)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("lazyquips.settings.dismissScrim")
            .accessibilityHidden(true)

            SettingsContentView(
                appearanceStore: appearanceStore,
                languageStore: languageStore,
                hotKeyStatusStore: hotKeyStatusStore
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: SettingsContentLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: SettingsContentLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .onTapGesture {}
            .shadow(
                color: .black.opacity(0.18),
                radius: SettingsContentLayout.cardShadowRadius,
                x: 0,
                y: SettingsContentLayout.cardShadowYOffset
            )
            .overlay(alignment: .topTrailing) {
                closeButton
                    .padding(.top, SettingsContentLayout.closeButtonInset)
                    .padding(.trailing, SettingsContentLayout.closeButtonInset)
            }
            .padding(SettingsContentLayout.overlayBreathingPadding)
            .accessibilityIdentifier("lazyquips.settings.card")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("lazyquips.settings.overlay")
        .onAppear {
            isCloseButtonFocused = true
        }
        .onExitCommand(perform: onDismiss)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: SettingsContentLayout.symbolFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(
                    width: SettingsContentLayout.closeButtonSize,
                    height: SettingsContentLayout.closeButtonSize
                )
                .background(
                    Color(nsColor: .controlBackgroundColor),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .focused($isCloseButtonFocused)
        .accessibilityLabel(AppStrings.text(.close, language: language))
        .accessibilityIdentifier("lazyquips.settings.closeButton")
    }
}

struct SettingsContentView: View {
    @ObservedObject var appearanceStore: AppAppearanceStore
    @ObservedObject var languageStore: AppLanguageStore
    @ObservedObject var hotKeyStatusStore: HotKeyRegistrationStatusStore

    let launchAtLoginController: LaunchAtLoginController
    let contactActionController: ContactActionController

    @State private var launchAtLogin: Bool
    @State private var displayState: LaunchAtLoginDisplayState
    @State private var errorKey: AppStringKey?
    @State private var contactFeedbackKey: AppStringKey?
    @State private var contactFeedbackTask: Task<Void, Never>?

    init(
        appearanceStore: AppAppearanceStore = .shared,
        languageStore: AppLanguageStore,
        hotKeyStatusStore: HotKeyRegistrationStatusStore,
        launchAtLoginController: LaunchAtLoginController = .shared,
        contactActionController: ContactActionController = ContactActionController()
    ) {
        self.appearanceStore = appearanceStore
        self.languageStore = languageStore
        self.hotKeyStatusStore = hotKeyStatusStore
        self.launchAtLoginController = launchAtLoginController
        self.contactActionController = contactActionController

        let currentState = launchAtLoginController.currentState()
        _displayState = State(initialValue: currentState)
        _launchAtLogin = State(initialValue: currentState == .enabled)
    }

    private var language: AppLanguage {
        languageStore.language
    }

    var body: some View {
        content
            .preferredColorScheme(appearanceStore.appearance.preferredColorScheme)
            .tint(LazyQuipsVisualStyle.carbonCopyPurple)
            .onAppear(perform: refreshLaunchAtLoginState)
            .onDisappear {
                contactFeedbackTask?.cancel()
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AppStrings.text(.settings, language: language))
                .font(.system(size: SettingsContentLayout.settingsTitleFontSize, weight: .bold))
                .padding(.bottom, SettingsContentLayout.titleBottomPadding)

            appearanceRow
            Divider()
                .frame(width: SettingsContentLayout.dividerWidth)

            languageRow
            Divider()
                .frame(width: SettingsContentLayout.dividerWidth)

            shortcutRow
            Divider()
                .frame(width: SettingsContentLayout.dividerWidth)

            openAtLoginRow
            Divider()
                .frame(width: SettingsContentLayout.dividerWidth)

            danielSection
        }
        .padding(SettingsContentLayout.contentPadding)
        .frame(width: SettingsContentLayout.cardWidth)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("lazyquips.settings.content")
    }

    private var appearanceRow: some View {
        SettingsRow(title: AppStrings.text(.appearance, language: language)) {
            Picker("", selection: appearanceSelection) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(AppStrings.text(appearance.titleKey, language: language)).tag(appearance)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.regular)
            .font(.system(size: SettingsContentLayout.controlFontSize))
            .fixedSize()
            .frame(width: SettingsContentLayout.appearancePickerWidth, alignment: .trailing)
            .accessibilityIdentifier("lazyquips.settings.appearancePicker")
        }
    }

    private var appearanceSelection: Binding<AppAppearance> {
        Binding {
            appearanceStore.appearance
        } set: { newAppearance in
            appearanceStore.select(newAppearance)
        }
    }

    private var languageRow: some View {
        SettingsRow(title: AppStrings.text(.language, language: language)) {
            Picker("", selection: languageSelection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.regular)
            .font(.system(size: SettingsContentLayout.controlFontSize))
            .fixedSize()
            .frame(width: SettingsContentLayout.languagePickerWidth, alignment: .trailing)
            .accessibilityIdentifier("lazyquips.settings.languagePicker")
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            languageStore.language
        } set: { newLanguage in
            languageStore.select(newLanguage)
        }
    }

    private var shortcutRow: some View {
        SettingsRow(title: AppStrings.text(.appShortcuts, language: language)) {
            HStack(spacing: SettingsContentLayout.inlineMessageSpacing) {
                if let shortcutIssueMessage {
                    Text(shortcutIssueMessage)
                        .font(.system(size: SettingsContentLayout.inlineMessageFontSize))
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.85)
                        .frame(
                            maxWidth: SettingsContentLayout.shortcutIssueMessageMaxWidth,
                            alignment: .trailing
                        )
                }

                Text(AppStrings.text(.appShortcutValue, language: language))
                    .font(.system(size: SettingsContentLayout.controlFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(
                        width: SettingsContentLayout.shortcutCapsuleWidth,
                        height: SettingsContentLayout.shortcutCapsuleHeight
                    )
                    .background(.regularMaterial, in: Capsule())
            }
            .accessibilityIdentifier("lazyquips.settings.shortcutStatus")
        }
    }

    private var shortcutIssueMessage: String? {
        if hotKeyStatusStore.status == .unavailable {
            return AppStrings.text(.appShortcutConflictHint, language: language)
        }

        return nil
    }

    private var openAtLoginRow: some View {
        SettingsRow(title: AppStrings.text(.openAtLogin, language: language)) {
            HStack(spacing: SettingsContentLayout.inlineMessageSpacing) {
                if let message = launchAtLoginMessage {
                    launchAtLoginMessageContent(message)
                        .frame(
                            maxWidth: SettingsContentLayout.launchAtLoginMessageMaxWidth,
                            alignment: .trailing
                        )
                }

                Toggle("", isOn: launchAtLoginBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.regular)
                    .fixedSize()
                    .frame(width: SettingsContentLayout.openAtLoginToggleWidth, alignment: .trailing)
                    .accessibilityIdentifier("lazyquips.settings.openAtLoginToggle")
            }
        }
    }

    @ViewBuilder
    private func launchAtLoginMessageContent(_ message: String) -> some View {
        if canOpenSystemSettingsFromLaunchAtLoginMessage {
            Button {
                launchAtLoginController.openSystemSettingsLoginItems()
            } label: {
                launchAtLoginMessageLabel(message)
            }
            .buttonStyle(.plain)
        } else {
            launchAtLoginMessageLabel(message)
        }
    }

    private func launchAtLoginMessageLabel(_ message: String) -> some View {
        Text(message)
            .font(.system(size: SettingsContentLayout.inlineMessageFontSize))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.trailing)
            .minimumScaleFactor(0.85)
    }

    private var canOpenSystemSettingsFromLaunchAtLoginMessage: Bool {
        errorKey == nil && displayState == .requiresApproval
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            launchAtLogin
        } set: { enabled in
            updateLaunchAtLogin(enabled)
        }
    }

    private var launchAtLoginMessage: String? {
        if let errorKey {
            return AppStrings.text(errorKey, language: language)
        }

        switch displayState {
        case .enabled, .disabled:
            return nil
        case .requiresApproval:
            return AppStrings.text(.openAtLoginUserAction, language: language)
        case .unavailable:
            return AppStrings.text(.openAtLoginUnavailable, language: language)
        }
    }

    private var danielSection: some View {
        VStack(alignment: .leading, spacing: SettingsContentLayout.danielStackSpacing) {
            Text(AppStrings.text(.daniel, language: language))
                .font(.system(size: SettingsContentLayout.sectionTitleFontSize))

            Text(AppStrings.text(.danielDescription, language: language))
                .font(.system(size: SettingsContentLayout.bodyFontSize))
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: SettingsContentLayout.contentWidth, alignment: .leading)

            HStack(spacing: SettingsContentLayout.contactButtonSpacing) {
                ForEach(ContactChannel.allCases, id: \.self) { channel in
                    ContactChannelButton(
                        channel: channel,
                        language: language,
                        action: { performContactAction(channel) }
                    )
                }
            }
            .frame(width: SettingsContentLayout.contentWidth, alignment: .leading)

            Text(contactFeedbackKey.map { AppStrings.text($0, language: language) } ?? "")
                .font(.system(size: SettingsContentLayout.inlineMessageFontSize))
                .foregroundStyle(.secondary)
                .frame(height: SettingsContentLayout.contactFeedbackHeight, alignment: .leading)
        }
        .frame(width: SettingsContentLayout.contentWidth, alignment: .leading)
        .padding(.top, SettingsContentLayout.sectionSpacing)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginController.setEnabled(enabled)
            errorKey = nil
            refreshLaunchAtLoginState()
        } catch {
            errorKey = .openAtLoginError
            refreshLaunchAtLoginState()
        }
    }

    private func refreshLaunchAtLoginState() {
        displayState = launchAtLoginController.currentState()
        launchAtLogin = displayState == .enabled
    }

    private func performContactAction(_ channel: ContactChannel) {
        contactFeedbackTask?.cancel()

        let result = contactActionController.perform(channel)
        switch result {
        case .opened:
            contactFeedbackKey = nil
        case .copied:
            contactFeedbackKey = .contactCopied
        case .failed:
            contactFeedbackKey = nil
        }

        contactFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                contactFeedbackKey = nil
            }
        }
    }
}

private struct SettingsRow<TrailingContent: View>: View {
    let title: String
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        HStack(alignment: .center, spacing: SettingsContentLayout.rowContentSpacing) {
            Text(title)
                .font(.system(size: SettingsContentLayout.rowTitleFontSize, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailingContent()
                .frame(
                    width: SettingsContentLayout.rowTrailingColumnWidth,
                    alignment: .trailing
                )
        }
        .frame(
            width: SettingsContentLayout.contentWidth,
            height: SettingsContentLayout.rowHeight
        )
    }
}

private struct ContactChannelButton: View {
    let channel: ContactChannel
    let language: AppLanguage
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: SettingsContentLayout.contactButtonInnerSpacing) {
                iconView

                HStack(spacing: SettingsContentLayout.contactLabelArrowSpacing) {
                    Text(AppStrings.text(channel.titleKey, language: language))
                        .font(.system(size: SettingsContentLayout.bodyFontSize))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .foregroundStyle(.secondary)
                        .layoutPriority(1)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: SettingsContentLayout.symbolFontSize, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)

                Spacer(minLength: SettingsContentLayout.contactSpacerMinLength)
            }
            .padding(.horizontal, SettingsContentLayout.contactButtonHorizontalPadding)
            .frame(
                width: SettingsContentLayout.contactButtonWidth(for: channel),
                height: SettingsContentLayout.contactButtonHeight,
                alignment: .leading
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: SettingsContentLayout.contactButtonCornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(SettingsContactButtonStyle(isHovered: isHovered))
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityIdentifier("lazyquips.settings.contact.\(channel)")
    }

    private var iconView: some View {
        Image(systemName: channel.systemSymbolName)
            .font(.system(size: SettingsContentLayout.symbolFontSize, weight: .semibold))
            .foregroundStyle(LazyQuipsVisualStyle.carbonCopyPurple)
            .frame(
                width: SettingsContentLayout.contactIconSize,
                height: SettingsContentLayout.contactIconSize
            )
            .background(
                RoundedRectangle(
                    cornerRadius: SettingsContentLayout.contactIconCornerRadius,
                    style: .continuous
                )
                .fill(LazyQuipsVisualStyle.carbonCopyPurple.opacity(0.12))
            )
    }
}

private struct SettingsContactButtonStyle: ButtonStyle {
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(
                    cornerRadius: SettingsContentLayout.contactButtonCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: SettingsContentLayout.contactButtonCornerRadius,
                    style: .continuous
                )
                .stroke(borderColor(isPressed: configuration.isPressed), lineWidth: 0.5)
            )
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed {
            return LazyQuipsVisualStyle.carbonCopyPurple.opacity(0.14)
        }

        if isHovered {
            return Color(nsColor: .controlBackgroundColor).opacity(0.95)
        }

        return Color(nsColor: .controlBackgroundColor).opacity(0.7)
    }

    private func borderColor(isPressed: Bool) -> Color {
        if isPressed {
            return LazyQuipsVisualStyle.carbonCopyPurple.opacity(0.32)
        }

        if isHovered {
            return Color(nsColor: .separatorColor).opacity(0.42)
        }

        return Color(nsColor: .separatorColor).opacity(0.28)
    }
}
