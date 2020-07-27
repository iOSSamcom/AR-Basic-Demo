//
//  ViewController.swift
//  Ar Demos
//
//  Created by Parth on 27/06/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit


class AddingTextVC: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var txtValue: UITextField!
    @IBOutlet var sceneView: ARSCNView!
    var currentAngleY: Float = 0.0
    var isRotating = false
    var currentNode: SCNNode?
    
    
    //MARK:- Initializers
       class func initViewController() -> AddingTextVC{
           let vc = mainStoryBoard.instantiateViewController(withIdentifier: "AddingTextVC") as! AddingTextVC
           return vc
       }
       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //1. Add A UIPinchGestureRecognizer So We Can Scale Our TextNode
        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleCurrentNode(_:)))
        self.view.addGestureRecognizer(scaleGesture)
        
        //2. Add A Tap Gesture Recogizer So We Can Place Our TextNode
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(placeOrAssignNode(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //3. Add A Rotation Gesture Recogizer So We Can Rotate Our TextNode
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        self.view.addGestureRecognizer(rotateGesture)
        //4. Add A Pan Gesture Recogizer So We Can Rotate Our TextNode
        let panGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        self.view.addGestureRecognizer(panGesture)
        
    }
  
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    @objc func placeOrAssignNode(_ gesture: UITapGestureRecognizer){

        //1. Get The Current Location Of The Tap
        let currentTouchLocation = gesture.location(in: self.sceneView)

        //2. If We Hit An SCNNode Set It As The Current Node So We Can Interact With It
        if let nodeHitTest = self.sceneView.hitTest(currentTouchLocation, options: nil).first?.node{

            currentNode = nodeHitTest
            return
        }

        //3. Do An ARHitTest For Features Points So We Can Place An SCNNode
        if let hitTest = self.sceneView.hitTest(currentTouchLocation, types: .featurePoint).first {

            //4. Get The World Transform
            let hitTestPosition = hitTest.worldTransform.columns.3

            //5. Add The TestNode At The Desired Position
            createTextFromPosition(SCNVector3(hitTestPosition.x, hitTestPosition.y, hitTestPosition.z))
            return

        }

    }

    func createTextFromPosition(_ position: SCNVector3){

        let textNode = SCNNode()

        //1. Create The Text Geometry With String & Depth Parameters
        let textGeometry = SCNText(string: txtValue.text ?? "" , extrusionDepth: 2)

        //2. Set The Font With Our Set Font & Size
        textGeometry.font = UIFont(name: "Helvatica", size: 1)

        //3. Set The Flatness To Zero (This Makes The Text Look Smoother)
//        textGeometry.flatness = 0

        //4. Set The Colour Of The Text
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white

        //5. Set The Text's Material
        textNode.geometry = textGeometry

        //6. Set The Pivot At The Center
        let min = textNode.boundingBox.min
        let max = textNode.boundingBox.max

        textNode.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )

        //7. Scale The Text So We Can Actually See It!
        textNode.scale = SCNVector3(0.005, 0.005 , 0.005)

        //8. Add It To The Hierachy & Position It
        self.sceneView.scene.rootNode.addChildNode(textNode)
        textNode.position = position

        //9. Set It As The Current Node
        currentNode = textNode
    }
    @objc func scaleCurrentNode(_ gesture: UIPinchGestureRecognizer) {

            if !isRotating, let selectedNode = currentNode{

                if gesture.state == .changed {

                    let pinchScaleX: CGFloat = gesture.scale * CGFloat((selectedNode.scale.x))
                    let pinchScaleY: CGFloat = gesture.scale * CGFloat((selectedNode.scale.y))
                    let pinchScaleZ: CGFloat = gesture.scale * CGFloat((selectedNode.scale.z))
                    selectedNode.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
                    gesture.scale = 1

                }

                if gesture.state == .ended {}
            }
        }
    
    
    
    @objc func panCurrentNode(_ gesture: UIPanGestureRecognizer) {

            
         }
        //----------------
        //MARK: Rotation
        //----------------

        /// Rotates The Currently Selected Node Around It's YAxis
        ///
        /// - Parameter gesture: UIRotationGestureRecognizer
        @objc func rotateNode(_ gesture: UIRotationGestureRecognizer){

            if let selectedNode = currentNode{

                //1. Get The Current Rotation From The Gesture
                let rotation = Float(gesture.rotation)

                //2. If The Gesture State Has Changed Set The Nodes EulerAngles.y
                if gesture.state == .changed{
                    isRotating = true
                    selectedNode.eulerAngles.y = currentAngleY + rotation
                }

                //3. If The Gesture Has Ended Store The Last Angle Of The CurrentNode
                if(gesture.state == .ended) {
                    currentAngleY = selectedNode.eulerAngles.y
                    isRotating = false
                }
            }

        }


   

    @IBAction func addClicked(_ sender: UIButton) {
        view.endEditing(true)
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
//        sceneView.scene.rootNode.addChildNode(addText())
//        sceneView.autoenablesDefaultLighting = true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension AddingTextVC{
    
    func addText(_ hitResult: ARHitTestResult,point: CGPoint){
        let text = SCNText(string: txtValue.text ?? "", extrusionDepth: 2)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(point.x, point.y, -0.15)
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        node.geometry = text
//        let node = SCNNode()
//        node.transform = SCNMatrix4(hitResult.anchor!.transform)
//        node.eulerAngles = SCNVector3(node.eulerAngles.x + (-Float.pi / 2), node.eulerAngles.y, node.eulerAngles.z)
//        node.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        node.geometry = text

        sceneView.scene.rootNode.addChildNode(node)
    }
}
