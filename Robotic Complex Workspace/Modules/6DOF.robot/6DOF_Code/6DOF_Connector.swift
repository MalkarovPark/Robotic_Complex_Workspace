//
// Robot Connector
//

import Foundation
import IndustrialKit

class _6DOF_Connector: RobotConnector
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
    
    override var performing_state: (output: PerformingState, log: String)
    {
        return (output: local_state, log: String())
    }
    
    private var local_state: PerformingState = .completed
    
    private func new_line_check()
    {
        if output != String()
        {
            output += "\n"
        }
    }
    
    // MARK: - Performing
    override func move_to(point: PositionPoint)
    {
        let seconds = 2
        usleep(UInt32(seconds * 1_000_000))
        
        local_state = .processing
        
        model_controller?.pointer_position = (x: point.x, y: point.y, z: point.z, r: point.r, p: point.p, w: point.w)
        
        local_state = .completed
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
