import Core
import XCTest

final class LaunchPolicyEvaluatorTests: XCTestCase {
    func testBlacklistedAppIsBlocked() {
        let evaluator = LaunchPolicyEvaluator()
        let fullWeekWindows = Dictionary(uniqueKeysWithValues: Weekday.allCases.map {
            ($0, BlockTimeWindow(startMinute: 0, endMinute: 1_440))
        })
        let policy = PolicySnapshot(
            blacklist: ["com.example.blocked"],
            schedule: WeeklyBlockSchedule(windows: fullWeekWindows)
        )

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
        let fullWeekWindows = Dictionary(uniqueKeysWithValues: Weekday.allCases.map {
            ($0, BlockTimeWindow(startMinute: 0, endMinute: 1_440))
        })
        let policy = PolicySnapshot(
            blacklist: ["com.example.blocked"],
            schedule: WeeklyBlockSchedule(windows: fullWeekWindows)
        )

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

    func testBlacklistedAppOutsideScheduleIsAllowed() {
        let evaluator = LaunchPolicyEvaluator()
        let schedule = WeeklyBlockSchedule(
            windows: [
                .monday: BlockTimeWindow(startMinute: 540, endMinute: 1_260)
            ]
        )
        let policy = PolicySnapshot(
            blacklist: ["com.example.blocked"],
            schedule: schedule
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let outsideTime = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 9, // Monday
            hour: 22,
            minute: 0
        ))!

        let decision = evaluator.evaluate(
            bundleID: "com.example.blocked",
            pid: 12,
            policy: policy,
            now: outsideTime,
            calendar: calendar
        )

        switch decision {
        case .allow:
            XCTAssertTrue(true)
        case .block:
            XCTFail("Expected allowed decision outside schedule")
        }
    }

    func testBlacklistedAppInsideScheduleIsBlocked() {
        let evaluator = LaunchPolicyEvaluator()
        let schedule = WeeklyBlockSchedule(
            windows: [
                .monday: BlockTimeWindow(startMinute: 540, endMinute: 1_260)
            ]
        )
        let policy = PolicySnapshot(
            blacklist: ["com.example.blocked"],
            schedule: schedule
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let insideTime = calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 9, // Monday
            hour: 10,
            minute: 30
        ))!

        let decision = evaluator.evaluate(
            bundleID: "com.example.blocked",
            pid: 13,
            policy: policy,
            now: insideTime,
            calendar: calendar
        )

        switch decision {
        case .allow:
            XCTFail("Expected blocked decision inside schedule")
        case .block(let reason):
            switch reason {
            case .blacklisted:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected reason")
            }
        }
    }
}
