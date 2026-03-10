import CommonCrypto
import Foundation
import Security

public enum PasswordHasher {
    public static let defaultIterations = 310_000
    private static let keyLength = 32
    private static let saltLength = 16

    public static func validatePolicy(_ password: String) -> Bool {
        guard (8...64).contains(password.count) else { return false }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }

    public static func createRecord(password: String, iterations: Int = defaultIterations) throws -> PasswordRecord {
        guard validatePolicy(password) else {
            throw AppError.invalidPasswordPolicy
        }

        var salt = Data(count: saltLength)
        let status = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, saltLength, bytes.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw AppError.failedToGenerateSalt
        }

        let hash = try deriveKey(password: password, salt: salt, iterations: iterations)
        return PasswordRecord(
            saltBase64: salt.base64EncodedString(),
            iterations: iterations,
            hashBase64: hash.base64EncodedString()
        )
    }

    public static func verify(password: String, against record: PasswordRecord) throws -> Bool {
        guard
            let salt = Data(base64Encoded: record.saltBase64),
            let expectedHash = Data(base64Encoded: record.hashBase64)
        else {
            throw AppError.invalidStoredPasswordRecord
        }

        let actualHash = try deriveKey(password: password, salt: salt, iterations: record.iterations)
        return constantTimeEqual(actualHash, expectedHash)
    }

    private static func deriveKey(password: String, salt: Data, iterations: Int) throws -> Data {
        var key = Data(repeating: 0, count: keyLength)
        let passwordData = Data(password.utf8)

        let derivationStatus = key.withUnsafeMutableBytes { keyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        keyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }

        guard derivationStatus == kCCSuccess else {
            throw AppError.invalidStoredPasswordRecord
        }

        return key
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<lhs.count {
            diff |= lhs[i] ^ rhs[i]
        }
        return diff == 0
    }
}
