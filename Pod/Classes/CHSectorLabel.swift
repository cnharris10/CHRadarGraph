//
//  CHSectorLabel.swift
//  CHRadarGraph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

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

    public init(text: String?, isBold: Bool = false, color: CGColor = UIColor.blackColor().CGColor) {
        self.text = text
        self.isBold = isBold
        self.color = color
    }

}