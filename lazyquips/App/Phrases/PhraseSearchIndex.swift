import Foundation

struct PhraseSearchIndex {
    let phrase: Phrase
    let normalizedShortcut: String
    let shortcutFuzzyTokens: [String]
    let foldedBody: String
    let pinyinFull: String
    let pinyinInitials: String
    let pinyinFuzzyTokens: [String]
    let fuzzyTokens: [String]

    init(phrase: Phrase) {
        self.phrase = phrase
        normalizedShortcut = PhraseSearchNormalizer.normalize(phrase.normalizedShortcut)
        shortcutFuzzyTokens = PhraseSearchIndex.shortcutFuzzyTokens(from: normalizedShortcut)
        foldedBody = PhraseSearchNormalizer.normalize(phrase.body)

        let shortcutPinyin = PhraseSearchNormalizer.pinyin(for: phrase.shortcut)
        let bodyPinyin = PhraseSearchNormalizer.pinyin(for: phrase.body)
        pinyinFull = [shortcutPinyin.full, bodyPinyin.full]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        pinyinInitials = [shortcutPinyin.initials, bodyPinyin.initials]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        pinyinFuzzyTokens = PhraseSearchIndex.tokens(from: [
            shortcutPinyin.full,
            shortcutPinyin.initials,
            bodyPinyin.full,
            bodyPinyin.initials
        ] + shortcutPinyin.joinedSyllableWindows + bodyPinyin.joinedSyllableWindows)

        fuzzyTokens = PhraseSearchIndex.tokens(from: [
            normalizedShortcut,
            foldedBody,
            pinyinFull,
            pinyinInitials
        ])
    }

    private static func tokens(from values: [String]) -> [String] {
        var seen = Set<String>()
        var tokens: [String] = []

        for value in values {
            let candidates = value
                .split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                + [value.filter { $0.isLetter || $0.isNumber }]

            for candidate in candidates where PhraseSearchNormalizer.isFuzzyToken(candidate) {
                if seen.insert(candidate).inserted {
                    tokens.append(candidate)
                }
            }
        }

        return tokens
    }

    private static func shortcutFuzzyTokens(from normalizedShortcut: String) -> [String] {
        let compactShortcut = normalizedShortcut.filter { $0.isLetter || $0.isNumber }
        var values = [compactShortcut]

        if let first = normalizedShortcut.first,
           !first.isLetter,
           !first.isNumber {
            let withoutLeadingSymbols = String(normalizedShortcut.drop(while: { !$0.isLetter && !$0.isNumber }))
            values.append(withoutLeadingSymbols.filter { $0.isLetter || $0.isNumber })
        }

        var seen = Set<String>()
        return values.filter { value in
            PhraseSearchNormalizer.isFuzzyToken(value) && seen.insert(value).inserted
        }
    }
}

final class PhraseSearchIndexCache {
    typealias IndexBuilder = (Phrase) -> PhraseSearchIndex

    private let makeIndex: IndexBuilder
    private var cachedSignatures: [PhraseSearchIndexSignature]?
    private var cachedIndexes: [PhraseSearchIndex]?
    private var cachedSortedIndexes: [PhraseSearchIndex]?

    init(makeIndex: @escaping IndexBuilder = PhraseSearchIndex.init) {
        self.makeIndex = makeIndex
    }

    func indexes(for phrases: [Phrase]) -> [PhraseSearchIndex] {
        let signatures = phrases.map(PhraseSearchIndexSignature.init)

        if cachedSignatures == signatures,
           let cachedIndexes {
            return cachedIndexes
        }

        return LazyQuipsPerformanceSignpost.interval("Search.IndexBuild") {
            let previousIndexesBySignature = Dictionary(
                zip(cachedSignatures ?? [], cachedIndexes ?? []),
                uniquingKeysWith: { existing, _ in existing }
            )
            let indexes = zip(signatures, phrases).map { signature, phrase in
                previousIndexesBySignature[signature] ?? makeIndex(phrase)
            }
            cachedSignatures = signatures
            cachedIndexes = indexes
            cachedSortedIndexes = nil
            return indexes
        }
    }

    func sortedIndexes(for phrases: [Phrase]) -> [PhraseSearchIndex] {
        let indexes = indexes(for: phrases)

        if let cachedSortedIndexes {
            return cachedSortedIndexes
        }

        return LazyQuipsPerformanceSignpost.interval("Search.IndexSort") {
            let sortedIndexes = PhraseSearch.sortedPreparedIndexes(indexes)
            cachedSortedIndexes = sortedIndexes
            return sortedIndexes
        }
    }
}

private struct PhraseSearchIndexSignature: Hashable {
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

enum PhraseSearchNormalizer {
    static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    static func pinyin(for value: String) -> (full: String, initials: String, joinedSyllableWindows: [String]) {
        let cjkText = String(value.unicodeScalars.filter(isCJKIdeograph))
        guard !cjkText.isEmpty,
              let latin = cjkText.applyingTransform(.toLatin, reverse: false)
        else {
            return ("", "", [])
        }

        let foldedLatin = normalize(latin)
        let syllables = foldedLatin
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !$0.isEmpty }

        let full = syllables.joined()
        let initials = syllables.compactMap(\.first).map(String.init).joined()
        return (full, initials, joinedSyllableWindows(from: syllables))
    }

    private static func joinedSyllableWindows(from syllables: [String]) -> [String] {
        var windows: [String] = []

        for startIndex in syllables.indices {
            var joined = ""

            for index in startIndex..<syllables.endIndex {
                joined += syllables[index]
                guard joined.count <= 32 else {
                    break
                }

                if joined.count >= 4 {
                    windows.append(joined)
                }
            }
        }

        return windows
    }

    static func isFuzzyToken(_ value: String) -> Bool {
        value.count >= 4
            && value.count <= 32
            && value.unicodeScalars.allSatisfy { scalar in
                CharacterSet.alphanumerics.contains(scalar) && scalar.isASCII
            }
    }

    private static func isCJKIdeograph(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF,
             0x4E00...0x9FFF,
             0xF900...0xFAFF,
             0x20000...0x2A6DF,
             0x2A700...0x2B73F,
             0x2B740...0x2B81F,
             0x2B820...0x2CEAF,
             0x2CEB0...0x2EBEF,
             0x30000...0x3134F,
             0x31350...0x323AF:
            return true
        default:
            return false
        }
    }
}
