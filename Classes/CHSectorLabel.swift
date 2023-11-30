import Foundation

protocol CHSectorLabelProtocol {
    var text: String? { get }
    var isBold: Bool { get }
    var color: CGColor? { get }
}

public struct CHSectorLabel: CHSectorLabelProtocol {

    public var text: String?
    public var isBold: Bool
    public var color: CGColor?

    public init(text: String?, isBold: Bool = false, color: CGColor = UIColor.black.cgColor) {
        self.text = text
        self.isBold = isBold
        self.color = color
    }

}
