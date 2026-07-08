import Foundation

enum PhraseSearchMatchKind: Int, Comparable {
    case shortcutExact
    case shortcutPrefix
    case shortcutContains
    case shortcutTypo
    case bodyContains
    case pinyinFull
    case pinyinInitials
    case pinyinTypo
    case bodyTokenTypo

    static func < (lhs: PhraseSearchMatchKind, rhs: PhraseSearchMatchKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct PhraseSearchResult {
    let phrase: Phrase
    let matchKind: PhraseSearchMatchKind
    let editDistance: Int?
    let matchPriority: Int

    init(
        phrase: Phrase,
        matchKind: PhraseSearchMatchKind,
        editDistance: Int?,
        matchPriority: Int = 0
    ) {
        self.phrase = phrase
        self.matchKind = matchKind
        self.editDistance = editDistance
        self.matchPriority = matchPriority
    }
}

enum PhraseSearch {
    static func search(_ query: String, in phrases: [Phrase]) -> [Phrase] {
        rankedResults(for: query, in: phrases).map(\.phrase)
    }

    static func search(
        _ query: String,
        in phrases: [Phrase],
        usageStats: [PhraseUsageStats]
    ) -> [Phrase] {
        let sortedPhrases = sortedPhrases(phrases)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return sortedPhrases
        }

        return search(
            query,
            inSortedIndexes: sortedPhrases.map(PhraseSearchIndex.init),
            usageStats: usageStats
        )
    }

    static func search(
        _ query: String,
        inPreparedIndexes indexes: [PhraseSearchIndex],
        usageStats: [PhraseUsageStats]
    ) -> [Phrase] {
        search(
            query,
            inSortedIndexes: sortedPreparedIndexes(indexes),
            usageStats: usageStats
        )
    }

    static func search(
        _ query: String,
        inSortedPreparedIndexes sortedIndexes: [PhraseSearchIndex],
        usageStats: [PhraseUsageStats]
    ) -> [Phrase] {
        search(
            query,
            inSortedIndexes: sortedIndexes,
            usageStats: usageStats
        )
    }

    private static func search(
        _ query: String,
        inSortedIndexes indexes: [PhraseSearchIndex],
        usageStats: [PhraseUsageStats]
    ) -> [Phrase] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return indexes.map(\.phrase)
        }

        return LazyQuipsPerformanceSignpost.interval("Search.Query") {
            let originalOrderByPhraseID = Dictionary(
                uniqueKeysWithValues: indexes.enumerated().map { ($0.element.phrase.id, $0.offset) }
            )
            let recentRankByPhraseID = recentRankByPhraseID(usageStats)

            return rankedResults(for: query, in: indexes)
                .sorted { lhs, rhs in
                    if lhs.matchKind != rhs.matchKind {
                        return lhs.matchKind < rhs.matchKind
                    }

                    if lhs.matchPriority != rhs.matchPriority {
                        return lhs.matchPriority < rhs.matchPriority
                    }

                    let lhsDistance = lhs.editDistance ?? 0
                    let rhsDistance = rhs.editDistance ?? 0
                    if lhsDistance != rhsDistance {
                        return lhsDistance < rhsDistance
                    }

                    if lhs.phrase.isStarred != rhs.phrase.isStarred {
                        return lhs.phrase.isStarred
                    }

                    let lhsRecentRank = recentRankByPhraseID[lhs.phrase.id] ?? Int.max
                    let rhsRecentRank = recentRankByPhraseID[rhs.phrase.id] ?? Int.max
                    if lhsRecentRank != rhsRecentRank {
                        return lhsRecentRank < rhsRecentRank
                    }

                    if lhs.phrase.normalizedShortcut != rhs.phrase.normalizedShortcut {
                        return lhs.phrase.normalizedShortcut < rhs.phrase.normalizedShortcut
                    }

                    return (originalOrderByPhraseID[lhs.phrase.id] ?? 0) < (originalOrderByPhraseID[rhs.phrase.id] ?? 0)
                }
                .map(\.phrase)
        }
    }

    static func rankedResults(for query: String, in phrases: [Phrase]) -> [PhraseSearchResult] {
        let normalizedQuery = PhraseSearchNormalizer.normalize(query)

        guard !normalizedQuery.isEmpty else {
            return phrases
                .enumerated()
                .map { index, phrase in
                    EmptyQueryResult(index: index, phrase: phrase)
                }
                .sorted()
                .map {
                    PhraseSearchResult(phrase: $0.phrase, matchKind: .shortcutPrefix, editDistance: nil)
                }
        }

        return rankedResults(
            forNormalizedQuery: normalizedQuery,
            in: phrases.enumerated().map { index, phrase in
                (index: index, searchIndex: PhraseSearchIndex(phrase: phrase))
            }
        )
    }

    static func rankedResults(for query: String, in indexes: [PhraseSearchIndex]) -> [PhraseSearchResult] {
        let normalizedQuery = PhraseSearchNormalizer.normalize(query)

        guard !normalizedQuery.isEmpty else {
            return indexes
                .enumerated()
                .map { index, searchIndex in
                    EmptyQueryResult(index: index, phrase: searchIndex.phrase)
                }
                .sorted()
                .map {
                    PhraseSearchResult(phrase: $0.phrase, matchKind: .shortcutPrefix, editDistance: nil)
                }
        }

        return rankedResults(
            forNormalizedQuery: normalizedQuery,
            in: indexes.enumerated().map { index, searchIndex in
                (index: index, searchIndex: searchIndex)
            }
        )
    }

    private static func rankedResults(
        forNormalizedQuery query: String,
        in indexes: [(index: Int, searchIndex: PhraseSearchIndex)]
    ) -> [PhraseSearchResult] {
        indexes
            .compactMap { indexedValue -> RankedPhraseSearchResult? in
                guard let match = bestMatch(for: query, in: indexedValue.searchIndex) else {
                    return nil
                }

                return RankedPhraseSearchResult(index: indexedValue.index, result: match)
            }
            .sorted()
            .map(\.result)
    }

    private static func bestMatch(for query: String, in index: PhraseSearchIndex) -> PhraseSearchResult? {
        if index.normalizedShortcut == query {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .shortcutExact, editDistance: nil)
        }

        if index.normalizedShortcut.hasPrefix(query) {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .shortcutPrefix, editDistance: nil)
        }

        if index.normalizedShortcut.contains(query) {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .shortcutContains, editDistance: nil)
        }

        if let distance = typoDistance(fromAnyOf: shortcutFuzzyQueries(from: query), toAnyOf: index.shortcutFuzzyTokens) {
            return PhraseSearchResult(
                phrase: index.phrase,
                matchKind: .shortcutTypo,
                editDistance: distance,
                matchPriority: shortcutTypoMatchPriority(query: query, shortcut: index.normalizedShortcut)
            )
        }

        if index.foldedBody.contains(query) {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .bodyContains, editDistance: nil)
        }

        if !index.pinyinFull.isEmpty, index.pinyinFull.contains(query) {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .pinyinFull, editDistance: nil)
        }

        if !index.pinyinInitials.isEmpty, index.pinyinInitials.contains(query) {
            return PhraseSearchResult(phrase: index.phrase, matchKind: .pinyinInitials, editDistance: nil)
        }

        if PhraseSearchNormalizer.isFuzzyToken(query) {
            if let distance = typoDistance(from: query, toAnyOf: index.pinyinFuzzyTokens) {
                return PhraseSearchResult(phrase: index.phrase, matchKind: .pinyinTypo, editDistance: distance)
            }

            if let distance = typoDistance(from: query, toAnyOf: index.fuzzyTokens) {
                return PhraseSearchResult(phrase: index.phrase, matchKind: .bodyTokenTypo, editDistance: distance)
            }
        }

        return nil
    }

    private static func typoDistance(from query: String, toAnyOf tokens: [String]) -> Int? {
        let maximumDistance = maximumTypoDistance(for: query)

        return tokens
            .filter { PhraseSearchNormalizer.isFuzzyToken($0) }
            .compactMap { token -> Int? in
                guard abs(token.count - query.count) <= maximumDistance else {
                    return nil
                }

                let distance = damerauLevenshteinDistance(query, token, maximumDistance: maximumDistance)
                return distance <= maximumDistance ? distance : nil
            }
            .min()
    }

    private static func typoDistance(fromAnyOf queries: [String], toAnyOf tokens: [String]) -> Int? {
        queries
            .compactMap { typoDistance(from: $0, toAnyOf: tokens) }
            .min()
    }

    private static func shortcutFuzzyQueries(from query: String) -> [String] {
        var seen = Set<String>()
        var queries: [String] = []

        func append(_ value: String) {
            guard PhraseSearchNormalizer.isFuzzyToken(value),
                  seen.insert(value).inserted
            else {
                return
            }

            queries.append(value)
        }

        append(query)
        append(query.filter { $0.isLetter || $0.isNumber })

        if let first = query.first,
           !first.isLetter,
           !first.isNumber {
            let withoutLeadingSymbols = String(query.drop(while: { !$0.isLetter && !$0.isNumber }))
            append(withoutLeadingSymbols)
            append(withoutLeadingSymbols.filter { $0.isLetter || $0.isNumber })
        }

        return queries
    }

    private static func shortcutTypoMatchPriority(query: String, shortcut: String) -> Int {
        let queryPrefix = leadingSymbols(in: query)
        guard !queryPrefix.isEmpty else {
            return 0
        }

        let shortcutPrefix = leadingSymbols(in: shortcut)
        if shortcutPrefix == queryPrefix {
            return 0
        }

        return shortcutPrefix.isEmpty ? 1 : 2
    }

    private static func leadingSymbols(in value: String) -> String {
        String(value.prefix { !$0.isLetter && !$0.isNumber })
    }

    private static func maximumTypoDistance(for query: String) -> Int {
        query.count >= 8 ? 2 : 1
    }

    private static func sortedPhrases(_ phrases: [Phrase]) -> [Phrase] {
        phrases.sorted { lhs, rhs in
            if lhs.normalizedShortcut != rhs.normalizedShortcut {
                return lhs.normalizedShortcut < rhs.normalizedShortcut
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    static func sortedPreparedIndexes(_ indexes: [PhraseSearchIndex]) -> [PhraseSearchIndex] {
        indexes.sorted { lhs, rhs in
            if lhs.phrase.normalizedShortcut != rhs.phrase.normalizedShortcut {
                return lhs.phrase.normalizedShortcut < rhs.phrase.normalizedShortcut
            }

            return lhs.phrase.id.uuidString < rhs.phrase.id.uuidString
        }
    }

    private static func recentRankByPhraseID(_ usageStats: [PhraseUsageStats]) -> [UUID: Int] {
        var ranks: [UUID: Int] = [:]

        for (index, stats) in usageStats
            .sorted(by: { lhs, rhs in
                if lhs.lastCopiedAt != rhs.lastCopiedAt {
                    return lhs.lastCopiedAt > rhs.lastCopiedAt
                }

                return lhs.phraseID.uuidString < rhs.phraseID.uuidString
            })
            .enumerated()
        where ranks[stats.phraseID] == nil {
            ranks[stats.phraseID] = index
        }

        return ranks
    }

    private static func damerauLevenshteinDistance(_ lhs: String, _ rhs: String, maximumDistance: Int) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        let lhsCount = lhs.count
        let rhsCount = rhs.count

        if lhsCount == 0 { return rhsCount }
        if rhsCount == 0 { return lhsCount }
        if abs(lhsCount - rhsCount) > maximumDistance { return maximumDistance + 1 }

        var distances = Array(
            repeating: Array(repeating: 0, count: rhsCount + 1),
            count: lhsCount + 1
        )

        for lhsIndex in 0...lhsCount {
            distances[lhsIndex][0] = lhsIndex
        }

        for rhsIndex in 0...rhsCount {
            distances[0][rhsIndex] = rhsIndex
        }

        for lhsIndex in 1...lhsCount {
            var rowMinimum = Int.max

            for rhsIndex in 1...rhsCount {
                let cost = lhs[lhsIndex - 1] == rhs[rhsIndex - 1] ? 0 : 1
                var value = min(
                    distances[lhsIndex - 1][rhsIndex] + 1,
                    distances[lhsIndex][rhsIndex - 1] + 1,
                    distances[lhsIndex - 1][rhsIndex - 1] + cost
                )

                if lhsIndex > 1,
                   rhsIndex > 1,
                   lhs[lhsIndex - 1] == rhs[rhsIndex - 2],
                   lhs[lhsIndex - 2] == rhs[rhsIndex - 1] {
                    value = min(value, distances[lhsIndex - 2][rhsIndex - 2] + 1)
                }

                distances[lhsIndex][rhsIndex] = value
                rowMinimum = min(rowMinimum, value)
            }

            if rowMinimum > maximumDistance {
                return maximumDistance + 1
            }
        }

        return distances[lhsCount][rhsCount]
    }
}

private struct RankedPhraseSearchResult: Comparable {
    let index: Int
    let result: PhraseSearchResult

    static func == (lhs: RankedPhraseSearchResult, rhs: RankedPhraseSearchResult) -> Bool {
        lhs.index == rhs.index
            && lhs.result.phrase.id == rhs.result.phrase.id
            && lhs.result.matchKind == rhs.result.matchKind
            && lhs.result.editDistance == rhs.result.editDistance
            && lhs.result.matchPriority == rhs.result.matchPriority
    }

    static func < (lhs: RankedPhraseSearchResult, rhs: RankedPhraseSearchResult) -> Bool {
        if lhs.result.matchKind != rhs.result.matchKind {
            return lhs.result.matchKind < rhs.result.matchKind
        }

        if lhs.result.matchPriority != rhs.result.matchPriority {
            return lhs.result.matchPriority < rhs.result.matchPriority
        }

        let lhsDistance = lhs.result.editDistance ?? 0
        let rhsDistance = rhs.result.editDistance ?? 0
        if lhsDistance != rhsDistance {
            return lhsDistance < rhsDistance
        }

        let lhsShortcut = lhs.result.phrase.normalizedShortcut
        let rhsShortcut = rhs.result.phrase.normalizedShortcut
        if lhsShortcut != rhsShortcut {
            return lhsShortcut < rhsShortcut
        }

        return lhs.index < rhs.index
    }
}

private struct EmptyQueryResult: Comparable {
    let index: Int
    let phrase: Phrase

    static func == (lhs: EmptyQueryResult, rhs: EmptyQueryResult) -> Bool {
        lhs.index == rhs.index && lhs.phrase.id == rhs.phrase.id
    }

    static func < (lhs: EmptyQueryResult, rhs: EmptyQueryResult) -> Bool {
        let lhsShortcut = lhs.phrase.normalizedShortcut
        let rhsShortcut = rhs.phrase.normalizedShortcut

        if lhsShortcut != rhsShortcut {
            return lhsShortcut < rhsShortcut
        }

        return lhs.index < rhs.index
    }
}
