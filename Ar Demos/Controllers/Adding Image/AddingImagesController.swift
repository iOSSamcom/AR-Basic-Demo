//
//  AddingImagesController.swift
//  Ar Demos
//
//  Created by Parth on 01/07/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit


class AddingImagesController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var imgView: UIImageView!

//    var grids = [Grid]()
    var hitOnWall : ARHitTestResult!
    var gridOnWall : Grid!
    var imagePicker = UIImagePickerController()
    var currentNode: SCNNode?
    
    //MARK:- Initializers
    class func initViewController() -> AddingImagesController{
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "AddingImagesController") as! AddingImagesController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        imgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openActionSheet)))

        sceneView.addGestureRecognizer(gestureRecognizer)
        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleCurrentNode(_:)))
        self.view.addGestureRecognizer(scaleGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let grid = Grid(anchor: planeAnchor)
//        self.grids.removeAll()
//        self.grids.append(grid)
//        node.addChildNode(grid)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
//        let grid = self.grids.filter { grid in
//            return grid.anchor.identifier == planeAnchor.identifier
//            }.first
//
//        guard let foundGrid = grid else {
//            return
//        }
//
//        foundGrid.update(anchor: planeAnchor)
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)
        
        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)
   
        if let hitTest = hitTestResults.first{
            hitOnWall = hitTest
            
            openActionSheet()
            if let nodeHitTest = self.sceneView.hitTest(touchPosition, options: nil).first?.node{
                currentNode = nodeHitTest
                return
            }
        }
    }
    func addPainting(_ hitResult: ARHitTestResult/*, _ grid: Grid*/) {
         // 1.
         let planeGeometry = SCNPlane(width: 0.2, height: 0.35)
         let material = SCNMaterial()
        material.diffuse.contents = imgView.image
         planeGeometry.materials = [material]
         
         // 2.
         let paintingNode = SCNNode(geometry: planeGeometry)
         paintingNode.transform = SCNMatrix4(hitResult.anchor!.transform)
         paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x + (-Float.pi / 2), paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
         paintingNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
         
         sceneView.scene.rootNode.addChildNode(paintingNode)
//         grid.removeFromParentNode()
     }
    
    func addPainting2(_ image:UIImage) {
             // 1.
             let planeGeometry = SCNPlane(width: 0.2, height: 0.35)
             let material = SCNMaterial()
            material.diffuse.contents = image
             planeGeometry.materials = [material]
             
             // 2.
             let paintingNode = SCNNode(geometry: planeGeometry)
             paintingNode.transform = SCNMatrix4(hitOnWall.anchor!.transform)
             paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x + (-Float.pi / 2), paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
             paintingNode.position = SCNVector3(hitOnWall.worldTransform.columns.3.x, hitOnWall.worldTransform.columns.3.y, hitOnWall.worldTransform.columns.3.z)
             
             sceneView.scene.rootNode.addChildNode(paintingNode)
         }
    @objc func scaleCurrentNode(_ gesture: UIPinchGestureRecognizer) {
        
        if let selectedNode = currentNode{
            
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
    
}

//MARK:- UIImagePickerController Delegate Method

extension AddingImagesController : UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    @objc func openActionSheet() {
        let alert = UIAlertController(title: "Choose Image", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view //to set the source of your alert
            let theHeight = view.frame.size.height
            popoverController.sourceRect = CGRect(x: 0, y: theHeight - 50 , width: self.view.frame.width, height: 200)
            popoverController.permittedArrowDirections = []
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK:- Select Image From  Gallery Or Capture Method
    func openCamera(){
        if (UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have perission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
//        imgView.image = selectedImage
        addPainting2(selectedImage)
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
