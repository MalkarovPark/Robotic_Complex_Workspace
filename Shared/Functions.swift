//
//  Functions.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 04.10.2023.
//

import Foundation
import IndustrialKit

//MARK: - Robot and Tool modules
func select_robot_modules(name: String, model_controller: inout RobotModelController, connector: inout RobotConnector)
{
    switch name
    {
    case "Portal":
        model_controller = PortalController()
        connector = PortalConnector()
    case "6DOF":
        model_controller = _6DOFController()
        connector = _6DOFConnector()
    default:
        break
    }
}

func select_tool_modules(name: String, model_controller: inout ToolModelController, connector: inout ToolConnector)
{
    switch name
    {
    case "gripper":
        model_controller = GripperController()
        connector = GripperConnector()
    case "drill":
        model_controller = DrillController()
        connector = DrillConnector()
    default:
        break
    }
}

//MARK: - Changer modules
func change_by(name: String, registers: inout [Int])
{
    switch name
    {
    case "Module":
        break
    case "Module 2":
        break
    default:
        break
    }
}
