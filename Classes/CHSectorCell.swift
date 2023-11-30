import Foundation

protocol CHSectorCellProtocol {
    var height: CGFloat { get }
    var backgroundColor: CGColor { get }
    var label: CHSectorLabel? { get }
}

public struct CHSectorCell: CHSectorCellProtocol {

    public var height: CGFloat
    public var backgroundColor: CGColor
    public var label: CHSectorLabel?

    public init(height: CGFloat, backgroundColor: CGColor, label: CHSectorLabel?) {
        self.height = height
        self.backgroundColor = backgroundColor
        self.label = label
    }

}
