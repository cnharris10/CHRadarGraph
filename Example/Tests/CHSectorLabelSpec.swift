import Quick
import Nimble
import CHRadarGraph

class CHSectorLabelSpec: QuickSpec {

    override func spec() {
        describe("CHSectorLabel") {

            var text: String!

            beforeEach {
                text = "text"
            }

            context("#init") {

                it("will initialize with text") {
                    let label = CHSectorLabel(text: text)
                    expect(label.text) == text
                }

                it("will initialize with text, boldness, and a color ") {
                    let isBold = true
                    let color = UIColor.blackColor().CGColor
                    let label = CHSectorLabel(text: text, isBold: isBold, color: color)
                    expect(label.text) == text
                }

            }
        }
    }
    
}
