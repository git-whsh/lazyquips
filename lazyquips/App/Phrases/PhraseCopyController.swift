import Foundation

enum PhraseCopyResult: Equatable {
    case failedToWrite
    case copied
    case copiedWithoutRecent

    var didCopy: Bool {
        self != .failedToWrite
    }
}

final class PhraseCopyController {
    private let writeString: (String) -> Bool
    private let recordCopy: (Phrase, Date) throws -> Void

    init(
        repository: PhraseRepository,
        pasteboardWriter: PasteboardWriter = PasteboardWriter()
    ) {
        self.writeString = pasteboardWriter.writeString
        self.recordCopy = { phrase, date in
            try repository.recordCopy(of: phrase, at: date)
        }
    }

    init(
        repository: PhraseRepository,
        writeString: @escaping (String) -> Bool
    ) {
        self.writeString = writeString
        self.recordCopy = { phrase, date in
            try repository.recordCopy(of: phrase, at: date)
        }
    }

    init(
        writeString: @escaping (String) -> Bool,
        recordCopy: @escaping (Phrase, Date) throws -> Void
    ) {
        self.writeString = writeString
        self.recordCopy = recordCopy
    }

    @discardableResult
    func copy(_ phrase: Phrase, at date: Date = Date()) -> PhraseCopyResult {
        guard writeString(phrase.body) else {
            return .failedToWrite
        }

        do {
            try recordCopy(phrase, date)
            return .copied
        } catch {
            return .copiedWithoutRecent
        }
    }
}
