import Foundation

final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    private let service = HelperService()
    private let validator = AuthorizedClientValidator()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        guard validator.isAuthorized(connection: newConnection) else {
            NSLog("LaunchShield helper rejected unauthorized XPC client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: LaunchShieldXPCProtocol.self)
        newConnection.exportedObject = service
        newConnection.resume()
        return true
    }
}
