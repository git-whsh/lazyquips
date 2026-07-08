import Foundation

struct ValidatedPhraseInput {
    let shortcut: String
    let normalizedShortcut: String
    let body: String
}

enum PhraseValidationError: Error, Equatable {
    case shortcutRequired
    case bodyRequired
    case duplicateShortcut

    var messageKey: AppStringKey {
        switch self {
        case .shortcutRequired:
            return .shortcutRequired
        case .bodyRequired:
            return .phraseRequired
        case .duplicateShortcut:
            return .duplicateShortcut
        }
    }

    var userFacingMessage: String {
        AppStrings.text(messageKey, language: .english)
    }
}

struct PhraseValidator {
    func validate(
        shortcut: String,
        body: String,
        existingPhrases: [Phrase],
        editingPhraseID: UUID? = nil
    ) throws -> ValidatedPhraseInput {
        let trimmedShortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedShortcut.isEmpty else {
            throw PhraseValidationError.shortcutRequired
        }

        guard !trimmedBody.isEmpty else {
            throw PhraseValidationError.bodyRequired
        }

        let normalizedShortcut = Phrase.normalizedShortcut(for: trimmedShortcut)
        let hasDuplicate = existingPhrases.contains { phrase in
            phrase.id != editingPhraseID && phrase.normalizedShortcut == normalizedShortcut
        }

        guard !hasDuplicate else {
            throw PhraseValidationError.duplicateShortcut
        }

        return ValidatedPhraseInput(
            shortcut: trimmedShortcut,
            normalizedShortcut: normalizedShortcut,
            body: body
        )
    }
}
