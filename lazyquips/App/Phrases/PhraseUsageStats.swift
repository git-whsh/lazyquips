import Foundation
import SwiftData

@Model
final class PhraseUsageStats {
    var id: UUID
    var phraseID: UUID
    var lastCopiedAt: Date
    var copyCount: Int

    init(
        id: UUID = UUID(),
        phraseID: UUID,
        lastCopiedAt: Date = Date(),
        copyCount: Int = 0
    ) {
        self.id = id
        self.phraseID = phraseID
        self.lastCopiedAt = lastCopiedAt
        self.copyCount = copyCount
    }

    func recordCopy(at date: Date = Date()) {
        lastCopiedAt = date
        copyCount += 1
    }
}
