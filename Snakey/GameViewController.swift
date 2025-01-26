import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Create and configure the scene
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            
            // Debug options (optional)
            view.showsFPS = true
            view.showsNodeCount = true
            
            view.presentScene(scene)
        }
    }
}
