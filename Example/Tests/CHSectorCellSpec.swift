import Quick
import Nimble
import CHRadarGraph

class CHSectorCellSpec: QuickSpec {

    override func spec() {
        describe("CHSectorCell") {

            context("#init") {

                it("will initialize") {
                    let height = CGFloat(1.0)
                    let backgroundColor = UIColor.black.cgColor
                    let label = CHSectorLabel(text: "label")
                    let cell = CHSectorCell(height: height, backgroundColor: backgroundColor, label: label)
                    expect(cell.height) == height
                    expect(cell.backgroundColor) === backgroundColor
                    expect(cell.label?.text) == "label"
                }

            }
        }
    }

}
