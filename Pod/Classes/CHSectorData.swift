//
//  CHSlice.swift
//  CHRadarGraph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import Foundation

protocol CHSliceProtocol {
    var height: CGFloat { get }
    var label: String? { get }
}

public struct CHSectorData: CHSliceProtocol {

    public var height: CGFloat
    public var label: String?

    public init(_ height: CGFloat, _ label: String?) {
        self.height = height
        self.label = label
    }

}