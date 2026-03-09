import Foundation

/// Forecasts end-of-window usage by linearly extending the current observed burn rate.
public struct UsageProjection: Sendable, Equatable {
    public let actualUsedPercent: Double
    public let projectedUsedPercentAtReset: Double
    public let projectedRemainingPercentAtReset: Double
    public let isProjectedToOverflow: Bool
    public let elapsedSeconds: TimeInterval
    public let remainingSeconds: TimeInterval

    public init(
        actualUsedPercent: Double,
        projectedUsedPercentAtReset: Double,
        projectedRemainingPercentAtReset: Double,
        isProjectedToOverflow: Bool,
        elapsedSeconds: TimeInterval,
        remainingSeconds: TimeInterval)
    {
        self.actualUsedPercent = actualUsedPercent
        self.projectedUsedPercentAtReset = projectedUsedPercentAtReset
        self.projectedRemainingPercentAtReset = projectedRemainingPercentAtReset
        self.isProjectedToOverflow = isProjectedToOverflow
        self.elapsedSeconds = elapsedSeconds
        self.remainingSeconds = remainingSeconds
    }

    public static func linear(
        window: RateWindow,
        now: Date = .init(),
        minimumElapsedSeconds: TimeInterval = 5 * 60) -> UsageProjection?
    {
        guard let resetsAt = window.resetsAt else { return nil }
        guard let minutes = window.windowMinutes else { return nil }
        guard minutes > 0 else { return nil }

        let duration = TimeInterval(minutes) * 60
        let remaining = resetsAt.timeIntervalSince(now)
        guard remaining > 0 else { return nil }
        guard remaining <= duration else { return nil }

        let elapsed = duration - remaining
        guard elapsed >= minimumElapsedSeconds else { return nil }

        let actual = max(0, window.usedPercent)
        let projectedUsed = actual == 0 ? 0 : actual + ((actual / elapsed) * remaining)
        let projectedRemaining = 100 - projectedUsed

        return UsageProjection(
            actualUsedPercent: actual,
            projectedUsedPercentAtReset: projectedUsed,
            projectedRemainingPercentAtReset: projectedRemaining,
            isProjectedToOverflow: projectedUsed > 100,
            elapsedSeconds: elapsed,
            remainingSeconds: remaining)
    }
}
