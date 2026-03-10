import Core
import XCTest

final class LaunchPolicyEvaluatorTests: XCTestCase {
    func testBlacklistedAppIsBlocked() {
        let evaluator = LaunchPolicyEvaluator()
        let policy = PolicySnapshot(blacklist: ["com.example.blocked"])

        let decision = evaluator.evaluate(bundleID: "com.example.blocked", pid: 10, policy: policy)

        switch decision {
        case .allow:
            XCTFail("Expected blocked decision")
        case .block(let reason):
            switch reason {
            case .blacklisted:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected reason")
            }
        }
    }

    func testPermitAllowsOnlyOnce() {
        let evaluator = LaunchPolicyEvaluator()
        let policy = PolicySnapshot(blacklist: ["com.example.blocked"])

        evaluator.addOneTimePermit(bundleID: "com.example.blocked", pid: 11)

        let first = evaluator.evaluate(bundleID: "com.example.blocked", pid: 11, policy: policy)
        let second = evaluator.evaluate(bundleID: "com.example.blocked", pid: 11, policy: policy)

        switch first {
        case .allow:
            XCTAssertTrue(true)
        case .block:
            XCTFail("Expected first decision to allow")
        }

        switch second {
        case .allow:
            XCTFail("Expected second decision to block")
        case .block:
            XCTAssertTrue(true)
        }
    }
}
