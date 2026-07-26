//
//  ViewController.swift
//  test-graph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import UIKit
import SwiftUI
import CHRadarGraph

class ViewController: UIViewController {

    // Presents SwiftUIDemoView, which uses the CHRadarGraph SwiftUI wrapper
    // instead of this screen's own delegate/dataSource conformance below.
    private let swiftUIDemoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("SwiftUI Demo", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = UIColor(red: 28/255, green: 92/255, blue: 171/255, alpha: 1)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var sectorData: CHSectorDataCollection<CHSectorData>?
    var graph: CHRadarGraphView?
    private var lastLayoutSize: CGSize = .zero
    // 4x the original 10 height steps/rings, so the same data shape now
    // resolves at finer radial granularity.
    private let maxSectorHeight: CGFloat = 40

    // Visible feedback for tap-to-select / VoiceOver activation - without
    // this, selecting a sector would only be observable in the console.
    // Draggable (see handleSelectionLabelPan) rather than pinned to a fixed
    // spot, so it's frame-based instead of Auto Layout-positioned - a pinned
    // constraint would just snap it back after every drag.
    // Hidden until the first selection - nothing to show or drag before then.
    private let selectionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(white: 0.3, alpha: 1)
        label.numberOfLines = 2
        label.backgroundColor = UIColor(white: 1, alpha: 0.9)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isUserInteractionEnabled = true // UILabel defaults this to false
        label.isHidden = true
        return label
    }()
    private var didPositionSelectionLabel = false

    private enum SelectionLabelPlacement {
        case aboveGraph
        case belowTitle
    }
    // Default: sits above the whole drawn circle, clear of every wedge.
    // Switch to .belowTitle to instead start it beneath graphDescription's
    // text - either way it's still draggable afterward.
    private let selectionLabelPlacement: SelectionLabelPlacement = .aboveGraph

    // Catches taps that land outside the graph's own view entirely (its
    // frame only covers the drawn circle's bounding box, not the whole
    // screen) - didTapOutsideSector only fires for taps within that frame
    // that miss a sector (the empty gap, or past a wedge's tip). Needs a
    // delegate so it doesn't also fire for taps that landed on the graph or
    // the label themselves, which already have their own recognizers.
    private let backgroundTapRecognizer = UITapGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(selectionLabel)
        selectionLabel.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleSelectionLabelPan(_:))))
        backgroundTapRecognizer.addTarget(self, action: #selector(handleBackgroundTap(_:)))
        backgroundTapRecognizer.delegate = self
        view.addGestureRecognizer(backgroundTapRecognizer)
        view.addSubview(swiftUIDemoButton)
        swiftUIDemoButton.addTarget(self, action: #selector(presentSwiftUIDemo), for: .touchUpInside)
        NSLayoutConstraint.activate([
            swiftUIDemoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            swiftUIDemoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        // Same 36 time slots as before (7am - 4pm, 15-min steps); heights are
        // the original 1-10 pattern scaled onto the finer 1-40 range so the
        // chart's shape is unchanged but now resolved across 4x as many rings.
        sectorData = CHSectorDataCollection([
            CHSectorData(4, "7am"),
            CHSectorData(8, "7:15"),
            CHSectorData(12, "7:30"),
            CHSectorData(16, "7:45"),
            CHSectorData(20, "8am"),
            CHSectorData(24, "8:15"),
            CHSectorData(28, "8:30"),
            CHSectorData(32, "8:45"),
            CHSectorData(36, "9am"),
            CHSectorData(40, "9:15"),
            CHSectorData(4, "9:30"),
            CHSectorData(8, "9:45"),
            CHSectorData(12, "10am"),
            CHSectorData(16, "10:15"),
            CHSectorData(20, "10:30"),
            CHSectorData(24, "10:45"),
            CHSectorData(28, "11am"),
            CHSectorData(32, "11:15"),
            CHSectorData(36, "11:30"),
            CHSectorData(40, "11:45"),
            CHSectorData(4, "12pm"),
            CHSectorData(8, "12:15"),
            CHSectorData(12, "12:30"),
            CHSectorData(16, "12:45"),
            CHSectorData(20, "1pm"),
            CHSectorData(24, "1:15"),
            CHSectorData(28, "1:30"),
            CHSectorData(32, "1:45"),
            CHSectorData(36, "2pm"),
            CHSectorData(40, "2:15"),
            CHSectorData(4, "2:30"),
            CHSectorData(8, "2:45"),
            CHSectorData(36, "3pm"),
            CHSectorData(40, "3:15"),
            CHSectorData(4, "3:30"),
            CHSectorData(8, "3:45"),
            CHSectorData(12, "4pm")
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.size != lastLayoutSize, view.bounds.size != .zero else { return }
        lastLayoutSize = view.bounds.size
        setUpGraph()

        // Only place it once - after that its position is whatever the user
        // dragged it to, and a rotation/relayout shouldn't reset that.
        if !didPositionSelectionLabel {
            didPositionSelectionLabel = true
            let width = view.bounds.width - 40
            let height: CGFloat = 44
            switch selectionLabelPlacement {
            case .aboveGraph:
                let origin = aboveGraphOrigin(width: width, height: height)
                selectionLabel.frame = CGRect(x: origin.x, y: origin.y, width: width, height: height)
            case .belowTitle:
                let origin = belowTitleOrigin(width: width)
                selectionLabel.frame = CGRect(x: origin.x, y: origin.y, width: width, height: height)
            }
        }
    }

    // Just above the topmost point of the drawn circle (centerOfGraph.y -
    // radiusOfGraph), clear of every wedge and every sector's time label.
    // Those labels sit at radius + 30 (see CHRadarGraphView's drawPieChart),
    // not radius itself, so the margin has to clear that offset plus the
    // label text's own height, or it just overlaps the ring of time labels
    // near the top instead. Not the view's own safe area top, which could
    // sit well above or below the graph depending on how much of the screen
    // it fills.
    private func aboveGraphOrigin(width: CGFloat, height: CGFloat) -> CGPoint {
        guard let g = graph else { return CGPoint(x: 20, y: view.safeAreaInsets.top + 12) }
        let graphCenter = centerOfGraph(g)
        let graphRadius = radiusOfGraph(g)
        let margin: CGFloat = 30 + 20 + 12
        let y = max(view.safeAreaInsets.top + 12, graphCenter.y - graphRadius - height - margin)
        return CGPoint(x: (view.bounds.width - width) / 2, y: y)
    }

    // Mirrors CHRadarGraphView's own placement of graphDescription (radius *
    // 0.6 along the empty gap's center direction) so this tracks wherever
    // the library actually draws that text, rather than a hardcoded guess.
    private func belowTitleOrigin(width: CGFloat) -> CGPoint {
        guard let g = graph else { return CGPoint(x: 20, y: view.safeAreaInsets.top + 12) }
        let graphCenter = centerOfGraph(g)
        let graphRadius = radiusOfGraph(g)
        let sectorsCount = CGFloat(numberOfSectors(g))
        let dataCount = CGFloat(numberOfDataSectors(g))
        let startAngle = startingAngleInDegrees(g) * .pi / 180
        let dataSweep = dataCount * (2 * .pi / sectorsCount)
        let gapCenterAngle = startAngle + dataSweep / 2 + .pi

        let titleRadius = graphRadius * 0.6
        let titleCenter = CGPoint(
            x: graphCenter.x + titleRadius * cos(gapCenterAngle),
            y: graphCenter.y + titleRadius * sin(gapCenterAngle)
        )
        return CGPoint(x: titleCenter.x - width / 2, y: titleCenter.y + 40)
    }

    @objc private func handleSelectionLabelPan(_ gesture: UIPanGestureRecognizer) {
        guard let label = gesture.view else { return }
        let translation = gesture.translation(in: view)
        label.center = CGPoint(x: label.center.x + translation.x, y: label.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        selectionLabel.isHidden = true
    }

    @objc private func presentSwiftUIDemo() {
        guard #available(iOS 14.0, *) else { return }
        let hosting = UIHostingController(rootView: NavigationView { SwiftUIDemoView() })
        present(hosting, animated: true)
    }

    private func setUpGraph() {
        graph?.view.removeFromSuperview()
        graph = CHRadarGraphView(delegate: self, dataSource: self)
        view.addSubview(graph!.view)
        graph!.reload()
        // Every relayout re-adds the graph's view, which - added after
        // selectionLabel back in viewDidLoad - would otherwise sit on top of
        // it in z-order every time, hiding the label whenever they overlap
        // (guaranteed with the default .overRadarChart placement).
        view.bringSubviewToFront(selectionLabel)
    }

    // Sector height is a magnitude, not a category, so it's encoded as one hue
    // (blue) going light -> dark rather than a hop across unrelated hues.
    // Interpolated between the sequential ramp's documented light-end floor
    // (step 250, the lightest step that still clears 2:1 on white) and step
    // 550 - a lighter overall ramp than the old 250-700 span - across all
    // maxSectorHeight steps rather than a fixed 10-case table.
    func sectorColor(value: CGFloat) -> UIColor {
        let start = (r: 134.0, g: 182.0, b: 239.0)
        let end = (r: 28.0, g: 92.0, b: 171.0)
        let t = max(0, min(1, (value - 1) / (maxSectorHeight - 1)))
        return UIColor(
            red: CGFloat(start.r + (end.r - start.r) * t) / 255,
            green: CGFloat(start.g + (end.g - start.g) * t) / 255,
            blue: CGFloat(start.b + (end.b - start.b) * t) / 255,
            alpha: 1
        )
    }

}

extension ViewController: CHRadarGraphViewDataSource {

    // Reserve room outside the radius for the sector time labels, which are
    // drawn past the edge of the graph (see drawPieChart's `distantX`/`distantY`).
    private var labelMargin: CGFloat { 80 }

    func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint {
        return CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat {
        let shortestSide = min(view.bounds.width, view.bounds.height)
        return max((shortestSide / 2) - labelMargin, 50)
    }

    func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat {
        return maxSectorHeight
    }

    func numberOfSectors(_ graphView: CHRadarGraphView) -> Int {
        return 50
    }

    func numberOfRings(_ graphView: CHRadarGraphView) -> Int {
        return Int(maxSectorHeight)
    }

    func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int {
        return sectorData!.count
    }

    func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor {
        return UIColor.white
    }

    func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func strokeColorOfDiskLines(_ graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat {
        // Centers the empty (data-less) gap at the bottom of the circle so the
        // first and last data sectors — 7am and 4pm — land at the same height.
        let sectorsCount = CGFloat(numberOfSectors(graphView))
        let dataCount = CGFloat(numberOfDataSectors(graphView))
        let gapInDegrees = 360.0 - (dataCount * (360.0 / sectorsCount))
        return 90.0 + gapInDegrees / 2.0
    }

    func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat {
        return 1.0
    }

    func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat {
        return 1.0
    }

    func graphDescription(_ graphView: CHRadarGraphView) -> String? {
        return "Number of GitHub PR's created"
    }

    func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell? {
        guard let data = sectorData?[index] else { return nil }
        let height = data.height
        let label = CHSectorLabel(text: data.label, isBold: false, color: UIColor.black.cgColor)
        return CHSectorCell(height: height, backgroundColor: sectorColor(value: height).cgColor, label: label)
    }

}

extension ViewController: CHRadarGraphViewDelegate {

    func willDisplayGraph(_ graphView: CHRadarGraphView) {
        print("Graph will display! - graph: \(graphView)")
    }

    func didDisplayGraph(_ graphView: CHRadarGraphView) {
        print("Graph did display! - graph: \(graphView)")
    }

    func willDisplayRing(_ graphView: CHRadarGraphView, index: Int) {
        print("Ring did display - graph: \(graphView), index: \(index)")
    }

    func didDisplayRing(_ graphView: CHRadarGraphView, index: Int) {
        print("Ring did display - graph: \(graphView), index: \(index)")
    }

    func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        print("Sector will display! - graph: \(graphView), sector: \(sector), index: \(index)")
    }

    func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        print("Sector did display! - graph: \(graphView), sector: \(sector), index: \(index)")
    }

    func didSelectSector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        print("Sector selected (tap or VoiceOver activation) - label: \(sector.label?.text ?? ""), height: \(sector.height)")
        let label = sector.label?.text ?? "sector \(index)"
        selectionLabel.text = "\(Int(sector.height)) PR's created at \(label)"
        selectionLabel.isHidden = false
    }

    // Tapped within the graph's bounds but not on any drawn sector - the
    // empty gap, or past a short wedge's actual tip.
    func didTapOutsideSector(_ graphView: CHRadarGraphView) {
        selectionLabel.isHidden = true
    }

}

extension ViewController: UIGestureRecognizerDelegate {

    // Only let backgroundTapRecognizer handle touches that land outside
    // both the graph's view and the (visible) selection label - each of
    // those already has its own recognizer for taps that land on them.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === backgroundTapRecognizer else { return true }
        let point = touch.location(in: view)
        if let graphView = graph?.view, graphView.frame.contains(point) {
            return false
        }
        if !selectionLabel.isHidden, selectionLabel.frame.contains(point) {
            return false
        }
        return true
    }

}
