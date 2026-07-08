import AppKit
import SwiftData
import SwiftUI

enum PhraseLibraryLayout {
    static let windowWidth: CGFloat = 800
    static let windowHeight: CGFloat = 600
    static let toolbarHorizontalPadding: CGFloat = 20
    static let toolbarControlSpacing: CGFloat = 20
    static let searchFieldWidth: CGFloat = 626
    static let toolbarControlHeight: CGFloat = 32
    static let searchFieldHeight: CGFloat = toolbarControlHeight
    static let addButtonWidth: CGFloat = 58
    static let settingsButtonWidth: CGFloat = 36
    static let rowHeight: CGFloat = 50
    static let listTopPadding: CGFloat = 20
    static let listBottomPadding: CGFloat = 20
    static let rowTextLeadingPadding: CGFloat = 20
    static let rowContentTrailingPadding: CGFloat = rowTextLeadingPadding

    static var rowCopiedFeedbackTrailingPadding: CGFloat {
        rowContentTrailingPadding + LazyQuipsVisualStyle.copiedBadgeTrailingPadding
    }

    static func rowBodyTrailingPadding(isCopied: Bool) -> CGFloat {
        rowContentTrailingPadding + (isCopied ? LazyQuipsVisualStyle.copiedBadgeReservedWidth : 0)
    }

    static var toolbarSearchX: CGFloat {
        toolbarHorizontalPadding
    }

    static var toolbarAddX: CGFloat {
        toolbarSearchX + searchFieldWidth + toolbarControlSpacing
    }

    static var toolbarSettingsX: CGFloat {
        toolbarAddX + addButtonWidth + toolbarControlSpacing
    }

    static var toolbarWidth: CGFloat {
        toolbarSettingsX + settingsButtonWidth + toolbarHorizontalPadding
    }
}

enum PhraseEditorLayout {
    static let cardWidth: CGFloat = 440
    static let minimumCardHeight: CGFloat = 327
    static let verticalMargin: CGFloat = 40
    static let cardCornerRadius: CGFloat = 30
    static let contentPadding: CGFloat = 20
    static let titleFontSize: CGFloat = 16
    static let titleLineHeight: CGFloat = 20
    static let modalTextFontSize: CGFloat = 14
    static let modalTextLineHeight: CGFloat = 18
    static let sameGroupSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 20
    static let relatedInlineSpacing: CGFloat = 8
    static let titleBottomPadding: CGFloat = sectionSpacing
    static let labelFontSize: CGFloat = modalTextFontSize
    static let labelLineHeight: CGFloat = modalTextLineHeight
    static let labelSpacing: CGFloat = 8
    static let fieldFontSize: CGFloat = modalTextFontSize
    static let shortcutFieldHeight: CGFloat = 20
    static let shortcutBottomPadding: CGFloat = sectionSpacing
    static let textFieldBottomPadding: CGFloat = 4
    static let bodyFieldMinimumHeight: CGFloat = 64
    static let bodyFieldVerticalPadding: CGFloat = 2
    static let phraseFieldBottomPadding: CGFloat = 0
    static let errorFontSize: CGFloat = modalTextFontSize
    static let errorHeight: CGFloat = 20
    static let errorTopPadding: CGFloat = sameGroupSpacing
    static let fieldSeparatorHeight: CGFloat = 1
    static let footerButtonSpacing: CGFloat = 20
    static let footerButtonFontSize: CGFloat = modalTextFontSize
    static let footerButtonHorizontalPadding: CGFloat = 20
    static let footerButtonVerticalPadding: CGFloat = 6
    static let footerButtonCornerRadius: CGFloat = 7
    static let footerTopPadding: CGFloat = sectionSpacing
    static let overlayDimmingOpacity: Double = 0.2

    static var cardHeight: CGFloat {
        minimumCardHeight
    }

    static var maximumCardHeight: CGFloat {
        maximumCardHeight(forContainerHeight: PhraseLibraryLayout.windowHeight)
    }

    static func maximumCardHeight(forContainerHeight containerHeight: CGFloat) -> CGFloat {
        max(minimumCardHeight, containerHeight - verticalMargin * 2)
    }

    static var contentWidth: CGFloat {
        cardWidth - contentPadding * 2
    }

    static var cardX: CGFloat {
        (PhraseLibraryLayout.windowWidth - cardWidth) / 2
    }

    static var cardY: CGFloat {
        cardY(forHeight: minimumCardHeight)
    }

    static func cardY(forHeight height: CGFloat) -> CGFloat {
        (PhraseLibraryLayout.windowHeight - height) / 2
    }

    static var contentX: CGFloat {
        cardX + contentPadding
    }

    static var titleY: CGFloat {
        cardY + contentPadding
    }

    static var fieldSeparatorWidth: CGFloat {
        contentWidth
    }

    static var footerButtonHeight: CGFloat {
        modalTextLineHeight + footerButtonVerticalPadding * 2
    }

    static var fixedHeightExcludingBodyField: CGFloat {
        contentPadding * 2
            + titleLineHeight
            + titleBottomPadding
            + labelLineHeight
            + labelSpacing
            + shortcutFieldHeight
            + textFieldBottomPadding
            + fieldSeparatorHeight
            + shortcutBottomPadding
            + labelLineHeight
            + labelSpacing
            + phraseFieldBottomPadding
            + errorTopPadding
            + errorHeight
            + footerTopPadding
            + footerButtonHeight
    }

    static var bodyFieldMaximumHeight: CGFloat {
        bodyFieldMaximumHeight(forContainerHeight: PhraseLibraryLayout.windowHeight)
    }

    static func bodyFieldMaximumHeight(forContainerHeight containerHeight: CGFloat) -> CGFloat {
        max(
            bodyFieldMinimumHeight,
            maximumCardHeight(forContainerHeight: containerHeight) - fixedHeightExcludingBodyField
        )
    }

    static func measuredBodyHeight(for text: String) -> CGFloat {
        let measuredText = text.isEmpty ? " " : text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fieldFontSize),
            .paragraphStyle: paragraphStyle
        ]
        let bounds = (measuredText as NSString).boundingRect(
            with: CGSize(
                width: fieldSeparatorWidth,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )

        return ceil(bounds.height) + bodyFieldVerticalPadding
    }

    static func bodyFieldHeight(
        for text: String,
        containerHeight: CGFloat = PhraseLibraryLayout.windowHeight
    ) -> CGFloat {
        min(
            bodyFieldMaximumHeight(forContainerHeight: containerHeight),
            max(bodyFieldMinimumHeight, measuredBodyHeight(for: text))
        )
    }

    static func cardHeight(
        for body: String,
        containerHeight: CGFloat = PhraseLibraryLayout.windowHeight
    ) -> CGFloat {
        min(
            maximumCardHeight(forContainerHeight: containerHeight),
            max(
                minimumCardHeight,
                fixedHeightExcludingBodyField
                    + bodyFieldHeight(for: body, containerHeight: containerHeight)
            )
        )
    }
}

private struct PhraseEditorFooterButtonStyle: ButtonStyle {
    enum Prominence {
        case standard
        case primary
    }

    let prominence: Prominence

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: PhraseEditorLayout.footerButtonFontSize))
            .lineLimit(1)
            .frame(height: PhraseEditorLayout.modalTextLineHeight)
            .padding(.horizontal, PhraseEditorLayout.footerButtonHorizontalPadding)
            .padding(.vertical, PhraseEditorLayout.footerButtonVerticalPadding)
            .foregroundStyle(foregroundStyle)
            .background(
                backgroundStyle,
                in: RoundedRectangle(cornerRadius: PhraseEditorLayout.footerButtonCornerRadius)
            )
            .overlay(standardStroke)
            .opacity(configuration.isPressed ? 0.86 : 1)
    }

    private var foregroundStyle: Color {
        switch prominence {
        case .standard:
            return Color.primary
        case .primary:
            return Color.white
        }
    }

    private var backgroundStyle: Color {
        switch prominence {
        case .standard:
            return Color(nsColor: .controlColor)
        case .primary:
            return LazyQuipsVisualStyle.carbonCopyPurple
        }
    }

    @ViewBuilder
    private var standardStroke: some View {
        if prominence == .standard {
            RoundedRectangle(cornerRadius: PhraseEditorLayout.footerButtonCornerRadius)
                .stroke(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5)
        }
    }
}

enum PhraseIndexLayout {
    static let itemWidth: CGFloat = 19
    static let itemHeight: CGFloat = 14
    static let hitWidth: CGFloat = 24
    static let hitHeight: CGFloat = itemHeight
    static let verticalSpacing: CGFloat = 1
    static let itemFontSize: CGFloat = 12
    static let libraryTrailingSpacing: CGFloat = 13

    static var libraryReservedTrailingWidth: CGFloat {
        hitWidth + libraryTrailingSpacing
    }

    static func stackHeight(forItemCount itemCount: Int) -> CGFloat {
        guard itemCount > 0 else {
            return 0
        }

        return CGFloat(itemCount) * hitHeight
            + CGFloat(itemCount - 1) * verticalSpacing
    }
}

struct PhraseLibraryView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var state: PhraseLibraryWindowState
    @ObservedObject private var appearanceStore: AppAppearanceStore
    @ObservedObject private var languageStore: AppLanguageStore
    @ObservedObject private var hotKeyStatusStore: HotKeyRegistrationStatusStore
    @Query private var phrases: [Phrase]
    @Query private var usageStats: [PhraseUsageStats]

    @State private var searchText = ""
    @State private var selectedRowID: PhraseLibraryRowID?
    @State private var copiedRowID: PhraseLibraryRowID?
    @State private var actionErrorKey: AppStringKey?
    @State private var copyFeedbackTask: Task<Void, Never>?
    @State private var copyFeedbackToken = UUID()
    @State private var snapshotCache = PhraseLibrarySnapshotCache()
    @State private var searchIndexPrewarmTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    init(
        state: PhraseLibraryWindowState,
        appearanceStore: AppAppearanceStore = .shared,
        languageStore: AppLanguageStore = .shared,
        hotKeyStatusStore: HotKeyRegistrationStatusStore
    ) {
        self.state = state
        self.appearanceStore = appearanceStore
        self.languageStore = languageStore
        self.hotKeyStatusStore = hotKeyStatusStore
    }

    private var language: AppLanguage {
        languageStore.language
    }

    private var isModalOverlayPresented: Bool {
        state.isSettingsPresented || state.editorMode != nil
    }

    var body: some View {
        let snapshot = currentSnapshot()
        let searchIndexPrewarmSignature = phrases.map(PhraseLibrarySearchIndexPrewarmSignature.init)

        ZStack {
            VStack(spacing: 0) {
                toolbar(snapshot: snapshot)

                PhraseListView(
                    sections: snapshot.sections,
                    indexTitles: snapshot.indexTitles,
                    isEmptyLibrary: phrases.isEmpty,
                    hasSearchText: snapshot.hasSearchText,
                    selectedRowID: selectedRowID,
                    copiedRowID: copiedRowID,
                    language: language,
                    onCopy: copyPhrase,
                    onToggleStar: toggleStar,
                    onEdit: state.openEdit,
                    onDelete: deletePhrase,
                    onAdd: state.openAdd
                )
                .padding(.top, PhraseLibraryLayout.listTopPadding)
                .padding(.bottom, PhraseLibraryLayout.listBottomPadding)
            }
            .disabled(isModalOverlayPresented)
            .accessibilityHidden(isModalOverlayPresented)

            if let actionErrorKey {
                Text(AppStrings.text(actionErrorKey, language: language))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red, in: Capsule())
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.opacity)
                    .accessibilityHidden(isModalOverlayPresented)
            }

            settingsOverlay
            editorOverlay(snapshot: snapshot)
        }
        .frame(minWidth: 800, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(appearanceStore.appearance.preferredColorScheme)
        .onAppear {
            refreshSearchSelection(resetToFirst: false, in: snapshot)
            focusSearchField(for: state.searchFocusRequest)
            scheduleSearchIndexPrewarm(for: phrases)
        }
        .onChange(of: state.searchFocusRequest) { _, request in
            focusSearchField(for: request)
        }
        .onChange(of: searchIndexPrewarmSignature) { _, _ in
            scheduleSearchIndexPrewarm(for: phrases)
        }
        .onChange(of: searchText) {
            refreshSearchSelection(resetToFirst: true, in: snapshot)
        }
        .onChange(of: snapshot.selectableRowIDs) {
            refreshSearchSelection(resetToFirst: false, in: snapshot)
        }
        .onChange(of: snapshot.phraseIDs) { _, phraseIDs in
            guard case .edit(let phraseID) = state.editorMode,
                  !phraseIDs.contains(phraseID)
            else {
                return
            }

            state.dismissEditor()
        }
        .onDisappear {
            copyFeedbackTask?.cancel()
            searchIndexPrewarmTask?.cancel()
            searchIndexPrewarmTask = nil
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

    private func currentSnapshot() -> PhraseLibrarySnapshot {
        snapshotCache.snapshot(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats
        )
    }

    private func toolbar(snapshot: PhraseLibrarySnapshot) -> some View {
        LazyQuipsToolbarGlassGroup(spacing: PhraseLibraryLayout.toolbarControlSpacing) {
            HStack(spacing: PhraseLibraryLayout.toolbarControlSpacing) {
                PhraseSearchField(
                    text: $searchText,
                    placeholder: AppStrings.text(.search, language: language),
                    isFocused: $isSearchFocused,
                    onSubmit: { copySelectedPhrase(in: snapshot) }
                )
                    .frame(
                        width: PhraseLibraryLayout.searchFieldWidth,
                        height: PhraseLibraryLayout.searchFieldHeight
                    )
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded {
                        isSearchFocused = true
                    })

                Button {
                    state.openAdd()
                } label: {
                    HStack(spacing: 4) {
                        Text(AppStrings.text(.add, language: language))
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(
                    LazyQuipsToolbarButtonStyle(
                        width: PhraseLibraryLayout.addButtonWidth,
                        height: PhraseLibraryLayout.toolbarControlHeight,
                        usesLiquidGlass: true
                    )
                )
                .accessibilityIdentifier("lazyquips.library.addButton")
                .help(AppStrings.text(.add, language: language))

                Button(action: state.openSettings) {
                    Image(systemName: "gearshape")
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(
                    LazyQuipsToolbarButtonStyle(
                        width: PhraseLibraryLayout.settingsButtonWidth,
                        height: PhraseLibraryLayout.toolbarControlHeight,
                        tone: .utility,
                        usesLiquidGlass: true
                    )
                )
                .accessibilityIdentifier("lazyquips.library.settingsButton")
                .help(AppStrings.text(.settings, language: language))
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, PhraseLibraryLayout.toolbarHorizontalPadding)
    }

    private func focusSearchField(for request: UUID) {
        DispatchQueue.main.async {
            guard state.searchFocusRequest == request, !isModalOverlayPresented else {
                return
            }

            isSearchFocused = true
        }
    }

    @ViewBuilder
    private func editorOverlay(snapshot: PhraseLibrarySnapshot) -> some View {
        if let presentation = PhraseEditorPresentation.make(
            for: state.editorMode,
            phraseByID: snapshot.phraseByID,
            language: language
        ) {
            PhraseEditorOverlay(
                languageStore: languageStore,
                title: presentation.title,
                initialShortcut: presentation.initialShortcut,
                initialBody: presentation.initialBody,
                onCancel: state.dismissEditor
            ) { shortcut, body in
                let repository = PhraseRepository(context: modelContext)
                switch presentation.kind {
                case .add:
                    try repository.add(
                        shortcut: shortcut,
                        body: body
                    )
                case .edit(let phraseID):
                    guard let phrase = currentSnapshot().phraseByID[phraseID] else {
                        return
                    }

                    try repository.edit(
                        phrase,
                        shortcut: shortcut,
                        body: body
                    )
                }

                actionErrorKey = nil
                state.dismissEditor()
            }
            .id(presentation.id)
            .zIndex(3)
        }
    }

    @ViewBuilder
    private var settingsOverlay: some View {
        if state.isSettingsPresented {
            SettingsOverlayView(
                appearanceStore: appearanceStore,
                languageStore: languageStore,
                hotKeyStatusStore: hotKeyStatusStore,
                onDismiss: state.dismissSettings
            )
            .transition(.opacity)
            .zIndex(2)
        }
    }

    private func copyPhrase(_ row: PhraseLibraryRow) {
        let result = PhraseCopyController(
            repository: PhraseRepository(context: modelContext)
        )
        .copy(row.phrase)

        guard result.didCopy else {
            return
        }

        actionErrorKey = nil
        showCopiedFeedback(for: row.id)
    }

    private func copySelectedPhrase(in snapshot: PhraseLibrarySnapshot) {
        LazyQuipsPerformanceSignpost.interval("Selection.Submit") {
            guard !isModalOverlayPresented,
                  let row = PhraseLibrarySelection.selectedRowForSubmit(
                    currentSelection: selectedRowID,
                    selectableRows: snapshot.selectableRows,
                    selectableRowByID: snapshot.selectableRowByID
                  )
            else {
                return
            }

            copyPhrase(row)
        }
    }

    private func refreshSearchSelection(
        resetToFirst: Bool,
        in snapshot: PhraseLibrarySnapshot
    ) {
        LazyQuipsPerformanceSignpost.interval("Selection.Update") {
            selectedRowID = PhraseLibrarySelection.selectionAfterRowsChange(
                currentSelection: resetToFirst ? nil : selectedRowID,
                selectableRows: snapshot.selectableRows,
                selectableRowByID: snapshot.selectableRowByID
            )
        }
    }

    private func toggleStar(_ phrase: Phrase) {
        do {
            try PhraseRepository(context: modelContext).setStarred(
                phrase,
                isStarred: !phrase.isStarred
            )
            actionErrorKey = nil
        } catch {
            actionErrorKey = .updateFailed
        }
    }

    private func deletePhrase(_ phrase: Phrase) {
        let phraseID = phrase.id

        do {
            try PhraseRepository(context: modelContext).delete(phrase)
            if state.editorMode == .edit(phraseID) {
                state.dismissEditor()
            }
            if copiedRowID?.phraseID == phraseID {
                copiedRowID = nil
            }
            if selectedRowID?.phraseID == phraseID {
                selectedRowID = nil
            }
            actionErrorKey = nil
        } catch {
            actionErrorKey = .deleteFailed
        }
    }

    private func showCopiedFeedback(for rowID: PhraseLibraryRowID) {
        copyFeedbackTask?.cancel()
        let token = UUID()
        copyFeedbackToken = token

        setFeedbackRowID(rowID)

        copyFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: LazyQuipsVisualStyle.phraseLibraryCopiedFeedbackDurationNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard copyFeedbackToken == token, copiedRowID == rowID else {
                    return
                }

                setFeedbackRowID(nil)
            }
        }
    }

    private func setFeedbackRowID(_ rowID: PhraseLibraryRowID?) {
        if let rowID {
            selectedRowID = rowID
        } else {
            refreshSearchSelection(resetToFirst: false, in: currentSnapshot())
        }

        setCopiedRowID(rowID)
    }

    private func setCopiedRowID(_ rowID: PhraseLibraryRowID?) {
        if accessibilityReduceMotion {
            copiedRowID = rowID
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            copiedRowID = rowID
        }
    }
}

struct PhraseLibraryRowID: Hashable {
    let sectionID: PhraseGroupID
    let phraseID: UUID

    var accessibilityIdentifier: String {
        "lazyquips.library.row.\(sectionIdentifier).\(phraseID.uuidString)"
    }

    private var sectionIdentifier: String {
        switch sectionID {
        case .all:
            return "all"
        case .starred:
            return "starred"
        case .digits:
            return "digits"
        case .letter(let character):
            return "letter-\(String(character).lowercased())"
        case .symbols:
            return "symbols"
        }
    }
}

struct PhraseLibraryRow: Identifiable {
    let id: PhraseLibraryRowID
    let phrase: Phrase
    let previewText: String
}

struct PhraseLibrarySection: Identifiable {
    let id: PhraseGroupID
    let title: String
    let showsTitle: Bool
    let rows: [PhraseLibraryRow]
}

enum PhraseLibraryDisplayData {
    static func snapshot(
        for searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats],
        sortedSearchIndexes: [PhraseSearchIndex]? = nil,
        previewText: (Phrase) -> String = { PhraseBodyPreview.text(for: $0.body) }
    ) -> PhraseLibrarySnapshot {
        let hasSearchText = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let displayedPhrases = displayedPhrases(
            for: searchText,
            phrases: phrases,
            usageStats: usageStats,
            sortedSearchIndexes: sortedSearchIndexes
        )
        let phraseByID = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, $0) })
        let groupSections = sections(
            displayedPhrases: displayedPhrases,
            hasSearchText: hasSearchText
        )
        let sections = librarySections(in: groupSections, previewText: previewText)
        let selectableRows = sections.flatMap(\.rows)
        let selectableRowByID = Dictionary(uniqueKeysWithValues: selectableRows.map { ($0.id, $0) })

        return PhraseLibrarySnapshot(
            hasSearchText: hasSearchText,
            phraseIDs: Set(phraseByID.keys),
            phraseByID: phraseByID,
            displayedPhrases: displayedPhrases,
            sections: sections,
            selectableRows: selectableRows,
            selectableRowIDs: selectableRows.map(\.id),
            selectableRowByID: selectableRowByID,
            indexTitles: hasSearchText ? [] : indexTitles(for: sections)
        )
    }

    static func rows(
        in sections: [PhraseGroupSection],
        previewText: (Phrase) -> String = { PhraseBodyPreview.text(for: $0.body) }
    ) -> [PhraseLibraryRow] {
        sections.flatMap { section in
            rows(in: section, previewText: previewText)
        }
    }

    private static func librarySections(
        in sections: [PhraseGroupSection],
        previewText: (Phrase) -> String
    ) -> [PhraseLibrarySection] {
        sections.map { section in
            PhraseLibrarySection(
                id: section.id,
                title: section.title,
                showsTitle: section.showsTitle,
                rows: rows(in: section, previewText: previewText)
            )
        }
    }

    private static func rows(
        in section: PhraseGroupSection,
        previewText: (Phrase) -> String
    ) -> [PhraseLibraryRow] {
        section.phrases.map { phrase in
            PhraseLibraryRow(
                id: PhraseLibraryRowID(sectionID: section.id, phraseID: phrase.id),
                phrase: phrase,
                previewText: previewText(phrase)
            )
        }
    }

    private static func indexTitles(for sections: [PhraseLibrarySection], includeStarred: Bool = true) -> [String] {
        sections.compactMap { section in
            if section.id == .all {
                return nil
            }

            if section.id == .starred && !includeStarred {
                return nil
            }

            return section.id.indexTitle
        }
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

    private static func sections(
        displayedPhrases: [Phrase],
        hasSearchText: Bool
    ) -> [PhraseGroupSection] {
        guard hasSearchText else {
            return PhraseGrouping.sections(for: displayedPhrases, preservingInputOrder: true)
        }

        guard !displayedPhrases.isEmpty else {
            return []
        }

        return [
            PhraseGroupSection(
                id: .all,
                title: PhraseGroupID.all.title,
                showsTitle: false,
                phrases: displayedPhrases
            )
        ]
    }
}

struct PhraseLibrarySnapshot {
    let hasSearchText: Bool
    let phraseIDs: Set<UUID>
    let phraseByID: [UUID: Phrase]
    let displayedPhrases: [Phrase]
    let sections: [PhraseLibrarySection]
    let selectableRows: [PhraseLibraryRow]
    let selectableRowIDs: [PhraseLibraryRowID]
    let selectableRowByID: [PhraseLibraryRowID: PhraseLibraryRow]
    let indexTitles: [String]
}

final class PhraseLibrarySnapshotCache {
    typealias PreviewTextBuilder = (Phrase) -> String
    typealias SnapshotBuilder = (String, [Phrase], [PhraseUsageStats], [PhraseSearchIndex]?, PreviewTextBuilder) -> PhraseLibrarySnapshot

    private let makeSnapshot: SnapshotBuilder
    private let makePreviewText: PreviewTextBuilder
    private let searchIndexCache: PhraseSearchIndexCache
    private var cachedKey: PhraseLibrarySnapshotCacheKey?
    private var cachedSnapshot: PhraseLibrarySnapshot?
    private var cachedPreviewTextBySignature: [PhraseLibraryPreviewSignature: String] = [:]

    init(
        makeSnapshot: @escaping SnapshotBuilder = { searchText, phrases, usageStats, sortedSearchIndexes, previewText in
            PhraseLibraryDisplayData.snapshot(
                for: searchText,
                phrases: phrases,
                usageStats: usageStats,
                sortedSearchIndexes: sortedSearchIndexes,
                previewText: previewText
            )
        },
        makeSearchIndex: @escaping PhraseSearchIndexCache.IndexBuilder = PhraseSearchIndex.init,
        makePreviewText: @escaping PreviewTextBuilder = { PhraseBodyPreview.text(for: $0.body) }
    ) {
        self.makeSnapshot = makeSnapshot
        self.makePreviewText = makePreviewText
        searchIndexCache = PhraseSearchIndexCache(makeIndex: makeSearchIndex)
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
    ) -> PhraseLibrarySnapshot {
        if cachedKey?.matches(
            searchText: searchText,
            phrases: phrases,
            usageStats: usageStats
        ) == true,
           let cachedSnapshot {
            return cachedSnapshot
        }

        return LazyQuipsPerformanceSignpost.interval("MainWindow.Snapshot") {
            let nextKey = PhraseLibrarySnapshotCacheKey(
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
                sortedSearchIndexes,
                previewText(for:)
            )
            trimPreviewTextCacheIfNeeded(keeping: phrases)
            cachedKey = nextKey
            cachedSnapshot = snapshot
            return snapshot
        }
    }

    private func previewText(for phrase: Phrase) -> String {
        let signature = PhraseLibraryPreviewSignature(phrase: phrase)
        if let cachedPreviewText = cachedPreviewTextBySignature[signature] {
            return cachedPreviewText
        }

        let previewText = makePreviewText(phrase)
        cachedPreviewTextBySignature[signature] = previewText
        return previewText
    }

    private func trimPreviewTextCacheIfNeeded(keeping phrases: [Phrase]) {
        guard cachedPreviewTextBySignature.count > phrases.count else {
            return
        }

        let activeSignatures = Set(phrases.map(PhraseLibraryPreviewSignature.init))
        cachedPreviewTextBySignature = cachedPreviewTextBySignature.filter { signature, _ in
            activeSignatures.contains(signature)
        }
    }
}

private struct PhraseLibrarySearchIndexPrewarmSignature: Equatable {
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

private struct PhraseLibraryPreviewSignature: Hashable {
    let phraseID: UUID
    let contentRevision: Int

    init(phrase: Phrase) {
        phraseID = phrase.id
        contentRevision = phrase.contentRevision
    }
}

private struct PhraseLibrarySnapshotCacheKey: Equatable {
    let searchText: String
    let usesUsageStats: Bool
    let phrases: [PhraseLibraryPhraseSignature]
    let usageStats: [PhraseLibraryUsageStatsSignature]

    init(
        searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) {
        self.searchText = searchText
        usesUsageStats = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.phrases = phrases.map(PhraseLibraryPhraseSignature.init)
        self.usageStats = usesUsageStats
            ? usageStats.map(PhraseLibraryUsageStatsSignature.init)
            : []
    }

    func matches(
        searchText: String,
        phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) -> Bool {
        guard self.searchText == searchText,
              self.phrases.count == phrases.count
        else {
            return false
        }

        for (signature, phrase) in zip(self.phrases, phrases) {
            guard signature.matches(phrase) else {
                return false
            }
        }

        guard usesUsageStats else {
            return true
        }

        guard self.usageStats.count == usageStats.count else {
            return false
        }

        for (signature, usageStats) in zip(self.usageStats, usageStats) {
            guard signature.matches(usageStats) else {
                return false
            }
        }

        return true
    }
}

private struct PhraseLibraryPhraseSignature: Equatable {
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

private struct PhraseLibraryUsageStatsSignature: Equatable {
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

enum PhraseLibrarySelection {
    static func selectionAfterRowsChange(
        currentSelection: PhraseLibraryRowID?,
        selectableRows: [PhraseLibraryRow],
        selectableRowByID: [PhraseLibraryRowID: PhraseLibraryRow]? = nil
    ) -> PhraseLibraryRowID? {
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

    static func selectedRowForSubmit(
        currentSelection: PhraseLibraryRowID?,
        selectableRows: [PhraseLibraryRow],
        selectableRowByID: [PhraseLibraryRowID: PhraseLibraryRow]? = nil
    ) -> PhraseLibraryRow? {
        guard let currentSelection else {
            return selectableRows.first
        }

        return selectableRowByID?[currentSelection]
            ?? selectableRows.first { $0.id == currentSelection }
            ?? selectableRows.first
    }
}

enum PhraseBodyPreview {
    static func text(for body: String) -> String {
        body
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

struct PhraseEditorPresentation: Equatable, Identifiable {
    enum Kind: Equatable {
        case add
        case edit(UUID)
    }

    let kind: Kind
    let title: String
    let initialShortcut: String
    let initialBody: String

    var id: String {
        switch kind {
        case .add:
            return "add"
        case .edit(let phraseID):
            return "edit-\(phraseID.uuidString)"
        }
    }

    static func make(
        for editorMode: PhraseLibraryWindowState.EditorMode?,
        phraseByID: [UUID: Phrase],
        language: AppLanguage = .english
    ) -> PhraseEditorPresentation? {
        switch editorMode {
        case .add:
            return PhraseEditorPresentation(
                kind: .add,
                title: AppStrings.text(.add, language: language),
                initialShortcut: "",
                initialBody: ""
            )
        case .edit(let phraseID):
            guard let phrase = phraseByID[phraseID] else {
                return nil
            }

            return PhraseEditorPresentation(
                kind: .edit(phraseID),
                title: AppStrings.text(.edit, language: language),
                initialShortcut: phrase.shortcut,
                initialBody: phrase.body
            )
        case .none:
            return nil
        }
    }
}

enum PhraseContextMenuAction {
    case toggleStar
    case edit
    case delete
}

struct PhraseContextMenuItem: Identifiable, Equatable {
    let action: PhraseContextMenuAction
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let hasLeadingSeparator: Bool
    let accessibilityIdentifier: String

    var id: PhraseContextMenuAction {
        action
    }

    var buttonRole: ButtonRole? {
        isDestructive ? .destructive : nil
    }

    static func items(for phrase: Phrase, language: AppLanguage = .english) -> [PhraseContextMenuItem] {
        [
            PhraseContextMenuItem(
                action: .toggleStar,
                title: phrase.isStarred
                    ? AppStrings.text(.unstar, language: language)
                    : AppStrings.text(.star, language: language),
                systemImage: phrase.isStarred ? "star.slash" : "star",
                isDestructive: false,
                hasLeadingSeparator: false,
                accessibilityIdentifier: phrase.isStarred
                    ? "lazyquips.library.context.unstarButton"
                    : "lazyquips.library.context.starButton"
            ),
            PhraseContextMenuItem(
                action: .edit,
                title: AppStrings.text(.edit, language: language),
                systemImage: "pencil",
                isDestructive: false,
                hasLeadingSeparator: true,
                accessibilityIdentifier: "lazyquips.library.context.editButton"
            ),
            PhraseContextMenuItem(
                action: .delete,
                title: AppStrings.text(.delete, language: language),
                systemImage: "trash",
                isDestructive: true,
                hasLeadingSeparator: false,
                accessibilityIdentifier: "lazyquips.library.context.deleteButton"
            )
        ]
    }
}

private struct PhraseSearchField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .focused($isFocused)
                .accessibilityIdentifier("lazyquips.library.searchField")
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .lazyQuipsToolbarControlSurface(usesLiquidGlass: true)
    }
}

private struct PhraseListView: View {
    let sections: [PhraseLibrarySection]
    let indexTitles: [String]
    let isEmptyLibrary: Bool
    let hasSearchText: Bool
    let selectedRowID: PhraseLibraryRowID?
    let copiedRowID: PhraseLibraryRowID?
    let language: AppLanguage
    let onCopy: (PhraseLibraryRow) -> Void
    let onToggleStar: (Phrase) -> Void
    let onEdit: (Phrase) -> Void
    let onDelete: (Phrase) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if sections.isEmpty {
                PhraseEmptyStateView(
                    isEmptyLibrary: isEmptyLibrary,
                    hasSearchText: hasSearchText,
                    language: language,
                    onAdd: onAdd
                )
            } else {
                header

                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                                ForEach(sections, id: \.id) { section in
                                    PhraseSectionView(
                                        section: section,
                                        selectedRowID: selectedRowID,
                                        copiedRowID: copiedRowID,
                                        language: language,
                                        onCopy: onCopy,
                                        onToggleStar: onToggleStar,
                                        onEdit: onEdit,
                                        onDelete: onDelete
                                    )
                                    .id(section.id)
                                }
                            }
                        }
                        .lazyQuipsScrollIndicatorsHidden()
                        .padding(.trailing, PhraseIndexLayout.libraryReservedTrailingWidth)

                        PhraseIndexView(titles: indexTitles, language: language) { title in
                            guard let section = sections.first(where: { $0.id.indexTitle == title }) else {
                                return
                            }

                            withAnimation(.easeInOut(duration: 0.16)) {
                                proxy.scrollTo(section.id, anchor: .top)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text(AppStrings.text(.shortcut, language: language))
                .frame(width: PhraseShortcutPreview.columnWidth, alignment: .leading)

            Text(AppStrings.text(.phrase, language: language))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.leading, PhraseLibraryLayout.rowTextLeadingPadding)
        .padding(.trailing, PhraseIndexLayout.libraryReservedTrailingWidth)
    }
}

private struct NativeScrollIndicatorHider: NSViewRepresentable {
    private static let retryDelays: [DispatchTimeInterval] = [
        .milliseconds(0),
        .milliseconds(16),
        .milliseconds(80),
        .milliseconds(200),
        .milliseconds(500)
    ]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.scheduleConfigure(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.scheduleConfigure(from: nsView)
    }

    final class Coordinator {
        private weak var cachedScrollView: NSScrollView?
        private var isRetryScheduled = false

        func scheduleConfigure(from view: NSView) {
            if let cachedScrollView,
               cachedScrollView.window != nil,
               cachedScrollView.window === view.window {
                NativeScrollIndicatorHider.configureScrollIndicatorsHidden(cachedScrollView)
                isRetryScheduled = false
                return
            }

            cachedScrollView = nil
            if let scrollView = NativeScrollIndicatorHider.configure(from: view) {
                cachedScrollView = scrollView
                isRetryScheduled = false
                return
            }

            guard !isRetryScheduled else {
                return
            }

            isRetryScheduled = true
            for (index, delay) in NativeScrollIndicatorHider.retryDelays.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak view] in
                    guard let self else {
                        return
                    }

                    guard let view else {
                        self.isRetryScheduled = false
                        return
                    }

                    if let scrollView = NativeScrollIndicatorHider.configure(from: view) {
                        self.cachedScrollView = scrollView
                        self.isRetryScheduled = false
                        return
                    }

                    if index == NativeScrollIndicatorHider.retryDelays.count - 1 {
                        self.isRetryScheduled = false
                    }
                }
            }
        }
    }

    private static func configure(from view: NSView) -> NSScrollView? {
        if let scrollView = enclosingScrollView(from: view) {
            configureScrollIndicatorsHidden(scrollView)
            return scrollView
        }

        guard let scrollView = matchingDescendantScrollView(for: view) else {
            return nil
        }

        configureScrollIndicatorsHidden(scrollView)
        return scrollView
    }

    private static func configureScrollIndicatorsHidden(_ scrollView: NSScrollView) {
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScroller = nil
        scrollView.horizontalScroller = nil
    }

    private static func enclosingScrollView(from view: NSView) -> NSScrollView? {
        var candidate: NSView? = view

        while let current = candidate {
            if let scrollView = current as? NSScrollView {
                return scrollView
            }

            candidate = current.superview
        }

        return nil
    }

    private static func matchingDescendantScrollView(for view: NSView) -> NSScrollView? {
        guard let contentView = view.window?.contentView else {
            return nil
        }

        let markerFrame = view.convert(view.bounds, to: nil)
        guard let scrollView = descendantScrollViews(in: contentView).max(by: { lhs, rhs in
            matchScore(for: lhs, markerFrame: markerFrame) < matchScore(for: rhs, markerFrame: markerFrame)
        }) else {
            return nil
        }

        guard matchScore(for: scrollView, markerFrame: markerFrame) > 0 else {
            return nil
        }

        return scrollView
    }

    private static func descendantScrollViews(in view: NSView) -> [NSScrollView] {
        var scrollViews: [NSScrollView] = []

        for subview in view.subviews {
            if let scrollView = subview as? NSScrollView {
                scrollViews.append(scrollView)
            }

            scrollViews.append(contentsOf: descendantScrollViews(in: subview))
        }

        return scrollViews
    }

    private static func matchScore(for scrollView: NSScrollView, markerFrame: NSRect) -> CGFloat {
        let scrollFrame = scrollView.convert(scrollView.bounds, to: nil)
        let overlap = scrollFrame.intersection(markerFrame)
        if !overlap.isNull, !overlap.isEmpty {
            return overlap.width * overlap.height
        }

        let xDistance = scrollFrame.midX - markerFrame.midX
        let yDistance = scrollFrame.midY - markerFrame.midY
        return -sqrt((xDistance * xDistance) + (yDistance * yDistance))
    }
}

extension View {
    func lazyQuipsScrollIndicatorsHidden() -> some View {
        scrollIndicators(.hidden)
            .background(NativeScrollIndicatorHider())
    }
}

private struct PhraseSectionView: View {
    let section: PhraseLibrarySection
    let selectedRowID: PhraseLibraryRowID?
    let copiedRowID: PhraseLibraryRowID?
    let language: AppLanguage
    let onCopy: (PhraseLibraryRow) -> Void
    let onToggleStar: (Phrase) -> Void
    let onEdit: (Phrase) -> Void
    let onDelete: (Phrase) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.showsTitle {
                HStack(spacing: 4) {
                    if section.id == .starred {
                        Image(systemName: "star")
                            .font(.system(size: 13, weight: .bold))
                    } else {
                        Text(sectionTitle)
                    }
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(LazyQuipsVisualStyle.accentForeground(for: colorScheme))
                .frame(height: 27, alignment: .leading)
                .padding(.leading, PhraseLibraryLayout.rowTextLeadingPadding)
            }

            ForEach(section.rows) { row in
                PhraseRowView(
                    rowID: row.id,
                    phrase: row.phrase,
                    previewText: row.previewText,
                    isSelected: selectedRowID == row.id,
                    isCopied: copiedRowID == row.id,
                    language: language,
                    onCopy: { onCopy(row) },
                    onToggleStar: { onToggleStar(row.phrase) },
                    onEdit: { onEdit(row.phrase) },
                    onDelete: { onDelete(row.phrase) }
                )
            }
        }
        .padding(.bottom, 20)
    }

    private var sectionTitle: String {
        switch section.id {
        case .all:
            return section.title
        case .starred:
            return AppStrings.text(.star, language: language)
        case .digits, .letter(_), .symbols:
            return section.title
        }
    }
}

private struct PhraseRowView: View {
    let rowID: PhraseLibraryRowID
    let phrase: Phrase
    let previewText: String
    let isSelected: Bool
    let isCopied: Bool
    let language: AppLanguage
    let onCopy: () -> Void
    let onToggleStar: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .trailing) {
            if isSelected || isHovered {
                Rectangle()
                    .fill(background)
            }

            HStack(spacing: 0) {
                Text(phrase.shortcut)
                    .lineLimit(PhraseShortcutPreview.maximumLineCount)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(width: PhraseShortcutPreview.wrappingWidth, alignment: .leading)
                    .frame(width: PhraseShortcutPreview.columnWidth, alignment: .leading)

                Text(previewText)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .padding(.trailing, PhraseLibraryLayout.rowBodyTrailingPadding(isCopied: isCopied))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 14))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.leading, PhraseLibraryLayout.rowTextLeadingPadding)

            if isCopied {
                LazyQuipsCopiedBadge(language: language)
                    .padding(.trailing, PhraseLibraryLayout.rowCopiedFeedbackTrailingPadding)
            }
        }
        .frame(height: PhraseLibraryLayout.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            if isSelected {
                LazyQuipsRowBoundaryOverlay()
            } else {
                Rectangle()
                    .fill(LazyQuipsVisualStyle.rowDivider)
                    .frame(height: 0.5)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .animation(copiedAnimation, value: isCopied)
        .contentShape(Rectangle())
        .onTapGesture(perform: onCopy)
        .onHover { isHovered = $0 }
        .contextMenu {
            PhraseContextMenu(
                phrase: phrase,
                language: language,
                onToggleStar: onToggleStar,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
        .accessibilityIdentifier(rowID.accessibilityIdentifier)
    }

    private var background: Color {
        if isSelected {
            return LazyQuipsVisualStyle.rowSelectedBackground
        }

        return LazyQuipsVisualStyle.rowHoverBackground
    }

    private var copiedAnimation: Animation? {
        accessibilityReduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.82)
    }
}

private struct PhraseContextMenu: View {
    let phrase: Phrase
    let language: AppLanguage
    let onToggleStar: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ForEach(PhraseContextMenuItem.items(for: phrase, language: language)) { item in
            if item.hasLeadingSeparator {
                Divider()
            }

            Button(role: item.buttonRole) {
                perform(item.action)
            } label: {
                Label(item.title, systemImage: item.systemImage)
            }
            .accessibilityIdentifier(item.accessibilityIdentifier)
        }
    }

    private func perform(_ action: PhraseContextMenuAction) {
        switch action {
        case .toggleStar:
            onToggleStar()
        case .edit:
            onEdit()
        case .delete:
            onDelete()
        }
    }
}

struct PhraseIndexView: View {
    let titles: [String]
    let onSelect: ((String) -> Void)?
    let language: AppLanguage

    @Environment(\.colorScheme) private var colorScheme

    init(
        titles: [String],
        language: AppLanguage = .english,
        onSelect: ((String) -> Void)? = nil
    ) {
        self.titles = titles
        self.language = language
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: PhraseIndexLayout.verticalSpacing) {
            ForEach(titles, id: \.self) { title in
                if let onSelect {
                    Button {
                        onSelect(title)
                    } label: {
                        hitTargetLabel(title)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityTitle(for: title))
                    .help(accessibilityTitle(for: title))
                } else {
                    hitTargetLabel(title)
                        .accessibilityLabel(accessibilityTitle(for: title))
                        .help(accessibilityTitle(for: title))
                }
            }
        }
        .foregroundStyle(LazyQuipsVisualStyle.accentForeground(for: colorScheme))
    }

    @ViewBuilder
    private func hitTargetLabel(_ title: String) -> some View {
        itemLabel(title)
            .frame(width: PhraseIndexLayout.hitWidth, height: PhraseIndexLayout.hitHeight)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func itemLabel(_ title: String) -> some View {
        if title == PhraseGroupID.starred.title {
            Image(systemName: "star")
                .font(.system(size: PhraseIndexLayout.itemFontSize, weight: .regular))
                .frame(width: PhraseIndexLayout.itemWidth, height: PhraseIndexLayout.itemHeight)
        } else {
            Text(title)
                .font(.system(size: PhraseIndexLayout.itemFontSize, weight: .regular))
                .frame(width: PhraseIndexLayout.itemWidth, height: PhraseIndexLayout.itemHeight)
        }
    }

    private func accessibilityTitle(for title: String) -> String {
        if title == PhraseGroupID.starred.title {
            return AppStrings.text(.star, language: language)
        }

        return title
    }
}

private struct PhraseEmptyStateView: View {
    let isEmptyLibrary: Bool
    let hasSearchText: Bool
    let language: AppLanguage
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))

            if isEmptyLibrary {
                Button(AppStrings.text(.add, language: language)) {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("lazyquips.library.empty.addButton")
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 320)
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

private struct PlainShortcutTextField: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let focusRequest: Int
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> PlainShortcutNSTextField {
        let textField = PlainShortcutNSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        configure(textField)
        return textField
    }

    func updateNSView(_ textField: PlainShortcutNSTextField, context: Context) {
        context.coordinator.parent = self
        configure(textField)

        if (textField.currentEditor() as? NSTextView)?.hasMarkedText() != true,
           textField.stringValue != text {
            textField.stringValue = text
        }

        context.coordinator.requestFocusIfNeeded(
            on: textField,
            focusRequest: focusRequest
        )
    }

    private func configure(_ textField: NSTextField) {
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = font
        textField.textColor = .labelColor
        textField.isEditable = true
        textField.isSelectable = true
        textField.usesSingleLineMode = true
        textField.maximumNumberOfLines = 1
        textField.lineBreakMode = .byClipping
        textField.alignment = .left
        textField.cell?.font = font
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.cell?.lineBreakMode = .byClipping
        textField.cell?.allowsUndo = true
    }

    private final class PlainShortcutTextFieldCell: NSTextFieldCell {
        override init(textCell string: String) {
            super.init(textCell: string)
            configure()
        }

        required init(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }

        override func drawingRect(forBounds rect: NSRect) -> NSRect {
            textRect(for: rect, controlView: controlView)
        }

        override func edit(
            withFrame rect: NSRect,
            in controlView: NSView,
            editor textObj: NSText,
            delegate: Any?,
            event: NSEvent?
        ) {
            super.edit(
                withFrame: textRect(for: rect, controlView: controlView),
                in: controlView,
                editor: textObj,
                delegate: delegate,
                event: event
            )
        }

        override func select(
            withFrame rect: NSRect,
            in controlView: NSView,
            editor textObj: NSText,
            delegate: Any?,
            start selStart: Int,
            length selLength: Int
        ) {
            super.select(
                withFrame: textRect(for: rect, controlView: controlView),
                in: controlView,
                editor: textObj,
                delegate: delegate,
                start: selStart,
                length: selLength
            )
        }

        private func configure() {
            usesSingleLineMode = true
            wraps = false
            isScrollable = true
            lineBreakMode = .byClipping
        }

        private func textRect(for rect: NSRect, controlView: NSView?) -> NSRect {
            let textHeight = min(rect.height, lineHeight)
            let y = controlView?.isFlipped == false
                ? rect.minY
                : rect.maxY - textHeight

            return NSRect(
                x: rect.minX,
                y: y,
                width: rect.width,
                height: textHeight
            )
        }

        private var lineHeight: CGFloat {
            guard let font else {
                return cellSize.height
            }

            return ceil(font.ascender - font.descender + font.leading)
        }
    }

    final class PlainShortcutNSTextField: NSTextField {
        private var shouldFocusOnWindowMove = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            cell = PlainShortcutTextFieldCell(textCell: "")
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            cell = PlainShortcutTextFieldCell(textCell: "")
        }

        func requestFocus() {
            guard window != nil else {
                shouldFocusOnWindowMove = true
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let textField = self else {
                    return
                }

                textField.window?.makeFirstResponder(textField)
            }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            guard shouldFocusOnWindowMove, window != nil else {
                return
            }

            shouldFocusOnWindowMove = false
            requestFocus()
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PlainShortcutTextField
        private var lastFocusRequest = 0

        init(_ parent: PlainShortcutTextField) {
            self.parent = parent
        }

        func requestFocusIfNeeded(
            on textField: PlainShortcutNSTextField,
            focusRequest: Int
        ) {
            guard focusRequest > 0,
                  focusRequest != lastFocusRequest
            else {
                return
            }

            lastFocusRequest = focusRequest
            textField.requestFocus()
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField,
                  parent.text != textField.stringValue else {
                return
            }

            parent.text = textField.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard !textView.hasMarkedText() else {
                return false
            }

            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onCommit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            default:
                return false
            }
        }
    }
}

private struct PlainPhraseTextEditor: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = FocusingTextScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.contentInsets = NSEdgeInsetsZero

        let textView = NSTextView()
        textView.frame = NSRect(
            origin: .zero,
            size: NSSize(width: 1, height: 1)
        )
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.font = font
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = textContainerSize(for: scrollView)
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        textView.textContainer?.containerSize = textContainerSize(for: scrollView)
        textView.textContainer?.widthTracksTextView = true

        if textView.string != text {
            textView.string = text
        }

        textView.font = font
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        updateDocumentSize(textView, in: scrollView)
    }

    private func textContainerSize(for scrollView: NSScrollView) -> NSSize {
        NSSize(
            width: max(scrollView.contentSize.width, 1),
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func updateDocumentSize(_ textView: NSTextView, in scrollView: NSScrollView) {
        let contentSize = scrollView.contentSize
        let width = max(contentSize.width, 1)
        var usedHeight: CGFloat = 0

        if let textContainer = textView.textContainer,
           let layoutManager = textView.layoutManager {
            layoutManager.ensureLayout(for: textContainer)
            usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
        }

        textView.frame.size = NSSize(
            width: width,
            height: max(contentSize.height, usedHeight)
        )
    }

    private final class FocusingTextScrollView: NSScrollView {
        override func mouseDown(with event: NSEvent) {
            if let textView = documentView as? NSTextView,
               window?.firstResponder !== textView {
                window?.makeFirstResponder(textView)
            }

            super.mouseDown(with: event)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainPhraseTextEditor

        init(_ parent: PlainPhraseTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  parent.text != textView.string else {
                return
            }

            parent.text = textView.string
        }
    }
}

private struct PhraseEditorOverlay: View {
    @ObservedObject var languageStore: AppLanguageStore

    let title: String
    let onCancel: () -> Void
    let onSave: (String, String) throws -> Void

    @State private var shortcut: String
    @State private var phraseBody: String
    @State private var errorKey: AppStringKey?
    @State private var shortcutFocusRequest = 0

    init(
        languageStore: AppLanguageStore,
        title: String,
        initialShortcut: String,
        initialBody: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String, String) throws -> Void
    ) {
        self.languageStore = languageStore
        self.title = title
        self.onCancel = onCancel
        self.onSave = onSave
        _shortcut = State(initialValue: initialShortcut)
        _phraseBody = State(initialValue: initialBody)
    }

    private var language: AppLanguage {
        languageStore.language
    }

    var body: some View {
        GeometryReader { proxy in
            overlayContent(containerHeight: proxy.size.height)
        }
        .transition(.opacity)
        .onAppear {
            requestShortcutFocus()
        }
    }

    private func overlayContent(containerHeight: CGFloat) -> some View {
        let bodyFieldHeight = PhraseEditorLayout.bodyFieldHeight(
            for: phraseBody,
            containerHeight: containerHeight
        )
        let cardHeight = PhraseEditorLayout.cardHeight(
            for: phraseBody,
            containerHeight: containerHeight
        )
        let cancelTitle = AppStrings.text(.cancel, language: language)
        let okTitle = AppStrings.text(.ok, language: language)

        return ZStack {
            DimmingScrim(opacity: PhraseEditorLayout.overlayDimmingOpacity)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: PhraseEditorLayout.titleFontSize, weight: .bold))
                    .lineLimit(1)
                    .frame(height: PhraseEditorLayout.titleLineHeight, alignment: .leading)
                    .padding(.bottom, PhraseEditorLayout.titleBottomPadding)

                VStack(alignment: .leading, spacing: PhraseEditorLayout.labelSpacing) {
                    Text(AppStrings.text(.shortcut, language: language))
                        .font(.system(size: PhraseEditorLayout.labelFontSize, weight: .medium))
                        .frame(height: PhraseEditorLayout.labelLineHeight, alignment: .leading)

                    PlainShortcutTextField(
                        text: $shortcut,
                        font: NSFont.systemFont(ofSize: PhraseEditorLayout.fieldFontSize),
                        focusRequest: shortcutFocusRequest,
                        onCommit: save,
                        onCancel: onCancel
                    )
                        .frame(width: PhraseEditorLayout.fieldSeparatorWidth, height: PhraseEditorLayout.shortcutFieldHeight)
                        .accessibilityIdentifier("lazyquips.library.editor.shortcutField")
                        .padding(.bottom, PhraseEditorLayout.textFieldBottomPadding)

                    Divider()
                        .frame(width: PhraseEditorLayout.fieldSeparatorWidth, height: PhraseEditorLayout.fieldSeparatorHeight)
                }
                .frame(width: PhraseEditorLayout.contentWidth, alignment: .leading)
                .padding(.bottom, PhraseEditorLayout.shortcutBottomPadding)

                VStack(alignment: .leading, spacing: PhraseEditorLayout.labelSpacing) {
                    Text(AppStrings.text(.phrase, language: language))
                        .font(.system(size: PhraseEditorLayout.labelFontSize, weight: .medium))
                        .frame(height: PhraseEditorLayout.labelLineHeight, alignment: .leading)

                    PlainPhraseTextEditor(
                        text: $phraseBody,
                        font: NSFont.systemFont(ofSize: PhraseEditorLayout.fieldFontSize)
                    )
                        .frame(width: PhraseEditorLayout.fieldSeparatorWidth, height: bodyFieldHeight)
                        .accessibilityIdentifier("lazyquips.library.editor.phraseField")
                        .padding(.bottom, PhraseEditorLayout.phraseFieldBottomPadding)
                }

                Text(errorKey.map { AppStrings.text($0, language: language) } ?? "")
                    .font(.system(size: PhraseEditorLayout.errorFontSize))
                    .foregroundStyle(.red)
                    .frame(height: PhraseEditorLayout.errorHeight, alignment: .leading)
                    .padding(.top, PhraseEditorLayout.errorTopPadding)

                Spacer(minLength: 0)

                HStack(spacing: PhraseEditorLayout.footerButtonSpacing) {
                    Spacer()

                    Button(action: onCancel) {
                        Text(cancelTitle)
                    }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(PhraseEditorFooterButtonStyle(prominence: .standard))
                        .accessibilityLabel(cancelTitle)
                        .accessibilityIdentifier("lazyquips.library.editor.cancelButton")

                    Button(action: save) {
                        Text(okTitle)
                    }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(PhraseEditorFooterButtonStyle(prominence: .primary))
                        .accessibilityLabel(okTitle)
                        .accessibilityIdentifier("lazyquips.library.editor.okButton")
                }
                .padding(.top, PhraseEditorLayout.footerTopPadding)
                .frame(width: PhraseEditorLayout.contentWidth)
            }
            .padding(PhraseEditorLayout.contentPadding)
            .frame(
                width: PhraseEditorLayout.cardWidth,
                height: cardHeight,
                alignment: .top
            )
            .background(
                Color(nsColor: .windowBackgroundColor),
                in: RoundedRectangle(cornerRadius: PhraseEditorLayout.cardCornerRadius)
            )
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func requestShortcutFocus() {
        shortcutFocusRequest += 1
    }

    private func save() {
        do {
            try onSave(shortcut, phraseBody)
        } catch {
            errorKey = (error as? PhraseValidationError)?.messageKey ?? .saveFailed
        }
    }
}
