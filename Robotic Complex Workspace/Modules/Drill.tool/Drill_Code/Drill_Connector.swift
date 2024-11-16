import Foundation
import IndustrialKit

class Drill_Connector: ToolConnector
{
    //MARK: - Connection
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
    }
    
    override func reset_device()
    {
        rotated[0] = false
        rotated[1] = false
        
        if update_model
        {
            model_controller?.reset_nodes()
            //remove_all_model_actions()
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
