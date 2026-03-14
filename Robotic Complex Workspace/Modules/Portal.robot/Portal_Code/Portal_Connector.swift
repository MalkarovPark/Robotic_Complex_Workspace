//
// Robot Connector
//

import Foundation
import IndustrialKit

class Portal_Connector: RobotConnector
{
    // MARK: - Connection
    override var default_parameters: [ConnectionParameter]
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
        sleep(1)
        
        let result = parameters[safe: 0]?.value as? Bool ?? false
        
        if result
        {
            connection_output_string = "Connected"
        }
        else
        {
            connection_output_string = "Failed"
            connection_error = NSError(domain: "Connection failed", code: 0, userInfo: nil)
        }
        
        return result
    }
    
    override func disconnection_process()
    {
        
    }
    
    override var performing_state: (output: PerformingState, log: String)
    {
        return (output: local_state, log: String())
    }
    
    private var local_state: PerformingState = .completed
    
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
    // ...
}
