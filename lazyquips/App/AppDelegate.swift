import AppKit
import os
import SwiftData
import SwiftUI

enum LazyQuipsPerformanceSignpost {
    private static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.lazyquips.public",
        category: "Performance"
    )

    static func interval<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        defer {
            os_signpost(.end, log: log, name: name, signpostID: signpostID)
        }

        return try work()
    }
}

struct ApplicationActivationClient {
    let setActivationPolicy: (NSApplication.ActivationPolicy) -> Bool
    let activateIgnoringOtherApps: () -> Void

    static let live = ApplicationActivationClient(
        setActivationPolicy: { NSApp.setActivationPolicy($0) },
        activateIgnoringOtherApps: {
            NSApp.activate(ignoringOtherApps: true)
        }
    )
}

typealias HotKeyControllerFactory = (@escaping () -> Void) -> HotKeyRegistering

final class AppDelegate: NSObject, NSApplicationDelegate {
    enum MainWindowIntent {
        case none
        case add
        case settings
        case search
    }

    private(set) var modelContainer: ModelContainer?
    private(set) var launchPolicy: LazyQuipsLaunchPolicy
    let appearanceStore: AppAppearanceStore
    let languageStore: AppLanguageStore
    let hotKeyStatusStore: HotKeyRegistrationStatusStore
    private let applicationActivation: ApplicationActivationClient
    private let launchAtLoginController: LaunchAtLoginController
    private let makeHotKeyController: HotKeyControllerFactory
    private var statusBarController: StatusBarController?
    private var hotKeyController: HotKeyRegistering?
    private(set) var phraseLibraryWindowState: PhraseLibraryWindowState?
    private(set) var mainWindowController: NSWindowController?
    private let resolvesLaunchPolicyAtFinishLaunching: Bool
    private var didReceiveLaunchAtLoginURL = false

    override init() {
        modelContainer = nil
        launchPolicy = LazyQuipsLaunchPolicy(intent: .userInitiated)
        appearanceStore = .shared
        languageStore = .shared
        hotKeyStatusStore = HotKeyRegistrationStatusStore()
        applicationActivation = .live
        launchAtLoginController = .shared
        makeHotKeyController = { HotKeyController(onPressed: $0) }
        resolvesLaunchPolicyAtFinishLaunching = true
        super.init()
        installLaunchAtLoginURLHandler()
    }

    deinit {
        if resolvesLaunchPolicyAtFinishLaunching {
            NSAppleEventManager.shared().removeEventHandler(
                forEventClass: AEEventClass(kInternetEventClass),
                andEventID: AEEventID(kAEGetURL)
            )
        }
    }

    init(
        modelContainer: ModelContainer?,
        launchPolicy: LazyQuipsLaunchPolicy = LazyQuipsLaunchPolicy(intent: .userInitiated),
        appearanceStore: AppAppearanceStore = .shared,
        languageStore: AppLanguageStore = .shared,
        hotKeyStatusStore: HotKeyRegistrationStatusStore = HotKeyRegistrationStatusStore(),
        applicationActivation: ApplicationActivationClient = .live,
        launchAtLoginController: LaunchAtLoginController = .shared,
        makeHotKeyController: @escaping HotKeyControllerFactory = { HotKeyController(onPressed: $0) }
    ) {
        self.modelContainer = modelContainer
        self.launchPolicy = launchPolicy
        self.appearanceStore = appearanceStore
        self.languageStore = languageStore
        self.hotKeyStatusStore = hotKeyStatusStore
        self.applicationActivation = applicationActivation
        self.launchAtLoginController = launchAtLoginController
        self.makeHotKeyController = makeHotKeyController
        resolvesLaunchPolicyAtFinishLaunching = false
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if resolvesLaunchPolicyAtFinishLaunching, !didReceiveLaunchAtLoginURL {
            launchPolicy = LazyQuipsLaunchPolicy(intent: LazyQuipsLaunchIntent())
        }

        ensureLaunchAtLoginEnabledForUserOpen()

        let modelContainer: ModelContainer
        if let existingModelContainer = self.modelContainer {
            modelContainer = existingModelContainer
        } else {
            do {
                modelContainer = try ModelContainer(for: Phrase.self, PhraseUsageStats.self)
            } catch {
                fatalError("Failed to create SwiftData ModelContainer for Phrase storage: \(error)")
            }
            self.modelContainer = modelContainer
        }

        setAccessoryActivationPolicy()
        let statusBarController = StatusBarController(
            modelContainer: modelContainer,
            appearanceStore: appearanceStore,
            languageStore: languageStore,
            onAddPhrase: { [weak self] in
                self?.showMainWindow(openAdd: true)
            },
            onOpenSettings: { [weak self] in
                self?.showSettings()
            },
            onOpenMainWindow: { [weak self] in
                self?.showMainWindow()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        self.statusBarController = statusBarController

        let hotKeyController = makeHotKeyController { [weak statusBarController] in
            statusBarController?.togglePalette()
        }
        self.hotKeyController = hotKeyController
        hotKeyStatusStore.update(isAvailable: hotKeyController.start())

        DispatchQueue.main.async { [weak self, weak statusBarController] in
            statusBarController?.prewarmPaletteContent()
            self?.prewarmApplicationMenus()
        }

        if launchPolicy.shouldShowMainWindowAfterLaunch {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.launchPolicy.shouldShowMainWindowAfterLaunch else {
                    return
                }

                self.showMainWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.stop()
        hotKeyController = nil
        statusBarController = nil
        phraseLibraryWindowState = nil
        mainWindowController = nil
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        retryGlobalHotKeyRegistration()

        if focusExistingWindow() {
            phraseLibraryWindowState?.requestSearchFocusIfNoActiveOverlay()
            return false
        }

        showMainWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.contains(where: LazyQuipsLaunchIntent.isLaunchAtLoginURL) {
            applyLaunchAtLoginIntent()
        }
    }

    @objc func handleLaunchURLAppleEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        if LazyQuipsLaunchIntent(openedURLs: [], currentAppleEvent: event) == .loginItem {
            applyLaunchAtLoginIntent()
        }
    }

    func showMainWindow(openAdd: Bool = false) {
        showMainWindow(intent: openAdd ? .add : .none)
    }

    func showSettings() {
        showMainWindow(intent: .settings)
    }

    func focusMainWindowSearch() {
        showMainWindow(intent: .search)
    }

    func showMainWindow(intent: MainWindowIntent) {
        LazyQuipsPerformanceSignpost.interval("MainWindow.Open") {
            guard let modelContainer else {
                return
            }

            showDockIconForWindow()

            let state = phraseLibraryWindowState ?? PhraseLibraryWindowState()
            phraseLibraryWindowState = state

            switch intent {
            case .none, .search:
                state.requestSearchFocusIfNoActiveOverlay()
            case .add:
                state.openAddIfNoActiveEditor()
            case .settings:
                state.openSettingsIfNoActiveEditor()
            }

            if let mainWindowController {
                mainWindowController.window?.deminiaturize(nil)
                mainWindowController.window?.makeKeyAndOrderFront(nil)
                return
            }

            let view = PhraseLibraryView(
                state: state,
                appearanceStore: appearanceStore,
                languageStore: languageStore,
                hotKeyStatusStore: hotKeyStatusStore
            )
                .modelContainer(modelContainer)

            let windowController = HostedWindowController(
                title: "Lazy Quips",
                size: NSSize(width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                minSize: NSSize(width: 800, height: 600),
                rootView: view
            ) { [weak self] in
                self?.phraseLibraryWindowState = nil
                self?.mainWindowController = nil
                self?.hideDockIconIfNoVisibleWindows()
            }

            windowController.window?.titleVisibility = .hidden
            windowController.window?.titlebarAppearsTransparent = true

            mainWindowController = windowController
            windowController.showWindow(nil as Any?)
            windowController.window?.makeKeyAndOrderFront(nil as Any?)
        }
    }

    private func showDockIconForWindow() {
        _ = applicationActivation.setActivationPolicy(.regular)
        applicationActivation.activateIgnoringOtherApps()
    }

    private func focusExistingWindow() -> Bool {
        focusWindow(mainWindowController?.window)
    }

    private func focusWindow(_ window: NSWindow?) -> Bool {
        guard let window else {
            return false
        }

        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private func hideDockIconIfNoVisibleWindows() {
        guard mainWindowController == nil else {
            return
        }

        setAccessoryActivationPolicy()
    }

    private func setAccessoryActivationPolicy() {
        _ = applicationActivation.setActivationPolicy(.accessory)
    }

    private func ensureLaunchAtLoginEnabledForUserOpen() {
        guard launchPolicy.intent == .userInitiated else {
            return
        }

        launchAtLoginController.ensureEnabledSilently()
    }

    private func retryGlobalHotKeyRegistration() {
        guard let hotKeyController else {
            return
        }

        hotKeyStatusStore.update(isAvailable: hotKeyController.restart())
    }

    private func prewarmApplicationMenus() {
        var visitedMenus: Set<ObjectIdentifier> = []
        prewarmApplicationMenu(NSApp.mainMenu, visitedMenus: &visitedMenus)
    }

    private func prewarmApplicationMenu(
        _ menu: NSMenu?,
        visitedMenus: inout Set<ObjectIdentifier>
    ) {
        guard let menu,
              visitedMenus.insert(ObjectIdentifier(menu)).inserted
        else {
            return
        }

        menu.update()
        for item in menu.items {
            prewarmApplicationMenu(item.submenu, visitedMenus: &visitedMenus)
        }
    }

    private func installLaunchAtLoginURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleLaunchURLAppleEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    private func applyLaunchAtLoginIntent() {
        didReceiveLaunchAtLoginURL = true
        launchPolicy = LazyQuipsLaunchPolicy(intent: .loginItem)
    }
}
