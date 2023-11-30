import Foundation

public protocol CHRadarGraphViewDelegate {

    // Graph
    func willDisplayGraph(_ graphView: CHRadarGraphView)
    func didDisplayGraph(_ graphView: CHRadarGraphView)

    // Rings
    func willDisplayRing(_ graphView: CHRadarGraphView, index: Int)
    func didDisplayRing(_ graphView: CHRadarGraphView, index: Int)

    // Sectors
    func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)
    func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)
}

public protocol CHRadarGraphViewDataSource {
    func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint
    func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat
    func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat
    func numberOfSectors(_ graphView: CHRadarGraphView) -> Int
    func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int
    func numberOfRings(_ graphView: CHRadarGraphView) -> Int
    func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat
    func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell?
    func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor
    func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat
    func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat
}

public struct CHRadarGraphView {

    fileprivate let degreesOfCircle: CGFloat = 360

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

        backgroundColor = dataSource.backgroundColorOfGraph(self)
        strokeColorOfSectorLines = dataSource.strokeColorOfSectorLines(self)
        strokeWidthOfSectorLines = dataSource.strokeWidthOfSectorLines(self)
        strokeColorOfRings = dataSource.strokeColorOfRings(self)
        strokeWidthOfRings = dataSource.strokeWidthOfRings(self)
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
        view.layer.contents = UIGraphicsGetImageFromCurrentImageContext()!.cgImage
        UIGraphicsEndImageContext()
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
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.sizeToFit()
            label.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.addSubview(label)
            delegate.didDisplaySector(self, sector: sectorCell, index: index)
        }
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
