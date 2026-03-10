import Core
import Foundation

final class HelperXPCClient {
    private var connection: NSXPCConnection?

    func connect() {
        let conn = NSXPCConnection(machServiceName: XPCConstants.machServiceName, options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: LaunchShieldXPCProtocol.self)
        conn.invalidationHandler = { print("Helper XPC invalidated") }
        conn.interruptionHandler = { print("Helper XPC interrupted") }
        conn.resume()
        connection = conn
    }

    func disconnect() {
        connection?.invalidate()
        connection = nil
    }

    func ping(completion: @escaping (Result<String, Error>) -> Void) {
        guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ completion(.failure($0)) }) as? LaunchShieldXPCProtocol else {
            completion(.failure(NSError(domain: "xpc", code: 1, userInfo: [NSLocalizedDescriptionKey: "No XPC connection"])))
            return
        }
        proxy.ping { response in
            completion(.success(response))
        }
    }

    func queryProtectionState(completion: @escaping (Result<ProtectionState, Error>) -> Void) {
        guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ completion(.failure($0)) }) as? LaunchShieldXPCProtocol else {
            completion(.failure(NSError(domain: "xpc", code: 1, userInfo: [NSLocalizedDescriptionKey: "No XPC connection"])))
            return
        }

        proxy.queryProtectionState { data, errorText in
            if let errorText {
                completion(.failure(NSError(domain: "helper", code: 2, userInfo: [NSLocalizedDescriptionKey: errorText])))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "helper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing state payload"])))
                return
            }
            do {
                let state = try JSONDecoder().decode(ProtectionState.self, from: data)
                completion(.success(state))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func beginUninstall(completion: @escaping (Result<(nonce: String, expiresAt: Date), Error>) -> Void) {
        guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ completion(.failure($0)) }) as? LaunchShieldXPCProtocol else {
            completion(.failure(NSError(domain: "xpc", code: 1, userInfo: [NSLocalizedDescriptionKey: "No XPC connection"])))
            return
        }

        proxy.issueUninstallChallenge { nonce, expiresAt, errorText in
            if let errorText {
                completion(.failure(NSError(domain: "helper", code: 4, userInfo: [NSLocalizedDescriptionKey: errorText])))
                return
            }
            guard let nonce, let expiresAt else {
                completion(.failure(NSError(domain: "helper", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid challenge payload"])))
                return
            }
            completion(.success((nonce, expiresAt)))
        }
    }

    func performFullUninstall(challengeNonce: String, dryRun: Bool, completion: @escaping (Result<(removed: [String], failures: [String]), Error>) -> Void) {
        guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ completion(.failure($0)) }) as? LaunchShieldXPCProtocol else {
            completion(.failure(NSError(domain: "xpc", code: 1, userInfo: [NSLocalizedDescriptionKey: "No XPC connection"])))
            return
        }

        proxy.performFullUninstall(challengeNonce: challengeNonce, dryRun: dryRun) { success, removed, failures, errorText in
            if let errorText {
                completion(.failure(NSError(domain: "helper", code: 6, userInfo: [NSLocalizedDescriptionKey: errorText])))
                return
            }
            if !success && failures.isEmpty {
                completion(.failure(NSError(domain: "helper", code: 7, userInfo: [NSLocalizedDescriptionKey: "Uninstall failed without details"])))
                return
            }
            completion(.success((removed, failures)))
        }
    }
}
