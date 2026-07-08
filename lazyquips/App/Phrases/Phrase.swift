import Foundation
import SwiftData

@Model
final class Phrase {
    var id: UUID
    private(set) var shortcut: String
    private(set) var normalizedShortcut: String
    private(set) var body: String
    private(set) var isStarred: Bool
    private(set) var createdAt: Date
    private(set) var updatedAt: Date
    @Transient private(set) var contentRevision: Int = 0

    init(
        id: UUID = UUID(),
        shortcut: String,
        body: String,
        isStarred: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.shortcut = shortcut
        self.normalizedShortcut = Self.normalizedShortcut(for: shortcut)
        self.body = body
        self.isStarred = isStarred
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func updateShortcut(_ shortcut: String, updatedAt: Date = Date()) {
        if self.shortcut != shortcut {
            contentRevision += 1
        }
        self.shortcut = shortcut
        normalizedShortcut = Self.normalizedShortcut(for: shortcut)
        self.updatedAt = updatedAt
    }

    func update(shortcut: String, body: String, updatedAt: Date = Date()) {
        if self.shortcut != shortcut || self.body != body {
            contentRevision += 1
        }
        self.shortcut = shortcut
        normalizedShortcut = Self.normalizedShortcut(for: shortcut)
        self.body = body
        self.updatedAt = updatedAt
    }

    func setStarred(_ isStarred: Bool, updatedAt: Date = Date()) {
        self.isStarred = isStarred
        self.updatedAt = updatedAt
    }

    static func normalizedShortcut(for shortcut: String) -> String {
        shortcut
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
