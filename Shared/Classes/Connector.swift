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
    
    //MARK: - Perfom functions
    public func move_to(point: PositionPoint)
    {
        
    }
    
    public func move_to(point: PositionPoint, completionHandler block: (() -> Void)? = nil)
    {
        block!()
    }
    
    private(set) var state: [[String: Any]]? //Connector state info
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
    
    //MARK: - Perfrom functions
    func perform_code(_ opcode: Int) //Perform function for tool operation code
    {
        
    }
    
    private(set) var info_code: Int = -1 //Info code parameter for tool
    private(set) var state: [[String: Any]]? //Connector state info
    
}
