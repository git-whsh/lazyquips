import AppKit

@main
struct LazyQuipsLoginHelper {
    static func main() {
        guard NSRunningApplication.runningApplications(
            withBundleIdentifier: LazyQuipsLaunchConfiguration.mainAppBundleIdentifier
        ).isEmpty else {
            return
        }

        let helperBundleURL = Bundle.main.bundleURL
        let mainAppURL = helperBundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let launchAtLoginURL = URL(
            string: "\(LazyQuipsLaunchConfiguration.launchReasonURLScheme)://\(LazyQuipsLaunchConfiguration.launchAtLoginURLHost)"
        )!
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false

        NSApplication.shared.setActivationPolicy(.prohibited)
        NSWorkspace.shared.open(
            [launchAtLoginURL],
            withApplicationAt: mainAppURL,
            configuration: configuration
        ) { _, _ in
            NSApp.terminate(nil)
        }
        NSApp.run()
    }
}
