//
//  CHSliceCollection.swift
//  CHRadarGraph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import Foundation

protocol CHSectorDataCollectionProtocol {
    associatedtype SectorData
    init(_ data: [SectorData])
}

public struct CHSectorDataCollection<T>: CHSectorDataCollectionProtocol {

    public typealias SectorData = T

    public var startIndex = 0
    public var endIndex: Int
    public var currentIndex = 0
    public var data: [SectorData]
    public var count: Int {
        return data.count
    }

    public init(_ data: [SectorData]) {
        self.data = data
        self.endIndex = data.count - 1
    }

    public subscript(index: Int) -> T? {
        get {
            return index < count ? data[index] : nil
        }
    }

}