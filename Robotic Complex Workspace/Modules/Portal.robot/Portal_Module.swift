import Foundation
import IndustrialKit

public let Portal_Module = RobotModule(
    name: "Portal",
    
    origin_shift: (x: 0.0, y: 0.0, z: 160.0),
    
    model_controller: Portal_Controller(),
    connector: Portal_Connector()
)
