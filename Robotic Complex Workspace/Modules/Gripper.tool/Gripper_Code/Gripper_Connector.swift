//
// Tool Connector
//

import Foundation
import IndustrialKit
import SceneKit

class Gripper_Connector: ToolConnector
{
    // MARK: - Connection
    override var parameters: [ConnectionParameter]
    {
        [
            .init(name: "String", value: "Text"),
            .init(name: "Int", value: 8),
            .init(name: "Float", value: Float(0.5)),
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
        
        sleep(2)
        
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
    
    override func disconnection_process()
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
    
    override var performing_state: (output: PerformingState, log: String)
    {
        return (output: local_state, log: String())
    }
    
    private var local_state: PerformingState = .completed
    
    // MARK: - Performing
    override func perform(code: Int)
    {
        //local_state = .processing
        
        guard let nodes = model_controller?.nodes else { return }
        
        if nodes.count == 2 // Gripper model has two nodes of jaws
        {
            switch code
            {
            case 0: // Close
                nodes[safe_name: "jaw"].runAction(.move(to: SCNVector3(0, 0, 20), duration: 1))
                nodes[safe_name: "jaw2"].runAction(.move(to: SCNVector3(0, 0, -20), duration: 1))
            case 1: // Open
                nodes[safe_name: "jaw"].runAction(.move(to: SCNVector3(0, 0, 46), duration: 1))
                nodes[safe_name: "jaw2"].runAction(.move(to: SCNVector3(0, 0, -46), duration: 1))
            default:
                break
            }
        }
        
        let seconds = 2
        usleep(UInt32(seconds * 1_000_000))
        self.local_state = .completed
    }
    
    // MARK: - Statistics
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
