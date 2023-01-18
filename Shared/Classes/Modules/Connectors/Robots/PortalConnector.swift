//
//  PortalConnector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 16.01.2023.
//

import Foundation
import IndustrialKit

class PortalConnector: RobotConnector
{
    override init()
    {
        super.init()
        parameters = [
            ConnectionParameter(name: "String", value: "Text"),
            ConnectionParameter(name: "Int", value: 8),
            ConnectionParameter(name: "Float", value: Float(6.0)),
            ConnectionParameter(name: "Bool", value: true)
        ]
    }
    
    override func connection_process() async -> Bool
    {
        //output += "\nConnected"
        sleep(4)
        return true
    }
    
    override func disconnection_process() async
    {
        //output += "\nDisconnected"
    }
}
