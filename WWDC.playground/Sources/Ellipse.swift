import UIKit

public class Ellipse: UIView {
    public override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}
