import AppKit
import SwiftData
import SwiftUI

enum PhraseColumnHeaderText {
    static let shortcut = "Shortcut"
    static let phrase = "Phrase"
}

final class PhrasePalettePresentationState: ObservableObject {
    @Published private(set) var presentationID: UUID
    @Published private(set) var dismissalID: PhrasePaletteDismissalID

    init() {
        let initialPresentationID = UUID()
        presentationID = initialPresentationID
        dismissalID = PhrasePaletteDismissalID(presentationID: initialPresentationID)
    }

    func beginPresentation() {
        presentationID = UUID()
    }

    func endPresentation() {
        dismissalID = PhrasePaletteDismissalID(presentationID: presentationID)
    }
}

struct PhrasePaletteDismissalID: Equatable {
    let id: UUID
    let presentationID: UUID

    init(presentationID: UUID, id: UUID = UUID()) {
        self.id = id
        self.presentationID = presentationID
    }
}

struct QuickRepliesView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var appearanceStore: AppAppearanceStore
    @ObservedObject private var languageStore: AppLanguageStore
    @ObservedObject private var presentationState: PhrasePalettePresentationState
    @Query private var phrases: [Phrase]
    @Query private var usageStats: [PhraseUsageStats]

    private let onAddPhrase: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenMainWindow: () -> Void
    private let onQuit: () -> Void
    private let onCopyComplete: () -> Void
    private let onPreferredContentSizeChange: (CGSize) -> Void
    private let onSubmenuPresentationChange: (StatusMenuSubmenuPresentation?) -> Void

    @State private var searchText = ""
    @State private var selectedRowID: PhrasePaletteRowID?
    @State private var copiedRowID: PhrasePaletteRowID?
    @State private var activeSubmenuPresentation: StatusMenuSubmenuPresentation?
    @State private var submenuHoverState = PhrasePaletteSubmenuHoverState()
    @State private var keyboardSubmenuRowID: PhrasePaletteRowID?
    @State private var submenuHoverTask: Task<Void, Never>?
    @State private var submenuDismissTask: Task<Void, Never>?
    @State private var isSubmenuHovered = false
    @State private var feedbackTask: Task<Void, Never>?
    @State private var closeAfterCopyTask: Task<Void, Never>?
    @State private var feedbackToken = UUID()
    @State private var frozenSnapshotAfterCopy: PhrasePaletteSnapshot?
    @State private var snapshotCache = PhrasePaletteSnapshotCache()
    @State private var textMetricsCache = PhrasePaletteTextMetrics.Cache()
    @State private var appliedPresentationID: UUID?
    @State private var searchIndexPrewarmTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    init(
        appearanceStore: AppAppearanceStore = .shared,
        languageStore: AppLanguageStore = .shared,
        presentationState: PhrasePalettePresentationState = PhrasePalettePresentationState(),
        onPreferredContentSizeChange: @escaping (CGSize) -> Void = { _ in },
        onSubmenuPresentationChange: @escaping (StatusMenuSubmenuPresentation?) -> Void = { _ in },
        onAddPhrase: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onOpenMainWindow: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onCopyComplete: @escaping () -> Void
    ) {
        self.appearanceStore = appearanceStore
        self.languageStore = languageStore
        self.presentationState = presentationState
        self.onPreferredContentSizeChange = onPreferredContentSizeChange
        self.onSubmenuPresentationChange = onSubmenuPresentationChange
        self.onAddPhrase = onAddPhrase
        self.onOpenSettings = onOpenSettings
        self.onOpenMainWindow = onOpenMainWindow
        self.onQuit = onQuit
        self.onCopyComplete = onCopyComplete
    }

    private var language: AppLanguage {
        languageStore.language
    }

    private var preferredContentWidth: CGFloat {
        StatusMenuLayout.width
    }

    private var activeSubmenuAnchorRowID: PhrasePaletteRowID? {
        submenuHoverState.activeRowID ?? keyboardSubmenuRowID
    }

    private func preferredVisiblePanelContentSize(for snapshot: PhrasePaletteSnapshot) -> CGSize {
        CGSize(
            width: StatusMenuLayout.panelWidth(hasSubmenu: activeSubmenuPresentation != nil),
            height: snapshot.preferredHeight
        )
    }

    var body: some View {
        let snapshot = currentSnapshot()
        let visiblePanelContentSize = preferredVisiblePanelContentSize(for: snapshot)
        let searchIndexPrewarmSignature = phrases.map(PhrasePaletteSearchIndexPrewarmSignature.init)

        StatusMenuGlassSurfaceGroup(
            visibleContentSize: visiblePanelContentSize,
            submenuPresentation: activeSubmenuPresentation
        ) {
            ZStack(alignment: .topLeading) {
                menuContent(snapshot: snapshot)
                    .frame(width: preferredContentWidth, height: snapshot.preferredHeight, alignment: .topLeading)
                    .overlayPreferenceValue(PhrasePaletteRowBoundsKey.self) { anchors in
                        submenuPresentationReporter(snapshot: snapshot, anchors: anchors)
                    }

                if let activeSubmenuPresentation {
                    PhrasePaletteSubmenuView(
                        presentation: activeSubmenuPresentation,
                        onHoverChange: updateSubmenuHover
                    )
                    .offset(x: StatusMenuLayout.width, y: activeSubmenuPresentation.topOffset)
                    .transition(.opacity)
                }
            }
            .frame(
                width: StatusMenuLayout.maximumPanelWidth,
                height: snapshot.preferredHeight,
                alignment: .topLeading
            )
        }
        .preferredColorScheme(appearanceStore.appearance.preferredColorScheme)
        .onAppear {
            applyPresentationIfNeeded(presentationState.presentationID)
            scheduleSearchIndexPrewarm(for: phrases)
        }
        .onChange(of: presentationState.presentationID) { _, nextPresentationID in
            applyPresentationIfNeeded(nextPresentationID)
        }
        .onChange(of: searchIndexPrewarmSignature) { _, _ in
            scheduleSearchIndexPrewarm(for: phrases)
        }
        .onChange(of: presentationState.dismissalID) { _, dismissalID in
            resetAfterDismissal(for: dismissalID)
        }
        .onChange(of: searchText) { _, _ in
            guard frozenSnapshotAfterCopy == nil else {
                cancelSubmenuHover(closeActivePresentation: false)
                return
            }

            selectFirstResult(in: snapshot, showsKeyboardSubmenu: snapshot.hasSearchText)
            cancelSubmenuHover(closeActivePresentation: false)
        }
        .onChange(of: snapshot.selectableRowIDs) { _, _ in
            keepSelectionValid(in: snapshot)
        }
        .onChange(of: snapshot.preferredContentSize) { _, _ in
            notifyPreferredContentSize(
                StatusMenuLayout.panelWindowContentSize(for: preferredVisiblePanelContentSize(for: snapshot))
            )
        }
        .onChange(of: activeSubmenuPresentation) { _, _ in
            onSubmenuPresentationChange(activeSubmenuPresentation)
            notifyPreferredContentSize(
                StatusMenuLayout.panelWindowContentSize(for: preferredVisiblePanelContentSize(for: snapshot))
            )
        }
        .onDisappear {
            searchIndexPrewarmTask?.cancel()
            searchIndexPrewarmTask = nil
            resetAfterDismissal()
        }
    }

    private func scheduleSearchIndexPrewarm(for phrases: [Phrase]) {
        searchIndexPrewarmTask?.cancel()

        guard !phrases.isEmpty else {
            searchIndexPrewarmTask = nil
            return
        }

        searchIndexPrewarmTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else {
                return
            }

            snapshotCache.prewarmSearchIndexes(for: phrases)
        }
    }

    private func applyPresentationIfNeeded(_ presentationID: UUID) {
        guard appliedPresentationID != presentationID else {
            focusSearchField(for: presentationID)
            return
        }

        appliedPresentationID = presentationID
        resetForPresentation(presentationID: presentationID)
    }

    private func resetForPresentation(presentationID: UUID) {
        cancelTransientTasks()

        searchText = ""
        clearTransientPresentationState()

        let snapshot = snapshotCache.snapshot(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats
        )
        selectFirstResult(in: snapshot, showsKeyboardSubmenu: snapshot.hasSearchText)
        notifyPreferredContentSize(
            StatusMenuLayout.panelWindowContentSize(for: preferredVisiblePanelContentSize(for: snapshot))
        )
        onSubmenuPresentationChange(nil)

        focusSearchField(for: presentationID)
    }

    private func resetAfterDismissal(for dismissalID: PhrasePaletteDismissalID) {
        guard appliedPresentationID == dismissalID.presentationID else {
            return
        }

        resetAfterDismissal()
    }

    private func resetAfterDismissal() {
        cancelTransientTasks()
        clearTransientPresentationState()
        onSubmenuPresentationChange(nil)
    }

    private func cancelTransientTasks() {
        feedbackTask?.cancel()
        feedbackTask = nil
        closeAfterCopyTask?.cancel()
        closeAfterCopyTask = nil
        submenuHoverTask?.cancel()
        submenuHoverTask = nil
        submenuDismissTask?.cancel()
        submenuDismissTask = nil
    }

    private func clearTransientPresentationState() {
        selectedRowID = nil
        copiedRowID = nil
        activeSubmenuPresentation = nil
        submenuHoverState.cancel()
        keyboardSubmenuRowID = nil
        isSubmenuHovered = false
        feedbackToken = UUID()
        frozenSnapshotAfterCopy = nil
    }

    private func focusSearchField(for presentationID: UUID) {
        DispatchQueue.main.async {
            guard appliedPresentationID == presentationID else {
                return
            }

            isSearchFocused = true
        }
    }

    private func currentSnapshot() -> PhrasePaletteSnapshot {
        if let frozenSnapshotAfterCopy {
            return frozenSnapshotAfterCopy
        }

        return snapshotCache.snapshot(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats
        )
    }

    private func menuContent(snapshot: PhrasePaletteSnapshot) -> some View {
        VStack(spacing: 0) {
            toolbar(snapshot: snapshot)
            header
            content(snapshot: snapshot)
                .frame(height: snapshot.preferredContentHeight)
            footer
        }
    }

    private func toolbar(snapshot: PhrasePaletteSnapshot) -> some View {
        HStack(spacing: StatusMenuLayout.toolbarControlSpacing) {
            searchField(snapshot: snapshot)
                .frame(width: StatusMenuLayout.searchFieldWidth, height: StatusMenuLayout.toolbarControlHeight)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    isSearchFocused = true
                })

            Button(action: onAddPhrase) {
                HStack(spacing: 4) {
                    Text(AppStrings.text(.add, language: language))
                    Image(systemName: "plus")
                }
            }
            .buttonStyle(
                LazyQuipsToolbarButtonStyle(
                    width: StatusMenuLayout.addButtonWidth,
                    height: StatusMenuLayout.toolbarControlHeight
                )
            )
            .accessibilityIdentifier("lazyquips.palette.addButton")
            .help(AppStrings.text(.add, language: language))
        }
        .padding(.top, StatusMenuLayout.toolbarTopPadding)
        .padding(.horizontal, StatusMenuLayout.contentHorizontalPadding)
    }

    private func searchField(snapshot: PhrasePaletteSnapshot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(AppStrings.text(.paletteSearchPlaceholder, language: language), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .focused($isSearchFocused)
                .accessibilityIdentifier("lazyquips.palette.searchField")
                .onSubmit {
                    copySelectedPhrase(in: snapshot)
                }
                .onKeyPress(.upArrow) {
                    moveSelection(by: -1, in: snapshot)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(by: 1, in: snapshot)
                    return .handled
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .lazyQuipsToolbarControlSurface()
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text(AppStrings.text(.shortcut, language: language))
                .frame(width: StatusMenuLayout.shortcutColumnWidth, alignment: .leading)

            Text(AppStrings.text(.phrase, language: language))
                .frame(maxWidth: .infinity, alignment: .leading)

        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.top, StatusMenuLayout.headerTopPadding)
        .padding(.horizontal, StatusMenuLayout.headerHorizontalPadding)
        .frame(height: StatusMenuLayout.headerHeight, alignment: .top)
    }

    @ViewBuilder
    private func content(snapshot: PhrasePaletteSnapshot) -> some View {
        if snapshot.sections.isEmpty {
            PhrasePaletteEmptyStateView(
                isEmptyLibrary: phrases.isEmpty,
                hasSearchText: snapshot.hasSearchText,
                language: language
            )
        } else {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(snapshot.sections) { section in
                                PhrasePaletteSectionView(
                                    section: section,
                                    selectedRowID: selectedRowID,
                                    copiedRowID: copiedRowID,
                                    activeSubmenuAnchorRowID: activeSubmenuAnchorRowID,
                                    language: language,
                                    onCopy: { row in copyPhrase(row, snapshot: snapshot) },
                                    onSubmenuHover: updateHoveredSubmenuRow
                                )
                                .id(PhrasePaletteScrollID.section(section.id))
                            }
                        }
                        .padding(.horizontal, StatusMenuLayout.listHorizontalPadding)
                    }
                    .lazyQuipsScrollIndicatorsHidden()
                    .onChange(of: presentationState.presentationID) { _, _ in
                        scrollToTop(in: snapshot, using: proxy)
                    }

                    if !snapshot.navigationTitles.isEmpty {
                        PhraseIndexView(titles: snapshot.navigationTitles, language: language) { title in
                            guard let item = snapshot.navigationItems.first(where: { $0.title == title }) else {
                                return
                            }

                            withAnimation(.easeInOut(duration: 0.16)) {
                                proxy.scrollTo(item.target, anchor: .top)
                            }
                        }
                        .padding(.trailing, StatusMenuLayout.navigationTrailingPadding)
                    }
                }
            }
        }
    }

    private func submenuPresentationReporter(
        snapshot: PhrasePaletteSnapshot,
        anchors: [PhrasePaletteRowID: Anchor<CGRect>]
    ) -> some View {
        GeometryReader { proxy in
            let presentation = submenuPresentation(in: proxy, snapshot: snapshot, anchors: anchors)

            Color.clear
                .onAppear {
                    reportSubmenuPresentation(presentation)
                }
                .onChange(of: presentation) { _, nextPresentation in
                    reportSubmenuPresentation(nextPresentation)
                }
        }
    }

    private func reportSubmenuPresentation(_ presentation: StatusMenuSubmenuPresentation?) {
        guard activeSubmenuPresentation != presentation else {
            return
        }

        activeSubmenuPresentation = presentation
    }

    @ViewBuilder
    private var footer: some View {
        let items = StatusMenuFooterItem.items(language: language)

        HStack(alignment: .center, spacing: 0) {
            ForEach(items) { item in
                Button {
                    performFooterAction(item.action)
                } label: {
                    Text(item.title)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .accessibilityIdentifier(item.accessibilityIdentifier)
                .help(item.title)
                .modifier(StatusMenuFooterButtonStyle(buttonWidth: item.buttonWidth))

                if item.id != items.last?.id {
                    Spacer()
                }
            }
        }
        .padding(.top, StatusMenuLayout.footerTopPadding)
        .padding(.horizontal, StatusMenuLayout.contentHorizontalPadding)
        .padding(.bottom, StatusMenuLayout.footerBottomPadding)
        .frame(height: StatusMenuLayout.footerHeight)
    }

    private func performFooterAction(_ action: StatusMenuFooterAction) {
        switch action {
        case .openSettings:
            resetSubmenuState()
            onOpenSettings()
        case .openMainWindow:
            resetSubmenuState()
            onOpenMainWindow()
        case .quit:
            resetSubmenuState()
            onQuit()
        }
    }

    private func selectFirstResult(in snapshot: PhrasePaletteSnapshot, showsKeyboardSubmenu: Bool) {
        LazyQuipsPerformanceSignpost.interval("Selection.Update") {
            let rowID = PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: nil,
                selectableRows: snapshot.selectableRows,
                selectableRowByID: snapshot.selectableRowByID
            )
            selectedRowID = rowID
            updateKeyboardSubmenu(rowID: rowID, in: snapshot, isEnabled: showsKeyboardSubmenu)
        }
    }

    private func keepSelectionValid(in snapshot: PhrasePaletteSnapshot) {
        LazyQuipsPerformanceSignpost.interval("Selection.Update") {
            let rowID = PhrasePaletteData.selectionAfterRowsChange(
                currentSelection: selectedRowID,
                selectableRows: snapshot.selectableRows,
                selectableRowByID: snapshot.selectableRowByID
            )
            let shouldKeepKeyboardSubmenu = keyboardSubmenuRowID != nil
            selectedRowID = rowID
            updateKeyboardSubmenu(rowID: rowID, in: snapshot, isEnabled: shouldKeepKeyboardSubmenu)
        }
    }

    private func moveSelection(by offset: Int, in snapshot: PhrasePaletteSnapshot) {
        LazyQuipsPerformanceSignpost.interval("Selection.Update") {
            let rowID = PhrasePaletteData.selectionByMoving(
                currentSelection: selectedRowID,
                offset: offset,
                selectableRows: snapshot.selectableRows,
                selectableRowByID: snapshot.selectableRowByID,
                selectableRowIndexByID: snapshot.selectableRowIndexByID
            )
            selectedRowID = rowID
            cancelSubmenuHover(closeActivePresentation: false)
            updateKeyboardSubmenu(rowID: rowID, in: snapshot, isEnabled: true)
        }
    }

    private func copySelectedPhrase(in snapshot: PhrasePaletteSnapshot) {
        LazyQuipsPerformanceSignpost.interval("Selection.Submit") {
            guard let selectedRowID,
                  let row = snapshot.selectableRowByID[selectedRowID]
            else {
                return
            }

            copyPhrase(row, snapshot: snapshot)
        }
    }

    private func updateHoveredSubmenuRow(_ row: PhrasePaletteRow, isHovered: Bool) {
        if isHovered {
            selectedRowID = row.id
            keyboardSubmenuRowID = nil
        }

        if !isHovered {
            endSubmenuHover(rowID: row.id)
            return
        }

        scheduleSubmenuHover(for: row)
    }

    private func submenuPresentation(
        in proxy: GeometryProxy,
        snapshot: PhrasePaletteSnapshot,
        anchors: [PhrasePaletteRowID: Anchor<CGRect>]
    ) -> StatusMenuSubmenuPresentation? {
        guard let activeSubmenuRow = activeSubmenuRow(in: snapshot),
              let anchor = anchors[activeSubmenuRow.id]
        else {
            return nil
        }

        let bodyHeight = textMetricsCache.submenuBodyHeight(
            for: activeSubmenuRow.phrase,
            menuHeight: snapshot.preferredHeight
        )
        let panelHeight = PhrasePaletteTextMetrics.submenuHeight(
            forBodyHeight: bodyHeight,
            menuHeight: snapshot.preferredHeight
        )
        let topOffset = max(
            0,
            min(snapshot.preferredHeight - panelHeight, proxy[anchor].minY)
        )

        return StatusMenuSubmenuPresentation(
            id: activeSubmenuRow.id,
            shortcut: activeSubmenuRow.phrase.shortcut,
            body: activeSubmenuRow.phrase.body,
            bodyHeight: bodyHeight,
            topOffset: topOffset,
            height: panelHeight
        )
    }

    private func activeSubmenuRow(in snapshot: PhrasePaletteSnapshot) -> PhrasePaletteRow? {
        if let rowID = submenuHoverState.activeRowID,
           let row = snapshot.selectableRowByID[rowID] {
            return row
        }

        if let rowID = keyboardSubmenuRowID,
           let row = snapshot.selectableRowByID[rowID] {
            return row
        }

        return nil
    }

    private func scrollToTop(in snapshot: PhrasePaletteSnapshot, using proxy: ScrollViewProxy) {
        guard let firstSection = snapshot.sections.first else {
            return
        }

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            proxy.scrollTo(PhrasePaletteScrollID.section(firstSection.id), anchor: .top)
        }
    }

    private func scheduleSubmenuHover(for row: PhrasePaletteRow) {
        guard row.mayNeedSubmenu else {
            cancelSubmenuHover()
            return
        }

        submenuHoverTask?.cancel()
        submenuDismissTask?.cancel()
        isSubmenuHovered = false
        submenuHoverState.begin(rowID: row.id)

        let rowID = row.id
        let phrase = row.phrase
        submenuHoverTask = Task {
            try? await Task.sleep(nanoseconds: StatusMenuLayout.submenuHoverDelayNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard submenuHoverState.pendingRowID == rowID else {
                    return
                }

                if textMetricsCache.needsSubmenu(for: phrase) {
                    submenuHoverState.activate(rowID: rowID)
                } else {
                    submenuHoverState.end(rowID: rowID)
                }
            }
        }
    }

    private func endSubmenuHover(rowID: PhrasePaletteRowID) {
        if submenuHoverState.pendingRowID == rowID {
            submenuHoverTask?.cancel()
            submenuHoverState.end(rowID: rowID)
            return
        }

        if submenuHoverState.activeRowID == rowID {
            scheduleSubmenuDismiss(rowID: rowID)
            return
        }

        submenuHoverState.end(rowID: rowID)
    }

    private func cancelSubmenuHover(closeActivePresentation: Bool = true) {
        submenuHoverTask?.cancel()
        submenuDismissTask?.cancel()
        isSubmenuHovered = false
        submenuHoverState.cancel()
        if closeActivePresentation {
            activeSubmenuPresentation = nil
        }
    }

    private func resetSubmenuState() {
        cancelSubmenuHover()
        keyboardSubmenuRowID = nil
    }

    private func updateSubmenuHover(_ isHovered: Bool) {
        isSubmenuHovered = isHovered

        if isHovered {
            submenuDismissTask?.cancel()
            return
        }

        if let activeRowID = submenuHoverState.activeRowID {
            scheduleSubmenuDismiss(rowID: activeRowID)
        }
    }

    private func scheduleSubmenuDismiss(rowID: PhrasePaletteRowID) {
        submenuDismissTask?.cancel()
        submenuDismissTask = Task {
            try? await Task.sleep(nanoseconds: StatusMenuLayout.submenuHoverDelayNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard !isSubmenuHovered else {
                    return
                }

                submenuHoverState.end(rowID: rowID)
            }
        }
    }

    private func updateKeyboardSubmenu(
        rowID: PhrasePaletteRowID?,
        in snapshot: PhrasePaletteSnapshot,
        isEnabled: Bool
    ) {
        guard isEnabled,
              let rowID,
              let row = snapshot.selectableRowByID[rowID],
              row.mayNeedSubmenu,
              textMetricsCache.needsSubmenu(for: row.phrase)
        else {
            keyboardSubmenuRowID = nil
            return
        }

        keyboardSubmenuRowID = rowID
    }

    private func notifyPreferredContentSize(_ size: CGSize) {
        onPreferredContentSizeChange(size)
    }

    private func copyPhrase(_ row: PhrasePaletteRow, snapshot: PhrasePaletteSnapshot) {
        resetSubmenuState()
        frozenSnapshotAfterCopy = snapshot

        let result = PhraseCopyController(
            repository: PhraseRepository(context: modelContext)
        )
        .copy(row.phrase)

        guard result.didCopy else {
            frozenSnapshotAfterCopy = nil
            return
        }

        showCopiedFeedback(for: row.id)
    }

    private func showCopiedFeedback(for rowID: PhrasePaletteRowID) {
        feedbackTask?.cancel()
        feedbackTask = nil
        closeAfterCopyTask?.cancel()
        closeAfterCopyTask = nil

        let token = UUID()
        feedbackToken = token
        let presentationID = presentationState.presentationID
        let dismissalID = presentationState.dismissalID

        setCopiedRowID(rowID)

        feedbackTask = Task {
            try? await Task.sleep(nanoseconds: LazyQuipsVisualStyle.phrasePaletteCopiedFeedbackDurationNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard feedbackToken == token,
                      copiedRowID == rowID,
                      presentationState.presentationID == presentationID,
                      presentationState.dismissalID == dismissalID
                else {
                    return
                }

                setCopiedRowID(nil)
            }
        }

        closeAfterCopyTask = Task {
            try? await Task.sleep(nanoseconds: LazyQuipsVisualStyle.phrasePaletteCopiedFeedbackDurationNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard feedbackToken == token,
                      presentationState.presentationID == presentationID,
                      presentationState.dismissalID == dismissalID
                else {
                    return
                }

                onCopyComplete()
            }
        }
    }

    private func setCopiedRowID(_ rowID: PhrasePaletteRowID?) {
        if accessibilityReduceMotion {
            copiedRowID = rowID
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            copiedRowID = rowID
        }
    }
}

enum PhrasePaletteData {
    static func snapshot(
        for searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats],
        sortedSearchIndexes: [PhraseSearchIndex]? = nil
    ) -> PhrasePaletteSnapshot {
        let hasSearchText = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let displayedPhrases = displayedPhrases(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats,
            sortedSearchIndexes: sortedSearchIndexes
        )
        let sections = sections(
            displayedPhrases: displayedPhrases,
            usageStats: usageStats,
            hasSearchText: hasSearchText
        )
        let selectableRows = selectableRows(in: sections)
        let selectableRowByID = Dictionary(uniqueKeysWithValues: selectableRows.map { ($0.id, $0) })
        let selectableRowIndexByID = Dictionary(
            uniqueKeysWithValues: selectableRows.enumerated().map { ($0.element.id, $0.offset) }
        )
        let navigationItems = PhrasePaletteNavigationItem.items(
            displayedPhrases: displayedPhrases,
            paletteSections: sections,
            hasSearchText: hasSearchText
        )
        let preferredContentHeight = StatusMenuLayout.preferredContentHeight(for: sections)
        let preferredHeight = StatusMenuLayout.preferredHeight(for: sections)

        return PhrasePaletteSnapshot(
            hasSearchText: hasSearchText,
            displayedPhrases: displayedPhrases,
            sections: sections,
            selectableRows: selectableRows,
            selectableRowIDs: selectableRows.map(\.id),
            selectableRowByID: selectableRowByID,
            selectableRowIndexByID: selectableRowIndexByID,
            navigationItems: navigationItems,
            navigationTitles: navigationItems.map(\.title),
            preferredContentHeight: preferredContentHeight,
            preferredHeight: preferredHeight,
            preferredContentSize: CGSize(width: StatusMenuLayout.width, height: preferredHeight)
        )
    }

    static func sections(
        for searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) -> [PhrasePaletteSection] {
        let hasSearchText = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let displayedPhrases = displayedPhrases(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats
        )

        return sections(
            displayedPhrases: displayedPhrases,
            usageStats: usageStats,
            hasSearchText: hasSearchText
        )
    }

    private static func sections(
        displayedPhrases: [Phrase],
        usageStats: [PhraseUsageStats],
        hasSearchText: Bool
    ) -> [PhrasePaletteSection] {
        var sections: [PhrasePaletteSection] = []

        if !hasSearchText {
            let recentRows = makeRows(
                for: recentPhrases(inSortedPhrases: displayedPhrases, usageStats: usageStats),
                sectionID: .recent
            )

            if !recentRows.isEmpty {
                sections.append(
                    PhrasePaletteSection(
                        id: .recent,
                        title: "Recent",
                        showsTitle: false,
                        isSelectable: true,
                        rows: recentRows
                    )
                )
            }

            let starredRows = makeRows(
                for: displayedPhrases.filter(\.isStarred),
                sectionID: .starred
            )
            if !starredRows.isEmpty {
                sections.append(
                    PhrasePaletteSection(
                        id: .starred,
                        title: "Star",
                        showsTitle: true,
                        isSelectable: true,
                        rows: starredRows
                    )
                )
            }
        }

        let allRows = makeRows(for: displayedPhrases, sectionID: .all)
        if !allRows.isEmpty {
            sections.append(
                PhrasePaletteSection(
                    id: .all,
                    title: "All",
                    showsTitle: !hasSearchText,
                    isSelectable: true,
                    rows: allRows
                )
            )
        }

        return sections
    }

    static func selectableRows(in sections: [PhrasePaletteSection]) -> [PhrasePaletteRow] {
        sections
            .filter(\.isSelectable)
            .flatMap(\.rows)
    }

    static func selectionAfterRowsChange(
        currentSelection: PhrasePaletteRowID?,
        selectableRows: [PhrasePaletteRow],
        selectableRowByID: [PhrasePaletteRowID: PhrasePaletteRow]? = nil
    ) -> PhrasePaletteRowID? {
        guard let currentSelection else {
            return selectableRows.first?.id
        }

        let containsCurrentSelection: Bool
        if let selectableRowByID {
            containsCurrentSelection = selectableRowByID[currentSelection] != nil
        } else {
            containsCurrentSelection = selectableRows.contains(where: { $0.id == currentSelection })
        }
        guard containsCurrentSelection else {
            return selectableRows.first?.id
        }

        return currentSelection
    }

    static func selectionByMoving(
        currentSelection: PhrasePaletteRowID?,
        offset: Int,
        selectableRows: [PhrasePaletteRow],
        selectableRowByID: [PhrasePaletteRowID: PhrasePaletteRow]? = nil,
        selectableRowIndexByID: [PhrasePaletteRowID: Int]? = nil
    ) -> PhrasePaletteRowID? {
        guard !selectableRows.isEmpty else {
            return nil
        }

        if let currentSelection,
           let selectableRowIndexByID {
            guard let currentIndex = selectableRowIndexByID[currentSelection] else {
                return selectionAfterRowsChange(
                    currentSelection: currentSelection,
                    selectableRows: selectableRows,
                    selectableRowByID: selectableRowByID
                )
            }

            let nextIndex = max(0, min(selectableRows.count - 1, currentIndex + offset))
            return selectableRows[nextIndex].id
        }

        guard let currentSelection,
              let currentIndex = selectableRows.firstIndex(where: { $0.id == currentSelection })
        else {
            return selectionAfterRowsChange(
                currentSelection: currentSelection,
                selectableRows: selectableRows,
                selectableRowByID: selectableRowByID
            )
        }

        let nextIndex = max(0, min(selectableRows.count - 1, currentIndex + offset))
        return selectableRows[nextIndex].id
    }

    static func displayedPhrases(
        for searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats],
        sortedSearchIndexes: [PhraseSearchIndex]? = nil
    ) -> [Phrase] {
        if let sortedSearchIndexes {
            return PhraseSearch.search(
                searchText,
                inSortedPreparedIndexes: sortedSearchIndexes,
                usageStats: usageStats
            )
        }

        return PhraseSearch.search(searchText, in: phrases, usageStats: usageStats)
    }

    static func recentPhrases(
        in phrases: [Phrase],
        usageStats: [PhraseUsageStats],
        limit: Int = 2
    ) -> [Phrase] {
        recentPhrases(
            inSortedPhrases: sortedPhrases(phrases),
            usageStats: usageStats,
            limit: limit
        )
    }

    private static func recentPhrases(
        inSortedPhrases sortedPhrases: [Phrase],
        usageStats: [PhraseUsageStats],
        limit: Int = 2
    ) -> [Phrase] {
        guard limit > 0 else {
            return []
        }

        let phrasesByID = Dictionary(uniqueKeysWithValues: sortedPhrases.map { ($0.id, $0) })

        let stats = sortedUsageStatsByRecent(
            usageStats
                .filter { phrasesByID[$0.phraseID] != nil },
            phrasesByID: phrasesByID
        )
        var seenPhraseIDs = Set<UUID>()

        return stats.compactMap { stats in
            guard seenPhraseIDs.insert(stats.phraseID).inserted else {
                return nil
            }

            return phrasesByID[stats.phraseID]
        }
        .prefix(limit)
        .map { $0 }
    }

    private static func sortedPhrases(_ phrases: [Phrase]) -> [Phrase] {
        phrases.sorted { lhs, rhs in
            if lhs.normalizedShortcut != rhs.normalizedShortcut {
                return lhs.normalizedShortcut < rhs.normalizedShortcut
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func sortedUsageStatsByRecent(
        _ stats: [PhraseUsageStats],
        phrasesByID: [UUID: Phrase]
    ) -> [PhraseUsageStats] {
        stats.sorted { lhs, rhs in
            if lhs.lastCopiedAt != rhs.lastCopiedAt {
                return lhs.lastCopiedAt > rhs.lastCopiedAt
            }

            let lhsShortcut = phrasesByID[lhs.phraseID]?.normalizedShortcut ?? ""
            let rhsShortcut = phrasesByID[rhs.phraseID]?.normalizedShortcut ?? ""
            if lhsShortcut != rhsShortcut {
                return lhsShortcut < rhsShortcut
            }

            return lhs.phraseID.uuidString < rhs.phraseID.uuidString
        }
    }

    private static func makeRows(
        for phrases: [Phrase],
        sectionID: PhrasePaletteSectionID
    ) -> [PhrasePaletteRow] {
        phrases.map { phrase in
            PhrasePaletteRow(
                id: PhrasePaletteRowID(sectionID: sectionID, phraseID: phrase.id),
                phrase: phrase,
                mayNeedSubmenu: PhrasePaletteTextMetrics.mayNeedSubmenuWithoutMeasurement(phrase.body)
            )
        }
    }

}

enum PhrasePaletteSectionID: String, Hashable {
    case recent
    case starred
    case all
}

struct PhrasePaletteRowID: Hashable {
    let sectionID: PhrasePaletteSectionID
    let phraseID: UUID
}

enum PhrasePaletteScrollID: Hashable {
    case section(PhrasePaletteSectionID)
    case row(PhrasePaletteRowID)
}

struct PhrasePaletteRow: Identifiable {
    let id: PhrasePaletteRowID
    let phrase: Phrase
    let mayNeedSubmenu: Bool
}

struct PhrasePaletteSection: Identifiable {
    let id: PhrasePaletteSectionID
    let title: String
    let showsTitle: Bool
    let isSelectable: Bool
    let rows: [PhrasePaletteRow]
}

struct PhrasePaletteSnapshot {
    let hasSearchText: Bool
    let displayedPhrases: [Phrase]
    let sections: [PhrasePaletteSection]
    let selectableRows: [PhrasePaletteRow]
    let selectableRowIDs: [PhrasePaletteRowID]
    let selectableRowByID: [PhrasePaletteRowID: PhrasePaletteRow]
    let selectableRowIndexByID: [PhrasePaletteRowID: Int]
    let navigationItems: [PhrasePaletteNavigationItem]
    let navigationTitles: [String]
    let preferredContentHeight: CGFloat
    let preferredHeight: CGFloat
    let preferredContentSize: CGSize
}

final class PhrasePaletteSnapshotCache {
    typealias SnapshotBuilder = (String, [Phrase], [PhraseUsageStats], [PhraseSearchIndex]?) -> PhrasePaletteSnapshot

    private let makeSnapshot: SnapshotBuilder
    private let searchIndexCache: PhraseSearchIndexCache
    private var cachedKey: PhrasePaletteSnapshotCacheKey?
    private var cachedSnapshot: PhrasePaletteSnapshot?

    init(
        searchIndexCache: PhraseSearchIndexCache = PhraseSearchIndexCache(),
        makeSnapshot: @escaping SnapshotBuilder = { searchText, phrases, usageStats, sortedSearchIndexes in
            PhrasePaletteData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes
            )
        }
    ) {
        self.searchIndexCache = searchIndexCache
        self.makeSnapshot = makeSnapshot
    }

    func prewarmSearchIndexes(for phrases: [Phrase]) {
        guard !phrases.isEmpty else {
            return
        }

        _ = searchIndexCache.sortedIndexes(for: phrases)
    }

    func snapshot(
        for searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) -> PhrasePaletteSnapshot {
        if cachedKey?.matches(
            searchText: searchText,
            phrases: phrases,
            usageStats: usageStats
        ) == true,
           let cachedSnapshot {
            return cachedSnapshot
        }

        return LazyQuipsPerformanceSignpost.interval("Palette.Snapshot") {
            let nextKey = PhrasePaletteSnapshotCacheKey(
                searchText: searchText,
                phrases: phrases,
                usageStats: usageStats
            )
            let sortedSearchIndexes = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : searchIndexCache.sortedIndexes(for: phrases)
            let snapshot = makeSnapshot(
                searchText,
                phrases,
                usageStats,
                sortedSearchIndexes
            )
            cachedKey = nextKey
            cachedSnapshot = snapshot
            return snapshot
        }
    }

}

private struct PhrasePaletteSearchIndexPrewarmSignature: Equatable {
    let id: UUID
    let shortcut: String
    let normalizedShortcut: String
    let contentRevision: Int

    init(phrase: Phrase) {
        id = phrase.id
        shortcut = phrase.shortcut
        normalizedShortcut = phrase.normalizedShortcut
        contentRevision = phrase.contentRevision
    }
}

private struct PhrasePaletteSnapshotCacheKey: Equatable {
    let searchText: String
    let phrases: [PhrasePalettePhraseSignature]
    let usageStats: [PhrasePaletteUsageStatsSignature]

    init(
        searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) {
        self.searchText = searchText
        self.phrases = phrases.map(PhrasePalettePhraseSignature.init)
        self.usageStats = usageStats.map(PhrasePaletteUsageStatsSignature.init)
    }

    func matches(
        searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) -> Bool {
        guard self.searchText == searchText,
              self.phrases.count == phrases.count,
              self.usageStats.count == usageStats.count
        else {
            return false
        }

        for (signature, phrase) in zip(self.phrases, phrases) {
            guard signature.matches(phrase) else {
                return false
            }
        }

        for (signature, usageStats) in zip(self.usageStats, usageStats) {
            guard signature.matches(usageStats) else {
                return false
            }
        }

        return true
    }
}

private struct PhrasePalettePhraseSignature: Equatable {
    let id: UUID
    let normalizedShortcut: String
    let isStarred: Bool
    let contentRevision: Int

    init(phrase: Phrase) {
        id = phrase.id
        normalizedShortcut = phrase.normalizedShortcut
        isStarred = phrase.isStarred
        contentRevision = phrase.contentRevision
    }

    func matches(_ phrase: Phrase) -> Bool {
        id == phrase.id
            && normalizedShortcut == phrase.normalizedShortcut
            && isStarred == phrase.isStarred
            && contentRevision == phrase.contentRevision
    }
}

private struct PhrasePaletteUsageStatsSignature: Equatable {
    let id: UUID
    let phraseID: UUID
    let lastCopiedAt: Date
    let copyCount: Int

    init(usageStats: PhraseUsageStats) {
        id = usageStats.id
        phraseID = usageStats.phraseID
        lastCopiedAt = usageStats.lastCopiedAt
        copyCount = usageStats.copyCount
    }

    func matches(_ usageStats: PhraseUsageStats) -> Bool {
        id == usageStats.id
            && phraseID == usageStats.phraseID
            && lastCopiedAt == usageStats.lastCopiedAt
            && copyCount == usageStats.copyCount
    }
}

struct PhrasePaletteSubmenuHoverState: Equatable {
    private(set) var pendingRowID: PhrasePaletteRowID?
    private(set) var activeRowID: PhrasePaletteRowID?

    mutating func begin(rowID: PhrasePaletteRowID) {
        pendingRowID = rowID
        activeRowID = nil
    }

    mutating func activate(rowID: PhrasePaletteRowID) {
        guard pendingRowID == rowID else {
            return
        }

        pendingRowID = nil
        activeRowID = rowID
    }

    mutating func end(rowID: PhrasePaletteRowID) {
        if pendingRowID == rowID {
            pendingRowID = nil
        }

        if activeRowID == rowID {
            activeRowID = nil
        }
    }

    mutating func cancel() {
        pendingRowID = nil
        activeRowID = nil
    }
}

struct PhrasePaletteNavigationItem: Identifiable, Equatable {
    let title: String
    let target: PhrasePaletteScrollID

    var id: String {
        title
    }

    static func items(
        displayedPhrases: [Phrase],
        paletteSections: [PhrasePaletteSection],
        hasSearchText: Bool
    ) -> [PhrasePaletteNavigationItem] {
        let groupedSections = PhraseGrouping.sections(
            for: displayedPhrases,
            preservingInputOrder: true
        )
        let hasStarredPaletteSection = paletteSections.contains { $0.id == .starred }

        return groupedSections.compactMap { section in
            switch section.id {
            case .all:
                return nil
            case .starred:
                if hasStarredPaletteSection {
                    return PhrasePaletteNavigationItem(
                        title: section.title,
                        target: .section(.starred)
                    )
                }

                guard let firstPhrase = section.phrases.first else {
                    return nil
                }

                return PhrasePaletteNavigationItem(
                    title: section.title,
                    target: .row(PhrasePaletteRowID(sectionID: .all, phraseID: firstPhrase.id))
                )
            case .digits, .letter(_), .symbols:
                guard let firstPhrase = section.phrases.first else {
                    return nil
                }

                return PhrasePaletteNavigationItem(
                    title: section.id.indexTitle,
                    target: .row(PhrasePaletteRowID(sectionID: .all, phraseID: firstPhrase.id))
                )
            }
        }
    }
}

struct PhrasePaletteRowBoundsKey: PreferenceKey {
    static var defaultValue: [PhrasePaletteRowID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [PhrasePaletteRowID: Anchor<CGRect>],
        nextValue: () -> [PhrasePaletteRowID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct StatusMenuSubmenuPresentation: Equatable {
    let id: PhrasePaletteRowID
    let shortcut: String
    let body: String
    let bodyHeight: CGFloat
    let topOffset: CGFloat
    let height: CGFloat
}

enum PhrasePaletteTextMetrics {
    static let previewLineLimit = 2
    static let fontSize: CGFloat = 14
    private static let shortLineCharacterLimit = 18

    static func needsSubmenu(_ text: String) -> Bool {
        lineCount(for: text, width: StatusMenuLayout.phraseColumnWidth) > previewLineLimit
    }

    static func mayNeedSubmenuWithoutMeasurement(_ text: String) -> Bool {
        let logicalLines = text.components(separatedBy: .newlines)
        guard logicalLines.count < previewLineLimit else {
            return true
        }

        return logicalLines.contains { $0.count > shortLineCharacterLimit }
    }

    static func lineCount(for text: String, width: CGFloat) -> Int {
        let height = measuredHeight(for: text, width: width)
        return max(1, Int(ceil(height / lineHeight)))
    }

    static func submenuHeight(
        for text: String,
        menuHeight: CGFloat = StatusMenuLayout.maximumHeight
    ) -> CGFloat {
        let bodyHeight = min(
            measuredHeight(for: text, width: StatusMenuLayout.submenuTextWidth),
            submenuMaximumBodyHeight(menuHeight: menuHeight)
        )
        return submenuHeight(forBodyHeight: bodyHeight, menuHeight: menuHeight)
    }

    static func submenuHeight(
        forBodyHeight bodyHeight: CGFloat,
        menuHeight: CGFloat = StatusMenuLayout.maximumHeight
    ) -> CGFloat {
        let height = StatusMenuLayout.submenuVerticalPadding
            + StatusMenuLayout.submenuShortcutHeight
            + StatusMenuLayout.submenuBodyTopPadding
            + bodyHeight
            + StatusMenuLayout.submenuVerticalPadding

        return min(max(height, StatusMenuLayout.rowHeight), menuHeight)
    }

    static func submenuBodyHeight(
        for text: String,
        menuHeight: CGFloat = StatusMenuLayout.maximumHeight
    ) -> CGFloat {
        min(
            measuredHeight(for: text, width: StatusMenuLayout.submenuTextWidth),
            submenuMaximumBodyHeight(menuHeight: menuHeight)
        )
    }

    private static func submenuMaximumBodyHeight(menuHeight: CGFloat) -> CGFloat {
        max(
            0,
            menuHeight
                - (StatusMenuLayout.submenuVerticalPadding * 2)
                - StatusMenuLayout.submenuShortcutHeight
                - StatusMenuLayout.submenuBodyTopPadding
        )
    }

    private static var font: NSFont {
        NSFont.systemFont(ofSize: fontSize)
    }

    private static var lineHeight: CGFloat {
        ceil(font.ascender - font.descender + font.leading)
    }

    private static func measuredHeight(for text: String, width: CGFloat) -> CGFloat {
        let source = text.isEmpty ? " " : text
        let attributed = NSAttributedString(
            string: source,
            attributes: [.font: font]
        )
        let rect = attributed.boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )

        return max(lineHeight, ceil(rect.height))
    }

    final class Cache {
        private struct LineCountKey: Hashable {
            let phraseID: UUID
            let contentRevision: Int
            let width: CGFloat
        }

        private struct BodyHeightKey: Hashable {
            let phraseID: UUID
            let contentRevision: Int
            let menuHeight: CGFloat
        }

        private let maximumEntries = 256
        private var lineCounts: [LineCountKey: Int] = [:]
        private var bodyHeights: [BodyHeightKey: CGFloat] = [:]

        func needsSubmenu(for phrase: Phrase) -> Bool {
            lineCount(
                for: phrase.body,
                phraseID: phrase.id,
                contentRevision: phrase.contentRevision,
                width: StatusMenuLayout.phraseColumnWidth
            ) > previewLineLimit
        }

        func submenuBodyHeight(
            for phrase: Phrase,
            menuHeight: CGFloat = StatusMenuLayout.maximumHeight
        ) -> CGFloat {
            let key = BodyHeightKey(
                phraseID: phrase.id,
                contentRevision: phrase.contentRevision,
                menuHeight: menuHeight
            )
            if let cachedHeight = bodyHeights[key] {
                return cachedHeight
            }

            let bodyHeight = PhrasePaletteTextMetrics.submenuBodyHeight(for: phrase.body, menuHeight: menuHeight)
            store(bodyHeight, for: key)
            return bodyHeight
        }

        private func lineCount(
            for text: String,
            phraseID: UUID,
            contentRevision: Int,
            width: CGFloat
        ) -> Int {
            let key = LineCountKey(
                phraseID: phraseID,
                contentRevision: contentRevision,
                width: width
            )
            if let cachedCount = lineCounts[key] {
                return cachedCount
            }

            let count = PhrasePaletteTextMetrics.lineCount(for: text, width: width)
            store(count, for: key)
            return count
        }

        private func store(_ count: Int, for key: LineCountKey) {
            if lineCounts.count >= maximumEntries {
                lineCounts.removeAll(keepingCapacity: true)
            }

            lineCounts[key] = count
        }

        private func store(_ bodyHeight: CGFloat, for key: BodyHeightKey) {
            if bodyHeights.count >= maximumEntries {
                bodyHeights.removeAll(keepingCapacity: true)
            }

            bodyHeights[key] = bodyHeight
        }
    }
}

enum StatusMenuFooterAction {
    case openSettings
    case openMainWindow
    case quit
}

struct StatusMenuFooterItem: Identifiable, Equatable {
    let action: StatusMenuFooterAction
    let title: String
    let accessibilityIdentifier: String
    let buttonWidth: CGFloat?

    var id: StatusMenuFooterAction {
        action
    }

    static func items(language: AppLanguage) -> [StatusMenuFooterItem] {
        [
            StatusMenuFooterItem(
                action: .openSettings,
                title: AppStrings.text(.settings, language: language),
                accessibilityIdentifier: "lazyquips.palette.footer.settingsButton",
                buttonWidth: nil
            ),
            StatusMenuFooterItem(
                action: .openMainWindow,
                title: AppStrings.text(.openLazyQuips, language: language),
                accessibilityIdentifier: "lazyquips.palette.footer.openMainWindowButton",
                buttonWidth: StatusMenuLayout.openMainWindowButtonWidth
            ),
            StatusMenuFooterItem(
                action: .quit,
                title: AppStrings.text(.quit, language: language),
                accessibilityIdentifier: "lazyquips.palette.footer.quitButton",
                buttonWidth: nil
            )
        ]
    }
}

private struct StatusMenuFooterButtonStyle: ViewModifier {
    let buttonWidth: CGFloat?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let buttonWidth {
            content.buttonStyle(
                LazyQuipsToolbarButtonStyle(
                    width: buttonWidth,
                    height: StatusMenuLayout.toolbarControlHeight,
                    usesLiquidGlass: true
                )
            )
        } else {
            content.buttonStyle(.plain)
                .frame(
                    minWidth: StatusMenuLayout.footerPlainButtonMinWidth,
                    minHeight: StatusMenuLayout.footerPlainButtonHeight
                )
                .contentShape(Rectangle())
        }
    }
}

private struct PhrasePaletteSectionView: View {
    let section: PhrasePaletteSection
    let selectedRowID: PhrasePaletteRowID?
    let copiedRowID: PhrasePaletteRowID?
    let activeSubmenuAnchorRowID: PhrasePaletteRowID?
    let language: AppLanguage
    let onCopy: (PhrasePaletteRow) -> Void
    let onSubmenuHover: (PhrasePaletteRow, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.showsTitle {
                titleView
                    .foregroundStyle(.secondary)
                    .frame(height: StatusMenuLayout.sectionTitleHeight, alignment: .leading)
                    .padding(.leading, StatusMenuLayout.sectionTitleLeadingPadding)
            }

            VStack(alignment: .leading, spacing: StatusMenuLayout.rowVerticalSpacing) {
                ForEach(section.rows) { row in
                    PhrasePaletteRowView(
                        row: row,
                        isSelected: selectedRowID == row.id,
                        isCopied: copiedRowID == row.id,
                        activeSubmenuAnchorRowID: activeSubmenuAnchorRowID,
                        language: language,
                        onCopy: { onCopy(row) },
                        onSubmenuHover: { isHovered in
                            onSubmenuHover(row, isHovered)
                        }
                    )
                    .id(PhrasePaletteScrollID.row(row.id))
                }
            }
        }
        .padding(.bottom, StatusMenuLayout.sectionBottomPadding)
    }

    @ViewBuilder
    private var titleView: some View {
        switch section.id {
        case .recent:
            Text(AppStrings.text(.recent, language: language))
                .font(.system(size: 12))
        case .starred:
            Image(systemName: "star")
                .font(.system(size: 13, weight: .semibold))
                .accessibilityLabel(AppStrings.text(.star, language: language))
        case .all:
            Text(AppStrings.text(.all, language: language))
                .font(.system(size: 12))
        }
    }
}

private struct PhrasePaletteRowView: View {
    let row: PhrasePaletteRow
    let isSelected: Bool
    let isCopied: Bool
    let activeSubmenuAnchorRowID: PhrasePaletteRowID?
    let language: AppLanguage
    let onCopy: () -> Void
    let onSubmenuHover: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            ZStack(alignment: .leading) {
                ZStack(alignment: .trailing) {
                    HStack(spacing: 0) {
                        Text(row.phrase.shortcut)
                            .lineLimit(PhraseShortcutPreview.maximumLineCount)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            .frame(width: PhraseShortcutPreview.wrappingWidth, alignment: .leading)
                            .frame(width: StatusMenuLayout.shortcutColumnWidth, alignment: .leading)

                        Text(row.phrase.body)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, StatusMenuLayout.rowLeadingPadding)
                    .padding(.trailing, StatusMenuLayout.rowTrailingPadding)

                    if isCopied {
                        LazyQuipsCopiedBadge(language: language)
                            .padding(.trailing, StatusMenuLayout.rowCopiedFeedbackTrailingPadding)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(
                    width: StatusMenuLayout.rowVisualWidth,
                    height: StatusMenuLayout.rowHeight,
                    alignment: .leading
                )
                .background(background)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        LazyQuipsRowBoundaryOverlay()
                    } else {
                        Rectangle()
                            .fill(LazyQuipsVisualStyle.rowDivider)
                            .frame(height: 0.5)
                            .padding(.leading, StatusMenuLayout.rowLeadingPadding)
                    }
                }
            }
            .frame(width: StatusMenuLayout.rowWidth, height: StatusMenuLayout.rowHeight, alignment: .leading)
            .animation(.easeInOut(duration: 0.12), value: isSelected)
            .animation(copiedAnimation, value: isCopied)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityIdentifier("lazyquips.palette.row.\(row.id.sectionID.rawValue).\(row.phrase.id.uuidString)")
        .anchorPreference(key: PhrasePaletteRowBoundsKey.self, value: .bounds) { anchor in
            row.mayNeedSubmenu && row.id == activeSubmenuAnchorRowID ? [row.id: anchor] : [:]
        }
        .onHover {
            isHovered = $0
            onSubmenuHover($0)
        }
    }

    private var background: Color {
        if isSelected {
            return LazyQuipsVisualStyle.rowSelectedBackground
        }

        if isHovered {
            return LazyQuipsVisualStyle.rowHoverBackground
        }

        return Color.clear
    }

    private var copiedAnimation: Animation? {
        accessibilityReduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.82)
    }
}

private struct PhrasePaletteEmptyStateView: View {
    let isEmptyLibrary: Bool
    let hasSearchText: Bool
    let language: AppLanguage

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        AppStrings.text(
            PhraseEmptyStateText.titleKey(
                isEmptyLibrary: isEmptyLibrary,
                hasSearchText: hasSearchText
            ),
            language: language
        )
    }
}

private struct StatusMenuGlassSurfaceGroup<Content: View>: View {
    let visibleContentSize: CGSize
    let submenuPresentation: StatusMenuSubmenuPresentation?
    private let content: () -> Content

    init(
        visibleContentSize: CGSize,
        submenuPresentation: StatusMenuSubmenuPresentation?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.visibleContentSize = visibleContentSize
        self.submenuPresentation = submenuPresentation
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            StatusMenuChromeSurface(
                visibleContentSize: visibleContentSize,
                submenuPresentation: submenuPresentation
            )
            .frame(
                width: StatusMenuLayout.maximumPanelWidth,
                height: visibleContentSize.height,
                alignment: .topLeading
            )
            .offset(x: StatusMenuLayout.chromePadding, y: StatusMenuLayout.chromeTopPadding)

            glassContent
                .frame(
                    width: StatusMenuLayout.maximumPanelWidth,
                    height: visibleContentSize.height,
                    alignment: .topLeading
                )
                .clipShape(
                    StatusMenuChromeShape(
                        visibleContentSize: visibleContentSize,
                        submenuPresentation: submenuPresentation
                    )
                )
                .offset(x: StatusMenuLayout.chromePadding, y: StatusMenuLayout.chromeTopPadding)
        }
        .frame(
            width: StatusMenuLayout.maximumPanelWindowWidth,
            height: StatusMenuLayout.panelWindowContentSize(for: visibleContentSize).height,
            alignment: .topLeading
        )
    }

    @ViewBuilder
    private var glassContent: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 0) {
                content()
            }
        } else {
            content()
        }
    }
}

private struct StatusMenuChromeSurface: View {
    let visibleContentSize: CGSize
    let submenuPresentation: StatusMenuSubmenuPresentation?

    var body: some View {
        let chromeShape = StatusMenuChromeShape(
            visibleContentSize: visibleContentSize,
            submenuPresentation: submenuPresentation
        )

        if #available(macOS 26.0, *) {
            chromeShape
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.18))
                .glassEffect(.regular, in: chromeShape)
                .overlay {
                    chromeShape.stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                }
                .shadow(
                    color: .black.opacity(0.08),
                    radius: StatusMenuLayout.chromeShadowRadius,
                    x: 0,
                    y: StatusMenuLayout.chromeShadowYOffset
                )
        } else {
            chromeShape
                .fill(.regularMaterial)
                .overlay {
                    chromeShape.stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
                .shadow(
                    color: .black.opacity(0.08),
                    radius: StatusMenuLayout.chromeShadowRadius,
                    x: 0,
                    y: StatusMenuLayout.chromeShadowYOffset
                )
        }
    }
}

private struct StatusMenuChromeShape: Shape {
    let visibleContentSize: CGSize
    let submenuPresentation: StatusMenuSubmenuPresentation?

    func path(in rect: CGRect) -> Path {
        let radius = StatusMenuLayout.surfaceCornerRadius
        let mainRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: StatusMenuLayout.width,
            height: visibleContentSize.height
        )

        guard let submenuPresentation else {
            return roundedRectPath(in: mainRect, radius: radius)
        }

        let submenuHeight = min(submenuPresentation.height, visibleContentSize.height)
        let submenuTopOffset = max(
            0,
            min(visibleContentSize.height - submenuHeight, submenuPresentation.topOffset)
        )
        let submenuRect = CGRect(
            x: rect.minX + StatusMenuLayout.width,
            y: rect.minY + submenuTopOffset,
            width: StatusMenuLayout.submenuWidth,
            height: submenuHeight
        )

        return unifiedChromePath(mainRect: mainRect, submenuRect: submenuRect, radius: radius)
    }

    private func roundedRectPath(in rect: CGRect, radius: CGFloat) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: radius, height: radius),
            style: .continuous
        )
        return path
    }

    private func unifiedChromePath(mainRect: CGRect, submenuRect: CGRect, radius: CGFloat) -> Path {
        let minX = mainRect.minX
        let joinX = mainRect.maxX
        let maxX = submenuRect.maxX
        let minY = mainRect.minY
        let maxY = mainRect.maxY
        let submenuMinY = submenuRect.minY
        let submenuMaxY = submenuRect.maxY
        let cornerRadius = min(radius, mainRect.width / 2, mainRect.height / 2, submenuRect.width / 2, submenuRect.height / 2)

        if submenuMinY <= minY, submenuMaxY >= maxY {
            return roundedRectPath(
                in: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
                radius: cornerRadius
            )
        }

        var path = Path()
        if submenuMinY <= minY {
            path.move(to: CGPoint(x: minX + cornerRadius, y: minY))
            path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
            path.addArc(
                tangent1End: CGPoint(x: maxX, y: minY),
                tangent2End: CGPoint(x: maxX, y: minY + cornerRadius),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: maxX, y: submenuMaxY - cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: maxX, y: submenuMaxY),
                tangent2End: CGPoint(x: maxX - cornerRadius, y: submenuMaxY),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: joinX, y: submenuMaxY))
        } else {
            path.move(to: CGPoint(x: minX + cornerRadius, y: minY))
            path.addLine(to: CGPoint(x: joinX - cornerRadius, y: minY))
            path.addArc(
                tangent1End: CGPoint(x: joinX, y: minY),
                tangent2End: CGPoint(x: joinX, y: minY + cornerRadius),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: joinX, y: submenuMinY))
            path.addLine(to: CGPoint(x: maxX - cornerRadius, y: submenuMinY))
            path.addArc(
                tangent1End: CGPoint(x: maxX, y: submenuMinY),
                tangent2End: CGPoint(x: maxX, y: submenuMinY + cornerRadius),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: maxX, y: submenuMaxY - cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: maxX, y: submenuMaxY),
                tangent2End: CGPoint(x: maxX - cornerRadius, y: submenuMaxY),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: joinX, y: submenuMaxY))
        }

        if submenuMaxY < maxY {
            path.addLine(to: CGPoint(x: joinX, y: maxY - cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: joinX, y: maxY),
                tangent2End: CGPoint(x: joinX - cornerRadius, y: maxY),
                radius: cornerRadius
            )
        } else {
            path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
            path.addArc(
                tangent1End: CGPoint(x: minX, y: maxY),
                tangent2End: CGPoint(x: minX, y: maxY - cornerRadius),
                radius: cornerRadius
            )
            path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
            path.addArc(
                tangent1End: CGPoint(x: minX, y: minY),
                tangent2End: CGPoint(x: minX + cornerRadius, y: minY),
                radius: cornerRadius
            )
            path.closeSubpath()
            return path
        }

        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addArc(
            tangent1End: CGPoint(x: minX, y: maxY),
            tangent2End: CGPoint(x: minX, y: maxY - cornerRadius),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: minX, y: minY),
            tangent2End: CGPoint(x: minX + cornerRadius, y: minY),
            radius: cornerRadius
        )
        path.closeSubpath()
        return path
    }
}

struct PhrasePaletteSubmenuView: View {
    let presentation: StatusMenuSubmenuPresentation
    let onHoverChange: (Bool) -> Void

    init(
        presentation: StatusMenuSubmenuPresentation,
        onHoverChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.presentation = presentation
        self.onHoverChange = onHoverChange
    }

    private var bodyHeight: CGFloat {
        presentation.bodyHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(presentation.shortcut)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(height: StatusMenuLayout.submenuShortcutHeight, alignment: .leading)
                .accessibilityIdentifier("lazyquips.palette.submenu.shortcut")

            ScrollView {
                Text(presentation.body)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: StatusMenuLayout.submenuTextWidth, alignment: .leading)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("lazyquips.palette.submenu.body")
            }
            .lazyQuipsScrollIndicatorsHidden()
            .frame(height: bodyHeight)
            .padding(.top, StatusMenuLayout.submenuBodyTopPadding)
        }
        .padding(.leading, StatusMenuLayout.submenuLeadingPadding)
        .padding(.trailing, StatusMenuLayout.submenuTrailingPadding)
        .padding(.vertical, StatusMenuLayout.submenuVerticalPadding)
        .frame(width: StatusMenuLayout.submenuWidth, height: presentation.height, alignment: .topLeading)
        .onHover(perform: onHoverChange)
        .accessibilityIdentifier("lazyquips.palette.submenu")
    }
}
