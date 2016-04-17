# CHRadarGraph

[![Version](https://img.shields.io/cocoapods/v/CHRadarGraph.svg?style=flat)](http://cocoapods.org/pods/CHRadarGraph)
[![License](https://img.shields.io/cocoapods/l/CHRadarGraph.svg?style=flat)](http://cocoapods.org/pods/CHRadarGraph)
[![Platform](https://img.shields.io/cocoapods/p/CHRadarGraph.svg?style=flat)](http://cocoapods.org/pods/CHRadarGraph)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
* iOS 9+
* Swift 2.2+

## Coming shortly...
* Unit Tests
* Features:
  * More control over label offsets
  * Shadows / Patterns within Sectors
  * Apple Watch support

## Example
![alt text](http://i.imgur.com/xEUetr6.png?1 "Radar Graph")

## Installation

CHRadarGraph is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod "CHRadarGraph", "~> 0.1.2"
```

## Changelog

v1.0.1: Removed dataSource methods `positionOfGraph` and `sizeOfGraph`

## Documentation

###Delegate methods:

Invoked before graph rendering

    func willDisplayGraph(graphView: CHRadarGraphView)

Invoked after graph rendering

    func didDisplayGraph(graphView: CHRadarGraphView)

Invoked before each ring rendering

    func willDisplayRing(graphView: CHRadarGraphView, index: Int)

Invoked after each ring rendering

    func didDisplayRing(graphView: CHRadarGraphView, index: Int)

Invoked before each sector rendering

    func willDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

Invoked after each sector rendering

    func didDisplaySector(graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

###DataSource methods:

Position and size of graph are automatically determined by center point and radius

    func centerOfGraph(graphView: CHRadarGraphView) -> CGPoint
    func radiusOfGraph(graphView: CHRadarGraphView) -> CGFloat

Height for largest sector cell.  This would be the largest Y-value on on a classic bar chart.

    func largestHeightForSectorCell(graphView: CHRadarGraphView) -> CGFloat

The total number of data points that CAN be shown on the graph.

    func numberOfSectors(graphView: CHRadarGraphView) -> Int

The total number of data points that WILL be shown on the graph.  For a graph that shows data around the entire 360 degress, this number should be equal to: `func numberOfSectors(graphView: CHRadarGraphView) -> Int`

    func numberOfDataSectors(graphView: CHRadarGraphView) -> Int

The number of Y points on the graph.  For example, if your largest Y-point is 10, there should be at least 10 rings shown.

    func numberOfRings(graphView: CHRadarGraphView) -> Int

The angle on the graph where the first data point is rendered.  Defaults to 0.

    func startingAngleInDegrees(graphView: CHRadarGraphView) -> CGFloat

Similar to `tableView#cellForRowAtIndexPath`, the callback  to render data on graph at specific positions.

Stroke colors and line widths:

    func sectorCellForPositionAtIndex(graph: CHRadarGraphView, index: Int) -> CHSectorCell?
    func backgroundColorOfGraph(graphView: CHRadarGraphView) -> UIColor
    func strokeColorOfRings(graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfRings(graphView: CHRadarGraphView) -> CGFloat
    func strokeColorOfSectorLines(graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfSectorLines(graphView: CHRadarGraphView) -> CGFloat

![alt text](http://i.imgur.com/PYd1AMS.png?1 "Radar Graph Explained")

## Author

[Christopher Harris](http://chrisharris.io), cnharris@gmail.com

## License

CHRadarGraph is available under the MIT license. See the LICENSE file for more info.
