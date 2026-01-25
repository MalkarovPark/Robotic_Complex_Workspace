import Foundation
import IndustrialKit

public let _6DOF_Module = RobotModule(
    name: "6DOF",
    
    origin_shift: (x: 0.0, y: 0.0, z: 160.0),
    
    model_controller: _6DOF_Controller(),
    connector: _6DOF_Connector()
)
