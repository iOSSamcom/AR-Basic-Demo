

import Foundation
class Wolf: VirtualObject {

    override init() {
        super.init(modelName: "wolf", fileExtension: "dae", thumbImageFilename: "wolf", title: "Wolf")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
