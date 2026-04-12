//
// Robot Connector
//

import Foundation
import RealityKit
import IndustrialKit

class _6DOF_Connector: RobotConnector, @unchecked Sendable
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
    
    override func perform_connection() async -> Bool
    {
        sleep(1)
        
        let result = parameters[safe: 3]?.value as? Bool ?? false
        
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
    
    override func perform_disconnection()
    {
        
    }
    
    // MARK: - Performing
    private var performing_task: Task<Void, Never>?
    private var current_performing_state: PerformingState = .none
    
    private var current_pointer_position = EntityPositionData()
    
    open override func start_process(point: PositionPoint)
    {
        performing_task = Task
        {
            current_performing_state = .processing
            
            sleep(1)
            
            current_performing_state = .completed
            
            current_pointer_position = EntityPositionData(
                position: (
                    x: point.x,
                    y: point.y,
                    z: point.z,
                    
                    r: point.r,
                    p: point.p,
                    w: point.w
                )
            )
        }
    }
    
    open override func reset_device()
    {
        performing_task?.cancel()
    }
    
    open override var current_device_state: RobotState?
    {
        return RobotState(
            performing_state: current_performing_state,
            pointer_position: current_pointer_position
        )
    }
    
    // MARK: - Statistics
    private var charts = [StateChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 6)
    private var domain_index: Float = 0
    
    private var pointer_entity: Entity
    {
        if let model_controller = model_controller,
           let entity = model_controller.entities["tool"]
        {
            return entity
        }
        else
        {
            return Entity()
        }
    }
    
    private var tool_entity: Entity?
    {
        pointer_entity
    }
    
    var current_charts: [StateChart]
    {
        if charts.count == 0
        {
            charts.append(StateChart(name: "Parts Rotation", style: .line))
            charts.append(StateChart(name: "Tool Location", style: .line))
            charts.append(StateChart(name: "Tool Rotation", style: .line))
        }
        
        // Update parts angles rotation chart
        for i in 0...chart_ik_values.count - 1
        {
            charts[0].data.append(ChartDataItem(name: "J\(i + 1)", domain: ["": domain_index], codomain: chart_ik_values[i]))
        }
        
        // Update tool location chart
        let tool_entity = pointer_entity
        
        var axis_names = ["X", "Y", "Z"]
        var components = [tool_entity.position.x, tool_entity.position.z, tool_entity.position.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i])))
        }
        
        // Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_entity.euler_angles.z, tool_entity.euler_angles.x, tool_entity.euler_angles.y]
        for i in 0...axis_names.count - 1
        {
            charts[2].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i]).to_deg))
        }
        
        domain_index += 1
        
        return charts
    }
    
    var current_items: [StateItem]
    {
        var states = [StateItem]()
        states.append(StateItem(name: "Temperature", value: "+10º", symbol_name: "thermometer"))
        states[0].children = [
            StateItem(name: "Еngine", value: "+50º", symbol_name: "thermometer.transmission"),
            StateItem(name: "Fridge", value: "-40º", symbol_name: "thermometer.snowflake.circle")
        ]
        
        states.append(StateItem(name: "Speed", value: "10 mm/sec", symbol_name: "windshield.front.and.wiper.intermittent"))
        
        return states
    }
    
    /// Updates device state data.
    /*override var current_device_output: DeviceState
    {
        // Prepare controller output
        return DeviceState(
            items: current_items,
            charts: current_charts
        )
    }
    
    var initial_charts: [StateChart]
    {
        chart_ik_values = [Float](repeating: 0, count: 6)
        domain_index = 0
        charts.removeAll()
        
        charts.append(StateChart(name: "Parts Rotation", style: .line))
        charts.append(StateChart(name: "Tool Location", style: .line))
        charts.append(StateChart(name: "Tool Rotation", style: .line))
        
        return charts
    }
    
    var initial_items: [StateItem]
    {
        var states = [StateItem]()
        
        states.append(StateItem(name: "Temperature", value: "0º", symbol_name: "thermometer"))
        states[0].children = [StateItem(name: "Еngine", value: "0º", symbol_name: "thermometer.transmission"),
                             StateItem(name: "Fridge", value: "0º", symbol_name: "thermometer.snowflake.circle")]
        
        states.append(StateItem(name: "Speed", value: "10 mm/sec", symbol_name: "windshield.front.and.wiper.intermittent"))
        
        return states
    }
    
    override var initial_device_output: DeviceState?
    {
        // Reset contolleroutput
        return DeviceState(
            items: initial_items,
            charts: initial_charts
        )
    }*/
}
