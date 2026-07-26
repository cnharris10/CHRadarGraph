# ``CHRadarGraph``

A UIKit radar (rose/polar) chart, with a SwiftUI wrapper for callers who'd
rather not implement its delegate/dataSource API directly.

## Overview

A radar graph is a circle divided into sectors, each drawn out from the
center to a radius proportional to its data value - useful for cyclical data
(a day's hours, a week's days) where a bar chart's straight axis would
otherwise wrap around awkwardly.

![A radar graph rendered on iPhone and iPad with a sequential blue palette, showing PR counts across a workday.](example)

The library ships two ways to build one:

- ``CHRadarGraphView`` - a UIKit delegate/dataSource pair, mirroring
  `UITableView`. Gives full control (per-ring labels, a custom gap-centering
  angle) at the cost of implementing about a dozen methods.
- `CHRadarGraph` (iOS 14+) - a SwiftUI `View` that wraps the above behind a
  single initializer taking a plain array of sectors, for the common case.

### Getting started with UIKit

```swift
import CHRadarGraph

class ViewController: UIViewController, CHRadarGraphViewDataSource, CHRadarGraphViewDelegate {
    var graph: CHRadarGraphView?

    func setUpGraph() {
        graph = CHRadarGraphView(delegate: self, dataSource: self)
        view.addSubview(graph!.view)
        graph!.reload()
    }

    // ... CHRadarGraphViewDataSource/CHRadarGraphViewDelegate conformance
}
```

### Getting started with SwiftUI

```swift
import SwiftUI
import CHRadarGraph

struct ContentView: View {
    var body: some View {
        CHRadarGraph(
            sectors: [
                .init(height: 3, label: "Mon", color: .blue),
                .init(height: 7, label: "Tue", color: .blue)
            ],
            title: "PRs created"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

## Topics

### UIKit

- ``CHRadarGraphView``
- ``CHRadarGraphViewDelegate``
- ``CHRadarGraphViewDataSource``

### Sector data

- ``CHSectorCell``
- ``CHSectorLabel``
- ``CHSectorData``
- ``CHSectorDataCollection``
