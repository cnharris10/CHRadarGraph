import Foundation

struct CHRadarGraphDefaultValues {

    static let greyColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)

    struct Graph {
        static let center = CGPoint(x: 300,y: 300)
        static let radius = CGFloat(200)
        static let size = CGSize(width: 400,height: 400)
        static let postion = CGPoint.zero
        static let numberOfRings = 10
        static let backgroundColor = UIColor.white
        static let startingAngleInDegrees = CGFloat(0)
    }

    struct Rings {
        static let strokeColorOfRings = greyColor
        static let strokeWidthOfRings = CGFloat(1)
    }

    struct Sector {
        static let largestHeight = CGFloat(5)
        static let total = 10
        static let count = 8
        static let strokeColorOfSectorLines = greyColor
        static let strokeWidthOfSectorLines = CGFloat(1)
    }

}
