import Core
import Foundation
import Security

public final class UninstallChallengeService: @unchecked Sendable {
    private struct StoredChallenge: Codable {
        let challenge: UninstallChallenge
        var consumed: Bool
    }

    private let challengeURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.launchshield.uninstallchallenge")

    public init(baseDirectory: URL? = nil) {
        let root = baseDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = root.appendingPathComponent("LaunchShield", isDirectory: true)
        self.challengeURL = appDir.appendingPathComponent("uninstall_challenge.json")
    }

    public func issue(validForSeconds: TimeInterval = 120) throws -> UninstallChallenge {
        let challenge = UninstallChallenge(
            nonce: Self.makeNonce(),
            issuedAt: Date(),
            expiresAt: Date().addingTimeInterval(validForSeconds)
        )
        try queue.sync {
            let dir = challengeURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let payload = StoredChallenge(challenge: challenge, consumed: false)
            let data = try encoder.encode(payload)
            try data.write(to: challengeURL, options: [.atomic])
        }
        return challenge
    }

    public func validateAndConsume(nonce: String) throws {
        try queue.sync {
            let data = try Data(contentsOf: challengeURL)
            var stored = try decoder.decode(StoredChallenge.self, from: data)

            guard stored.challenge.nonce == nonce else {
                throw AppError.uninstallChallengeInvalid
            }
            guard !stored.consumed else {
                throw AppError.uninstallChallengeInvalid
            }
            guard !stored.challenge.isExpired else {
                throw AppError.uninstallChallengeExpired
            }

            stored.consumed = true
            let encoded = try encoder.encode(stored)
            try encoded.write(to: challengeURL, options: [.atomic])
        }
    }

    public func clear() {
        queue.sync {
            try? FileManager.default.removeItem(at: challengeURL)
        }
    }

    private static func makeNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).map { String(format: "%02x", $0) }.joined()
    }
}
