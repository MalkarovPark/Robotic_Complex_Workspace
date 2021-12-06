//
//  Workspace.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit

class Workspace
{
    var robot1 = Robot()
    func open_robot()
    {
        robot1.select_program(prog_name: "f")
    }
}
