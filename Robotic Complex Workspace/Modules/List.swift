//
//  List.swift
//  Robotic Complex Workspace
//
//  For internal modules mount.
//

import Foundation
import IndustrialKit

public var internal_modules: (robot: [RobotModule], tool: [ToolModule], part: [PartModule], changer: [ChangerModule]) = (
    [
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=RobotModule()@*//*@END_MENU_TOKEN@*/
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
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=ChangerModule()@*//*@END_MENU_TOKEN@*/
    ]
)
