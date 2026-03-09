import CodexBarCore
import Foundation

enum UsageProjectionText {
    static func summary(projection: UsageProjection, now _: Date = .init()) -> String {
        let percent = projection.projectedUsedPercentAtReset
        return String(format: "Forecast %.0f%% at reset", percent)
    }

    static func displayPercent(projection: UsageProjection, showUsed: Bool) -> Double {
        if showUsed {
            return projection.projectedUsedPercentAtReset
        }
        return projection.projectedRemainingPercentAtReset
    }
}
