import SwiftUI

/// Static progress fill with no implicit animations, used inside the menu card.
struct UsageProgressBar: View {
    struct Overlay: Equatable {
        enum Style: Equatable {
            case pace(isDeficit: Bool)
            case forecast(isOverflow: Bool)
        }

        let percent: Double
        let style: Style

        static func pace(percent: Double?, onTop: Bool) -> Overlay? {
            guard let percent else { return nil }
            return Overlay(percent: percent, style: .pace(isDeficit: onTop == false))
        }

        static func forecast(percent: Double?, isOverflow: Bool) -> Overlay? {
            guard let percent else { return nil }
            return Overlay(percent: percent, style: .forecast(isOverflow: isOverflow))
        }
    }

    private static let overlayStripeCount = 3
    private static func overlayStripeWidth(for scale: CGFloat) -> CGFloat {
        2
    }

    private static func overlayStripeSpan(for scale: CGFloat) -> CGFloat {
        let stripeCount = max(1, Self.overlayStripeCount)
        return Self.overlayStripeWidth(for: scale) * CGFloat(stripeCount)
    }

    let percent: Double
    let tint: Color
    let accessibilityLabel: String
    let overlay: Overlay?
    @Environment(\.menuItemHighlighted) private var isHighlighted
    @Environment(\.displayScale) private var displayScale

    init(
        percent: Double,
        tint: Color,
        accessibilityLabel: String,
        overlay: Overlay? = nil)
    {
        self.percent = percent
        self.tint = tint
        self.accessibilityLabel = accessibilityLabel
        self.overlay = overlay
    }

    private var clamped: Double {
        min(100, max(0, self.percent))
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(self.displayScale, 1)
            let fillWidth = proxy.size.width * self.clamped / 100
            let overlayWidth = proxy.size.width * Self.clampedPercent(self.overlay?.percent) / 100
            let tipWidth = max(25, proxy.size.height * 6.5)
            let stripeInset = 1 / scale
            let tipOffset = overlayWidth - tipWidth + (Self.overlayStripeSpan(for: scale) / 2) + stripeInset
            let showTip = self.shouldShowOverlay && tipWidth > 0.5
            let needsPunchCompositing = showTip
            let bar = ZStack(alignment: .leading) {
                Capsule()
                    .fill(MenuHighlightStyle.progressTrack(self.isHighlighted))
                self.actualBar(width: fillWidth)
                if showTip {
                    self.overlayTip(width: tipWidth)
                        .offset(x: tipOffset)
                }
            }
            .clipped()
            if self.isHighlighted {
                bar
                    .compositingGroup()
                    .drawingGroup()
            } else if needsPunchCompositing {
                bar
                    .compositingGroup()
            } else {
                bar
            }
        }
        .frame(height: 6)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityValue("\(Int(self.clamped)) percent")
    }

    private func actualBar(width: CGFloat) -> some View {
        Capsule()
            .fill(MenuHighlightStyle.progressTint(self.isHighlighted, fallback: self.tint))
            .frame(width: width)
            .contentShape(Rectangle())
            .allowsHitTesting(false)
    }

    private var shouldShowOverlay: Bool {
        guard let overlay else { return false }
        switch overlay.style {
        case .pace:
            return true
        case .forecast:
            return abs(Self.clampedPercent(overlay.percent) - self.clamped) >= 0.5
        }
    }

    private func overlayTip(width: CGFloat) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rect = CGRect(origin: .zero, size: size)
            let scale = max(self.displayScale, 1)
            let stripes = Self.overlayStripePaths(size: size, scale: scale)
            let stripeColor = self.overlayStripeColor()

            ZStack {
                Canvas { context, _ in
                    context.clip(to: Path(rect))
                    context.fill(stripes.punched, with: .color(.white.opacity(0.9)))
                }
                .blendMode(.destinationOut)

                Canvas { context, _ in
                    context.clip(to: Path(rect))
                    context.fill(stripes.center, with: .color(stripeColor))
                }
            }
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .allowsHitTesting(false)
    }

    private func overlayStripeColor() -> Color {
        guard let overlay else { return .white }
        if self.isHighlighted {
            return .white
        }

        switch overlay.style {
        case let .pace(isDeficit):
            return isDeficit ? .red : .green
        case let .forecast(isOverflow):
            return isOverflow ? .red : self.tint
        }
    }

    private static func overlayStripePaths(size: CGSize, scale: CGFloat) -> (punched: Path, center: Path) {
        let rect = CGRect(origin: .zero, size: size)
        let extend = size.height * 2
        let stripeTopY: CGFloat = -extend
        let stripeBottomY: CGFloat = size.height + extend
        let align: (CGFloat) -> CGFloat = { value in
            (value * scale).rounded() / scale
        }

        let stripeWidth = Self.overlayStripeWidth(for: scale)
        let punchWidth = stripeWidth * 3
        let stripeInset = 1 / scale
        let stripeAnchorX = align(rect.maxX - stripeInset)
        let stripeMinY = align(stripeTopY)
        let stripeMaxY = align(stripeBottomY)
        let anchorTopX = stripeAnchorX
        var punchedStripe = Path()
        var centerStripe = Path()
        let availableWidth = (anchorTopX - punchWidth) - rect.minX
        guard availableWidth >= 0 else { return (punchedStripe, centerStripe) }

        let punchRightTopX = align(anchorTopX)
        let punchLeftTopX = punchRightTopX - punchWidth
        let punchRightBottomX = punchRightTopX
        let punchLeftBottomX = punchLeftTopX
        punchedStripe.addPath(Path { path in
            path.move(to: CGPoint(x: punchLeftTopX, y: stripeMinY))
            path.addLine(to: CGPoint(x: punchRightTopX, y: stripeMinY))
            path.addLine(to: CGPoint(x: punchRightBottomX, y: stripeMaxY))
            path.addLine(to: CGPoint(x: punchLeftBottomX, y: stripeMaxY))
            path.closeSubpath()
        })

        let centerLeftTopX = align(punchLeftTopX + (punchWidth - stripeWidth) / 2)
        let centerRightTopX = centerLeftTopX + stripeWidth
        let centerRightBottomX = centerRightTopX
        let centerLeftBottomX = centerLeftTopX
        centerStripe.addPath(Path { path in
            path.move(to: CGPoint(x: centerLeftTopX, y: stripeMinY))
            path.addLine(to: CGPoint(x: centerRightTopX, y: stripeMinY))
            path.addLine(to: CGPoint(x: centerRightBottomX, y: stripeMaxY))
            path.addLine(to: CGPoint(x: centerLeftBottomX, y: stripeMaxY))
            path.closeSubpath()
        })

        return (punchedStripe, centerStripe)
    }

    private static func clampedPercent(_ value: Double?) -> Double {
        guard let value else { return 0 }
        return min(100, max(0, value))
    }
}
