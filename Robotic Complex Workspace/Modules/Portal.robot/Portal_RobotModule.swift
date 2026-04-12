//
// Portal Robot
// Internal Module Declaration
//

import Foundation
import IndustrialKit

@MainActor public let Portal_RobotModule = RobotModule(
    name: "Portal",
    
    default_origin_position: (x: 200, y: 200, z: 200, r: 0, p: 0, w: 0),
    
    origin_shift: (x: 0.0, y: 0.0, z: 160.0),
    end_entity_name: "tool",
    
    model_controller: Portal_Controller(),
    connector: Portal_Connector()
)
