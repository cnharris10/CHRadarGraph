//
//  all.swift
//  CHRadarGraph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import Foundation

public protocol CHRadarGraphViewDelegate {

    // Graph
    func willDisplayGraph(graphView: CHRadarGraphView)
    func didDisplayGraph(graphView: CHRadarGraphView)

    // Rings
    func willDisplayRing(graphView: CHRadarGraphView, index: Int)
    func didDisplayRing(graphView: CHRadarGraphView, index: Int)

    // Sectors
    func willDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)
    func didDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)
}

public protocol CHRadarGraphViewDataSource {
    func centerOfGraph(graphView: CHRadarGraphView) -> CGPoint
    func radiusOfGraph(graphView: CHRadarGraphView) -> CGFloat
    func largestHeightForSectorCell(graphView: CHRadarGraphView) -> CGFloat
    func numberOfSectors(graphView: CHRadarGraphView) -> Int
    func numberOfDataSectors(graphView: CHRadarGraphView) -> Int
    func numberOfRings(graphView: CHRadarGraphView) -> Int
    func startingAngleInDegrees(graphView: CHRadarGraphView) -> CGFloat
    func sectorCellForPositionAtIndex(graph: CHRadarGraphView, index: Int) -> CHSectorCell?
    func backgroundColorOfGraph(graphView: CHRadarGraphView) -> UIColor
    func strokeColorOfRings(graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfRings(graphView: CHRadarGraphView) -> CGFloat
    func strokeColorOfSectorLines(graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfSectorLines(graphView: CHRadarGraphView) -> CGFloat
}

public struct CHRadarGraphView {

    private let degreesOfCircle: CGFloat = 360

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

    public init(delegate: CHRadarGraphViewDelegate, dataSource: CHRadarGraphViewDataSource) {
        self.view = UIView(frame: CGRect.zero)
        self.delegate = delegate
        self.dataSource = dataSource
        startAngle = CHRadarGraphView.degreesToRadians(degrees: dataSource.startingAngleInDegrees(graphView: self))
        largestHeight = dataSource.largestHeightForSectorCell(graphView: self)
        numberOfRings = dataSource.numberOfRings(graphView: self)
        sectorsCount = CGFloat(dataSource.numberOfSectors(graphView: self))
        sectorsDataCount = CGFloat(dataSource.numberOfDataSectors(graphView: self))
        center = dataSource.centerOfGraph(graphView: self)
        radius = dataSource.radiusOfGraph(graphView: self)

        let x = center.x - radius
        let y = center.y - radius
        position = CGPoint(x: x, y: y)

        let width = center.x + radius - position.x
        let height = center.y + radius - position.y
        size = CGSize(width: width, height: height)

        backgroundColor = dataSource.backgroundColorOfGraph(graphView: self)
        strokeColorOfSectorLines = dataSource.strokeColorOfSectorLines(graphView: self)
        strokeWidthOfSectorLines = dataSource.strokeWidthOfSectorLines(graphView: self)
        strokeColorOfRings = dataSource.strokeColorOfRings(graphView: self)
        strokeWidthOfRings = dataSource.strokeWidthOfRings(graphView: self)
    }

    public func reload() {
        delegate.willDisplayGraph(graphView: self)
        let endAngle = startAngle + CGFloat(sectorsDataCount) * CHRadarGraphView.degreesToRadians(degrees: CGFloat(self.degreesOfCircle / self.sectorsCount))
        let view: UIView = UIView(frame: CGRect(origin: position, size: size))
        view.backgroundColor = backgroundColor
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        drawRings(endAngle: endAngle)
        drawPieChart()
        drawSectors()
        view.layer.contents = UIGraphicsGetImageFromCurrentImageContext()!.cgImage
        UIGraphicsEndImageContext()
        delegate.didDisplayGraph(graphView: self)
    }

    // Circles
    func drawRings(endAngle: CGFloat) {
        if numberOfRings < 1 {
            return
        }

        for index in 1...numberOfRings {
            delegate.willDisplayRing(graphView: self, index: index)
            let pathRadius = (CGFloat(index) / CGFloat(numberOfRings)) * radius
            let path = buildPath(radius: pathRadius, startAngle: startAngle, endAngle: endAngle)
            let shape = buildShape(path: path, fillColor: UIColor.clear.cgColor, strokeColor: strokeColorOfRings.cgColor, lineWidth: strokeWidthOfRings)
            view.layer.addSublayer(shape)
            delegate.didDisplayRing(graphView: self, index: index)
        }
    }

    // Divisions
    func drawSectors() {
        for index in 0...Int(sectorsDataCount) {
            let path = UIBezierPath(rect: CGRect.init(x: center.x, y: center.y, width: radius, height: 0.1))
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: center.x, y: center.y);
            transform = transform.rotated(by: startAngle + CHRadarGraphView.degreesToRadians(degrees: CGFloat(CGFloat(index) * (degreesOfCircle / sectorsCount))));
            transform = transform.translatedBy(x: -center.x, y: -center.y);
            path.apply(transform)

            let shape = buildShape(path: path, fillColor: backgroundColor.cgColor, strokeColor: strokeColorOfSectorLines.cgColor, lineWidth: strokeWidthOfSectorLines)
            view.layer.addSublayer(shape)
        }
    }

    // Content
    func drawPieChart() {
        if sectorsDataCount < 1 {
            return
        }

        var angle = startAngle
        var sectorCell: CHSectorCell
        for index in 0...Int(sectorsDataCount) - 1 {
            sectorCell = dataSource.sectorCellForPositionAtIndex(graph: self, index: index)!
            delegate.willDisplaySector(graphView: self, sector: sectorCell, index: index)
            let height = CGFloat(sectorCell.height)

            let pathRadius = (height / largestHeight) * radius
            let sectorAngle = (1 / CGFloat(sectorsCount)) * CHRadarGraphView.degreesToRadians(degrees: degreesOfCircle)
            let path = buildPath(radius: pathRadius, startAngle: angle, endAngle: angle + sectorAngle)

            // Create Shape
            let shape = buildShape(path: path, fillColor: sectorCell.backgroundColor, strokeColor: nil, lineWidth: nil)
            view.layer.addSublayer(shape)
            angle += sectorAngle

            // Create Label
            let distantX = center.x + (radius + 30) * cos(angle - CHRadarGraphView.degreesToRadians(degrees: 4)) - 26
            let distantY = center.y + (radius + 30) * sin(angle - CHRadarGraphView.degreesToRadians(degrees: 3)) - 11
            let label = UILabel()
            label.frame.origin = CGPoint(x: distantX, y: distantY)
            label.text = sectorCell.label?.text ?? ""
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.sizeToFit()
            label.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.addSubview(label)
            delegate.didDisplaySector(graphView: self, sector: sectorCell, index: index)
        }
    }

    func buildPath(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.move(to: center)
        path.close()
        return path
    }

    func buildShape(path: UIBezierPath, fillColor: CGColor?, strokeColor: CGColor?, lineWidth: CGFloat?) -> CAShapeLayer {
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

    static func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * (CGFloat(Double.pi) / (360 / 2))
    }

}
