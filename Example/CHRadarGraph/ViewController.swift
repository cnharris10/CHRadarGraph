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

    func sectorColor(value: CGFloat) -> UIColor {
        switch(value) {
        case 1:
            return UIColor(red: 0/255, green: 73/255, blue: 165/255, alpha: 1)
        case 2:
            return UIColor(red: 70/255, green: 125/255, blue: 195/255, alpha: 1)
        case 3:
            return UIColor(red: 126/255, green: 184/255, blue: 224/255, alpha: 1)
        case 4:
            return UIColor(red: 160/255, green: 214/255, blue: 243/255, alpha: 1)
        case 5:
            return UIColor(red: 221/255, green: 241/255, blue: 250/255, alpha: 1)
        case 6:
            return UIColor(red: 251/255, green: 224/255, blue: 198/255, alpha: 1)
        case 7:
            return UIColor(red: 251/255, green: 201/255, blue: 157/255, alpha: 1)
        case 8:
            return UIColor(red: 254/255, green: 161/255, blue: 102/255, alpha: 1)
        case 9:
            return UIColor(red: 255/255, green: 124/255, blue: 32/255, alpha: 1)
        case 10:
            return UIColor(red: 255/255, green: 50/255, blue: 0, alpha: 1)
        default:
            return UIColor.white
        }
    }

}

extension ViewController: CHRadarGraphViewDataSource {

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
        return sectorData!.count
    }

    func backgroundColorOfGraph(graphView: CHRadarGraphView) -> UIColor {
        return UIColor.white
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
        let height = data.height
        let label = CHSectorLabel(text: data.label, isBold: false, color: UIColor.black.cgColor)
        return CHSectorCell(height: height, backgroundColor: sectorColor(value: height).cgColor, label: label)
    }

}

extension ViewController: CHRadarGraphViewDelegate {

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
