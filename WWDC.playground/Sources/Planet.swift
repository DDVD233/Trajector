import UIKit

public class Planet: Ellipse {
    public var attachment: UIAttachmentBehavior!
    public var gravity: UIFieldBehavior!
    
    public init(centerX: Double, centerY: Double, radius: Double, density: Double = 1) {
        super.init(frame: CGRect(x: centerX - radius, y: centerY - radius, width: 2*radius, height: 2*radius))
        backgroundColor = UIColor.gray
        layer.cornerRadius = CGFloat(radius)
        layer.masksToBounds = true
        layer.contents = UIImage(named: "Earth.jpg")?.cgImage
        attachment = UIAttachmentBehavior(item: self, offsetFromCenter: UIOffset(horizontal: 3, vertical: 3), attachedToAnchor: CGPoint(x: centerX, y: centerY))
        gravity = UIFieldBehavior.radialGravityField(position: CGPoint(x: centerX, y: centerY))
        gravity.strength = CGFloat(radius / 19 * density)
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }
}



