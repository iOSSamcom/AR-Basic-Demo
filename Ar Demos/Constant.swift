//
//  Constant.swift
//  Ar Demos
//
//  Created by Parth on 02/07/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit


let mainStoryBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

extension ARSCNView {
    func setUp(viewController: PlacingVirtualObjectsVC, session: ARSession) {
        delegate = viewController
        self.session = session
        antialiasingMode = .multisampling4X
        automaticallyUpdatesLighting = false
        preferredFramesPerSecond = 60
        contentScaleFactor = 1.3
        enableEnvironmentMapWithIntensity(25.0)
        if let camera = pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }

    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                scene.lightingEnvironment.contents = environmentMap
            }
        }
        scene.lightingEnvironment.intensity = intensity
    }
}


enum Setting: String {
    // Bool settings with SettingsViewController switches
    case debugMode
    case scaleWithPinchGesture
    case ambientLightEstimation
    case dragOnInfinitePlanes
    case showHitTestAPI
    case use3DOFTracking
    case use3DOFFallback
    case useOcclusionPlanes

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Setting.ambientLightEstimation.rawValue: true,
            Setting.dragOnInfinitePlanes.rawValue: true
        ])
    }
}
extension UserDefaults {
    func bool(for setting: Setting) -> Bool {
        return bool(forKey: setting.rawValue)
    }
    func set(_ bool: Bool, for setting: Setting) {
        set(bool, forKey: setting.rawValue)
    }
    func integer(for setting: Setting) -> Int {
        return integer(forKey: setting.rawValue)
    }
    func set(_ integer: Int, for setting: Setting) {
        set(integer, forKey: setting.rawValue)
    }
}
