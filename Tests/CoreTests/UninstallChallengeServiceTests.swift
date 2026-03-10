import Core
import Foundation
import Services
import XCTest

final class UninstallChallengeServiceTests: XCTestCase {
    func testIssueAndConsumeChallenge() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let service = UninstallChallengeService(baseDirectory: dir)
        let challenge = try service.issue(validForSeconds: 60)
        XCTAssertFalse(challenge.isExpired)

        XCTAssertNoThrow(try service.validateAndConsume(nonce: challenge.nonce))
        XCTAssertThrowsError(try service.validateAndConsume(nonce: challenge.nonce))
    }

    func testExpiredChallengeFails() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let service = UninstallChallengeService(baseDirectory: dir)
        let challenge = try service.issue(validForSeconds: 0.01)
        usleep(30_000)

        XCTAssertThrowsError(try service.validateAndConsume(nonce: challenge.nonce)) { error in
            guard case AppError.uninstallChallengeExpired = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
