//
//  GripperController.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 15.11.2022.
//

import Foundation
import SceneKit
import IndustrialKit

class GripperController: ToolModelController
{
    override func nodes_connect(_ node: SCNNode)
    {
        guard let jaw_node = node.childNode(withName: "jaw", recursively: true)
        else
        {
            return
        }
        
        guard let jaw2_node = node.childNode(withName: "jaw2", recursively: true)
        else
        {
            return
        }
        
        nodes += [jaw_node, jaw2_node]
    }
    
    private var closed = false
    private var moved = false
    
    override func nodes_perform(code: Int)
    {
        if nodes.count == 2 //Gripper model has two nodes of jaws
        {
            switch code
            {
            case 0: //Grip
                if !closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    {
                        self.moved = false
                        self.closed = true
                    }
                }
            case 1: //Release
                if closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    {
                        self.moved = false
                        self.closed = false
                    }
                }
            default:
                remove_all_model_actions()
            }
        }
    }
    
    override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        if nodes.count == 2 //Gripper model has two nodes of jaws
        {
            switch code
            {
            case 0: //Grip
                if !closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    {
                        self.moved = false
                        self.closed = true
                        
                        completion()
                    }
                }
                else
                {
                    completion()
                }
            case 1: //Release
                if closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    {
                        self.moved = false
                        self.closed = false
                        
                        completion()
                    }
                }
                else
                {
                    completion()
                }
            default:
                remove_all_model_actions()
                completion()
            }
        }
        else
        {
            completion()
        }
    }
    
    override func reset_model()
    {
        closed = false
        moved = false
        
        if nodes.count == 2
        {
            nodes[0].position.z = 46
            nodes[1].position.z = -46
        }
    }
}
