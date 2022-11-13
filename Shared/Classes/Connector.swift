//
//  Connector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.10.2022.
//

import Foundation

//MARK: - Workspace object connector
class WorkspaceObjectConnector
{
    //Connection functions
    public func connect() //Connect to robot controller function
    {
        
    }
    
    public func disconnect() //Disconnect robot function
    {
        
    }
    
    public var connected: Bool = false
    
    //Visual model handling
    //public var model_controller = ModelController()
    
    //Info
    public var state: [String: Any]? //Connector state info
}

//MARK: - Robot connector
class RobotConnector: WorkspaceObjectConnector
{
    //Perform functions
    public func move_to(point: PositionPoint)
    {
        
    }
    
    public func move_to(point: PositionPoint, completion: @escaping () -> Void)
    {
        move_to(point: point)
        completion()
    }
    
    //Visual model handling
    public var model_controller = RobotModelController()
}

//MARK: - Tool connector
class ToolConnector: WorkspaceObjectConnector
{
    //Perform functions
    func perform(code: Int) //Perform function for tool operation code
    {
        
    }
    
    func perform(code: Int, completion: @escaping () -> Void)
    {
        perform(code: code)
        completion()
    }
    
    //Visual model handling
    public var model_controller = ToolModelController()
}
