import Foundation

final class AdminUninstallController {
    private let client: HelperXPCClient

    init(client: HelperXPCClient) {
        self.client = client
    }

    func dryRunFullUninstall(completion: @escaping (Result<(removed: [String], failures: [String]), Error>) -> Void) {
        client.beginUninstall { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let challenge):
                self.client.performFullUninstall(challengeNonce: challenge.nonce, dryRun: true, completion: completion)
            }
        }
    }
}
