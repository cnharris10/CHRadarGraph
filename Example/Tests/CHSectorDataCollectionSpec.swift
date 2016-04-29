import Quick
import Nimble
import CHRadarGraph

class CHSectorDataCollectionSpec: QuickSpec {

    override func spec() {
        describe("CHSectorDataCollection") {

            var height1: CGFloat!
            var label1: String!
            var height2: CGFloat!
            var label2: String!
            var sectorData: [CHSectorData]!
            var sdc: CHSectorDataCollection<CHSectorData>!

            beforeEach {
                height1 = 1.0
                label1 = "label1"
                height2 = 2.0
                label2 = "label2"
                sectorData = [
                    CHSectorData(height1, label1),
                    CHSectorData(height2, label2)
                ]
                sdc = CHSectorDataCollection(sectorData)
            }

            context("#init") {
                it("will initialize with text") {
                    let items = sdc.data
                    expect(items[0].height) == height1
                    expect(items[0].label) == label1
                    expect(items[1].height) == height2
                    expect(items[1].label) == label2
                    expect(items.endIndex) == sdc.count
                }
                
            }
            
        }
    }
    
}
