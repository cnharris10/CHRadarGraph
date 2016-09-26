import Quick
import Nimble
@testable import CHRadarGraph

class CHGraphViewSpec: QuickSpec {

    override func spec() {
        describe("CHRadarGraphView") {

            var testViewController: TestViewController!
            var dataSource: CHRadarGraphViewDataSource!

            beforeEach {
                testViewController = TestViewController()
                let _ = testViewController.view!
                dataSource = testViewController.graph!.dataSource
            }

            context("#init") {
                it("will load a CHRadarGraphView") {
                    let graph = testViewController!.graph
                    expect(graph!.view).to(beAKindOf(UIView.self))
                    expect(graph!.startAngle) == CHRadarGraphView.degreesToRadians(degrees: dataSource.startingAngleInDegrees(graphView: graph!))
                    expect(graph!.largestHeight) == dataSource.largestHeightForSectorCell(graphView: graph!)
                    expect(graph!.numberOfRings) == dataSource.numberOfRings(graphView: graph!)
                    expect(Int(graph!.sectorsCount)).to(equal(dataSource.numberOfSectors(graphView: graph!)))
                    expect(Int(graph!.sectorsDataCount)).to(equal(dataSource.numberOfDataSectors(graphView: graph!)))
                    expect(graph!.center) == dataSource.centerOfGraph(graphView: graph!)
                    expect(graph!.radius) == dataSource.radiusOfGraph(graphView: graph!)
                    expect(graph!.backgroundColor) == dataSource.backgroundColorOfGraph(graphView: graph!)
                    expect(graph!.strokeColorOfSectorLines) == dataSource.strokeColorOfSectorLines(graphView: graph!)
                    expect(graph!.strokeWidthOfSectorLines) == dataSource.strokeWidthOfSectorLines(graphView: graph!)
                    expect(graph!.strokeColorOfRings) == dataSource.strokeColorOfRings(graphView: graph!)
                    expect(graph!.strokeWidthOfRings) == dataSource.strokeWidthOfRings(graphView: graph!)
                }
            }

            context("#reload") {
                it("will load a CHRadarGraphView") {
                    testViewController.graph!.reload()
                    expect(testViewController.graph!.backgroundColor) == dataSource.backgroundColorOfGraph(graphView: testViewController.graph!)
                }
            }

            context("#buildPath") {
                it("will return a UIBezierPath") {
                    let startAngle = CHRadarGraphView.degreesToRadians(degrees: 90)
                    let endAngle = CHRadarGraphView.degreesToRadians(degrees: 180)
                    let path = testViewController.graph?.buildPath(radius: 1.0, startAngle: startAngle, endAngle: endAngle)
                    expect(path).to(beAKindOf(UIBezierPath.self))
                }
            }

            context("#buildShape") {
                it("will return a CAShapeLayer") {
                    let startAngle = CHRadarGraphView.degreesToRadians(degrees: 90)
                    let endAngle = CHRadarGraphView.degreesToRadians(degrees: 180)
                    let fillColor = UIColor.black.cgColor
                    let strokeColor = UIColor.gray.cgColor
                    let lineWidth: CGFloat = 1.0
                    let path = testViewController.graph?.buildPath(radius: 1.0, startAngle: startAngle, endAngle: endAngle)
                    let shape = testViewController.graph?.buildShape(path: path!, fillColor: fillColor, strokeColor: strokeColor, lineWidth: lineWidth)
                    expect(shape).to(beAKindOf(CAShapeLayer.self))
                    expect(shape!.fillColor).to(equal(fillColor))
                    expect(shape!.strokeColor).to(equal(strokeColor))
                    expect(shape!.lineWidth) == lineWidth
                }
            }

            context("#degressToRadians") {
                it("will convert degrees to radians") {
                    let degrees: CGFloat = 180
                    let radians: CGFloat = CHRadarGraphView.degreesToRadians(degrees: degrees)
                    expect(radians).to(beCloseTo(3.14159265, within: 0.00000001))
                }
            }

        }
    }
    
}

// Mark: - TestViewController

class TestViewController: UIViewController {

    var sectorData: CHSectorDataCollection<CHSectorData>?
    var graph: CHRadarGraphView?

    override func viewDidLoad() {
        super.viewDidLoad()
        sectorData = CHSectorDataCollection([
            CHSectorData(1, "7am"),
            CHSectorData(2, "7:15"),
            CHSectorData(3, "7:30"),
            CHSectorData(4, "7:45"),
            CHSectorData(5, "8am"),
            CHSectorData(6, "8:15"),
            CHSectorData(7, "8:30"),
            CHSectorData(8, "8:45"),
            CHSectorData(9, "9am"),
            CHSectorData(10, "9:15"),
            CHSectorData(1, "9:30"),
            CHSectorData(2, "9:45"),
            CHSectorData(3, "10am"),
            CHSectorData(4, "10:15"),
            CHSectorData(5, "10:30"),
            CHSectorData(6, "10:45"),
            CHSectorData(7, "11am"),
            CHSectorData(8, "11:15"),
            CHSectorData(9, "11:30"),
            CHSectorData(10, "11:45"),
            CHSectorData(1, "12pm"),
            CHSectorData(2, "12:15"),
            CHSectorData(3, "12:30"),
            CHSectorData(4, "12:45"),
            CHSectorData(5, "1pm"),
            CHSectorData(6, "1:15"),
            CHSectorData(7, "1:30"),
            CHSectorData(8, "1:45"),
            CHSectorData(9, "2pm"),
            CHSectorData(10, "2:15"),
            CHSectorData(1, "2:30"),
            CHSectorData(2, "2:45"),
            CHSectorData(9, "3pm"),
            CHSectorData(10, "3:15"),
            CHSectorData(1, "3:30"),
            CHSectorData(2, "3:45"),
            CHSectorData(3, "4pm")
        ])
        graph = CHRadarGraphView(delegate: self, dataSource: self)
        view.addSubview(graph!.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        graph!.reload()
    }

}

extension TestViewController: CHRadarGraphViewDataSource {

    func centerOfGraph(graphView: CHRadarGraphView) -> CGPoint {
        return CGPoint(x: 500, y: 500)
    }

    func radiusOfGraph(graphView: CHRadarGraphView) -> CGFloat {
        return 400.0
    }

    func largestHeightForSectorCell(graphView: CHRadarGraphView) -> CGFloat {
        return 10
    }

    func numberOfSectors(graphView: CHRadarGraphView) -> Int {
        return 50
    }

    func numberOfRings(graphView: CHRadarGraphView) -> Int {
        return 10
    }

    func numberOfDataSectors(graphView: CHRadarGraphView) -> Int {
        return self.sectorData!.count
    }

    func backgroundColorOfGraph(graphView: CHRadarGraphView) -> UIColor {
        return UIColor.white
    }

    func strokeColorOfRings(graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func strokeColorOfDiskLines(_ graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func strokeColorOfSectorLines(graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func startingAngleInDegrees(graphView: CHRadarGraphView) -> CGFloat {
        return 136.5
    }

    func strokeWidthOfRings(graphView: CHRadarGraphView) -> CGFloat {
        return 1.0
    }

    func strokeWidthOfSectorLines(graphView: CHRadarGraphView) -> CGFloat {
        return 1.0
    }

    func sectorCellForPositionAtIndex(graph: CHRadarGraphView, index: Int) -> CHSectorCell? {
        let data = sectorData![index]
        let height = data!.height
        let label = CHSectorLabel(text: data!.label, isBold: false, color: UIColor.black.cgColor)
        return CHSectorCell(height: height, backgroundColor: UIColor.white.cgColor, label: label)
    }

}

extension TestViewController: CHRadarGraphViewDelegate {

    func willDisplayGraph(graphView: CHRadarGraphView) {
        print("Graph will display! - graph: \(graphView)")
    }

    func didDisplayGraph(graphView: CHRadarGraphView) {
        print("Graph did display! - graph: \(graphView)")
    }

    func willDisplayRing(graphView: CHRadarGraphView, index: Int) {
        print("Ring did display - graph: \(graphView), index: \(index)")
    }

    func didDisplayRing(graphView: CHRadarGraphView, index: Int) {
        print("Ring did display - graph: \(graphView), index: \(index)")
    }
    
    func willDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        print("Sector will display! - graph: \(graphView), sector: \(sector), index: \(index)")
    }
    
    func didDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int) {
        print("Sector did display! - graph: \(graphView), sector: \(sector), index: \(index)")
    }

}
