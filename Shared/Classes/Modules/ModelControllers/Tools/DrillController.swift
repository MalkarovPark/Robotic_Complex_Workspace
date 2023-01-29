//
//  DrillController.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 15.11.2022.
//

import Foundation
import SceneKit
import IndustrialKit

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
        if nodes.count == 1 //Drill has one rotated node
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
                    DispatchQueue.main.asyncAfter(deadline: .now())
                    {
                        self.nodes.first?.runAction(.repeatForever(.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                        self.rotated[0] = true
                        self.rotated[1] = false
                    }
                }
            case 2: //Counter clockwise rotation
                if !rotated[1]
                {
                    nodes.first?.removeAllActions()
                    DispatchQueue.main.asyncAfter(deadline: .now())
                    {
                        self.nodes.first?.runAction(.repeatForever(.rotate(by: -.pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                        self.rotated[1] = true
                        self.rotated[0] = false
                    }
                }
            default:
                remove_all_model_actions()
                rotated[0] = false
                rotated[1] = false
            }
        }
        else
        {
            completion()
        }
    }
    
    override func reset_model()
    {
        rotated[0] = false
        rotated[1] = false
    }
    
    override func state() -> [StateItem]?
    {
        var state = [StateItem]()
        state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "arrow.triangle.2.circlepath"))
        
        return state
    }
}