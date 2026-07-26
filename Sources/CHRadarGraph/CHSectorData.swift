import Foundation

protocol CHSliceProtocol {
    var height: CGFloat { get }
    var label: String? { get }
}

/// A single data point for a radar graph: a height and an optional label,
/// e.g. `CHSectorData(7, "7am")`. Typically collected into a
/// ``CHSectorDataCollection``.
public struct CHSectorData: CHSliceProtocol {

    /// The data value this point represents.
    public var height: CGFloat
    /// An optional label for this point, e.g. a time or category name.
    public var label: String?

    public init(_ height: CGFloat, _ label: String?) {
        self.height = height
        self.label = label
    }

}
