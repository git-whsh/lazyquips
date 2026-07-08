import SwiftUI

@main
struct LazyquipsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(AppStrings.text(.settings, language: appDelegate.languageStore.language)) {
                    appDelegate.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button(AppStrings.text(.search, language: appDelegate.languageStore.language)) {
                    appDelegate.focusMainWindowSearch()
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
