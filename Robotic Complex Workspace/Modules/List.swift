//
//  Internal Modules List
//

import Foundation
import IndustrialKit

@MainActor public let internal_modules: (robot: [RobotModule], tool: [ToolModule], part: [PartModule], changer: [ChangerModule]) = (
    [
        _6DOF_RobotModule,
        Portal_RobotModule
    ],
    [
        Drill_ToolModule,
        Gripper_ToolModule
    ],
    [
        Cup_PartModule,
        Books_PartModule,
        Table_PartModule
    ],
    [
        Random_ChangerModule
    ]
)
