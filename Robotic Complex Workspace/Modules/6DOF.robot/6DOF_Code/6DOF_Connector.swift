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
    
    override func disconnection_process()// async
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
    
    // MARK: - Performing
    override func move_to(point: PositionPoint)
    {
        var seconds = 2
        usleep(UInt32(seconds * 1_000_000))
        
        model_controller?.pointer_location = [point.x, point.y, point.z]
        model_controller?.pointer_rotation = [point.r, point.p, point.w]
        //usleep(UInt32(point.move_speed) * 1_000_000)
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
    
    override open func sync_model()
    {
        //model_controller?.update_by_pointer()
    }
}
