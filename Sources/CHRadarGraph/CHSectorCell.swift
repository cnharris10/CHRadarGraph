import Foundation
import CoreGraphics

protocol CHSectorCellProtocol {
    var height: CGFloat { get }
    var backgroundColor: CGColor { get }
    var label: CHSectorLabel? { get }
}

/// The content drawn for a single sector: how far it reaches, what color it
/// is, and an optional label. Returned by
/// ``CHRadarGraphViewDataSource/sectorCellForPositionAtIndex(_:index:)``.
public struct CHSectorCell: CHSectorCellProtocol {

    /// The sector's data value - how far it reaches, relative to
    /// ``CHRadarGraphViewDataSource/largestHeightForSectorCell(_:)``.
    public var height: CGFloat
    /// The fill color for this sector's wedge.
    public var backgroundColor: CGColor
    /// An optional label drawn just past the sector's outer edge.
    public var label: CHSectorLabel?

    public init(height: CGFloat, backgroundColor: CGColor, label: CHSectorLabel?) {
        self.height = height
        self.backgroundColor = backgroundColor
        self.label = label
    }

}
