import XCTest
@testable import CHRadarGraph

final class CHRadarGraphTests: XCTestCase {

    func testSectorDataStoresHeightAndLabel() {
        let sector = CHSectorData(7, "7am")
        XCTAssertEqual(sector.height, 7)
        XCTAssertEqual(sector.label, "7am")
    }

    func testSectorDataCollectionCount() {
        let collection = CHSectorDataCollection([
            CHSectorData(1, "7am"),
            CHSectorData(2, "8am"),
            CHSectorData(3, "9am")
        ])
        XCTAssertEqual(collection.count, 3)
    }

    func testSectorDataCollectionSubscript() {
        let collection = CHSectorDataCollection([
            CHSectorData(1, "7am"),
            CHSectorData(2, "8am")
        ])
        XCTAssertEqual(collection[0]?.label, "7am")
        XCTAssertEqual(collection[1]?.label, "8am")
        XCTAssertNil(collection[2])
    }
}
