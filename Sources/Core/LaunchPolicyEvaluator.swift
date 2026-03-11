import Foundation

public final class LaunchPolicyEvaluator: @unchecked Sendable {
    private let lock = NSLock()
    private var permits: [String: OneTimePermit] = [:]

    public init() {}

    public func evaluate(bundleID: String?, pid: Int32, policy: PolicySnapshot, now: Date = Date(), calendar: Calendar = .current) -> LaunchDecision {
        guard let bundleID, !bundleID.isEmpty else {
            return .block(reason: .missingBundleID)
        }

        if policy.systemExemptions.contains(bundleID) {
            return .allow
        }

        if consumePermitIfExists(bundleID: bundleID, pid: pid) {
            return .allow
        }

        if policy.blacklist.contains(bundleID) {
            guard isInActiveBlockWindow(policy: policy, date: now, calendar: calendar) else {
                return .allow
            }
            return .block(reason: .blacklisted)
        }

        return .allow
    }

    public func addOneTimePermit(bundleID: String, pid: Int32) {
        let permit = OneTimePermit(bundleID: bundleID, pid: pid)
        lock.lock()
        permits[bundleID] = permit
        lock.unlock()
    }

    public func clearPermits() {
        lock.lock()
        permits.removeAll()
        lock.unlock()
    }

    private func consumePermitIfExists(bundleID: String, pid: Int32) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard var permit = permits[bundleID], !permit.consumed else {
            return false
        }

        guard permit.pid == pid else {
            // If PID changed due to relaunch, allow one launch for same bundle.
            permit.pid = pid
            permit.consumed = true
            permits[bundleID] = permit
            return true
        }

        permit.consumed = true
        permits[bundleID] = permit
        return true
    }

    private func isInActiveBlockWindow(policy: PolicySnapshot, date: Date, calendar: Calendar) -> Bool {
        let calendarWeekday = calendar.component(.weekday, from: date)
        guard let weekday = Weekday.from(calendarWeekday: calendarWeekday) else {
            return false
        }

        guard let window = policy.schedule.windows[weekday] else {
            return false
        }

        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let minuteOfDay = hour * 60 + minute
        guard window.startMinute < window.endMinute else {
            return false
        }
        return minuteOfDay >= window.startMinute && minuteOfDay < window.endMinute
    }
}
