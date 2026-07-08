enum PhraseEmptyStateText {
    static func titleKey(isEmptyLibrary: Bool, hasSearchText: Bool) -> AppStringKey {
        if isEmptyLibrary {
            return .noPhrasesYet
        }

        if hasSearchText {
            return .noResults
        }

        return .noPhrases
    }

    static func title(isEmptyLibrary: Bool, hasSearchText: Bool) -> String {
        AppStrings.text(
            titleKey(isEmptyLibrary: isEmptyLibrary, hasSearchText: hasSearchText),
            language: .english
        )
    }
}
