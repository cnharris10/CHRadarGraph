import Quick
import Nimble
@testable import CHRadarGraph

class CHGraphViewSpec: QuickSpec {

    override func spec() {
        describe("CHRadarGraphView") {

            var testViewController: TestViewController!
            var view: UIView!
            var dataSource: CHRadarGraphViewDataSource!
            var delegate: CHRadarGraphViewDelegate!

            beforeEach {
                testViewController = TestViewController()
                view = testViewController!.view
                dataSource = testViewController.graph!.dataSource
                delegate = testViewController.graph!.delegate
            }

            context("#init") {
                it("will load a CHRadarGraphView") {
                    let graph = testViewController!.graph
                    expect(graph!.view).to(beAKindOf(UIView))
                    expect(graph!.delegate).to(beTruthy())
                    expect(graph!.dataSource).to(beTruthy())
                    expect(graph!.startAngle) == CHRadarGraphView.degreesToRadians(dataSource.startingAngleInDegrees(graph!))
                    expect(graph!.largestHeight) == dataSource.largestHeightForSectorCell(graph!)
                    expect(graph!.numberOfRings) == dataSource.numberOfRings(graph!)
                    expect(graph!.sectorsCount as NSNumber) == dataSource.numberOfSectors(graph!)
                    expect(graph!.sectorsDataCount as NSNumber) == dataSource.numberOfDataSectors(graph!)
                    expect(graph!.center) == dataSource.centerOfGraph(graph!)
                    expect(graph!.radius) == dataSource.radiusOfGraph(graph!)
                    expect(graph!.backgroundColor) == dataSource.backgroundColorOfGraph(graph!)
                    expect(graph!.strokeColorOfSectorLines) == dataSource.strokeColorOfSectorLines(graph!)
                    expect(graph!.strokeWidthOfSectorLines) == dataSource.strokeWidthOfSectorLines(graph!)
                    expect(graph!.strokeColorOfRings) == dataSource.strokeColorOfRings(graph!)
                    expect(graph!.strokeWidthOfRings) == dataSource.strokeWidthOfRings(graph!)
                }
            }

            context("#reload") {
                it("will load a CHRadarGraphView") {
                    testViewController.graph!.reload()
                    expect(testViewController.graph!.backgroundColor) == dataSource.backgroundColorOfGraph(testViewController.graph!)
                }
            }

            context("#buildPath") {
                it("will return a UIBezierPath") {
                    let startAngle = CHRadarGraphView.degreesToRadians(90)
                    let endAngle = CHRadarGraphView.degreesToRadians(180)
                    let path = testViewController.graph?.buildPath(1.0, startAngle: startAngle, endAngle: endAngle)
                    expect(path).to(beAKindOf(UIBezierPath))
                }
            }

            context("#buildShape") {
                it("will return a CAShapeLayer") {
                    let startAngle = CHRadarGraphView.degreesToRadians(90)
                    let endAngle = CHRadarGraphView.degreesToRadians(180)
                    let fillColor = UIColor.blackColor().CGColor
                    let strokeColor = UIColor.grayColor().CGColor
                    let lineWidth: CGFloat = 1.0
                    let path = testViewController.graph?.buildPath(1.0, startAngle: startAngle, endAngle: endAngle)
                    let shape = testViewController.graph?.buildShape(path!, fillColor: fillColor, strokeColor: strokeColor, lineWidth: lineWidth)
                    expect(shape).to(beAKindOf(CAShapeLayer))
                    expect(shape!.fillColor).to(beTruthy())
                    expect(shape!.strokeColor).to(beTruthy())
                    expect(shape!.lineWidth) == lineWidth
                }
            }

            context("#degressToRadians") {
                it("will convert degrees to radians") {
                    let degrees: CGFloat = 180
                    let radians: CGFloat = CHRadarGraphView.degreesToRadians(degrees)
                    expect(radians) > 3.14159265
                    expect(radians) < 3.14159266
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        graph!.reload()
    }

}

extension TestViewController: CHRadarGraphViewDataSource {

    func centerOfGraph(graphView: CHRadarGraphView) -> CGPoint {
        return CGPointMake(500, 500)
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
        return UIColor.whiteColor()
    }

    func strokeColorOfRings(graphView: CHRadarGraphView) -> UIColor {
        return UIColor(red: 238/255.0, green: 238/255, blue: 238/255, alpha: 1.0)
    }

    func strokeColorOfDiskLines(graphView: CHRadarGraphView) -> UIColor {
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
        let label = CHSectorLabel(text: data!.label, isBold: false, color: UIColor.blackColor().CGColor)
        return CHSectorCell(height: height, backgroundColor: UIColor.whiteColor().CGColor, label: label)
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
