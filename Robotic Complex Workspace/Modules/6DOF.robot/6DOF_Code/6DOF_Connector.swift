import Foundation
import IndustrialKit

class _6DOF_Connector: RobotConnector
{
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
    override func move_to(point: PositionPoint)
    {
        let number_x = point.x
        let number_y = point.y
        let number_z = point.z

        let parts_count = 10
        let lpart_x: Float = number_x / Float(parts_count)
        let lpart_y: Float = number_y / Float(parts_count)
        let lpart_z: Float = number_z / Float(parts_count)

        var sum_x: Float = 0
        var sum_y: Float = 0
        var sum_z: Float = 0

        for i in 0...parts_count
        {
            if canceled
            {
                break
            }
            
            sum_x = lpart_x * Float(i)
            sum_y = lpart_y * Float(i)
            sum_z = lpart_z * Float(i)

            model_controller?.update_nodes(pointer_location: [sum_x, sum_y, sum_z], pointer_rotation: [point.r, point.p, point.w], origin_location: origin_location, origin_rotation: origin_rotation)
            
            if canceled
            {
                break
            }

            usleep(500000) //sleep(1)
        }
        
        if canceled
        {
            model_controller?.update_nodes(pointer_location: [0, 0, 0], pointer_rotation: [0, 0, 0], origin_location: origin_location, origin_rotation: origin_rotation)
        }
        
        //model_controller?.nodes_update(pointer_location: [point.x, point.y, point.z], pointer_roation: [point.r, point.p, point.w], origin_location: origin_location, origin_rotation: origin_rotation)
        //sleep(2)
    }
    
    //MARK: - State functions
    override func updated_states_data() -> [StateItem]?
    {
        var state = [StateItem]()
        state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "arrow.triangle.2.circlepath"))
        
        return state
    }
}
