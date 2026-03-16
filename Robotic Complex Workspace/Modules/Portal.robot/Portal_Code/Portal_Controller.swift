import Foundation
import IndustrialKit
import RealityKit

class Portal_Controller: RobotModelController
{
    // MARK: - Parameters
    override var entity_names: [String]
    {
        [
            "base",
            "column",
            "frame",
            "d0",
            "d1",
            "d2"
        ]
    }
    
    // MARK: - Performing
    let lengths: [Float] = [
        440.0,
        80.0,
        160.0,
        40.0,
        20.0,
        320.0,
        320.0,
        320.0,
        160.0
    ]
    
    override open func entity_positions(
        pointer_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        ),
        origin_position: (
            x: Float, y: Float, z: Float,
            r: Float, p: Float, w: Float
        )
    ) throws -> [EntityPositionData]
    {
        let values = inverse_kinematic_calculation(pointer_position: pointer_position, origin_position: origin_position)
        
        let entity_positions: [EntityPositionData] = [
            .init(name: "d0", position: (x: values[1], y: 0, z: 0, r: 0, p: 0, w: 0)),
            .init(name: "d2", position: (x: 0, y: 0, z: values[2], r: 0, p: 0, w: 0)),
            .init(name: "d1", position: (x: 0, y: values[0], z: 0, r: 0, p: 0, w: 0))
        ]
        
        entities[safe: "d0", default: Entity()].position.x = Float(values[1])
        entities[safe: "d2", default: Entity()].position.y = Float(values[2])
        entities[safe: "d1", default: Entity()].position.z = Float(values[0])
        
        return entity_positions
    }
    
    private func inverse_kinematic_calculation(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float), origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)) -> [Float]
    {
        var px, py, pz: Float
        
        px = pointer_position.x + origin_position.x - lengths[1]
        py = pointer_position.y + origin_position.y - lengths[2]
        pz = pointer_position.z + origin_position.z - lengths[0] + lengths[3] + lengths[4]
        
        // Checking X part limit
        if px < 0
        {
            px = 0
        }
        else
        {
            if px > lengths[5]
            {
                px = lengths[5]
            }
        }
        
        // Checking Y part limit
        if py < 0
        {
            py = 0
        }
        else
        {
            if py > lengths[6] - lengths[2] / 2
            {
                py = lengths[6] - lengths[2] / 2
            }
        }
        
        // Checking Z part limit
        if pz > 0
        {
            pz = 0
        }
        else
        {
            if pz < -lengths[7]
            {
                pz = -lengths[7]
            }
        }

        return [px, py, pz]
    }
    
    // MARK: - Statistics
    private var charts = [StateChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 3)
    private var domain_index: Float = 0
    
    var current_charts: [StateChart]
    {
        if charts.count == 0
        {
            charts.append(StateChart(name: "Tool Location", style: .line))
            charts.append(StateChart(name: "Tool Rotation", style: .line))
        }
        
        // Update tool location chart
        let tool_entity = pointer_entity
        
        var axis_names = ["X", "Y", "Z"]
        var components = [tool_entity?.position.x, tool_entity?.position.z, tool_entity?.position.y]
        for i in 0...axis_names.count - 1
        {
            charts[0].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0)))
        }
        
        // Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_entity?.eulerAngles.z, tool_entity?.eulerAngles.x, tool_entity?.eulerAngles.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0).to_deg))
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
        domain_index = 0
        chart_ik_values = [Float](repeating: 0, count: 3)
        charts = [StateChart]()
        
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
