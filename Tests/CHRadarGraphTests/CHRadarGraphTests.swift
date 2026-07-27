import XCTest
import UIKit
import SwiftUI
@testable import CHRadarGraph

@MainActor
private final class FakeGraphSource: CHRadarGraphViewDataSource, CHRadarGraphViewDelegate {
    var heights: [CGFloat]
    var sectorsCount: Int
    var dataCount: Int
    var center = CGPoint(x: 100, y: 100)
    var radius: CGFloat = 100
    var largestHeight: CGFloat = 10
    var labels: [CHSectorLabel?]?
    var title: String?
    var titleColor: UIColor?
    var titleFont: UIFont?

    init(heights: [CGFloat], sectorsCount: Int? = nil) {
        self.heights = heights
        self.dataCount = heights.count
        self.sectorsCount = sectorsCount ?? heights.count
    }

    func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint { center }
    func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat { radius }
    func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat { largestHeight }
    func numberOfSectors(_ graphView: CHRadarGraphView) -> Int { sectorsCount }
    func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int { dataCount }
    func numberOfRings(_ graphView: CHRadarGraphView) -> Int { 4 }
    func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat { 0 }
    func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell? {
        CHSectorCell(height: heights[index], backgroundColor: UIColor.blue.cgColor, label: labels?[index])
    }
    func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor { .white }
    func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor { .gray }
    func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat { 1 }
    func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor { .gray }
    func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat { 1 }
    func graphDescription(_ graphView: CHRadarGraphView) -> String? { title }
    func graphDescriptionColor(_ graphView: CHRadarGraphView) -> UIColor { titleColor ?? UIColor(white: 0.4, alpha: 1) }
    func graphDescriptionFont(_ graphView: CHRadarGraphView) -> UIFont { titleFont ?? .systemFont(ofSize: 22.5) }

    func willDisplayGraph(_ graphView: CHRadarGraphView) {}
    func didDisplayGraph(_ graphView: CHRadarGraphView) {}
    func willDisplayRing(_ graphView: CHRadarGraphView, index: Int) {}
    func didDisplayRing(_ graphView: CHRadarGraphView, index: Int) {}
    func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {}
    func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {}

    var selectedSector: CHSectorCell?
    var selectedIndex: Int?
    func didSelectSector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        selectedSector = sector
        selectedIndex = index
    }
}

@MainActor
final class CHRadarGraphTests: XCTestCase {

    func testSectorDataStoresHeightAndLabel() {
        let sector = CHSectorData(7, "7am")
        XCTAssertEqual(sector.height, 7)
        XCTAssertEqual(sector.label, "7am")
    }

    func testSectorDataCollectionCount() {
        let collection = CHSectorDataCollection([
            CHSectorData(1, "7am"),
            CHSectorData(2, "8am"),
            CHSectorData(3, "9am")
        ])
        XCTAssertEqual(collection.count, 3)
    }

    func testSectorDataCollectionSubscript() {
        let collection = CHSectorDataCollection([
            CHSectorData(1, "7am"),
            CHSectorData(2, "8am")
        ])
        XCTAssertEqual(collection[0]?.label, "7am")
        XCTAssertEqual(collection[1]?.label, "8am")
        XCTAssertNil(collection[2])
    }

    // A negative index passed the `index < count` half of the bounds check
    // (any negative number is less than a positive count) straight through
    // to `data[index]`, which traps instead of returning nil like every
    // other out-of-range index does.
    func testSectorDataCollectionSubscriptRejectsNegativeIndexInsteadOfCrashing() {
        let collection = CHSectorDataCollection([CHSectorData(1, "7am")])
        XCTAssertNil(collection[-1])
    }

    // MARK: - Sector hit-testing (tap-to-select geometry)

    func testHitTestFindsSectorAtItsAngleAndWithinItsRadius() {
        // 4 sectors, full circle, 90 degrees each, starting at 0.
        // Sector 0 spans [0, 90) degrees and has the full radius (height == largestHeight).
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        let hit = graph.sector(at: CGPoint(x: source.center.x + 50, y: source.center.y))
        XCTAssertEqual(hit?.1, 0)
    }

    func testHitTestMissesPastAShortSectorsActualTip() {
        // Sector 1 spans [90, 180) degrees but only reaches height 1 of 10,
        // i.e. 1/10th of the radius - a tap further out than that, even
        // though still inside the overall circle, should not register.
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        let pastTip = CGPoint(x: source.center.x, y: source.center.y + 50)
        XCTAssertNil(graph.sector(at: pastTip))

        let withinTip = CGPoint(x: source.center.x, y: source.center.y + 5)
        XCTAssertEqual(graph.sector(at: withinTip)?.1, 1)
    }

    func testHitTestMissesOutsideOverallRadius() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        let outside = CGPoint(x: source.center.x + 150, y: source.center.y)
        XCTAssertNil(graph.sector(at: outside))
    }

    // This exercises UIKit's real hitTest(_:with:), not just the sector(at:)
    // math - a previous version of this view had frame = .zero, which meant
    // sector(at:) was correct but UIKit's own touch hit-testing rejected
    // every point before ever calling it, so the tap gesture recognizer
    // silently never fired. sector(at:) tests alone did not catch that.
    func testViewFrameActuallyAcceptsTouchesOverTheDrawnCircle() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        XCTAssertNotEqual(graph.view.frame.size, .zero, "a zero-sized view can never pass hit-testing")

        let insideCircle = CGPoint(x: source.center.x + 50, y: source.center.y)
        XCTAssertNotNil(graph.view.hitTest(insideCircle, with: nil))

        let farOutside = CGPoint(x: -1000, y: -1000)
        XCTAssertNil(graph.view.hitTest(farOutside, with: nil))
    }

    func testHitTestMissesInTheEmptyGapWhenDataSectorsAreFewerThanTotal() {
        // 8 total sectors but only 4 have data, leaving the back half empty.
        let source = FakeGraphSource(heights: [10, 10, 10, 10], sectorsCount: 8)
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        // 225 degrees is well within the gap (sectors 4-7 have no data).
        let inGap = CGPoint(
            x: source.center.x + 50 * cos(225 * .pi / 180),
            y: source.center.y + 50 * sin(225 * .pi / 180)
        )
        XCTAssertNil(graph.sector(at: inGap))
    }

    // MARK: - Sector labels

    // CHSectorLabel's color/isBold were never actually read when drawing a
    // sector's on-screen time label - it silently kept UILabel's default
    // textColor instead, which is the dynamic .label color on iOS 13+ and
    // resolves to white in dark mode. Against a graph whose background/
    // rings a consumer drew with static light colors (as the Example app
    // does), that made every time label invisible the moment the system
    // switched to dark mode.
    func testSectorLabelUsesItsOwnColorAndBoldness() {
        let source = FakeGraphSource(heights: [10, 5])
        source.labels = [
            CHSectorLabel(text: "A", isBold: true, color: UIColor.red.cgColor),
            nil
        ]
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let labels = graph.view.subviews.compactMap { $0 as? UILabel }
        let labelA = labels.first { $0.text == "A" }
        XCTAssertEqual(labelA?.textColor, .red)
        XCTAssertEqual(labelA?.font, .boldSystemFont(ofSize: 12.0))
    }

    // A sector with no label at all (or a label with no explicit color)
    // must not fall back to UILabel's own dynamic default - same reasoning
    // as above, just the nil-label case.
    func testSectorWithNoLabelColorDefaultsToStaticBlackNotUIKitsDynamicDefault() {
        let source = FakeGraphSource(heights: [10])
        source.labels = [nil]
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let label = graph.view.subviews.compactMap { $0 as? UILabel }.first
        XCTAssertEqual(label?.textColor, .black)
    }

    // graphDescriptionColor/graphDescriptionFont are opt-in dataSource
    // methods (added alongside title/label customization) - confirms
    // drawAxisLabels() actually reads them instead of the hardcoded
    // defaults it used before they existed.
    func testGraphDescriptionUsesCustomColorAndFont() {
        let source = FakeGraphSource(heights: [10, 5], sectorsCount: 4)
        source.title = "Custom Title"
        source.titleColor = .red
        source.titleFont = .boldSystemFont(ofSize: 30)
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let label = graph.view.subviews.compactMap { $0 as? UILabel }.first { $0.text == "Custom Title" }
        XCTAssertEqual(label?.textColor, .red)
        XCTAssertEqual(label?.font, .boldSystemFont(ofSize: 30))
    }

    // MARK: - Regression tests for the review findings fixed in this commit

    // Each accessibility element's activate action used to capture a `var`
    // declared once above the drawing loop and reassigned every iteration,
    // rather than a fresh per-iteration value - so every element reported
    // whichever sector was drawn last, regardless of which one VoiceOver
    // actually activated.
    func testEachAccessibilityElementActivatesWithItsOwnSectorNotTheLastOne() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let elements = graph.view.accessibilityElements as? [UIAccessibilityElement] ?? []
        XCTAssertEqual(elements.count, 4)

        // Activate sector 0 (height 10) - not the last one (index 3, also
        // height 10, so a same-height coincidence couldn't mask the bug -
        // sector 1's height 1 is the distinguishing case actually exercised
        // next).
        _ = elements[0].accessibilityActivate()
        XCTAssertEqual(source.selectedIndex, 0)
        XCTAssertEqual(source.selectedSector?.height, 10)

        // Activate sector 1 (height 1). Under the bug, this incorrectly
        // reported the last-drawn sector's height (10) instead of 1.
        _ = elements[1].accessibilityActivate()
        XCTAssertEqual(source.selectedIndex, 1)
        XCTAssertEqual(source.selectedSector?.height, 1)
    }

    // The tap-handling coordinator used to capture the whole CHRadarGraphView
    // struct in a stored closure - which, since that struct carries the
    // coordinator itself as one of its own properties, retained itself (and
    // `view`, and the delegate/dataSource) forever, independent of any
    // external reference.
    func testViewDoesNotLeakAfterGraphGoesOutOfScope() {
        weak var weakView: UIView?
        do {
            let source = FakeGraphSource(heights: [10, 1, 5, 10])
            let graph = CHRadarGraphView(delegate: source, dataSource: source)
            graph.reload()
            weakView = graph.view
            XCTAssertNotNil(weakView)
        }
        XCTAssertNil(weakView, "view should deallocate once nothing outside the (now out-of-scope) graph references it")
    }

    // MARK: - Trait collection (dark mode) changes

    // A graph drawn once in light mode used to keep those exact colors
    // forever, even if the device later switched appearance, since nothing
    // ever called reload() again on its behalf. traitCollectionDidChange is
    // UIKit's own hook for this - dynamically dispatched even through the
    // view's public `UIView` static type, so calling it directly here
    // exercises the real override on the private CHRadarGraphContentView
    // subclass without needing a window or an actual system appearance
    // change.
    func testTraitCollectionChangeTriggersARedrawWithoutStackingDuplicateLayers() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let sublayerCountAfterFirstReload = graph.view.layer.sublayers?.count ?? 0
        let subviewCountAfterFirstReload = graph.view.subviews.count
        XCTAssertGreaterThan(sublayerCountAfterFirstReload, 0, "rings/pie/divider shapes should have been drawn")

        let oppositeStyle: UIUserInterfaceStyle = graph.view.traitCollection.userInterfaceStyle == .dark ? .light : .dark
        let previousTraits = UITraitCollection(userInterfaceStyle: oppositeStyle)
        graph.view.traitCollectionDidChange(previousTraits)

        XCTAssertEqual(graph.view.layer.sublayers?.count ?? 0, sublayerCountAfterFirstReload, "a color-appearance change should redraw in place, not stack a second copy of every layer on top of the first")
        XCTAssertEqual(graph.view.subviews.count, subviewCountAfterFirstReload, "same for subviews (axis/sector labels)")
    }

    // DIAGNOSTIC: does VoiceOver activation still work after a trait-driven
    // redraw? handleTraitChange() reloads through a throwaway "handoff"
    // CHRadarGraphView (see makeHandoff()) rather than the original value -
    // if drawPieChart's accessibility closures capture *that* value's own
    // (fresh, unwired) coordinator instead of the original, activation would
    // silently no-op after any dark/light mode switch.
    func testVoiceOverActivationStillWorksAfterATraitChange() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)
        graph.reload()

        let oppositeStyle: UIUserInterfaceStyle = graph.view.traitCollection.userInterfaceStyle == .dark ? .light : .dark
        let previousTraits = UITraitCollection(userInterfaceStyle: oppositeStyle)
        graph.view.traitCollectionDidChange(previousTraits)

        let elements = graph.view.accessibilityElements as? [UIAccessibilityElement] ?? []
        XCTAssertEqual(elements.count, 4)
        _ = elements[1].accessibilityActivate()

        XCTAssertEqual(source.selectedIndex, 1, "VoiceOver activation should still route to didSelectSector after a trait change")
    }

    // Isolates reload()'s own idempotency (independent of the trait-change
    // wiring above) - calling it twice on the same view must redraw in
    // place, not accumulate a duplicate set of layers/labels each time.
    func testCallingReloadTwiceDoesNotStackDuplicateLayersOrLabels() {
        let source = FakeGraphSource(heights: [10, 1, 5, 10])
        let graph = CHRadarGraphView(delegate: source, dataSource: source)

        graph.reload()
        let sublayerCountAfterFirstReload = graph.view.layer.sublayers?.count ?? 0
        let subviewCountAfterFirstReload = graph.view.subviews.count

        graph.reload()

        XCTAssertEqual(graph.view.layer.sublayers?.count ?? 0, sublayerCountAfterFirstReload)
        XCTAssertEqual(graph.view.subviews.count, subviewCountAfterFirstReload)
    }

    // MARK: - SwiftUI wrapper

    @available(iOS 14.0, *)
    func testSwiftUICoordinatorMapsSectorsToCells() {
        let sectors = [
            CHRadarGraph.Sector(height: 5, label: "A", color: .blue),
            CHRadarGraph.Sector(height: 8, label: "B", color: .red)
        ]
        let view = CHRadarGraph(sectors: sectors, maxHeight: 10)
        let coordinator = view.makeCoordinator()
        coordinator.container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let graph = CHRadarGraphView(delegate: coordinator, dataSource: coordinator)

        XCTAssertEqual(coordinator.numberOfDataSectors(graph), 2)
        XCTAssertEqual(coordinator.numberOfSectors(graph), 2, "defaults to sectors.count with no gap")
        XCTAssertEqual(coordinator.largestHeightForSectorCell(graph), 10)

        let cell = coordinator.sectorCellForPositionAtIndex(graph, index: 1)
        XCTAssertEqual(cell?.height, 8)
        XCTAssertEqual(cell?.label?.text, "B")
    }

    // Sector.labelColor/labelIsBold/labelFontSize (added alongside title
    // customization) must actually reach the CHSectorLabel built for each
    // cell, not just the wedge's own fill color.
    @available(iOS 14.0, *)
    func testSwiftUISectorLabelStylingReachesTheBuiltCell() {
        let sectors = [
            CHRadarGraph.Sector(height: 5, label: "A", color: .blue, labelColor: .green, labelIsBold: true, labelFontSize: 20)
        ]
        let view = CHRadarGraph(sectors: sectors)
        let coordinator = view.makeCoordinator()
        coordinator.container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let graph = CHRadarGraphView(delegate: coordinator, dataSource: coordinator)

        let cell = coordinator.sectorCellForPositionAtIndex(graph, index: 0)
        // Compared against UIColor(Color.green), not UIKit's own .green -
        // SwiftUI's Color.green bridges to a perceptually-tuned green, not
        // the (0, 1, 0) primary UIColor.green is.
        XCTAssertEqual(cell?.label?.color, UIColor(Color.green).cgColor)
        XCTAssertEqual(cell?.label?.isBold, true)
        XCTAssertEqual(cell?.label?.fontSize, 20)
    }

    // titleColor/titleFontSize (added alongside per-sector label styling)
    // must actually reach the drawn title label via
    // graphDescriptionColor/graphDescriptionFont.
    @available(iOS 14.0, *)
    func testSwiftUITitleStylingIsAppliedToTheDrawnLabel() {
        let sectors = [CHRadarGraph.Sector(height: 5, color: .blue)]
        let view = CHRadarGraph(
            sectors: sectors, totalSectorSlots: 4, title: "Custom Title",
            titleColor: .red, titleFontSize: 30
        )
        let coordinator = view.makeCoordinator()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        coordinator.container = container
        coordinator.rebuildIfNeeded()

        let label = container.subviews.first?.subviews.compactMap { $0 as? UILabel }.first { $0.text == "Custom Title" }
        // Compared against UIColor(Color.red), not UIKit's own .red -
        // SwiftUI's Color.red bridges to the dynamic system-red color, not
        // the static (1, 0, 0) UIColor.red is.
        XCTAssertEqual(label?.textColor, UIColor(Color.red))
        XCTAssertEqual(label?.font, .systemFont(ofSize: 30))
    }

    @available(iOS 14.0, *)
    func testSwiftUICoordinatorRespectsExplicitTotalSectorSlots() {
        let sectors = [CHRadarGraph.Sector(height: 5, color: .blue)]
        let view = CHRadarGraph(sectors: sectors, totalSectorSlots: 4)
        let coordinator = view.makeCoordinator()
        coordinator.container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let graph = CHRadarGraphView(delegate: coordinator, dataSource: coordinator)

        XCTAssertEqual(coordinator.numberOfSectors(graph), 4)
        XCTAssertEqual(coordinator.numberOfDataSectors(graph), 1)
    }

    @available(iOS 14.0, *)
    func testSwiftUICoordinatorForwardsSelectionToOnSelect() {
        var selected: (CHRadarGraph.Sector, Int)?
        let sectors = [CHRadarGraph.Sector(height: 5, label: "A", color: .blue)]
        let view = CHRadarGraph(sectors: sectors, onSelect: { sector, index in
            selected = (sector, index)
        })
        let coordinator = view.makeCoordinator()
        coordinator.container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let graph = CHRadarGraphView(delegate: coordinator, dataSource: coordinator)

        let cell = CHSectorCell(height: 5, backgroundColor: UIColor.blue.cgColor, label: nil)
        coordinator.didSelectSector(graph, sector: cell, index: 0)

        XCTAssertEqual(selected?.1, 0)
        XCTAssertEqual(selected?.0.label, "A")
    }

    // SwiftUI only calls updateUIView when this View's own inputs change, not
    // when Auto Layout later resolves the container's size from zero to real
    // - a container created with no frame yet (the common case: the very
    // first layout pass) used to never get its graph built, since nothing
    // else would prompt a second call to rebuildIfNeeded(). ContainerView's
    // layoutSubviews hook exists specifically to catch that first resize.
    @available(iOS 14.0, *)
    func testCoordinatorRebuildsOnFirstLayoutPassEvenWithoutAnUpdateUIViewCall() {
        let sectors = [CHRadarGraph.Sector(height: 5, color: .blue)]
        let view = CHRadarGraph(sectors: sectors)
        let coordinator = view.makeCoordinator()
        let container = CHRadarGraph.ContainerView()
        coordinator.container = container
        container.onLayout = { [weak coordinator] in coordinator?.rebuildIfNeeded() }

        XCTAssertTrue(container.subviews.isEmpty, "zero size - nothing to draw yet")

        container.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        container.layoutIfNeeded()

        XCTAssertEqual(container.subviews.count, 1, "the first real layout pass should have prompted the coordinator to build and add the graph's view")
    }

    // DIAGNOSTIC: rebuildIfNeeded() only rebuilds when the container's size
    // changes or `sectors`/`totalSectorSlots` change - every other property
    // (title, numberOfRings, startingAngleInDegrees, maxHeight, and all
    // three colors) is silently ignored, so a SwiftUI consumer who only
    // changes one of those would see the graph never update.
    @available(iOS 14.0, *)
    func testRebuildIfNeededPicksUpATitleChangeWithNoOtherPropertyChanging() {
        let sectors = [CHRadarGraph.Sector(height: 5, color: .blue)]
        var view = CHRadarGraph(sectors: sectors, totalSectorSlots: 4)
        let coordinator = view.makeCoordinator()
        // container is a `weak var` on Coordinator (matching how a real
        // UIViewRepresentable-managed view is owned by SwiftUI, not by the
        // Coordinator) - it must be kept alive by a local strong reference
        // for the length of the test, or it deallocates the instant it's
        // assigned and every container-dependent call below silently no-ops.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        coordinator.container = container
        coordinator.parent = view
        coordinator.rebuildIfNeeded()
        let subviewCountWithNoTitle = container.subviews.first?.subviews.count ?? -1

        view.title = "New Title"
        coordinator.parent = view
        coordinator.rebuildIfNeeded()
        let subviewCountWithTitle = container.subviews.first?.subviews.count ?? -1

        XCTAssertGreaterThan(subviewCountWithTitle, subviewCountWithNoTitle, "adding a title should draw a label for it, even though sectors/totalSectorSlots never changed")
    }
}
