import UIKit

public class Screen {
    public let height = 668.0
    public let width = 375.0
    public let center: CGPoint
    public let midX: Double
    public let midY: Double
    
    public init() {
        center = CGPoint(x: height/2, y: width/2)
        midX = width/2
        midY = height/2
    }
}
