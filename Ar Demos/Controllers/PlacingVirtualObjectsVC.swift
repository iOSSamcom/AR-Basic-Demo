import UIKit
import Photos

class PlacingVirtualObjectsVC: UIViewController ,RenderARDelegate, RecordARDelegate  {
    //MARK:- IB Outlets -
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var debugMessageLabel: UILabel!
    @IBOutlet var featurePointCountLabel: UILabel!
    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var screenshotButton: UIButton!
    
    @IBOutlet var recordBtn: UIButton!
    @IBOutlet var pauseBtn: UIButton!
    //MARK:- Properties -
    var focusSquare: FocusSquare?
    var textManager: TextManager!
    var planes = [ARPlaneAnchor: Plane]()
    let session = ARSession()
    var sessionConfig = ARWorldTrackingConfiguration()
    var dragOnInfinitePlanesEnabled = false
    var currentGesture: Gesture?
    var use3DOFTrackingFallback = false
    var hitTestVisualization: HitTestVisualization?
    var rightBarButton = UIBarButtonItem()
    let DEFAULT_DISTANCE_CAMERA_TO_OBJECTS = Float(10)
    var recentVirtualObjectDistances = [CGFloat]()
    var recorder:RecordAR?
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    var currentNode: SCNNode?

    
    var screenCenter: CGPoint?
    var trackingFallbackTimer: Timer?
    var restartExperienceButtonIsEnabled = true

    //MARK:- Initializers -
    class func initViewController() -> PlacingVirtualObjectsVC{
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "PlacingVirtualObjectsVC") as! PlacingVirtualObjectsVC
        return vc
    }
    
    //MARK:- VC Methods -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setupDebug()
        setupUIControls()
        setupFocusSquare()
        updateSettings()
        resetVirtualObject()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionConfig.planeDetection = .vertical
        sceneView.session.run(sessionConfig)
        recorder?.prepare(sessionConfig)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        session.pause()
        if recorder?.status == .recording {
            recorder?.stopAndExport()
        }
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARWorldTrackingConfiguration())
        recorder?.rest()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIApplication.shared.isIdleTimerDisabled = true
        restartPlaneDetection()
    }


    //MARK:- Did Sets -
    
    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet {
            featurePointCountLabel.isHidden = !showDebugVisuals
            debugMessageLabel.isHidden = !showDebugVisuals
            messagePanel.isHidden = !showDebugVisuals
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            sceneView.debugOptions = []
            if showDebugVisuals {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            }
            UserDefaults.standard.set(showDebugVisuals, for: .debugMode)
        }
    }
    
    var showHitTestAPIVisualization = UserDefaults.standard.bool(for: .showHitTestAPI) {
        didSet {
            UserDefaults.standard.set(showHitTestAPIVisualization, for: .showHitTestAPI)
            if showHitTestAPIVisualization {
                hitTestVisualization = HitTestVisualization(sceneView: sceneView)
            } else {
                hitTestVisualization = nil
            }
        }
    }
    var use3DOFTracking = false {
        didSet {
            if use3DOFTracking {
                sessionConfig = ARWorldTrackingConfiguration()
            }
            sessionConfig.isLightEstimationEnabled = UserDefaults.standard.bool(for: .ambientLightEstimation)
            session.run(sessionConfig)
        }
    }
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.settingsButton.isEnabled = !self.isLoadingObject
                self.addObjectButton.isEnabled = !self.isLoadingObject
                self.screenshotButton.isEnabled = !self.isLoadingObject
                self.rightBarButton.isEnabled = !self.isLoadingObject
            }
        }
    }
}

//MARK:- Helper Methods -

extension PlacingVirtualObjectsVC{
    func setUpView(){
        Setting.registerDefaults()
        sceneView.setUp(viewController: self, session: session)
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
        setRightBarButton()
        setRecorder()
    }
    
    func setRecorder(){
        pauseBtn.isHidden = true

        recorder = RecordAR(ARSceneKit: sceneView)
        recorder?.delegate = self
        recorder?.renderAR = self
        recorder?.onlyRenderWhileRecording = false
        recorder?.contentMode = .aspectFill
        recorder?.enableAdjustEnvironmentLighting = true
        recorder?.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        recorder?.deleteCacheWhenExported = false
    }
    
   
    func restartPlaneDetection() {
        // configure session
        if let worldSessionConfig = sessionConfig as? ARWorldTrackingConfiguration {
            worldSessionConfig.planeDetection = .horizontal
            session.run(worldSessionConfig, options: [.resetTracking, .removeExistingAnchors])
        }

        // reset timer
        if trackingFallbackTimer != nil {
            trackingFallbackTimer!.invalidate()
            trackingFallbackTimer = nil
        }

        textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
        
        textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    func setupUIControls() {
        textManager = TextManager(viewController: self)
        debugMessageLabel.isHidden = true
        featurePointCountLabel.text = ""
        debugMessageLabel.text = ""
        messageLabel.text = ""
    }
    func setRightBarButton(){
        rightBarButton = UIBarButtonItem.init(image: #imageLiteral(resourceName: "restart"), style: .plain, target: self, action: #selector(refreshClicked))
        
        rightBarButton.tintColor = UIColor.black
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc func refreshClicked(){
            guard restartExperienceButtonIsEnabled, !isLoadingObject else {
                return
            }

            DispatchQueue.main.async {
                self.restartExperienceButtonIsEnabled = false

                self.textManager.cancelAllScheduledMessages()
                self.textManager.dismissPresentedAlert()
                self.textManager.showMessage("STARTING A NEW SESSION")
                self.use3DOFTracking = false

                self.setupFocusSquare()
                self.restartPlaneDetection()

                self.rightBarButton.image = #imageLiteral(resourceName: "restart")

                // Disable Restart button for five seconds in order to give the session enough time to restart.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                    self.restartExperienceButtonIsEnabled = true
                })
            }
        }
    
    func setupDebug() {
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
    }
    func refreshFeaturePoints() {
        guard showDebugVisuals else {
            return
        }
        
        guard let cloud = session.currentFrame?.rawFeaturePoints else {
            return
        }
        
        DispatchQueue.main.async {
            self.featurePointCountLabel.text = "Features: \(cloud.__count)".uppercased()
        }
    }
    private func updateSettings() {
        let defaults = UserDefaults.standard
        
        showDebugVisuals = defaults.bool(for: .debugMode)
        toggleAmbientLightEstimation(defaults.bool(for: .ambientLightEstimation))
        dragOnInfinitePlanesEnabled = defaults.bool(for: .dragOnInfinitePlanes)
        showHitTestAPIVisualization = defaults.bool(for: .showHitTestAPI)
        use3DOFTracking    = defaults.bool(for: .use3DOFTracking)
        use3DOFTrackingFallback = defaults.bool(for: .use3DOFFallback)
        for (_, plane) in planes {
            plane.updateOcclusionSetting()
        }
    }
    func toggleAmbientLightEstimation(_ enabled: Bool) {
        if enabled {
            if !sessionConfig.isLightEstimationEnabled {
                sessionConfig.isLightEstimationEnabled = true
                session.run(sessionConfig)
            }
        } else {
            if sessionConfig.isLightEstimationEnabled {
                sessionConfig.isLightEstimationEnabled = false
                session.run(sessionConfig)
            }
        }
    }
    func resetVirtualObject() {
        VirtualObjectsManager.shared.resetVirtualObjects()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
    }
    func setNewVirtualObjectPosition(_ pos: SCNVector3) {
        
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
            let cameraTransform = session.currentFrame?.camera.transform else {
                return
        }
        
        recentVirtualObjectDistances.removeAll()
        
        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)
        
        object.position = cameraWorldPos + cameraToPosition
        
        if object.parent == nil {
            sceneView.scene.rootNode.addChildNode(object)
        }
    }
    
    //for adding object to screen
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        let virtualObject = VirtualObjectsManager.shared.getVirtualObjectSelected()
        if virtualObject != nil && sceneView.isNode(virtualObject!, insideFrustumOf: sceneView.pointOfView!) {
            focusSquare?.hide()
        } else {
            focusSquare?.unhide()
        }
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
            textManager.cancelScheduledMessage(forType: .focusSquare)
        }
    }
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?,
        planeAnchor: ARPlaneAnchor?,
        hitAPlane: Bool) {
            
            // -------------------------------------------------------------------------------
            // 1. Always do a hit test against exisiting plane anchors first.
            //    (If any such anchors exist & only within their extents.)
            
            let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
            if let result = planeHitTestResults.first {
                
                let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
                let planeAnchor = result.anchor
                
                // Return immediately - this is the best possible outcome.
                return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
            }
            
            // -------------------------------------------------------------------------------
            // 2. Collect more information about the environment by hit testing against
            //    the feature point cloud, but do not return the result yet.
            
            var featureHitTestPosition: SCNVector3?
            var highQualityFeatureHitTestResult = false
            
            let highQualityfeatureHitTestResults =
                sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
            
            if !highQualityfeatureHitTestResults.isEmpty {
                let result = highQualityfeatureHitTestResults[0]
                featureHitTestPosition = result.position
                highQualityFeatureHitTestResult = true
            }
            
            // -------------------------------------------------------------------------------
            // 3. If desired or necessary (no good feature hit test result): Hit test
            //    against an infinite, horizontal plane (ignoring the real world).
            
            if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
                
                let pointOnPlane = objectPos ?? SCNVector3Zero
                
                let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
                if pointOnInfinitePlane != nil {
                    return (pointOnInfinitePlane, nil, true)
                }
            }
            
            // -------------------------------------------------------------------------------
            // 4. If available, return the result of the hit test against high quality
            //    features if the hit tests against infinite planes were skipped or no
            //    infinite plane was hit.
            
            if highQualityFeatureHitTestResult {
                return (featureHitTestPosition, nil, false)
            }
            
            // -------------------------------------------------------------------------------
            // 5. As a last resort, perform a second, unfiltered hit test against features.
            //    If there are no features in the scene, the result returned here will be nil.
            
            let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
            if !unfilteredFeatureHitTestResults.isEmpty {
                let result = unfilteredFeatureHitTestResults[0]
                return (result.position, nil, false)
            }
            
            return (nil, nil, false)
    }
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {

          let pos = SCNVector3.positionFromTransform(anchor.transform)
          textManager.showDebugMessage("NEW SURFACE DETECTED AT \(pos.friendlyString())")

          let plane = Plane(anchor, showDebugVisuals)

          planes[anchor] = plane
          node.addChildNode(plane)

          textManager.cancelScheduledMessage(forType: .planeEstimation)
          textManager.showMessage("SURFACE DETECTED")
          if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
              textManager.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
          }
      }
    func checkIfObjectShouldMoveOntoPlane(anchor: ARPlaneAnchor) {
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
            let planeAnchorNode = sceneView.node(for: anchor) else {
            return
        }

        // Get the object's position in the plane's coordinate system.
        let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)

        if objectPos.y == 0 {
            return; // The object is already on the plane
        }

        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1

        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance

        if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
            return
        }

        // Drop the object onto the plane if it is near it.
        let verticalAllowance: Float = 0.03
        if objectPos.y > -verticalAllowance && objectPos.y < verticalAllowance {
            textManager.showDebugMessage("OBJECT MOVED\nSurface detected nearby")

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            object.position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }
}

//MARK:- IB Actions -

extension PlacingVirtualObjectsVC{
    @IBAction func chooseObject(_ button: UIButton) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        
        textManager.cancelScheduledMessage(forType: .contentPlacement)
        
        let rowHeight = 45
        let popoverSize = CGSize(width: 250, height: rowHeight * VirtualObjectSelectionViewController.COUNT_OBJECTS)
        
        let objectViewController = VirtualObjectSelectionViewController(size: popoverSize)
        objectViewController.delegate = self
        objectViewController.modalPresentationStyle = .popover
        objectViewController.popoverPresentationController?.delegate = self
        self.present(objectViewController, animated: true, completion: nil)
        objectViewController.popoverPresentationController?.sourceView = button
        objectViewController.popoverPresentationController?.sourceRect = button.bounds
    }
    
    @IBAction func showSettings(_ button: UIButton) {
        let settingsViewController = SettingsViewController.initViewController()
        

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Options"

        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20,
                                                           height: sceneView.bounds.size.height - 50)
        self.present(navigationController, animated: true, completion: nil)

        navigationController.popoverPresentationController?.sourceView = settingsButton
        navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds
    }

    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        updateSettings()
    }
    
    @IBAction func takeSnapShot() {
       let snapShot = self.sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(snapShot, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {

        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            let alert = UIAlertController(title: "Screenshot Saved", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            print("ARKit Scene Successfully Saved")
        }
    }
    
    @IBAction func record(_ sender: UIButton) {
        if sender.tag == 0 {
            //Record
            if recorder?.status == .readyToRecord {
                sender.setImage(UIImage(named: "stopRecord"), for: .normal)
//                pauseBtn.setTitle("Pause", for: .normal)
                pauseBtn.isEnabled = true
                pauseBtn.isHidden = false
                recordingQueue.async {
                    self.recorder?.record()
                }
            }else if recorder?.status == .recording {
                sender.setImage(UIImage(named: "startRecord"), for: .normal)
//                pauseBtn.setTitle("Pause", for: .normal)
                pauseBtn.isEnabled = false
                pauseBtn.isHidden = true
                recorder?.stop() { path in
                    self.recorder?.export(video: path) { saved, status in
                        DispatchQueue.main.sync {
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                }
            }
        }else if sender.tag == 1 {
            //Record with duration
            if recorder?.status == .readyToRecord {
                sender.setImage(UIImage(named: "stopRecord"), for: .normal)
//                pauseBtn.setTitle("Pause", for: .normal)
                pauseBtn.isEnabled = false
                pauseBtn.isHidden = true
                recordBtn.isEnabled = false
                recordingQueue.async {
                    self.recorder?.record(forDuration: 10) { path in
                        self.recorder?.export(video: path) { saved, status in
                            DispatchQueue.main.sync {
//                                sender.setTitle("w/Duration", for: .normal)
//                                self.pauseBtn.setTitle("Pause", for: .normal)
                                self.pauseBtn.isEnabled = false
                                self.recordBtn.isEnabled = true
                                self.exportMessage(success: saved, status: status)
                            }
                        }
                    }
                }
            }else if recorder?.status == .recording {
//                sender.setTitle("w/Duration", for: .normal)
//                pauseBtn.setTitle("Pause", for: .normal)
                pauseBtn.isEnabled = false
                pauseBtn.isHidden = true
                recordBtn.isEnabled = true
                recorder?.stop() { path in
                    self.recorder?.export(video: path) { saved, status in
                        DispatchQueue.main.sync {
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                }
            }
        }else if sender.tag == 2 {
            //Pause
            if recorder?.status == .paused {
                sender.setImage(UIImage(named: "pauseRecord"), for: .normal)
                recorder?.record()
            }else if recorder?.status == .recording {
                sender.setImage(UIImage(named: "resumeRecord"), for: .normal)
                recorder?.pause()
            }
        }
    }

}

// MARK: - UIPopoverPresentationControllerDelegate
extension PlacingVirtualObjectsVC: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        updateSettings()
    }
}

// MARK: - VirtualObjectSelectionViewControllerDelegate
extension PlacingVirtualObjectsVC: VirtualObjectSelectionViewControllerDelegate {
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, object: VirtualObject) {
        loadVirtualObject(object: object)
    }
    
    func loadVirtualObject(object: VirtualObject) {
        // Show progress indicator
        let spinner = UIActivityIndicatorView()
        spinner.center = addObjectButton.center
        spinner.bounds.size = CGSize(width: addObjectButton.bounds.width - 5, height: addObjectButton.bounds.height - 5)
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        sceneView.addSubview(spinner)
        spinner.startAnimating()
        
        DispatchQueue.global().async {
            self.isLoadingObject = true
            object.viewController = self
            VirtualObjectsManager.shared.addVirtualObject(virtualObject: object)
            VirtualObjectsManager.shared.setVirtualObjectSelected(virtualObject: object)
            
            object.loadModel()
            
            DispatchQueue.main.async {
                if let lastFocusSquarePos = self.focusSquare?.lastPosition {
                    self.setNewVirtualObjectPosition(lastFocusSquarePos)
                } else {
                    self.setNewVirtualObjectPosition(SCNVector3Zero)
                }
                
                spinner.removeFromSuperview()
                
                // Update the icon of the add object button
                let buttonImage = UIImage.composeButtonImage(from: object.thumbImage)
                let pressedButtonImage = UIImage.composeButtonImage(from: object.thumbImage, alpha: 0.3)
                self.addObjectButton.setImage(buttonImage, for: [])
                self.addObjectButton.setImage(pressedButtonImage, for: [.highlighted])
                self.isLoadingObject = false
            }
        }
    }
}

// MARK: - ARSCNViewDelegate
extension PlacingVirtualObjectsVC: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        refreshFeaturePoints()
        
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.hitTestVisualization?.render()
            
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.session.currentFrame?.lightEstimate {
                self.sceneView.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40)
            } else {
                self.sceneView.enableEnvironmentMapWithIntensity(25)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
                self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if let plane = self.planes[planeAnchor] {
                    plane.update(planeAnchor)
                }
                self.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor, let plane = self.planes.removeValue(forKey: planeAnchor) {
                plane.removeFromParentNode()
            }
        }
    }
}

// MARK: Gesture Recognized
extension PlacingVirtualObjectsVC {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
            return
        }

        if currentGesture == nil {
            currentGesture = Gesture.startGestureFromTouches(touches, self.sceneView, object)
        } else {
            currentGesture = currentGesture!.updateGestureFromTouches(touches, .touchBegan)
        }

        displayVirtualObjectTransform()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
        displayVirtualObjectTransform()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
            chooseObject(addObjectButton)
            return
        }

        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
    }
    func displayVirtualObjectTransform() {
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected(),
            let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }

        // Output the current translation, rotation & scale of the virtual object as text.
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        let vectorToCamera = cameraPos - object.position

        let distanceToUser = vectorToCamera.length()

        var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360
        if angleDegrees < 0 {
            angleDegrees += 360
        }

        let distance = String(format: "%.2f", distanceToUser)
        let scale = String(format: "%.2f", object.scale.x)
        textManager.showDebugMessage("Distance: \(distance) m\nRotation: \(angleDegrees)°\nScale: \(scale)x")
    }

    func moveVirtualObjectToPosition(_ pos: SCNVector3?, _ instantly: Bool, _ filterPosition: Bool) {

        guard let newPosition = pos else {
            textManager.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            // Reset the content selection in the menu only if the content has not yet been initially placed.
            if !VirtualObjectsManager.shared.isAVirtualObjectPlaced() {
                resetVirtualObject()
            }
            return
        }

        if instantly {
            setNewVirtualObjectPosition(newPosition)
        } else {
            updateVirtualObjectPosition(newPosition, filterPosition)
        }
    }
    func updateVirtualObjectPosition(_ pos: SCNVector3, _ filterPosition: Bool) {
        guard let object = VirtualObjectsManager.shared.getVirtualObjectSelected() else {
            return
        }

        guard let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }

        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        cameraToPosition.setMaximumLength(DEFAULT_DISTANCE_CAMERA_TO_OBJECTS)

        // Compute the average distance of the object from the camera over the last ten
        // updates. If filterPosition is true, compute a new position for the object
        // with this average. Notice that the distance is applied to the vector from
        // the camera to the content, so it only affects the percieved distance of the
        // object - the averaging does _not_ make the content "lag".
        let hitTestResultDistance = CGFloat(cameraToPosition.length())

        recentVirtualObjectDistances.append(hitTestResultDistance)
        recentVirtualObjectDistances.keepLast(10)

        if filterPosition {
            let averageDistance = recentVirtualObjectDistances.average!

            cameraToPosition.setLength(Float(averageDistance))
            let averagedDistancePos = cameraWorldPos + cameraToPosition

            object.position = averagedDistancePos
        } else {
            object.position = cameraWorldPos + cameraToPosition
        }
    }

}

//MARK: - ARVideoKit Delegate Methods
extension PlacingVirtualObjectsVC {
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording. Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
    
    func exportMessage(success: Bool, status:PHAuthorizationStatus) {
        if success {
            let alert = UIAlertController(title: "Exported", message: "Media exported to camera roll successfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else if status == .denied || status == .restricted || status == .notDetermined {
            let errorView = UIAlertController(title: "", message: "Please allow access to the photo library in order to save this media file.", preferredStyle: .alert)
            let settingsBtn = UIAlertAction(title: "Open Settings", style: .cancel) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(URL(string:UIApplication.openSettingsURLString)!)
                    }
                }
            }
            errorView.addAction(UIAlertAction(title: "Later", style: UIAlertAction.Style.default, handler: {
                (UIAlertAction)in
            }))
            errorView.addAction(settingsBtn)
            self.present(errorView, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Exporting Failed", message: "There was an error while exporting your media file.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
