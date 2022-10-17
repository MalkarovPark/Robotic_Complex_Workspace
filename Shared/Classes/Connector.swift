//
//  Connector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 08.10.2022.
//

import Foundation

class RobotConnector
{
    //MARK: - Connection functions
    public func connect() //Connect to robot controller function
    {
        
    }
    
    public func disconnect() //Disconnect robot function
    {
        
    }
    
    private(set) var connected: Bool = false
    
    //MARK: - Perform functions
    public func move_to(point: PositionPoint)
    {
        
    }
    
    public func move_to(point: PositionPoint, completionHandler block: (() -> Void)? = nil)
    {
        block!()
    }
    
    func perform_code(_ opcode: Int) //Perform function for robot operation code
    {
        
    }
    
    //MARK: - Info
    private(set) var state: [[String: Any]]? //Connector state info
    private(set) var info_code: Int = -1 //Info code parameter for robot
}

class ToolConnector
{
    //MARK: - Connection functions
    func connect() //Connect to tool controller function
    {
        
    }
    
    func disconnect() //Disconnect tool function
    {
        
    }
    
    private(set) var connected: Bool = false
    
    //MARK: - Perform functions
    func perform_code(_ opcode: Int) //Perform function for tool operation code
    {
        
    }
    
    //MARK: - Info
    private(set) var state: [[String: Any]]? //Connector state info
    private(set) var info_code: Int = -1 //Info code parameter for tool
}
