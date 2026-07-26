import SwiftUI

// A SwiftUI-native entry point. CHRadarGraphView's own API is a UIKit
// delegate/dataSource pair (~15 methods, mirroring UITableViewDataSource) -
// exactly the pattern SwiftUI has no idiomatic way to consume. This wraps
// that whole mechanism behind a single `View` that just takes a plain array
// of sectors, absorbing all delegate/dataSource conformance into a private
// Coordinator so nobody using this has to implement it themselves.
//
// This is intentionally a slice of what the UIKit API can do (a full circle
// or a fixed-size gap, one title, no per-ring labels) rather than a 1:1
// mirror of every CHRadarGraphViewDataSource method - reach for
// CHRadarGraphView directly (see the Example target) for anything this
// doesn't cover, e.g. ring labels or a custom gap-centering angle.
/// A SwiftUI radar (rose/polar) chart - the SwiftUI-native counterpart to
/// ``CHRadarGraphView``, for callers who'd rather pass an array of sectors
/// than implement ``CHRadarGraphViewDataSource``/``CHRadarGraphViewDelegate``.
///
/// ```swift
/// CHRadarGraph(
///     sectors: [.init(height: 3, label: "Mon", color: .blue)],
///     title: "PRs created",
///     onSelect: { sector, index in ... }
/// )
/// .frame(maxWidth: .infinity, maxHeight: .infinity)
/// ```
///
/// > Important: The underlying `UIView` has no intrinsic content size, so
/// > give it an explicit frame (as above) or place it somewhere that already
/// > constrains its size - otherwise SwiftUI collapses it to zero size.
///
/// This covers the common case (one title, a fixed gap, no per-ring labels)
/// - reach for ``CHRadarGraphView`` directly for anything it doesn't cover,
/// such as ring labels or a custom gap-centering angle.
@available(iOS 14.0, *)
public struct CHRadarGraph: UIViewRepresentable {

    /// A single data point: how far it reaches, an optional label, and its
    /// color.
    public struct Sector: Equatable {
        /// The sector's data value, relative to ``CHRadarGraph/maxHeight``.
        public var height: CGFloat
        /// An optional label drawn just past the sector's outer edge.
        public var label: String?
        /// The sector's fill color.
        public var color: Color

        public init(height: CGFloat, label: String? = nil, color: Color) {
            self.height = height
            self.label = label
            self.color = color
        }
    }

    /// The data points to draw, one per sector.
    public var sectors: [Sector]
    // Leaves an empty gap when larger than sectors.count, matching
    // CHRadarGraphViewDataSource.numberOfSectors vs numberOfDataSectors -
    // nil (the default) fills the whole circle with `sectors`.
    /// The total number of sector slots around the circle. `nil` (the
    /// default) fills the whole circle with `sectors`; a larger value
    /// leaves an empty gap (see ``title``).
    public var totalSectorSlots: Int?
    // nil (the default) uses the tallest sector's height, so every sector
    // reaches a sensible fraction of the radius without the caller having
    // to know the others' heights up front.
    /// The height that reaches the full radius. `nil` (the default) uses the
    /// tallest sector's own height.
    public var maxHeight: CGFloat?
    /// The number of concentric rings drawn to mark the height scale.
    public var numberOfRings: Int
    // 0 = 3 o'clock, increasing clockwise (matches CHRadarGraphView's raw
    // convention) - -90 is a common choice to start at 12 o'clock instead.
    /// The angle, in degrees, where the first sector begins. 0 is 3 o'clock;
    /// angles increase clockwise. Defaults to -90 (12 o'clock).
    public var startingAngleInDegrees: CGFloat
    /// The color used to fill the thin dividing lines drawn between sectors.
    public var backgroundColor: Color
    /// The stroke color for the concentric rings.
    public var ringColor: Color
    /// The stroke color for the lines dividing each sector.
    public var sectorLineColor: Color
    /// A title drawn in the empty gap left when `totalSectorSlots` is larger
    /// than `sectors.count`. `nil` (the default) draws nothing.
    public var title: String?
    /// Called when a sector is selected, via tap or VoiceOver activation.
    public var onSelect: ((Sector, Int) -> Void)?
    /// Called when a tap lands within the graph but doesn't correspond to
    /// any drawn sector - e.g. the empty gap, or past a short wedge's actual
    /// tip. Commonly used to clear whatever UI showed the last selection.
    public var onDeselectAll: (() -> Void)?

    public init(
        sectors: [Sector],
        totalSectorSlots: Int? = nil,
        maxHeight: CGFloat? = nil,
        numberOfRings: Int = 10,
        startingAngleInDegrees: CGFloat = -90,
        backgroundColor: Color = Color(white: 1),
        ringColor: Color = Color(white: 0.93),
        sectorLineColor: Color = Color(white: 0.93),
        title: String? = nil,
        onSelect: ((Sector, Int) -> Void)? = nil,
        onDeselectAll: (() -> Void)? = nil
    ) {
        self.sectors = sectors
        self.totalSectorSlots = totalSectorSlots
        self.maxHeight = maxHeight
        self.numberOfRings = numberOfRings
        self.startingAngleInDegrees = startingAngleInDegrees
        self.backgroundColor = backgroundColor
        self.ringColor = ringColor
        self.sectorLineColor = sectorLineColor
        self.title = title
        self.onSelect = onSelect
        self.onDeselectAll = onDeselectAll
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> UIView {
        let container = ContainerView()
        context.coordinator.container = container
        // SwiftUI only calls updateUIView when this View's own inputs change,
        // not when Auto Layout later resolves the container's actual size -
        // so the very first layout pass (zero size -> real size) would
        // otherwise never trigger a rebuild. layoutSubviews catches that.
        container.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.rebuildIfNeeded()
        }
        return container
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.rebuildIfNeeded()
    }

    final class ContainerView: UIView {
        var onLayout: (() -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            onLayout?()
        }
    }

    // Absorbs CHRadarGraphViewDataSource/Delegate so callers of CHRadarGraph
    // never implement them - it answers every question from `parent`
    // (the current SwiftUI-side struct) and `container`'s own bounds,
    // re-reading both on every rebuild rather than caching stale copies.
    @MainActor
    public final class Coordinator: NSObject, CHRadarGraphViewDataSource, CHRadarGraphViewDelegate {
        // internal (not private/fileprivate) so tests can drive the
        // Coordinator directly without needing a real SwiftUI render pass.
        var parent: CHRadarGraph
        weak var container: UIView?
        private var graph: CHRadarGraphView?
        private var lastSize: CGSize = .zero
        private var lastSectors: [Sector] = []
        private var lastTotalSectorSlots: Int?

        fileprivate init(parent: CHRadarGraph) {
            self.parent = parent
        }

        // updateUIView runs on every SwiftUI re-render, most of which have
        // nothing to do with this graph - only actually rebuild (recreate
        // the CHRadarGraphView and redraw) when the size changed or the
        // data actually did, same as CHRadarGraphView's own consumers do by
        // hand in viewDidLayoutSubviews.
        // internal (not fileprivate) so tests and ContainerView's layout
        // hook can both call this directly.
        func rebuildIfNeeded() {
            guard let container, container.bounds.size != .zero else { return }
            let sizeChanged = container.bounds.size != lastSize
            let dataChanged = parent.sectors != lastSectors || parent.totalSectorSlots != lastTotalSectorSlots
            guard sizeChanged || dataChanged else { return }
            lastSize = container.bounds.size
            lastSectors = parent.sectors
            lastTotalSectorSlots = parent.totalSectorSlots

            graph?.view.removeFromSuperview()
            let newGraph = CHRadarGraphView(delegate: self, dataSource: self)
            graph = newGraph
            container.addSubview(newGraph.view)
            newGraph.reload()
        }

        // MARK: - CHRadarGraphViewDataSource

        public func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint {
            guard let container else { return .zero }
            return CGPoint(x: container.bounds.midX, y: container.bounds.midY)
        }

        public func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat {
            guard let container else { return 0 }
            let labelMargin: CGFloat = 60
            let shortestSide = min(container.bounds.width, container.bounds.height)
            return max(shortestSide / 2 - labelMargin, 20)
        }

        public func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat {
            parent.maxHeight ?? parent.sectors.map(\.height).max() ?? 1
        }

        public func numberOfSectors(_ graphView: CHRadarGraphView) -> Int {
            parent.totalSectorSlots ?? parent.sectors.count
        }

        public func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int {
            parent.sectors.count
        }

        public func numberOfRings(_ graphView: CHRadarGraphView) -> Int {
            parent.numberOfRings
        }

        public func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat {
            parent.startingAngleInDegrees
        }

        public func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell? {
            guard index >= 0, index < parent.sectors.count else { return nil }
            let sector = parent.sectors[index]
            let label = sector.label.map { CHSectorLabel(text: $0) }
            return CHSectorCell(height: sector.height, backgroundColor: UIColor(sector.color).cgColor, label: label)
        }

        public func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor {
            UIColor(parent.backgroundColor)
        }

        public func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor {
            UIColor(parent.ringColor)
        }

        public func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat { 1 }

        public func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor {
            UIColor(parent.sectorLineColor)
        }

        public func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat { 1 }

        public func graphDescription(_ graphView: CHRadarGraphView) -> String? {
            parent.title
        }

        // MARK: - CHRadarGraphViewDelegate

        public func willDisplayGraph(_ graphView: CHRadarGraphView) {}
        public func didDisplayGraph(_ graphView: CHRadarGraphView) {}
        public func willDisplayRing(_ graphView: CHRadarGraphView, index: Int) {}
        public func didDisplayRing(_ graphView: CHRadarGraphView, index: Int) {}
        public func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {}
        public func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {}

        public func didSelectSector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
            guard index >= 0, index < parent.sectors.count else { return }
            parent.onSelect?(parent.sectors[index], index)
        }

        public func didTapOutsideSector(_ graphView: CHRadarGraphView) {
            parent.onDeselectAll?()
        }
    }
}
