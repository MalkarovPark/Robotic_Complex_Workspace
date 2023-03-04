//
//  GripperConnector.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 16.01.2023.
//

import Foundation
import IndustrialKit

class GripperConnector: ToolConnector
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
    private var closed = false
    private var moved = false
    
    //private var perform_task = Task {}
    
    override func perform(code: Int, completion: @escaping () -> Void)
    {
        /*if update_model
        {
            model_controller?.nodes_perform(code: code)
        }*/
        
        new_line_check()
        
        DispatchQueue.global().async
        {
            self.performation_task(code: code)
            completion()
        }
        
        /*perform_task = Task
        {
            await performation_task(code: code)
            //perform_task.cancel()
            completion()
        }*/
        
        //completion()
    }
    
    private func performation_task(code: Int)// async
    {
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
}
