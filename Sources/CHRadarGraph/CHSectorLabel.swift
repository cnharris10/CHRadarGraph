import Foundation
import UIKit

protocol CHSectorLabelProtocol {
    var text: String? { get }
    var isBold: Bool { get }
    var color: CGColor? { get }
}

/// The label drawn next to a sector, e.g. a time or category name. Part of a
/// ``CHSectorCell``.
public struct CHSectorLabel: CHSectorLabelProtocol {

    /// The label's text.
    public var text: String?
    /// Whether the label is drawn in bold.
    public var isBold: Bool
    /// The label's text color. Defaults to black.
    public var color: CGColor?

    public init(text: String?, isBold: Bool = false, color: CGColor = UIColor.black.cgColor) {
        self.text = text
        self.isBold = isBold
        self.color = color
    }

}
