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
    
    /*public func nodes_update()
    {
        
    }*/
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
    
    public func nodes_perform(code: Int, completion: () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    public var state: [[String: Any]]?
}

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
    
    override func nodes_perform(code: Int)
    {
        switch code
        {
        case 1: //Strop rotation
            nodes.first?.removeAllActions()
        case 2: //Clockwise rotation
            nodes.first?.runAction(.rotateBy(x: 0, y: 1, z: 0, duration: 0.5))
        case 3: //Counter clockwise rotation
            nodes.first?.runAction(.rotateBy(x: 0, y: -1, z: 0, duration: 0.5))
        default:
            break
        }
    }
}
