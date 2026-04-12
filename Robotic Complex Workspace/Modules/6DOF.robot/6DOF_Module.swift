import Foundation
import IndustrialKit

public let _6DOF_RobotModule = RobotModule(
    name: "6DOF",
    
    default_origin_position: (x: 200, y: 0, z: 100, r: 0, p: 0, w: 0),
    
    origin_shift: (x: 0.0, y: 0.0, z: 160.0),
    end_entity_name: "tool",
    
    model_controller: _6DOF_Controller(),
    connector: _6DOF_Connector()
)
