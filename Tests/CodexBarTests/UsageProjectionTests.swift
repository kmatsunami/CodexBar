import CodexBarCore
import Foundation
import Testing

@Suite
struct UsageProjectionTests {
    @Test
    func linearProjection_computesProjectedOverrunFromCurrentRate() throws {
        let now = Date(timeIntervalSince1970: 0)
        let window = RateWindow(
            usedPercent: 50,
            windowMinutes: 10080,
            resetsAt: now.addingTimeInterval(4 * 24 * 3600),
            resetDescription: nil)

        let projection = try #require(UsageProjection.linear(window: window, now: now))

        #expect(projection.actualUsedPercent == 50)
        #expect(abs(projection.projectedUsedPercentAtReset - 116.667) < 0.01)
        #expect(abs(projection.projectedRemainingPercentAtReset + 16.667) < 0.01)
        #expect(projection.isProjectedToOverflow)
        #expect(abs(projection.elapsedSeconds - (3 * 24 * 3600)) < 1)
        #expect(abs(projection.remainingSeconds - (4 * 24 * 3600)) < 1)
    }

    @Test
    func linearProjection_returnsInRangeForecastWhenBurnRateFitsWindow() throws {
        let now = Date(timeIntervalSince1970: 0)
        let window = RateWindow(
            usedPercent: 20,
            windowMinutes: 10080,
            resetsAt: now.addingTimeInterval(4 * 24 * 3600),
            resetDescription: nil)

        let projection = try #require(UsageProjection.linear(window: window, now: now))

        #expect(abs(projection.projectedUsedPercentAtReset - 46.667) < 0.01)
        #expect(abs(projection.projectedRemainingPercentAtReset - 53.333) < 0.01)
        #expect(projection.isProjectedToOverflow == false)
    }

    @Test
    func linearProjection_keepsZeroUsageAtZeroAfterMinimumElapsed() throws {
        let now = Date(timeIntervalSince1970: 0)
        let window = RateWindow(
            usedPercent: 0,
            windowMinutes: 10080,
            resetsAt: now.addingTimeInterval(4 * 24 * 3600),
            resetDescription: nil)

        let projection = try #require(UsageProjection.linear(window: window, now: now))

        #expect(projection.actualUsedPercent == 0)
        #expect(projection.projectedUsedPercentAtReset == 0)
        #expect(projection.projectedRemainingPercentAtReset == 100)
        #expect(projection.isProjectedToOverflow == false)
    }

    @Test
    func linearProjection_returnsExactHundredWhenRateEndsAtLimit() throws {
        let now = Date(timeIntervalSince1970: 0)
        let window = RateWindow(
            usedPercent: 25,
            windowMinutes: 100,
            resetsAt: now.addingTimeInterval(75 * 60),
            resetDescription: nil)

        let projection = try #require(
            UsageProjection.linear(
                window: window,
                now: now,
                minimumElapsedSeconds: 60))

        #expect(projection.projectedUsedPercentAtReset == 100)
        #expect(projection.projectedRemainingPercentAtReset == 0)
        #expect(projection.isProjectedToOverflow == false)
    }

    @Test
    func linearProjection_hidesWhenTimingInfoIsMissingOrOutsideWindow() {
        let now = Date(timeIntervalSince1970: 0)
        let missingReset = RateWindow(
            usedPercent: 10,
            windowMinutes: 10080,
            resetsAt: nil,
            resetDescription: nil)
        let missingWindow = RateWindow(
            usedPercent: 10,
            windowMinutes: nil,
            resetsAt: now.addingTimeInterval(2 * 24 * 3600),
            resetDescription: nil)
        let tooFar = RateWindow(
            usedPercent: 10,
            windowMinutes: 10080,
            resetsAt: now.addingTimeInterval(9 * 24 * 3600),
            resetDescription: nil)

        #expect(UsageProjection.linear(window: missingReset, now: now) == nil)
        #expect(UsageProjection.linear(window: missingWindow, now: now) == nil)
        #expect(UsageProjection.linear(window: tooFar, now: now) == nil)
    }

    @Test
    func linearProjection_hidesWhenElapsedTimeIsBelowStabilityThreshold() {
        let now = Date(timeIntervalSince1970: 0)
        let window = RateWindow(
            usedPercent: 1,
            windowMinutes: 60,
            resetsAt: now.addingTimeInterval(56 * 60),
            resetDescription: nil)

        let projection = UsageProjection.linear(
            window: window,
            now: now,
            minimumElapsedSeconds: 5 * 60)

        #expect(projection == nil)
    }
}
