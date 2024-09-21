//
//  Functions.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 04.10.2023.
//

import Foundation
import IndustrialKit

//MARK: - Robot and Tool modules
func select_robot_modules(name: String, model_controller: inout RobotModelController, connector: inout RobotConnector)
{
    switch name
    {
    case "Portal":
        model_controller = Portal_Controller()
        connector = Portal_Connector()
    case "6DOF":
        model_controller = _6DOF_Controller()
        connector = _6DOF_Connector()
    default:
        break
    }
}

//MARK: - Changer modules
let changer_modules_names = ["Module", "Module 2"]

func change_by(name: String, registers: inout [Float])
{
    switch name
    {
    case "Module":
        registers[4] = 55
        registers[8] = 56
    case "Module 2":
        registers[12] = 60
        registers[13] = 77
    default:
        break
    }
}
