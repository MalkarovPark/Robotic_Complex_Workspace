//
//  Drill.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 15.11.2022.
//

import Foundation
import SceneKit

class DrillController: ToolModelController
{
    override func nodes_connect(_ node: SCNNode)
    {
        guard let drill_node = node.childNode(withName: "drill", recursively: true)
        else
        {
            return //Return if node not found
        }
        
        nodes.append(drill_node)
    }
    
    private var rotated = [false, false]
    
    override func nodes_perform(code: Int)
    {
        switch code
        {
        case 0: //Strop rotation
            nodes.first?.removeAllActions()
            rotated[0] = false
            rotated[1] = false
        case 1: //Clockwise rotation
            if !rotated[0]
            {
                nodes.first?.removeAllActions()
                nodes.first?.runAction(.repeatForever(.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                rotated[0] = true
                rotated[1] = false
            }
        case 2: //Counter clockwise rotation
            print(rotated)
            if !rotated[1]
            {
                nodes.first?.removeAllActions()
                nodes.first?.runAction(.repeatForever(.rotate(by: -.pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                rotated[1] = true
                rotated[0] = false
            }
        default:
            remove_all_model_actions()
            rotated[0] = false
            rotated[1] = false
        }
    }
    
    override func reset_model()
    {
        rotated[0] = false
        rotated[1] = false
    }
}
