//
//  ModelController.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 11.11.2022.
//

import Foundation
import SceneKit

class ModelController
{
    public var nodes = [SCNNode]()
    
    public func nodes_connect(_ node: SCNNode)
    {
        //Get details nodes links from root node and pass to array
    }
    
    public func nodes_disconnect()
    {
        nodes.removeAll()
    }
    
    public func reset_model()
    {
        //Reset model controller function
    }
    
    public func remove_all_model_actions()
    {
        for node in nodes
        {
            node.removeAllActions()
        }
        
        reset_model()
    }
}

//MARK: - Robot model controllers
class RobotModelController: ModelController
{
    public func nodes_connect(_ lengths: inout [Float], _ node: SCNNode, _ details: inout [SCNNode], _ with_lengths: Bool)
    {
        
    }
    
    public func update_nodes_geometry(_ details: inout [SCNNode], _ lengths: [Float])
    {
        
    }
    
    public func update_nodes_position(_ nodes: inout [SCNNode], _ values: [Float])
    {
        
    }
    
    public func ik_perform(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float], lengths: [Float])
    {
        
    }
}

//MARK: - Tool model controller
class ToolModelController: ModelController
{
    public func nodes_perform(code: Int)
    {
        //Perform node action by operation code
    }
    
    public func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    public var state: [[String: Any]]?
    
    public var info_code: Int?
}

//MARK: Gripper controller
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
    
    override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        switch code
        {
        case 0: //Grip
            if !closed && !moved
            {
                moved = true
                nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -18), duration: 1))
                nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 18), duration: 1))
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
                nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 18), duration: 1))
                nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -18), duration: 1))
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
    
    override func reset_model()
    {
        closed = false
        moved = false
        
        nodes[0].position.z = 46
        nodes[1].position.z = -46
    }
}

//MARK: Drill controller
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
