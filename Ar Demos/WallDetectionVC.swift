
import UIKit

class WallDetectionVC: UIViewController, ARSCNViewDelegate {
    @IBOutlet var arView: ARSCNView!

    let configuration = ARWorldTrackingConfiguration()
      //MARK:- Initializers -
      class func initViewController() -> WallDetectionVC{
          let vc = mainStoryBoard.instantiateViewController(withIdentifier: "WallDetectionVC") as! WallDetectionVC
          return vc
      }
      override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    //    configuration.planeDetection = [.horizontal, .vertical]
        configuration.planeDetection = [.vertical]

        arView.session.run(configuration, options: [])
        arView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        arView.delegate = self
      }
      
      func create(_ name: String, anchor: ARPlaneAnchor) -> SCNNode {
        let node = SCNNode()
        node.name = name
        node.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        node.geometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
//        node.geometry?.firstMaterial?.diffuse.contents = name == "wall" ? #imageLiteral(resourceName: "Wall") : #imageLiteral(resourceName: "Floor")
         node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.geometry?.firstMaterial?.isDoubleSided = true
        node.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        return node
      }
      
      func removeNode(named: String) {
        arView.scene.rootNode.enumerateChildNodes { (node, _) in
          if node.name == named {
            node.removeFromParentNode()
          }
        }
      }
      
      override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
      }
      
      func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("New plane anchor found with extent:", anchorPlane.extent)
        var name = "wall"
        if anchorPlane.alignment == ARPlaneAnchor.Alignment.vertical {
          name = "wall"
        } else {
          name = "floor"
        }
        let planeNode = create(name, anchor: anchorPlane)
        node.addChildNode(planeNode)
      }
      
      func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("Plane anchor updated with extent:", anchorPlane.extent)
        var name = "wall"
        if anchorPlane.alignment == ARPlaneAnchor.Alignment.vertical {
          name = "wall"
        } else {
          name = "floor"
        }
        removeNode(named: name)
        let planeNode = create(name, anchor: anchorPlane)
        node.addChildNode(planeNode)
      }
      
      func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let anchorPlane = anchor as? ARPlaneAnchor else { return }
        print("Plane anchor removed with extent:", anchorPlane.extent)
        var name = "wall"
        if anchorPlane.alignment == ARPlaneAnchor.Alignment.vertical {
          name = "wall"
        } else {
          name = "floor"
        }
        removeNode(named: name)
      }
      

}

extension Int {
  var degreesToRadians: Double { return Double(self) * .pi/180 }
}
 
