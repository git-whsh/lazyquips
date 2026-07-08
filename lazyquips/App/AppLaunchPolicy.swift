import AppKit

enum LazyQuipsLaunchConfiguration {
    static let mainAppBundleIdentifier = "dev.lazyquips.public"
    static let loginItemBundleIdentifier = "dev.lazyquips.public.login-helper"
    static let launchReasonURLScheme = "lazyquips"
    static let launchAtLoginURLHost = "launch-at-login"
}

enum LazyQuipsLaunchIntent: Equatable {
    case userInitiated
    case loginItem

    init(
        openedURLs: [URL] = [],
        currentAppleEvent: NSAppleEventDescriptor? = NSAppleEventManager.shared().currentAppleEvent
    ) {
        let allOpenedURLs = openedURLs + Self.openedURLs(from: currentAppleEvent)
        self = allOpenedURLs.contains(where: Self.isLaunchAtLoginURL) ? .loginItem : .userInitiated
    }

    static func isLaunchAtLoginURL(_ url: URL) -> Bool {
        url.scheme == LazyQuipsLaunchConfiguration.launchReasonURLScheme
            && url.host == LazyQuipsLaunchConfiguration.launchAtLoginURLHost
    }

    private static func openedURLs(from event: NSAppleEventDescriptor?) -> [URL] {
        guard let event,
              event.eventClass == kInternetEventClass,
              event.eventID == kAEGetURL,
              let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return []
        }

        return [url]
    }
}

struct LazyQuipsLaunchPolicy: Equatable {
    let intent: LazyQuipsLaunchIntent

    var shouldShowMainWindowAfterLaunch: Bool {
        intent == .userInitiated
    }
}
