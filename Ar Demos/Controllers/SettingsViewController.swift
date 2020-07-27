import UIKit


class SettingsViewController: UITableViewController {

	@IBOutlet weak var debugModeSwitch: UISwitch!
	@IBOutlet weak var scaleWithPinchGestureSwitch: UISwitch!
	@IBOutlet weak var ambientLightEstimateSwitch: UISwitch!
	@IBOutlet weak var dragOnInfinitePlanesSwitch: UISwitch!
	@IBOutlet weak var showHitTestAPISwitch: UISwitch!
	@IBOutlet weak var use3DOFTrackingSwitch: UISwitch!
	@IBOutlet weak var useAuto3DOFFallbackSwitch: UISwitch!
	@IBOutlet weak var useOcclusionPlanesSwitch: UISwitch!

    //MARK:- Initializers -
    class func initViewController() -> SettingsViewController{
        let vc = mainStoryBoard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        return vc
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateSettings()
    }

	@IBAction func didChangeSetting(_ sender: UISwitch) {
		let defaults = UserDefaults.standard
		switch sender {
            case debugModeSwitch:
                defaults.set(sender.isOn, for: .debugMode)
            case scaleWithPinchGestureSwitch:
                defaults.set(sender.isOn, for: .scaleWithPinchGesture)
            case ambientLightEstimateSwitch:
                defaults.set(sender.isOn, for: .ambientLightEstimation)
            case dragOnInfinitePlanesSwitch:
                defaults.set(sender.isOn, for: .dragOnInfinitePlanes)
            case showHitTestAPISwitch:
                defaults.set(sender.isOn, for: .showHitTestAPI)
            case use3DOFTrackingSwitch:
                defaults.set(sender.isOn, for: .use3DOFTracking)
            case useAuto3DOFFallbackSwitch:
                defaults.set(sender.isOn, for: .use3DOFFallback)
            case useOcclusionPlanesSwitch:
                defaults.set(sender.isOn, for: .useOcclusionPlanes)
            default: break
        }
	}

	private func populateSettings() {
		let defaults = UserDefaults.standard

		debugModeSwitch.isOn = defaults.bool(for: Setting.debugMode)
		scaleWithPinchGestureSwitch.isOn = defaults.bool(for: .scaleWithPinchGesture)
		ambientLightEstimateSwitch.isOn = defaults.bool(for: .ambientLightEstimation)
		dragOnInfinitePlanesSwitch.isOn = defaults.bool(for: .dragOnInfinitePlanes)
		showHitTestAPISwitch.isOn = defaults.bool(for: .showHitTestAPI)
		use3DOFTrackingSwitch.isOn = defaults.bool(for: .use3DOFTracking)
		useAuto3DOFFallbackSwitch.isOn = defaults.bool(for: .use3DOFFallback)
		useOcclusionPlanesSwitch.isOn = defaults.bool(for: .useOcclusionPlanes)
	}
}
