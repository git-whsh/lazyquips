import AppKit
import SwiftData
import SwiftUI

enum StatusMenuLayout {
    static let width: CGFloat = 428
    static let maximumHeight: CGFloat = 712
    static let contentHorizontalPadding: CGFloat = 20
    static let listHorizontalPadding: CGFloat = 0
    static let rowLeadingPadding: CGFloat = 20
    static let rowTrailingPadding: CGFloat = 8
    static let toolbarTopPadding: CGFloat = 20
    static let toolbarControlSpacing: CGFloat = 20
    static let toolbarControlHeight: CGFloat = 32
    static let searchFieldWidth: CGFloat = 310
    static let addButtonWidth: CGFloat = 58
    static let headerTopPadding: CGFloat = 20
    static let headerHorizontalPadding: CGFloat = 20
    static let headerHeight: CGFloat = 36
    static let shortcutColumnWidth: CGFloat = PhraseShortcutPreview.columnWidth
    static let minimumContentHeight: CGFloat = 160
    static let sectionTitleHeight: CGFloat = 16
    static let rowVerticalSpacing: CGFloat = 0
    static let sectionBottomPadding: CGFloat = 18
    static let rowWidth: CGFloat = width
    static let rowHeight: CGFloat = 50
    static let navigationTrailingPadding: CGFloat = 1
    static let submenuWidth: CGFloat = 317
    static let submenuLeadingPadding: CGFloat = 0
    static let submenuTrailingPadding: CGFloat = 10
    static let submenuVerticalPadding: CGFloat = 10
    static let submenuShortcutHeight: CGFloat = 17
    static let submenuBodyTopPadding: CGFloat = 8
    static let submenuHoverDelayNanoseconds: UInt64 = 120_000_000
    static let footerTopPadding: CGFloat = 10
    static let footerBottomPadding: CGFloat = 26
    static let footerHeight: CGFloat = 72
    static let openMainWindowButtonWidth: CGFloat = 121
    static let footerPlainButtonMinWidth: CGFloat = 64
    static let footerPlainButtonHeight: CGFloat = toolbarControlHeight
    static let statusItemMouseEvents: NSEvent.EventTypeMask = [.leftMouseUp, .rightMouseUp]
    static let surfaceCornerRadius: CGFloat = 16
    static let chromePadding: CGFloat = 28
    static let chromeTopPadding: CGFloat = 4
    static let chromeShadowRadius: CGFloat = 18
    static let chromeShadowYOffset: CGFloat = 8
    static let panelAnchorGap: CGFloat = 2

    static var defaultContentSize: NSSize {
        NSSize(width: width, height: maximumHeight)
    }

    static var defaultPanelWindowContentSize: NSSize {
        panelWindowContentSize(for: defaultContentSize)
    }

    static var maximumPanelWidth: CGFloat {
        width + submenuWidth
    }

    static var maximumPanelWindowWidth: CGFloat {
        maximumPanelWidth + (chromePadding * 2)
    }

    static var toolbarHeight: CGFloat {
        toolbarTopPadding + toolbarControlHeight
    }

    static var maximumContentHeight: CGFloat {
        maximumHeight - toolbarHeight - headerHeight - footerHeight
    }

    static var submenuTextWidth: CGFloat {
        submenuWidth - submenuLeadingPadding - submenuTrailingPadding
    }

    static var toolbarSearchX: CGFloat {
        contentHorizontalPadding
    }

    static var toolbarAddX: CGFloat {
        toolbarSearchX + searchFieldWidth + toolbarControlSpacing
    }

    static var headerShortcutX: CGFloat {
        headerHorizontalPadding
    }

    static var headerPhraseX: CGFloat {
        headerShortcutX + shortcutColumnWidth
    }

    static var sectionTitleLeadingPadding: CGFloat {
        rowLeadingPadding
    }

    static var sectionTitleX: CGFloat {
        listHorizontalPadding + sectionTitleLeadingPadding
    }

    static var rowTextX: CGFloat {
        listHorizontalPadding + rowLeadingPadding
    }

    static var phraseTextX: CGFloat {
        rowTextX + shortcutColumnWidth
    }

    static var phraseColumnWidth: CGFloat {
        rowVisualWidth - rowLeadingPadding - rowTrailingPadding - shortcutColumnWidth
    }

    static var rowVisualWidth: CGFloat {
        rowWidth - navigationReservedTrailingWidth
    }

    static var rowCopiedFeedbackTrailingPadding: CGFloat {
        rowTrailingPadding + LazyQuipsVisualStyle.copiedBadgeTrailingPadding
    }

    static var navigationReservedTrailingWidth: CGFloat {
        PhraseIndexLayout.hitWidth + navigationTrailingPadding
    }

    static func preferredContentHeight(for sections: [PhrasePaletteSection]) -> CGFloat {
        let naturalHeight: CGFloat
        if sections.isEmpty {
            naturalHeight = minimumContentHeight
        } else {
            naturalHeight = sections.reduce(0) { result, section in
                result + preferredSectionHeight(for: section)
            }
        }

        return min(max(naturalHeight, minimumContentHeight), maximumContentHeight)
    }

    static func preferredHeight(for sections: [PhrasePaletteSection]) -> CGFloat {
        toolbarHeight + headerHeight + preferredContentHeight(for: sections) + footerHeight
    }

    static func panelWidth(hasSubmenu: Bool) -> CGFloat {
        width + (hasSubmenu ? submenuWidth : 0)
    }

    static func panelWindowContentSize(for visibleContentSize: CGSize) -> CGSize {
        CGSize(
            width: visibleContentSize.width + (chromePadding * 2),
            height: visibleContentSize.height + chromeTopPadding + chromePadding
        )
    }

    static func visibleContentSize(for panelWindowContentSize: CGSize) -> CGSize {
        CGSize(
            width: max(0, panelWindowContentSize.width - (chromePadding * 2)),
            height: max(0, panelWindowContentSize.height - chromeTopPadding - chromePadding)
        )
    }

    static func visibleContentFrame(inWindowContentSize panelWindowContentSize: CGSize) -> CGRect {
        CGRect(
            x: chromePadding,
            y: chromePadding,
            width: visibleContentSize(for: panelWindowContentSize).width,
            height: visibleContentSize(for: panelWindowContentSize).height
        )
    }

    static func visibleContentFrame(inPanelFrame panelFrame: CGRect) -> CGRect {
        let visibleSize = visibleContentSize(for: panelFrame.size)
        return CGRect(
            x: panelFrame.minX + chromePadding,
            y: panelFrame.minY + chromePadding,
            width: visibleSize.width,
            height: visibleSize.height
        )
    }

    private static func preferredSectionHeight(for section: PhrasePaletteSection) -> CGFloat {
        let titleHeight = section.showsTitle ? sectionTitleHeight : 0
        let rowSpacing = max(0, section.rows.count - 1)
        let rowsHeight = CGFloat(section.rows.count) * rowHeight
            + CGFloat(rowSpacing) * rowVerticalSpacing

        return titleHeight + rowsHeight + sectionBottomPadding
    }
}

enum StatusMenuAction: CaseIterable {
    case addPhrase
    case openSettings
    case openMainWindow
    case quit
}

enum StatusMenuPanelPlacement {
    static func panelFrame(
        anchorRect: NSRect,
        contentSize: NSSize,
        reservedWidth: CGFloat,
        screenVisibleFrame: NSRect?
    ) -> NSRect {
        let visibleContentSize = StatusMenuLayout.visibleContentSize(for: contentSize)
        let placementWidth = max(contentSize.width, reservedWidth + (StatusMenuLayout.chromePadding * 2))
        var origin = NSPoint(
            x: anchorRect.midX - (StatusMenuLayout.width / 2) - StatusMenuLayout.chromePadding,
            y: anchorRect.minY
                - StatusMenuLayout.panelAnchorGap
                - visibleContentSize.height
                - StatusMenuLayout.chromePadding
        )

        if let screenVisibleFrame {
            let maxX = max(screenVisibleFrame.minX, screenVisibleFrame.maxX - placementWidth)
            let maxY = max(screenVisibleFrame.minY, screenVisibleFrame.maxY - contentSize.height)
            origin.x = min(max(origin.x, screenVisibleFrame.minX), maxX)
            origin.y = min(max(origin.y, screenVisibleFrame.minY), maxY)
        }

        return NSRect(origin: origin, size: contentSize)
    }

    static func frameKeepingTopLeading(
        currentFrame: NSRect,
        contentSize: NSSize,
        screenVisibleFrame: NSRect?
    ) -> NSRect {
        var frame = currentFrame
        frame.origin.y = currentFrame.maxY - contentSize.height
        frame.size = contentSize

        if let screenVisibleFrame {
            let maxX = max(screenVisibleFrame.minX, screenVisibleFrame.maxX - contentSize.width)
            let maxY = max(screenVisibleFrame.minY, screenVisibleFrame.maxY - contentSize.height)
            frame.origin.x = min(max(frame.origin.x, screenVisibleFrame.minX), maxX)
            frame.origin.y = min(max(frame.origin.y, screenVisibleFrame.minY), maxY)
        }

        return frame
    }
}

enum StatusMenuPanelHitTesting {
    static func containsVisibleSurface(
        point: NSPoint,
        contentSize: NSSize,
        submenuPresentation: StatusMenuSubmenuPresentation?
    ) -> Bool {
        let visibleFrame = StatusMenuLayout.visibleContentFrame(inWindowContentSize: contentSize)
        let mainSurface = NSRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: StatusMenuLayout.width,
            height: visibleFrame.height
        )
        if mainSurface.contains(point) {
            return true
        }

        guard let submenuPresentation else {
            return false
        }

        let submenuHeight = min(submenuPresentation.height, visibleFrame.height)
        let submenuMinY = max(
            0,
            min(
                visibleFrame.height - submenuHeight,
                visibleFrame.height - submenuPresentation.topOffset - submenuPresentation.height
            )
        )
        let submenuSurface = NSRect(
            x: visibleFrame.minX + StatusMenuLayout.width,
            y: visibleFrame.minY + submenuMinY,
            width: StatusMenuLayout.submenuWidth,
            height: submenuHeight
        )
        return submenuSurface.contains(point)
    }
}

struct StatusMenuActionDispatcher {
    let closePalette: () -> Void
    let onAddPhrase: () -> Void
    let onOpenSettings: () -> Void
    let onOpenMainWindow: () -> Void
    let onQuit: () -> Void

    func perform(_ action: StatusMenuAction) {
        closePalette()

        switch action {
        case .addPhrase:
            onAddPhrase()
        case .openSettings:
            onOpenSettings()
        case .openMainWindow:
            onOpenMainWindow()
        case .quit:
            onQuit()
        }
    }
}

final class StatusMenuPanel: NSPanel {
    var onCancelOperation: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func cancelOperation(_ sender: Any?) {
        if let onCancelOperation {
            onCancelOperation()
        } else {
            super.cancelOperation(sender)
        }
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == 53, let onCancelOperation {
            onCancelOperation()
            return
        }

        super.sendEvent(event)
    }
}

enum StatusItemDefaults {
    static let autosaveName = "dev.lazyquips.public.statusItem"
}

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let modelContainer: ModelContainer
    private let appearanceStore: AppAppearanceStore
    private let languageStore: AppLanguageStore
    private let onAddPhrase: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenMainWindow: () -> Void
    private let onQuit: () -> Void
    private var palettePanel: StatusMenuPanel?
    private let palettePresentationState = PhrasePalettePresentationState()
    private var activePanelWindowContentSize = StatusMenuLayout.defaultPanelWindowContentSize
    private var activeSubmenuPresentation: StatusMenuSubmenuPresentation?
    private var outsideClickMonitor: Any?
    private var localEventMonitor: Any?

    init(
        modelContainer: ModelContainer,
        appearanceStore: AppAppearanceStore,
        languageStore: AppLanguageStore,
        onAddPhrase: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenMainWindow: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = StatusItemDefaults.autosaveName
        if !statusItem.isVisible {
            statusItem.isVisible = true
        }
        self.modelContainer = modelContainer
        self.appearanceStore = appearanceStore
        self.languageStore = languageStore
        self.onAddPhrase = onAddPhrase
        self.onOpenSettings = onOpenSettings
        self.onOpenMainWindow = onOpenMainWindow
        self.onQuit = onQuit
        super.init()

        configureStatusItem()
    }

    deinit {
        closePalette()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let iconURL = Bundle.main.url(forResource: "StatusIconTemplate", withExtension: "pdf"),
           let image = NSImage(contentsOf: iconURL) {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            button.image = image
            button.imageScaling = .scaleProportionallyDown
        } else {
            button.title = "lq"
        }

        button.toolTip = "Lazy Quips"
        button.setAccessibilityLabel("Lazy Quips")
        button.target = self
        button.action = #selector(togglePalette)
        button.sendAction(on: StatusMenuLayout.statusItemMouseEvents)
    }

    @objc func togglePalette() {
        if palettePanel?.isVisible == true {
            closePalette()
        } else {
            showPalette()
        }
    }

    func prewarmPaletteContent() {
        LazyQuipsPerformanceSignpost.interval("Popover.Prewarm") {
            refreshPaletteContent()
            guard let view = palettePanel?.contentViewController?.view else {
                return
            }

            view.frame = NSRect(origin: .zero, size: StatusMenuLayout.defaultPanelWindowContentSize)
            view.layoutSubtreeIfNeeded()
        }
    }

    private func showPalette() {
        LazyQuipsPerformanceSignpost.interval("Popover.Open") {
            let openContext = LazyQuipsPerformanceSignpost.interval("Popover.Open.Prepare") { () -> (NSStatusBarButton, NSRect)? in
                guard let button = statusItem.button,
                      let anchorRect = button.screenFrame
                else {
                    return nil
                }

                activePanelWindowContentSize = StatusMenuLayout.defaultPanelWindowContentSize
                return (button, anchorRect)
            }
            guard let (button, anchorRect) = openContext else {
                return
            }

            refreshPaletteContent()
            LazyQuipsPerformanceSignpost.interval("Popover.Open.PresentationReset") {
                palettePresentationState.beginPresentation()
            }
            guard let panel = palettePanel else {
                return
            }

            LazyQuipsPerformanceSignpost.interval("Popover.Open.Frame") {
                let panelFrame = StatusMenuPanelPlacement.panelFrame(
                    anchorRect: anchorRect,
                    contentSize: activePanelWindowContentSize,
                    reservedWidth: StatusMenuLayout.maximumPanelWidth,
                    screenVisibleFrame: button.window?.screen?.visibleFrame
                )
                if panel.frame.equalTo(panelFrame) {
                    return
                }

                if panel.frame.size == panelFrame.size {
                    panel.setFrameOrigin(panelFrame.origin)
                } else {
                    panel.setFrame(panelFrame, display: false)
                }
            }
            LazyQuipsPerformanceSignpost.interval("Popover.Open.OrderFront") {
                panel.makeKeyAndOrderFront(nil)
            }
            LazyQuipsPerformanceSignpost.interval("Popover.Open.Monitors") {
                startOutsideClickMonitor()
            }
        }
    }

    private func refreshPaletteContent() {
        LazyQuipsPerformanceSignpost.interval("Popover.RefreshContent") {
            let panel = palettePanel ?? makePalettePanel()
            palettePanel = panel
            guard panel.contentViewController == nil else {
                return
            }

            panel.contentViewController = NSHostingController(
                rootView: QuickRepliesView(
                    appearanceStore: appearanceStore,
                    languageStore: languageStore,
                    presentationState: palettePresentationState,
                    onPreferredContentSizeChange: { [weak self] size in
                        self?.updatePanelContentSize(size)
                    },
                    onSubmenuPresentationChange: { [weak self] presentation in
                        self?.activeSubmenuPresentation = presentation
                    },
                    onAddPhrase: { [weak self] in
                        self?.performPaletteAction(.addPhrase)
                    },
                    onOpenSettings: { [weak self] in
                        self?.performPaletteAction(.openSettings)
                    },
                    onOpenMainWindow: { [weak self] in
                        self?.performPaletteAction(.openMainWindow)
                    },
                    onQuit: { [weak self] in
                        self?.performPaletteAction(.quit)
                    },
                    onCopyComplete: { [weak self] in
                        self?.closePalette()
                    }
                )
                .modelContainer(modelContainer)
            )
        }
    }

    private func updatePanelContentSize(_ size: CGSize) {
        let contentSize = NSSize(width: size.width, height: size.height)
        guard activePanelWindowContentSize != contentSize else {
            return
        }

        activePanelWindowContentSize = contentSize
        guard let panel = palettePanel,
              panel.isVisible
        else {
            return
        }

        let frame = StatusMenuPanelPlacement.frameKeepingTopLeading(
            currentFrame: panel.frame,
            contentSize: contentSize,
            screenVisibleFrame: panel.screen?.visibleFrame
        )
        panel.setFrame(frame, display: true)
    }

    private func makePalettePanel() -> StatusMenuPanel {
        let panel = StatusMenuPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: StatusMenuLayout.defaultPanelWindowContentSize.width,
                height: StatusMenuLayout.defaultPanelWindowContentSize.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.transient, .ignoresCycle]
        panel.onCancelOperation = { [weak self] in
            self?.closePalette()
        }
        return panel
    }

    private func performPaletteAction(_ action: StatusMenuAction) {
        StatusMenuActionDispatcher(
            closePalette: { [weak self] in
                self?.closePalette()
            },
            onAddPhrase: onAddPhrase,
            onOpenSettings: onOpenSettings,
            onOpenMainWindow: onOpenMainWindow,
            onQuit: onQuit
        )
        .perform(action)
    }

    private func closePalette() {
        LazyQuipsPerformanceSignpost.interval("Popover.Close") {
            palettePresentationState.endPresentation()
            palettePanel?.orderOut(nil)
            activePanelWindowContentSize = StatusMenuLayout.defaultPanelWindowContentSize
            activeSubmenuPresentation = nil
            stopOutsideClickMonitor()
        }
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self else {
                return event
            }

            if !self.eventHitsPaletteOrStatusItem(event) {
                let shouldConsumeEvent = event.window === self.palettePanel
                self.closePalette()
                return shouldConsumeEvent ? nil : event
            }

            return event
        }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePalette()
            }
        }
    }

    private func stopOutsideClickMonitor() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        guard let outsideClickMonitor else {
            return
        }

        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }

    private func eventHitsPaletteOrStatusItem(_ event: NSEvent) -> Bool {
        if event.window === palettePanel {
            return StatusMenuPanelHitTesting.containsVisibleSurface(
                point: event.locationInWindow,
                contentSize: activePanelWindowContentSize,
                submenuPresentation: activeSubmenuPresentation
            )
        }

        guard let button = statusItem.button,
              event.window === button.window
        else {
            return false
        }

        let point = button.convert(event.locationInWindow, from: nil)
        return button.bounds.contains(point)
    }
}

private extension NSView {
    var screenFrame: NSRect? {
        guard let window else {
            return nil
        }

        return window.convertToScreen(convert(bounds, to: nil))
    }
}
