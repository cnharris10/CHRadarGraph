//
//  CHSliceCollection.swift
//  CHRadarGraph
//
//  Created by Christopher Harris on 4/9/16.
//  Copyright © 2016 Christopher Harris. All rights reserved.
//

import Foundation

protocol CHSectorDataCollectionProtocol: CollectionType {
    associatedtype SectorData
    init(_ data: [SectorData])
}

public struct CHSectorDataCollection<T>: CHSectorDataCollectionProtocol {

    public typealias SectorData = T
    public typealias Element = T

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

    public func generate() -> AnyGenerator<T> {
        var nextIndex = data.count - 1

        return AnyGenerator<T> {
            if (nextIndex < 0) {
                return nil
            }
            nextIndex -= 1
            return self.data[nextIndex]
        }
    }

    public mutating func next() -> Element? {
        if currentIndex < data.count {
            currentIndex += 1
            return data[currentIndex]
        }
        return nil
    }

    public subscript(index: Int) -> T {
        get {
            return data[index]
        }
    }



}