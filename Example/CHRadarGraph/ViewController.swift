//
//  ViewController.swift
//  test-graph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import UIKit
import CHRadarGraph

class ViewController: UIViewController {

    var sectorData: CHSectorDataCollection<CHSectorData>?
    var graph: CHRadarGraphView?
    private var lastLayoutSize: CGSize = .zero
    // 4x the original 10 height steps/rings, so the same data shape now
    // resolves at finer radial granularity.
    private let maxSectorHeight: CGFloat = 40

    override func viewDidLoad() {
        super.viewDidLoad()
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
    }

    // What the chart's height/color encodes. Anyone embedding CHRadarGraphView
    // can set this to describe their own data; the Example sets it to
    // demonstrate the pattern.
    var graphDescription: String? = "Number of GitHub PR's created"

    private func setUpGraph() {
        graph?.view.removeFromSuperview()
        graph = CHRadarGraphView(delegate: self, dataSource: self)
        view.addSubview(graph!.view)
        graph!.reload()
        addDescriptionLabel(to: graph!)
    }

    // The chart's data spans fewer sectors than numberOfSectors, leaving an
    // empty, widening wedge of dead space centered at the bottom of the
    // circle (see startingAngleInDegrees). graphDescription is placed well
    // down into that wedge - both for clearance from the wedges near the
    // center and because the wedge is widest there - and its width is capped
    // to what's actually free at that distance from center, so long text
    // wraps instead of overlapping a wedge.
    private func addDescriptionLabel(to graph: CHRadarGraphView) {
        guard let text = graphDescription else { return }
        let center = centerOfGraph(graph)
        let radius = radiusOfGraph(graph)

        let sectorsCount = CGFloat(numberOfSectors(graph))
        let dataCount = CGFloat(numberOfDataSectors(graph))
        let gapHalfAngleRadians = (CGFloat.pi / 180) * (360 - dataCount * (360 / sectorsCount)) / 2

        let verticalOffset = radius * 0.6
        let availableWidth = 2 * verticalOffset * tan(gapHalfAngleRadians) * 0.85

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13 * 1.5)
        label.textColor = UIColor(white: 0.4, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 0
        let width = min(radius * 1.1, availableWidth)
        label.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        label.sizeToFit()
        label.frame.size.width = width
        label.center = CGPoint(x: center.x, y: center.y + verticalOffset)
        graph.view.addSubview(label)
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
    
}
