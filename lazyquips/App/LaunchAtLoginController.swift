import Foundation
import ServiceManagement

enum LaunchAtLoginDisplayState: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

struct LaunchAtLoginService {
    let status: () -> SMAppService.Status
    let register: () throws -> Void
    let unregister: () throws -> Void

    init(service: SMAppService) {
        self.status = { service.status }
        self.register = {
            try service.register()
        }
        self.unregister = {
            try service.unregister()
        }
    }

    init(
        status: @escaping () -> SMAppService.Status,
        register: @escaping () throws -> Void,
        unregister: @escaping () throws -> Void
    ) {
        self.status = status
        self.register = register
        self.unregister = unregister
    }
}

final class LaunchAtLoginController {
    static let loginItemIdentifier = LazyQuipsLaunchConfiguration.loginItemBundleIdentifier
    static let shared = LaunchAtLoginController()

    private let serviceProvider: () -> LaunchAtLoginService

    init(
        serviceProvider: @escaping () -> LaunchAtLoginService = {
            LaunchAtLoginService(
                service: SMAppService.loginItem(
                    identifier: LaunchAtLoginController.loginItemIdentifier
                )
            )
        }
    ) {
        self.serviceProvider = serviceProvider
    }

    func currentState() -> LaunchAtLoginDisplayState {
        switch serviceProvider().status() {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        let service = serviceProvider()
        let status = service.status()

        if enabled {
            guard status != .enabled else {
                return
            }

            try service.register()
        } else {
            guard status != .notRegistered, status != .notFound else {
                return
            }

            try service.unregister()
        }
    }

    func ensureEnabledSilently() {
        let service = serviceProvider()
        guard service.status() == .notRegistered else {
            return
        }

        try? service.register()
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
