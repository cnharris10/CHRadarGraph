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
    func numberOfRings(graphView: CHRadarGraphView) -> Int
    func numberOfDataSectors(graphView: CHRadarGraphView) -> Int
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
    internal var center: CGPoint = CGPointZero
    internal var radius: CGFloat = 0
    internal var size: CGSize = CGSizeZero
    internal var position: CGPoint = CGPointZero
    internal var backgroundColor: UIColor = UIColor()
    internal var strokeColorOfSectorLines: UIColor = UIColor()
    internal var strokeColorOfRings: UIColor = UIColor()
    internal var strokeWidthOfSectorLines: CGFloat = CGFloat()
    internal var strokeWidthOfRings: CGFloat = CGFloat()

    public init(delegate: CHRadarGraphViewDelegate, dataSource: CHRadarGraphViewDataSource) {
        self.view = UIView(frame: CGRectZero)
        self.delegate = delegate
        self.dataSource = dataSource
        startAngle = CHRadarGraphView.degreesToRadians(dataSource.startingAngleInDegrees(self) ?? CHRadarGraphDefaultValues.Graph.startingAngleInDegrees)
        largestHeight = dataSource.largestHeightForSectorCell(self) ?? CHRadarGraphDefaultValues.Sector.largestHeight
        numberOfRings = dataSource.numberOfRings(self) ?? CHRadarGraphDefaultValues.Graph.numberOfRings
        sectorsCount = CGFloat(dataSource.numberOfSectors(self) ?? CHRadarGraphDefaultValues.Sector.count)
        sectorsDataCount = CGFloat(dataSource.numberOfDataSectors(self) ?? CHRadarGraphDefaultValues.Sector.count)
        center = dataSource.centerOfGraph(self) ?? CHRadarGraphDefaultValues.Graph.center
        radius = dataSource.radiusOfGraph(self) ?? CHRadarGraphDefaultValues.Graph.radius

        let x = center.x - radius
        let y = center.y - radius
        position = CGPoint(x: x, y: y)

        let width = center.x + radius - position.x
        let height = center.y + radius - position.y
        size = CGSize(width: width, height: height)

        backgroundColor = dataSource.backgroundColorOfGraph(self) ?? CHRadarGraphDefaultValues.Graph.backgroundColor
        strokeColorOfSectorLines = dataSource.strokeColorOfSectorLines(self) ?? CHRadarGraphDefaultValues.Sector.strokeColorOfSectorLines
        strokeWidthOfSectorLines = dataSource.strokeWidthOfSectorLines(self) ?? CHRadarGraphDefaultValues.Sector.strokeWidthOfSectorLines
        strokeColorOfRings = dataSource.strokeColorOfRings(self) ?? CHRadarGraphDefaultValues.Rings.strokeColorOfRings
        strokeWidthOfRings = dataSource.strokeWidthOfRings(self) ?? CHRadarGraphDefaultValues.Rings.strokeWidthOfRings
    }

    public func reload() {
        delegate.willDisplayGraph(self)
        let endAngle = startAngle + CGFloat(sectorsDataCount) * CHRadarGraphView.degreesToRadians(CGFloat(self.degreesOfCircle / self.sectorsCount))
        let view: UIView = UIView(frame: CGRect(origin: position, size: size))
        view.backgroundColor = backgroundColor
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        drawRings(endAngle)
        drawPieChart()
        drawSectors()
        view.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        delegate.didDisplayGraph(self)
    }

    // Circles
    func drawRings(endAngle: CGFloat) {
        if numberOfRings < 1 {
            return
        }

        for index in 1...numberOfRings {
            delegate.willDisplayRing(self, index: index)
            let pathRadius = (CGFloat(index) / CGFloat(numberOfRings)) * radius
            let path = buildPath(pathRadius, startAngle: startAngle, endAngle: endAngle)
            let shape = buildShape(path, fillColor: UIColor.clearColor().CGColor, strokeColor: strokeColorOfRings.CGColor, lineWidth: strokeWidthOfRings)
            view.layer.addSublayer(shape)
            delegate.didDisplayRing(self, index: index)
        }
    }

    // Divisions
    func drawSectors() {
        for index in 0...Int(sectorsDataCount) {
            let path = UIBezierPath(rect: CGRectMake(center.x, center.y, radius, 0.1))
            var transform = CGAffineTransformIdentity;
            transform = CGAffineTransformTranslate(transform, center.x, center.y);
            transform = CGAffineTransformRotate(transform, startAngle + CHRadarGraphView.degreesToRadians(CGFloat(CGFloat(index) * (degreesOfCircle / sectorsCount))));
            transform = CGAffineTransformTranslate(transform, -center.x, -center.y);
            path.applyTransform(transform)

            let shape = buildShape(path, fillColor: backgroundColor.CGColor, strokeColor: strokeColorOfSectorLines.CGColor, lineWidth: strokeWidthOfSectorLines)
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
            sectorCell = dataSource.sectorCellForPositionAtIndex(self, index: index)!
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
            label.textAlignment = .Right
            label.font = UIFont.systemFontOfSize(12.0)
            label.sizeToFit()
            label.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.addSubview(label)
            delegate.didDisplaySector(self, sector: sectorCell, index: index)
        }
    }

    func buildPath(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(center)
        path.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.moveToPoint(center)
        path.closePath()
        return path
    }

    func buildShape(path: UIBezierPath, fillColor: CGColor?, strokeColor: CGColor?, lineWidth: CGFloat?) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = path.CGPath

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
        return degrees * (CGFloat(M_PI) / (360 / 2))
    }

}