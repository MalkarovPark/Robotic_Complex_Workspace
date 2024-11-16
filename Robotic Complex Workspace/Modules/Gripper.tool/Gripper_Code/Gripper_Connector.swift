import Foundation
import IndustrialKit

class Gripper_Connector: ToolConnector
{
    //MARK: - Connecting
    override var parameters: [ConnectionParameter]
    {
        [
            .init(name: "String", value: "Text"),
            .init(name: "Int", value: 8),
            .init(name: "Float", value: Float(6)),
            .init(name: "Bool", value: true)
        ]
    }
    
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
    
    //MARK: - Performing
    private var closed = false
    private var moved = false
    
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
    
    //MARK: - Statistics
    override func initial_charts_data() -> [WorkspaceObjectChart]
    {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=return [WorkspaceObjectChart]()@*/return [WorkspaceObjectChart]()/*@END_MENU_TOKEN@*/
    }
    
    override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=return [WorkspaceObjectChart]()@*/return [WorkspaceObjectChart]()/*@END_MENU_TOKEN@*/
    }
    
    override func initial_states_data() -> [StateItem]
    {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=return [StateItem]()@*/return [StateItem]()/*@END_MENU_TOKEN@*/
    }
    
    override func updated_states_data() -> [StateItem]?
    {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=return [StateItem]()@*/return [StateItem]()/*@END_MENU_TOKEN@*/
    }
}
