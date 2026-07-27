import Foundation
import UIKit
import QuartzCore

/// Callbacks for a ``CHRadarGraphView``'s drawing lifecycle and user
/// interaction, mirroring `UITableViewDelegate`'s will/did pattern.
///
/// Every method has a default no-op implementation except the drawing
/// lifecycle ones, so a minimal conformer only needs to implement whichever
/// callbacks it actually cares about.
// AnyObject-constrained so CHRadarGraphView's internal coordinator can hold
// these weakly - without that, its stored closures/targets would strongly
// retain whatever implements them (typically a view controller), which is
// also often what stores the CHRadarGraphView itself, forming a retain cycle.
@MainActor
public protocol CHRadarGraphViewDelegate: AnyObject {

    /// Called immediately before ``CHRadarGraphView/reload()`` draws anything.
    func willDisplayGraph(_ graphView: CHRadarGraphView)
    /// Called after ``CHRadarGraphView/reload()`` has finished drawing.
    func didDisplayGraph(_ graphView: CHRadarGraphView)

    /// Called before a given ring (1...`numberOfRings`) is drawn.
    func willDisplayRing(_ graphView: CHRadarGraphView, index: Int)
    /// Called after a given ring (1...`numberOfRings`) is drawn.
    func didDisplayRing(_ graphView: CHRadarGraphView, index: Int)

    /// Called before a given data sector is drawn.
    func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)
    /// Called after a given data sector is drawn.
    func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

    /// A sector was selected, via tap or VoiceOver activation (double-tap).
    /// Opt-in - the default implementation does nothing.
    func didSelectSector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

    /// A tap landed within the graph's overall bounds but didn't correspond
    /// to any drawn sector - e.g. in the empty gap left when
    /// `numberOfDataSectors` < `numberOfSectors`, or past a short wedge's
    /// actual tip. Consumers commonly use this to clear whatever UI showed
    /// the last selection. Opt-in - the default implementation does nothing.
    func didTapOutsideSector(_ graphView: CHRadarGraphView)
}

// Both are opt-in: existing conformers don't have to implement them.
public extension CHRadarGraphViewDelegate {
    func didSelectSector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {}
    func didTapOutsideSector(_ graphView: CHRadarGraphView) {}
}

/// Supplies the geometry, styling, and per-sector content a
/// ``CHRadarGraphView`` draws, mirroring `UITableViewDataSource`.
@MainActor
public protocol CHRadarGraphViewDataSource: AnyObject {
    /// The graph's center, in the consumer's own view coordinate space (e.g.
    /// `view.bounds.midX`/`midY`).
    func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint
    /// The graph's overall radius, in points.
    func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat
    /// The height a sector needs to reach the full radius - the largest
    /// Y-value on a classic bar chart.
    func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat
    /// The total number of sector slots the circle is divided into - the
    /// data sectors plus any empty gap left for axis labels.
    func numberOfSectors(_ graphView: CHRadarGraphView) -> Int
    /// The number of slots (starting from index 0) that actually have data.
    /// Equal to `numberOfSectors` for a graph with no empty gap.
    func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int
    /// The number of concentric rings drawn to mark the height scale.
    func numberOfRings(_ graphView: CHRadarGraphView) -> Int
    /// The angle, in degrees, where sector index 0 begins. 0 is 3 o'clock;
    /// angles increase clockwise.
    func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat
    /// The cell (height, color, label) to draw at a given sector index, or
    /// `nil` for an empty slot.
    func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell?
    /// The color used to fill the thin dividing lines drawn between sectors.
    func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor
    /// The stroke color for the concentric rings.
    func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor
    /// The stroke width for the concentric rings.
    func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat
    /// The stroke color for the lines dividing each sector.
    func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor
    /// The stroke width for the lines dividing each sector.
    func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat

    /// What the graph's height/color encodes, e.g. "Number of GitHub PRs
    /// created". Shown in the empty gap left when `numberOfDataSectors` is
    /// less than `numberOfSectors`. Opt-in - `nil` (the default) draws
    /// nothing.
    func graphDescription(_ graphView: CHRadarGraphView) -> String?

    /// An optional label for a given ring (1...`numberOfRings`), e.g. "10",
    /// "20" to mark the height scale. Opt-in - returning `nil` for a given
    /// index (the default) skips that ring's label.
    func ringLabel(_ graphView: CHRadarGraphView, forRingIndex index: Int) -> String?

    /// The font for ``graphDescription(_:)``. Opt-in - defaults to a 22.5pt
    /// system font.
    func graphDescriptionFont(_ graphView: CHRadarGraphView) -> UIFont
    /// The text color for ``graphDescription(_:)``. Opt-in - defaults to a
    /// mid-gray.
    func graphDescriptionColor(_ graphView: CHRadarGraphView) -> UIColor

    /// The font for ``ringLabel(_:forRingIndex:)``. Opt-in - defaults to an
    /// 11pt system font.
    func ringLabelFont(_ graphView: CHRadarGraphView) -> UIFont
    /// The text color for ``ringLabel(_:forRingIndex:)``. Opt-in - defaults
    /// to a light gray.
    func ringLabelColor(_ graphView: CHRadarGraphView) -> UIColor
}

// All opt-in: existing conformers get no axis labels and the original
// hardcoded styling, same as before.
public extension CHRadarGraphViewDataSource {
    func graphDescription(_ graphView: CHRadarGraphView) -> String? { nil }
    func ringLabel(_ graphView: CHRadarGraphView, forRingIndex index: Int) -> String? { nil }
    func graphDescriptionFont(_ graphView: CHRadarGraphView) -> UIFont { .systemFont(ofSize: 22.5) }
    func graphDescriptionColor(_ graphView: CHRadarGraphView) -> UIColor { UIColor(white: 0.4, alpha: 1) }
    func ringLabelFont(_ graphView: CHRadarGraphView) -> UIFont { .systemFont(ofSize: 11) }
    func ringLabelColor(_ graphView: CHRadarGraphView) -> UIColor { UIColor(white: 0.55, alpha: 1) }
}

/// A radar (rose/polar) chart: a circle divided into sectors, each drawn out
/// from the center to a radius proportional to its data value.
///
/// This is a UIKit delegate/dataSource pair (mirroring `UITableView`), not a
/// `UIView` subclass itself - construct one with a delegate and dataSource,
/// add its ``view`` to your view hierarchy, and call ``reload()`` to draw.
/// For SwiftUI, use `CHRadarGraph` instead, which wraps this entire API
/// behind a single `View`.
@MainActor
public struct CHRadarGraphView {

    fileprivate let degreesOfCircle: CGFloat = 360

    /// The drawable view - add this to your view hierarchy. Its frame is
    /// computed from the dataSource's ``CHRadarGraphViewDataSource/centerOfGraph(_:)``
    /// and ``CHRadarGraphViewDataSource/radiusOfGraph(_:)`` at init time.
    public var view: UIView
    internal var delegate: CHRadarGraphViewDelegate
    internal var dataSource: CHRadarGraphViewDataSource
    internal var startAngle: CGFloat = 0
    internal var largestHeight: CGFloat = 0
    internal var numberOfRings: Int = 0
    internal var sectorsCount: CGFloat = 0
    internal var sectorsDataCount: CGFloat = 0
    internal var center: CGPoint = CGPoint.zero
    internal var radius: CGFloat = 0
    internal var size: CGSize = CGSize.zero
    internal var position: CGPoint = CGPoint.zero
    internal var backgroundColor: UIColor = UIColor()
    internal var strokeColorOfSectorLines: UIColor = UIColor()
    internal var strokeColorOfRings: UIColor = UIColor()
    internal var strokeWidthOfSectorLines: CGFloat = CGFloat()
    internal var strokeWidthOfRings: CGFloat = CGFloat()
    private let coordinator: SectorSelectionCoordinator

    /// Queries `dataSource` for the graph's geometry and creates ``view``
    /// at the resulting frame. Call ``reload()`` afterward to actually draw
    /// - nothing is drawn until then.
    public init(delegate: CHRadarGraphViewDelegate, dataSource: CHRadarGraphViewDataSource) {
        self.view = CHRadarGraphContentView(frame: CGRect.zero)
        self.coordinator = SectorSelectionCoordinator()
        self.delegate = delegate
        self.dataSource = dataSource
        startAngle = CHRadarGraphView.degreesToRadians(dataSource.startingAngleInDegrees(self))
        largestHeight = dataSource.largestHeightForSectorCell(self)
        numberOfRings = dataSource.numberOfRings(self)
        sectorsCount = CGFloat(dataSource.numberOfSectors(self))
        sectorsDataCount = CGFloat(dataSource.numberOfDataSectors(self))
        center = dataSource.centerOfGraph(self)
        radius = dataSource.radiusOfGraph(self)

        let x = center.x - radius
        let y = center.y - radius
        position = CGPoint(x: x, y: y)

        let width = center.x + radius - position.x
        let height = center.y + radius - position.y
        size = CGSize(width: width, height: height)

        // Every path/label drawn below uses coordinates relative to `center`,
        // which is itself expressed in the consumer's own view space (e.g.
        // view.bounds.midX/midY) - i.e. this view's local origin is assumed
        // to coincide with (0, 0) in that space. A zero-sized frame (the
        // previous value here) can never pass UIKit's touch hit-testing, so
        // it silently made every gesture recognizer on this view dead on
        // arrival even though everything still rendered correctly (CALayer
        // doesn't clip to bounds).
        //
        // Setting bounds.origin to `position` (which can be negative - the
        // circle's top-left corner is often above/left of `center`) rather
        // than assuming (0, 0), while keeping frame.origin equal to that same
        // `position` in the superview, preserves the "bounds-space equals
        // the consumer's absolute coordinate space" assumption exactly, for
        // any center/radius rather than only ones whose bounding box happens
        // to start at a non-negative position.
        self.view.bounds = CGRect(origin: position, size: size)
        self.view.center = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)

        backgroundColor = dataSource.backgroundColorOfGraph(self)
        strokeColorOfSectorLines = dataSource.strokeColorOfSectorLines(self)
        strokeWidthOfSectorLines = dataSource.strokeWidthOfSectorLines(self)
        strokeColorOfRings = dataSource.strokeColorOfRings(self)
        strokeWidthOfRings = dataSource.strokeWidthOfRings(self)

        // The coordinator must not hold a strong reference (directly or
        // transitively) back to itself or to `view` - capturing this whole
        // struct in a stored closure would do exactly that, since the struct
        // itself carries `coordinator` (and `view`) as one of its own
        // properties. It holds the plain values it needs directly, and only
        // ever reaches `view`/`dataSource`/`delegate` weakly, so it never
        // keeps the graph's view - or the consumer that owns both - alive
        // past their natural lifetime.
        coordinator.view = view
        coordinator.dataSource = dataSource
        coordinator.delegate = delegate
        coordinator.startAngle = startAngle
        coordinator.largestHeight = largestHeight
        coordinator.numberOfRings = numberOfRings
        coordinator.sectorsCount = sectorsCount
        coordinator.sectorsDataCount = sectorsDataCount
        coordinator.center = center
        coordinator.radius = radius
        coordinator.size = size
        coordinator.position = position
        coordinator.backgroundColor = backgroundColor
        coordinator.strokeColorOfSectorLines = strokeColorOfSectorLines
        coordinator.strokeColorOfRings = strokeColorOfRings
        coordinator.strokeWidthOfSectorLines = strokeWidthOfSectorLines
        coordinator.strokeWidthOfRings = strokeWidthOfRings
        view.addGestureRecognizer(UITapGestureRecognizer(target: coordinator, action: #selector(SectorSelectionCoordinator.handleTap(_:))))

        // Colors captured above (backgroundColor, strokeColorOfRings, etc.)
        // may be dynamic UIColors (e.g. .systemBackground) - if so their
        // .cgColor only resolves to the right appearance for whatever
        // UITraitCollection.current is at the moment reload() runs. A light-
        // mode graph that's never told about a later switch to dark mode
        // would otherwise keep drawing with light-mode colors forever.
        // Capturing `coordinator` (not `self`/`view` directly) here follows
        // the same weak-back-reference ownership as the tap gesture above:
        // view -> this closure -> coordinator (strong), coordinator -> view
        // (weak), so this never keeps the view alive past its natural
        // lifetime either.
        (self.view as? CHRadarGraphContentView)?.onTraitCollectionChange = { [coordinator] in
            coordinator.handleTraitChange()
        }
    }

    // A lightweight reconstruction used only to hand the delegate/dataSource
    // a CHRadarGraphView value from within SectorSelectionCoordinator, without
    // capturing the original (which would reintroduce the retain cycle this
    // type exists to avoid). Takes the SAME coordinator that built it (not a
    // fresh one) - reload(), called through this handoff for a trait-driven
    // redraw, rebuilds each sector's accessibility element with an
    // onActivate closure that captures self.coordinator; a fresh, unwired
    // coordinator there would make VoiceOver activation silently no-op
    // (its weak view/dataSource/delegate would all be nil) for every sector
    // drawn after the first light/dark mode switch.
    fileprivate init(
        view: UIView, delegate: CHRadarGraphViewDelegate, dataSource: CHRadarGraphViewDataSource,
        coordinator: SectorSelectionCoordinator,
        startAngle: CGFloat, largestHeight: CGFloat, numberOfRings: Int,
        sectorsCount: CGFloat, sectorsDataCount: CGFloat, center: CGPoint, radius: CGFloat,
        size: CGSize, position: CGPoint, backgroundColor: UIColor,
        strokeColorOfSectorLines: UIColor, strokeColorOfRings: UIColor,
        strokeWidthOfSectorLines: CGFloat, strokeWidthOfRings: CGFloat
    ) {
        self.view = view
        self.coordinator = coordinator
        self.delegate = delegate
        self.dataSource = dataSource
        self.startAngle = startAngle
        self.largestHeight = largestHeight
        self.numberOfRings = numberOfRings
        self.sectorsCount = sectorsCount
        self.sectorsDataCount = sectorsDataCount
        self.center = center
        self.radius = radius
        self.size = size
        self.position = position
        self.backgroundColor = backgroundColor
        self.strokeColorOfSectorLines = strokeColorOfSectorLines
        self.strokeColorOfRings = strokeColorOfRings
        self.strokeWidthOfSectorLines = strokeWidthOfSectorLines
        self.strokeWidthOfRings = strokeWidthOfRings
    }

    // Inverse of drawPieChart's angle math: given a point in `view`'s own
    // coordinate space, find which (if any) data sector it falls inside -
    // both angularly and radially, so a tap past a short wedge's tip (but
    // still within the overall circle) correctly misses.
    func sector(at point: CGPoint) -> (CHSectorCell, Int)? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance <= radius, sectorsCount > 0 else { return nil }

        let twoPi = 2 * CGFloat.pi
        var rawAngle = atan2(dy, dx)
        if rawAngle < 0 { rawAngle += twoPi }
        var relativeAngle = (rawAngle - startAngle).truncatingRemainder(dividingBy: twoPi)
        if relativeAngle < 0 { relativeAngle += twoPi }

        let sectorAngleWidth = twoPi / sectorsCount
        let index = Int(relativeAngle / sectorAngleWidth)
        guard index >= 0, CGFloat(index) < sectorsDataCount,
              let cell = dataSource.sectorCellForPositionAtIndex(self, index: index) else { return nil }

        let pathRadius = (cell.height / largestHeight) * radius
        guard distance <= pathRadius else { return nil }
        return (cell, index)
    }

    /// Draws (or redraws) the graph into ``view``: rings, sectors, dividers,
    /// and axis labels, using the current values from `dataSource`. Safe to
    /// call more than once - each call replaces the previous drawing rather
    /// than stacking on top of it.
    ///
    /// > Warning: This removes every sublayer and subview of ``view`` first,
    /// > including any you may have added directly rather than through
    /// > `dataSource`. It's also called automatically on a light/dark mode
    /// > switch, so don't add your own content straight onto ``view``.
    public func reload() {
        delegate.willDisplayGraph(self)
        let endAngle = startAngle + CGFloat(sectorsDataCount) * CHRadarGraphView.degreesToRadians(CGFloat(self.degreesOfCircle / self.sectorsCount))

        // reload() can now run more than once against the same view (e.g. a
        // trait collection change re-triggers it) - drawRings/drawPieChart/
        // drawSectors/drawAxisLabels only ever add sublayers/subviews, so
        // without clearing first, every call after the first would stack a
        // second copy on top of the last instead of replacing it.
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        view.subviews.forEach { $0.removeFromSuperview() }

        drawRings(endAngle)
        drawPieChart()
        drawSectors()
        drawAxisLabels()
        delegate.didDisplayGraph(self)
    }

    // Circles
    func drawRings(_ endAngle: CGFloat) {
        if numberOfRings < 1 {
            return
        }

        for index in 1...numberOfRings {
            delegate.willDisplayRing(self, index: index)
            let pathRadius = (CGFloat(index) / CGFloat(numberOfRings)) * radius
            let path = buildPath(pathRadius, startAngle: startAngle, endAngle: endAngle)
            let shape = buildShape(path, fillColor: UIColor.clear.cgColor, strokeColor: strokeColorOfRings.cgColor, lineWidth: strokeWidthOfRings)
            view.layer.addSublayer(shape)
            delegate.didDisplayRing(self, index: index)
        }
    }

    // Places graphDescription and any per-ring labels in the empty gap left
    // when numberOfDataSectors < numberOfSectors. The gap's center is always
    // directly opposite the midpoint of the drawn data arc, regardless of
    // where startingAngleInDegrees put it, so this works for any consumer's
    // angle choice rather than assuming a fixed direction.
    func drawAxisLabels() {
        guard sectorsDataCount < sectorsCount else { return }

        let dataSweep = sectorsDataCount * (CHRadarGraphView.degreesToRadians(degreesOfCircle) / sectorsCount)
        let gapCenterAngle = startAngle + dataSweep / 2 + .pi
        let gapAngleWidth = (CHRadarGraphView.degreesToRadians(degreesOfCircle)) - dataSweep

        func point(atRadius r: CGFloat) -> CGPoint {
            CGPoint(x: center.x + r * cos(gapCenterAngle), y: center.y + r * sin(gapCenterAngle))
        }

        func availableWidth(atRadius r: CGFloat) -> CGFloat {
            2 * r * tan(min(gapAngleWidth / 2, .pi / 2 - 0.01)) * 0.85
        }

        if numberOfRings > 0 {
            let ringFont = dataSource.ringLabelFont(self)
            let ringColor = dataSource.ringLabelColor(self)
            for index in 1...numberOfRings {
                guard let text = dataSource.ringLabel(self, forRingIndex: index) else { continue }
                let ringRadius = (CGFloat(index) / CGFloat(numberOfRings)) * radius
                addLabel(text, center: point(atRadius: ringRadius), width: availableWidth(atRadius: ringRadius), font: ringFont, color: ringColor)
            }
        }

        if let description = dataSource.graphDescription(self) {
            let descriptionRadius = radius * 0.6
            addLabel(description, center: point(atRadius: descriptionRadius), width: min(radius * 1.1, availableWidth(atRadius: descriptionRadius)), font: dataSource.graphDescriptionFont(self), color: dataSource.graphDescriptionColor(self))
        }
    }

    private func addLabel(_ text: String, center labelCenter: CGPoint, width: CGFloat, font: UIFont, color: UIColor) {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        label.frame = CGRect(x: 0, y: 0, width: max(width, 0), height: 0)
        label.sizeToFit()
        label.frame.size.width = max(width, 0)
        label.center = labelCenter
        view.addSubview(label)
    }

    // Divisions
    func drawSectors() {
        for index in 0...Int(sectorsDataCount) {
            let path = UIBezierPath(rect: CGRect(x: center.x, y: center.y, width: radius, height: 0.1))
            var transform = CGAffineTransform.identity;
            transform = transform.translatedBy(x: center.x, y: center.y);
            transform = transform.rotated(by: startAngle + CHRadarGraphView.degreesToRadians(CGFloat(CGFloat(index) * (degreesOfCircle / sectorsCount))));
            transform = transform.translatedBy(x: -center.x, y: -center.y);
            path.apply(transform)

            let shape = buildShape(path, fillColor: backgroundColor.cgColor, strokeColor: strokeColorOfSectorLines.cgColor, lineWidth: strokeWidthOfSectorLines)
            view.layer.addSublayer(shape)
        }
    }

    // Content
    func drawPieChart() {
        if sectorsDataCount < 1 {
            return
        }

        var angle = startAngle
        var accessibilityElements: [UIAccessibilityElement] = []
        for index in 0...Int(sectorsDataCount) - 1 {
            // Declared fresh inside the loop body (unlike a `var` declared
            // above the loop and reassigned each iteration) so the closure
            // below captures this iteration's cell, not whatever the last
            // iteration left behind.
            let sectorCell = dataSource.sectorCellForPositionAtIndex(self, index: index)!
            delegate.willDisplaySector(self, sector: sectorCell, index: index)
            let height = CGFloat(sectorCell.height)

            let pathRadius = (height / largestHeight) * radius
            let sectorAngle = (1 / CGFloat(sectorsCount)) * CHRadarGraphView.degreesToRadians(degreesOfCircle)
            let path = buildPath(pathRadius, startAngle: angle, endAngle: angle + sectorAngle)

            // Create Shape
            let shape = buildShape(path, fillColor: sectorCell.backgroundColor, strokeColor: nil, lineWidth: nil)
            view.layer.addSublayer(shape)
            angle += sectorAngle

            // Create Label
            let distantX = center.x + (radius + 30) * cos(angle - CHRadarGraphView.degreesToRadians(4)) - 26
            let distantY = center.y + (radius + 30) * sin(angle - CHRadarGraphView.degreesToRadians(3)) - 11
            let label = UILabel()
            label.frame.origin = CGPoint(x: distantX, y: distantY)
            label.text = sectorCell.label?.text ?? ""
            label.textAlignment = .right
            // Falls back to explicit black (CHSectorLabel's own default)
            // rather than leaving UILabel's default textColor in place -
            // that default is the dynamic .label color, which resolves to
            // white in dark mode and would go invisible against a sector
            // background that a consumer has drawn with static light colors.
            label.textColor = sectorCell.label?.color.map { UIColor(cgColor: $0) } ?? .black
            let sectorLabelFontSize = sectorCell.label?.fontSize ?? 12.0
            label.font = sectorCell.label?.isBold == true
                ? .boldSystemFont(ofSize: sectorLabelFontSize)
                : .systemFont(ofSize: sectorLabelFontSize)
            label.sizeToFit()
            label.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.addSubview(label)

            // Expose each sector to VoiceOver as its own element - without
            // this, the whole graph is a single opaque image with no
            // semantic content for a screen reader. Double-tap activation
            // routes through the same coordinator (and hence the same
            // didSelectSector callback) a sighted user's tap gesture uses -
            // capturing `coordinator` here (not `self`/`delegate` directly)
            // avoids retaining `view` through the closure this element's
            // `onActivate` is stored on (view.accessibilityElements), which
            // would otherwise be its own separate retain cycle.
            let element = SectorAccessibilityElement(accessibilityContainer: view)
            element.accessibilityFrameInContainerSpace = path.cgPath.boundingBoxOfPath
            element.accessibilityLabel = sectorCell.label?.text
            element.accessibilityValue = "\(formatted(height)) of \(formatted(largestHeight))"
            element.accessibilityTraits = .button
            element.onActivate = { [coordinator] in
                coordinator.select(sector: sectorCell, index: index)
            }
            accessibilityElements.append(element)

            delegate.didDisplaySector(self, sector: sectorCell, index: index)
        }
        view.isAccessibilityElement = false
        view.accessibilityElements = accessibilityElements
    }

    private func formatted(_ value: CGFloat) -> String {
        value == value.rounded() ? "\(Int(value))" : "\(value)"
    }

    func buildPath(_ radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.move(to: center)
        path.close()
        return path
    }

    func buildShape(_ path: UIBezierPath, fillColor: CGColor?, strokeColor: CGColor?, lineWidth: CGFloat?) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = path.cgPath

        if let fc = fillColor {
            shape.fillColor = fc
        }

        if let sc = strokeColor {
            shape.strokeColor = sc
        }

        if let lw = lineWidth {
            shape.lineWidth = lw
        }
        return shape
    }

    static func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * (CGFloat(Double.pi) / (360 / 2))
    }

}

// Bridges both interaction paths (tap gesture + VoiceOver activation) to the
// delegate. Lives outside CHRadarGraphView's own stored-property graph on
// purpose: it holds `view`/`dataSource`/`delegate` weakly and everything
// else by plain value, so it never keeps the graph's view - or whatever
// consumer owns both it and the CHRadarGraphView itself - alive past their
// natural lifetime. (An earlier version captured the whole CHRadarGraphView
// struct in a stored closure, which - since that struct carries this very
// coordinator as one of its own properties - retained itself forever.)
@MainActor
private final class SectorSelectionCoordinator: NSObject {
    weak var view: UIView?
    weak var dataSource: CHRadarGraphViewDataSource?
    weak var delegate: CHRadarGraphViewDelegate?
    var startAngle: CGFloat = 0
    var largestHeight: CGFloat = 0
    var numberOfRings: Int = 0
    var sectorsCount: CGFloat = 0
    var sectorsDataCount: CGFloat = 0
    var center: CGPoint = .zero
    var radius: CGFloat = 0
    var size: CGSize = .zero
    var position: CGPoint = .zero
    var backgroundColor: UIColor = .clear
    var strokeColorOfSectorLines: UIColor = .clear
    var strokeColorOfRings: UIColor = .clear
    var strokeWidthOfSectorLines: CGFloat = 0
    var strokeWidthOfRings: CGFloat = 0

    private func makeHandoff() -> CHRadarGraphView? {
        guard let view, let dataSource, let delegate else { return nil }
        return CHRadarGraphView(
            view: view, delegate: delegate, dataSource: dataSource, coordinator: self,
            startAngle: startAngle, largestHeight: largestHeight, numberOfRings: numberOfRings,
            sectorsCount: sectorsCount, sectorsDataCount: sectorsDataCount, center: center, radius: radius,
            size: size, position: position, backgroundColor: backgroundColor,
            strokeColorOfSectorLines: strokeColorOfSectorLines, strokeColorOfRings: strokeColorOfRings,
            strokeWidthOfSectorLines: strokeWidthOfSectorLines, strokeWidthOfRings: strokeWidthOfRings
        )
    }

    func select(sector: CHSectorCell, index: Int) {
        guard let handoff = makeHandoff() else { return }
        delegate?.didSelectSector(handoff, sector: sector, index: index)
    }

    // reload() re-fetches each sector's cell (and hence its color) fresh from
    // the dataSource, but the graph-wide colors (background, ring/sector
    // stroke) were only ever captured once at init - if those are dynamic
    // UIColors, redrawing is exactly what makes their .cgColor re-resolve
    // for the new appearance.
    func handleTraitChange() {
        guard let handoff = makeHandoff() else { return }
        handoff.reload()
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let view, let handoff = makeHandoff() else { return }
        let point = recognizer.location(in: view)
        guard let (cell, index) = handoff.sector(at: point) else {
            delegate?.didTapOutsideSector(handoff)
            return
        }
        select(sector: cell, index: index)
    }
}

@MainActor
private final class SectorAccessibilityElement: UIAccessibilityElement {
    var onActivate: (() -> Void)?

    override func accessibilityActivate() -> Bool {
        guard let onActivate else { return false }
        onActivate()
        return true
    }
}

// The concrete type behind CHRadarGraphView.view (still exposed publicly as
// plain UIView) - exists solely to detect light/dark mode switches, which
// UIKit only reports via this override, not via any notification a struct
// could observe on its own.
@MainActor
private final class CHRadarGraphContentView: UIView {
    var onTraitCollectionChange: (() -> Void)?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection,
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        onTraitCollectionChange?()
    }
}
