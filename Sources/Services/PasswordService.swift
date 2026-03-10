import Core
import Foundation

public final class PasswordService: @unchecked Sendable {
    private let keychain: KeychainStore

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    public func hasPassword() -> Bool {
        (try? keychain.loadPasswordRecord()) != nil
    }

    public func createPassword(_ password: String) throws {
        let record = try PasswordHasher.createRecord(password: password)
        try keychain.savePasswordRecord(record)
    }

    public func verify(_ password: String) throws -> Bool {
        guard let record = try keychain.loadPasswordRecord() else {
            return false
        }
        return try PasswordHasher.verify(password: password, against: record)
    }

    public func resetPassword(_ newPassword: String) throws {
        let record = try PasswordHasher.createRecord(password: newPassword)
        try keychain.savePasswordRecord(record)
    }
}
