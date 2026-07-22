# CHRadarGraph

## Usage

To run the example project, open `Example/CHRadarGraph.xcworkspace` (or `Example/CHRadarGraph.xcodeproj`) in Xcode. The Example app depends on this package as a local Swift package, so no separate install step is required.

## Requirements
* iOS 13+
* Swift 6

## Example
![alt text](http://i.imgur.com/xEUetr6.png?1 "Radar Graph")

## Installation

CHRadarGraph is available through the [Swift Package Manager](https://www.swift.org/documentation/package-manager/). To install
it, add it as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cnharris10/CHRadarGraph.git", from: "0.4.0")
]
```

Or add it via Xcode: **File > Add Package Dependencies...** and enter the repository URL.

## Changelog
* v0.4.0: Convert to Swift Package Manager, adopt Swift 6 language mode (iOS 13+ minimum deployment target). Example app graph now sizes itself to the current view bounds (fixes clipping on iPad portrait) and starts at an angle that keeps the first/last data sectors mirror-symmetric about the bottom of the circle
* v0.3.0: Convert to Swift 5 & iOS 13+
* v0.2.1: Convert to Swift 3.0
* v0.1.5: Convert to Swift 2.3
* v0.1.4: Added more Unit tests
* v0.1.3: Added Unit tests
* v0.1.1: Removed dataSource methods `positionOfGraph` and `sizeOfGraph`

## Documentation

### Delegate methods:

Invoked before graph rendering

    func willDisplayGraph(_ graphView: CHRadarGraphView)

Invoked after graph rendering

    func didDisplayGraph(_ graphView: CHRadarGraphView)

Invoked before each ring rendering

    func willDisplayRing(_ graphView: CHRadarGraphView, index: Int)

Invoked after each ring rendering

    func didDisplayRing(_ graphView: CHRadarGraphView, index: Int)

Invoked before each sector rendering

    func willDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

Invoked after each sector rendering

    func didDisplaySector(_ graphView: CHRadarGraphView, sector: CHSectorCell, index: Int)

###DataSource methods:

Position and size of graph are automatically determined by center point and radius

    func centerOfGraph(_ graphView: CHRadarGraphView) -> CGPoint
    func radiusOfGraph(_ graphView: CHRadarGraphView) -> CGFloat

Height for largest sector cell.  This would be the largest Y-value on on a classic bar chart.

    func largestHeightForSectorCell(_ graphView: CHRadarGraphView) -> CGFloat

The total number of data points that CAN be shown on the graph.

    func numberOfSectors(_ graphView: CHRadarGraphView) -> Int

The total number of data points that WILL be shown on the graph.  For a graph that shows data around the entire 360 degress, this number should be equal to: `func numberOfSectors(_ graphView: CHRadarGraphView) -> Int`

    func numberOfDataSectors(_ graphView: CHRadarGraphView) -> Int

The number of Y points on the graph.  For example, if your largest Y-point is 10, there should be at least 10 rings shown.

    func numberOfRings(_ graphView: CHRadarGraphView) -> Int

The angle on the graph where the first data point is rendered.  Defaults to 0.

    func startingAngleInDegrees(_ graphView: CHRadarGraphView) -> CGFloat

Similar to `tableView#cellForRowAtIndexPath`, the callback  to render data on graph at specific positions.

Stroke colors and line widths:

    func sectorCellForPositionAtIndex(_ graph: CHRadarGraphView, index: Int) -> CHSectorCell?
    func backgroundColorOfGraph(_ graphView: CHRadarGraphView) -> UIColor
    func strokeColorOfRings(_ graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfRings(_ graphView: CHRadarGraphView) -> CGFloat
    func strokeColorOfSectorLines(_ graphView: CHRadarGraphView) -> UIColor
    func strokeWidthOfSectorLines(_ graphView: CHRadarGraphView) -> CGFloat

![alt text](http://i.imgur.com/PYd1AMS.png?1 "Radar Graph Explained")

## Author

Christopher Harris, cnharris@gmail.com

## License

CHRadarGraph is available under the MIT license. See the LICENSE file for more info.
