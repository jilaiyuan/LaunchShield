import Foundation

// Example bootstrap sequence to wire SMJobBless + XPC in the macOS app startup flow.
final class BootstrapExample {
    private let bootstrapController = HelperBootstrapController()

    func run() {
        do {
            try bootstrapController.installAndConnect()
            bootstrapController.client().ping { result in
                switch result {
                case .success(let text):
                    print("helper ping: \(text)")
                case .failure(let error):
                    print("helper ping failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("helper bootstrap failed: \(error.localizedDescription)")
        }
    }
}
