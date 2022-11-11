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
    public func nodes_connect(_ node: inout SCNNode)
    {
        //Get details nodes links from root node and pass to array
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
