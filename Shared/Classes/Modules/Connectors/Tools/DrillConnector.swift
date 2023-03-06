//
//  DrillConnector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 16.01.2023.
//

import Foundation
import IndustrialKit

class DrillConnector: ToolConnector
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
    
    //MARK: - Connection functions
    override func connection_process() async -> Bool
    {
        new_line_check()
        output += "Connecting..."
        
        sleep(4)
        
        new_line_check()
        
        if parameters[3].value as! Bool == true
        {
            output += "Connected"
            return true
        }
        else
        {
            output += "Connection failed"
            return false
        }
    }
    
    override func disconnection_process() async
    {
        new_line_check()
        output += "Disconnected"
    }
    
    private func new_line_check()
    {
        if output != String()
        {
            output += "\n"
        }
    }
    
    //MARK: - Control functions
    private var rotated = [false, false]
    
    override func perform(code: Int)
    {
        model_controller?.nodes_perform(code: code)
        
        new_line_check()
        switch code
        {
        case 0: //Strop rotation
            //nodes.first?.removeAllActions()
            output += "Stopped"
            
            rotated[0] = false
            rotated[1] = false
        case 1: //Clockwise rotation
            if !rotated[0]
            {
                //nodes.first?.removeAllActions()
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    //self.nodes.first?.runAction(.repeatForever(.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                    self.output += "Rotated Clockwise"
                    
                    self.rotated[0] = true
                    self.rotated[1] = false
                }
            }
        case 2: //Counter clockwise rotation
            if !rotated[1]
            {
                //nodes.first?.removeAllActions()
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    //self.nodes.first?.runAction(.repeatForever(.rotate(by: -.pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                    self.output += "Rotated Counterclockwise"
                    
                    self.rotated[1] = true
                    self.rotated[0] = false
                }
            }
        default:
            //remove_all_model_actions()
            output += "Reset"
            
            rotated[0] = false
            rotated[1] = false
        }
        
        //output += "Rotated"
    }
    
    override func pause()
    {
        rotated[0] = false
        rotated[1] = false
        
        if update_model
        {
            model_controller?.reset_model()
            //remove_all_model_actions()
        }
    }
    
    //MARK: - State functions
    override func state() -> [StateItem]?
    {
        var state = [StateItem]()
        state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "arrow.triangle.2.circlepath"))
        state.append(StateItem(name: "Address", value: "Local", image: "mappin"))
        
        return state
    }
}
