//
// Robot Connector
//

import Foundation
import IndustrialKit
import RealityKit

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
    
    override func connection_process() async -> Bool
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
    
    override func disconnection_process()
    {
        
    }
    
    // MARK: - Performing
    // ...
    
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
        components = [tool_entity.eulerAngles.z, tool_entity.eulerAngles.x, tool_entity.eulerAngles.y]
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
    override var current_device_state: DeviceState
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
    
    override var initial_device_state: DeviceState?
    {
        // Reset contolleroutput
        return DeviceState(
            items: initial_items,
            charts: initial_charts
        )
    }
}
