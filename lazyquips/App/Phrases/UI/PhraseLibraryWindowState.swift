import Foundation
import Combine

final class PhraseLibraryWindowState: ObservableObject {
    enum EditorMode: Equatable {
        case add
        case edit(UUID)
    }

    @Published private(set) var editorMode: EditorMode?
    @Published private(set) var isSettingsPresented = false
    @Published private(set) var searchFocusRequest = UUID()

    func openAdd() {
        isSettingsPresented = false
        editorMode = .add
    }

    func openAddIfNoActiveEditor() {
        guard editorMode == nil else {
            return
        }

        openAdd()
    }

    func openEdit(_ phrase: Phrase) {
        isSettingsPresented = false
        editorMode = .edit(phrase.id)
    }

    func openSettingsIfNoActiveEditor() {
        guard editorMode == nil else {
            return
        }

        isSettingsPresented = true
    }

    func openSettings() {
        openSettingsIfNoActiveEditor()
    }

    func requestSearchFocusIfNoActiveOverlay() {
        guard editorMode == nil, !isSettingsPresented else {
            return
        }

        searchFocusRequest = UUID()
    }

    func dismissEditor() {
        editorMode = nil
    }

    func dismissSettings() {
        isSettingsPresented = false
    }
}
