import UIKit
import ARKit

class MeasureDistanceVC: UIViewController
{
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var meterImageView: UIImageView!
    
    
    var session = ARSession()
    var sessionConfiguration = ARWorldTrackingConfiguration()
    var isMeasuring = false;
    var vectorZero = SCNVector3()
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    var lines: [Line] = []
    var currentLine: Line?
    var unit: DistanceUnit = .centimeter
    //MARK:- Initializers -
       class func initViewController() -> MeasureDistanceVC{
           let vc = mainStoryBoard.instantiateViewController(withIdentifier: "MeasureDistanceVC") as! MeasureDistanceVC
           return vc
       }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetValues()
        isMeasuring = true
        targetImageView.image = UIImage(named: "targetGreen")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMeasuring = false
        targetImageView.image = UIImage(named: "targetWhite")
        if let line = currentLine {
            lines.append(line)
            currentLine = nil
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - ARSCNViewDelegate

extension MeasureDistanceVC: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.detectObjects()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Error occurred"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
    }
}

// MARK: - Users Interactions

extension MeasureDistanceVC {
    @IBAction func meterButtonTapped(button: UIButton) {
        let alertVC = UIAlertController(title: "Settings", message: "Please select distance unit options", preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default) { [weak self] _ in
            self?.unit = .centimeter
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default) { [weak self] _ in
            self?.unit = .inch
        })
        alertVC.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default) { [weak self] _ in
            self?.unit = .meter
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popoverController = alertVC.popoverPresentationController {
                   popoverController.sourceView = self.view //to set the source of your alert
                   let theHeight = view.frame.size.height
                   popoverController.sourceRect = CGRect(x: 0, y: theHeight - 50 , width: self.view.frame.width, height: 200)
                   popoverController.permittedArrowDirections = []
               }
        present(alertVC, animated: true, completion: nil)
    }
    
}

// MARK: - Privates

extension MeasureDistanceVC {
    func setupScene() {
        targetImageView.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        meterImageView.isHidden = true
        messageLabel.text = "Detecting the world…"
       
        session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue =  SCNVector3()
    }
    
    func detectObjects() {
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        targetImageView.isHidden = false
        meterImageView.isHidden = false
        if lines.isEmpty {
            messageLabel.text = "Hold screen & move your phone…"
        }
        loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit, lineColor: .blue)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)
            messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating…"
        }
    }
    func setRightBarButton(){
           let rightBarButton = UIBarButtonItem.init(image: #imageLiteral(resourceName: "restart"), style: .plain, target: self, action: #selector(refreshClicked))
           
           rightBarButton.tintColor = UIColor.black
           self.navigationItem.rightBarButtonItem = rightBarButton
       }
       
       @objc func refreshClicked(){
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
}
