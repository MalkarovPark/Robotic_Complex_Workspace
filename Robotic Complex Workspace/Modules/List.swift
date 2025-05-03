//
//  Internal Modules List
//

import Foundation
import IndustrialKit

public var internal_modules: (robot: [RobotModule], tool: [ToolModule], part: [PartModule], changer: [ChangerModule]) = (
    [
        _6DOF_Module,
        Portal_Module
    ],
    [
        Drill_Module,
        Gripper_Module
    ],
    [
        Cup_Module,
        Books_Module
    ],
    [
        Random_Module
    ]
)
