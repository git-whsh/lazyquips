import Foundation

enum PhraseGroupID: Hashable {
    case all
    case starred
    case digits
    case letter(Character)
    case symbols

    var title: String {
        switch self {
        case .all:
            return "All"
        case .starred:
            return "Star"
        case .digits:
            return "0-9"
        case .letter(let character):
            return String(character)
        case .symbols:
            return "#"
        }
    }

    var indexTitle: String {
        switch self {
        case .all:
            return title
        case .digits:
            return "0"
        default:
            return title
        }
    }

    fileprivate var sortOrder: Int {
        switch self {
        case .all:
            return -1
        case .starred:
            return 0
        case .digits:
            return 1
        case .letter(let character):
            guard let scalar = character.unicodeScalars.first else {
                return 28
            }
            return 2 + Int(scalar.value - UnicodeScalar("A").value)
        case .symbols:
            return 28
        }
    }
}

struct PhraseGroupSection {
    let id: PhraseGroupID
    let title: String
    let showsTitle: Bool
    let phrases: [Phrase]

    init(
        id: PhraseGroupID,
        title: String,
        showsTitle: Bool = true,
        phrases: [Phrase]
    ) {
        self.id = id
        self.title = title
        self.showsTitle = showsTitle
        self.phrases = phrases
    }
}

enum PhraseGrouping {
    static func sections(
        for phrases: [Phrase],
        preservingInputOrder: Bool = false
    ) -> [PhraseGroupSection] {
        let indexedPhrases = phrases.enumerated().map { IndexedPhrase(index: $0.offset, phrase: $0.element) }
        var sections: [PhraseGroupSection] = []
        let starred = ordered(indexedPhrases.filter(\.phrase.isStarred), preservingInputOrder: preservingInputOrder)

        if !starred.isEmpty {
            sections.append(PhraseGroupSection(id: .starred, title: PhraseGroupID.starred.title, phrases: starred))
        }

        let grouped = Dictionary(grouping: indexedPhrases) { indexedPhrase in
            groupID(for: indexedPhrase.phrase)
        }

        let regularSections = grouped
            .map { id, indexedPhrases in
                PhraseGroupSection(
                    id: id,
                    title: id.title,
                    phrases: ordered(indexedPhrases, preservingInputOrder: preservingInputOrder)
                )
            }
            .sorted { lhs, rhs in
                lhs.id.sortOrder < rhs.id.sortOrder
            }

        sections.append(contentsOf: regularSections)
        return sections
    }

    static func indexTitles(for sections: [PhraseGroupSection], includeStarred: Bool = true) -> [String] {
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

    static func groupID(for phrase: Phrase) -> PhraseGroupID {
        let shortcut = phrase.normalizedShortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let scalar = shortcut.unicodeScalars.first else {
            return .symbols
        }

        switch scalar.value {
        case UnicodeScalar("0").value...UnicodeScalar("9").value:
            return .digits
        case UnicodeScalar("a").value...UnicodeScalar("z").value:
            return .letter(Character(String(scalar).uppercased()))
        case UnicodeScalar("A").value...UnicodeScalar("Z").value:
            return .letter(Character(String(scalar).uppercased()))
        default:
            return .symbols
        }
    }

    private static func stableSorted(_ indexedPhrases: [IndexedPhrase]) -> [Phrase] {
        indexedPhrases
            .sorted { lhs, rhs in
                let lhsShortcut = lhs.phrase.normalizedShortcut
                let rhsShortcut = rhs.phrase.normalizedShortcut

                if lhsShortcut == rhsShortcut {
                    return lhs.index < rhs.index
                }

                return lhsShortcut < rhsShortcut
            }
            .map(\.phrase)
    }

    private static func ordered(
        _ indexedPhrases: [IndexedPhrase],
        preservingInputOrder: Bool
    ) -> [Phrase] {
        if preservingInputOrder {
            return indexedPhrases.map(\.phrase)
        }

        return stableSorted(indexedPhrases)
    }
}

private struct IndexedPhrase {
    let index: Int
    let phrase: Phrase
}
