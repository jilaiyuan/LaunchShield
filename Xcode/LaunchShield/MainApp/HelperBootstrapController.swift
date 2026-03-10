import Foundation

final class HelperBootstrapController {
    private let blessingService = HelperBlessingService()
    private let xpcClient = HelperXPCClient()

    func installAndConnect() throws {
        try blessingService.blessHelper()
        xpcClient.connect()
    }

    func client() -> HelperXPCClient {
        xpcClient
    }
}
