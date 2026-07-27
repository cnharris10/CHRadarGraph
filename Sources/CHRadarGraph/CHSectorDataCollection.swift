import Foundation

protocol CHSectorDataCollectionProtocol {
    associatedtype SectorData
    init(_ data: [SectorData])
}

/// An ordered collection of data points (typically ``CHSectorData``) for a
/// radar graph, with bounds-safe subscript access - `collection[index]`
/// returns `nil` rather than trapping for an out-of-range index.
public struct CHSectorDataCollection<T>: CHSectorDataCollectionProtocol {

    public typealias SectorData = T

    public var startIndex = 0
    public var endIndex: Int
    public var currentIndex = 0
    /// The underlying data points, in order.
    public var data: [SectorData]
    /// The number of data points in the collection.
    public var count: Int {
        return data.count
    }

    public init(_ data: [SectorData]) {
        self.data = data
        self.endIndex = data.count - 1
    }

    /// Returns the data point at `index`, or `nil` if `index` is out of range.
    public subscript(index: Int) -> T? {
        get {
            return index >= 0 && index < count ? data[index] : nil
        }
    }

}
