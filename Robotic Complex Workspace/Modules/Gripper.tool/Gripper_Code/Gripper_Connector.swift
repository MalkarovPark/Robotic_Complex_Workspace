//
//  GripperConnector.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 16.01.2023.
//

import Foundation
import IndustrialKit

class Gripper_Connector: ToolConnector
{
    override init()
    {
        super.init()
        parameters = [
            ConnectionParameter(name: "String", value: "Text"),
            ConnectionParameter(name: "Int", value: 8),
            ConnectionParameter(name: "Float", value: Float(6)),
            ConnectionParameter(name: "Bool", value: true)
        ]
    }
    
    //MARK: - Connection functions
    override func connection_process() async -> Bool
    {
        new_line_check()
        output += "Connecting..."
        
        new_line_check()
        
        output += "\n \(parameters.count) parameters used:\n"
        for parameter in parameters
        {
            output += " • \(parameter.value)\n"
        }
        output += "\n"
        
        sleep(4)
        
        if parameters[3].value as! Bool
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
    private var closed = false
    private var moved = false
    
    //private var perform_task = Task {}
    
    /*override func perform(code: Int, completion: @escaping () -> Void)
    {
        new_line_check()
        
        DispatchQueue.global().async
        {
            self.performation_task(code: code)
            completion()
        }
    }*/
    
    override func perform(code: Int)
    {
        new_line_check()
        model_controller?.nodes_perform(code: code)
        
        switch code
        {
        case 0: //Grip
            if !closed && !moved
            {
                output += "Gripping"
                moved = true
                
                sleep(4)
                
                output += "\nGripped"
                self.moved = false
                self.closed = true
            }
            else
            {
                output += "Already gripped"
            }
        case 1: //Release
            if closed && !moved
            {
                output += "Releasing"
                moved = true
                
                sleep(4)
                
                output += "\nReleased"
                self.moved = false
                self.closed = false
            }
            else
            {
                output += "Already released"
            }
        default:
            //remove_all_model_actions()
            output += "???"
        }
    }
    
    //MARK: - State functions
    override func updated_states_data() -> [StateItem]?
    {
        var state = [StateItem]()
        state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "arrow.triangle.2.circlepath"))
        state.append(StateItem(name: "Address", value: "Local", image: "mappin"))
        
        return state
    }
}
