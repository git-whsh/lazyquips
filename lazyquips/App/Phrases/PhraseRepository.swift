import Foundation
import SwiftData

struct RecentPhrase {
    let phrase: Phrase
    let stats: PhraseUsageStats
}

final class PhraseRepository {
    private let context: ModelContext
    private let validator: PhraseValidator

    init(context: ModelContext, validator: PhraseValidator = PhraseValidator()) {
        self.context = context
        self.validator = validator
    }

    func fetchAll() throws -> [Phrase] {
        try sortedPhrases(context.fetch(FetchDescriptor<Phrase>()))
    }

    @discardableResult
    func add(
        shortcut: String,
        body: String,
        isStarred: Bool = false,
        now: Date = Date()
    ) throws -> Phrase {
        let input = try validator.validate(
            shortcut: shortcut,
            body: body,
            existingPhrases: fetchAll()
        )
        let phrase = Phrase(
            shortcut: input.shortcut,
            body: input.body,
            isStarred: isStarred,
            createdAt: now,
            updatedAt: now
        )

        context.insert(phrase)
        try context.save()

        return phrase
    }

    func edit(
        _ phrase: Phrase,
        shortcut: String,
        body: String,
        now: Date = Date()
    ) throws {
        let input = try validator.validate(
            shortcut: shortcut,
            body: body,
            existingPhrases: fetchAll(),
            editingPhraseID: phrase.id
        )

        phrase.update(shortcut: input.shortcut, body: input.body, updatedAt: now)
        try context.save()
    }

    func delete(_ phrase: Phrase) throws {
        let phraseID = phrase.id

        for stats in try fetchUsageStats() where stats.phraseID == phraseID {
            context.delete(stats)
        }

        context.delete(phrase)
        try context.save()
    }

    func star(_ phrase: Phrase, now: Date = Date()) throws {
        try setStarred(phrase, isStarred: true, now: now)
    }

    func unstar(_ phrase: Phrase, now: Date = Date()) throws {
        try setStarred(phrase, isStarred: false, now: now)
    }

    func setStarred(_ phrase: Phrase, isStarred: Bool, now: Date = Date()) throws {
        phrase.setStarred(isStarred, updatedAt: now)
        try context.save()
    }

    @discardableResult
    func recordCopy(of phrase: Phrase, at date: Date = Date()) throws -> PhraseUsageStats {
        let matchingStats = sortedUsageStatsByRecent(
            try fetchUsageStats(for: phrase.id),
            phrasesByID: [phrase.id: phrase]
        )

        if let stats = matchingStats.first {
            stats.recordCopy(at: date)
            for duplicateStats in matchingStats.dropFirst() {
                context.delete(duplicateStats)
            }
            try context.save()
            return stats
        }

        let stats = PhraseUsageStats(
            phraseID: phrase.id,
            lastCopiedAt: date,
            copyCount: 1
        )
        context.insert(stats)
        try context.save()

        return stats
    }

    func recent(limit: Int = 2) throws -> [RecentPhrase] {
        guard limit > 0 else {
            return []
        }

        let phrasesByID = Dictionary(uniqueKeysWithValues: try fetchAll().map { ($0.id, $0) })
        let stats = sortedUsageStatsByRecent(
            try fetchUsageStats()
                .filter { phrasesByID[$0.phraseID] != nil },
            phrasesByID: phrasesByID
        )
        var seenPhraseIDs = Set<UUID>()

        return stats.compactMap { stats in
            guard seenPhraseIDs.insert(stats.phraseID).inserted else {
                return nil
            }
            guard let phrase = phrasesByID[stats.phraseID] else {
                return nil
            }

            return RecentPhrase(phrase: phrase, stats: stats)
        }
        .prefix(limit)
        .map { $0 }
    }

    private func fetchUsageStats() throws -> [PhraseUsageStats] {
        try context.fetch(FetchDescriptor<PhraseUsageStats>())
    }

    private func fetchUsageStats(for phraseID: UUID) throws -> [PhraseUsageStats] {
        try context.fetch(
            FetchDescriptor<PhraseUsageStats>(
                predicate: #Predicate { stats in
                    stats.phraseID == phraseID
                }
            )
        )
    }

    private func sortedUsageStatsByRecent(
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

    private func sortedPhrases(_ phrases: [Phrase]) -> [Phrase] {
        phrases.sorted { lhs, rhs in
            if lhs.normalizedShortcut != rhs.normalizedShortcut {
                return lhs.normalizedShortcut < rhs.normalizedShortcut
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
