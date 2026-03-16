import Foundation
import IndustrialKit
import RealityKit

nonisolated class _6DOF_Controller: RobotModelController, @unchecked Sendable
{
    // MARK: - Parameters
    override var entity_names: [String]
    {
        [
            "base",
            "column",
            "d0",
            "d1",
            "d2",
            "d3",
            "d4",
            "d5",
            "d6"
        ]
    }
    
    // MARK: - Performing
    let lengths: [Float] = [
        160.0,
        160.0,
        80.0,
        160.0,
        50.0,
        20.0,
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
            .init(name: "d0", position: (x: 0, y: 0, z: 0, r: 0, p: 0, w: values[0].to_deg)),
            .init(name: "d1", position: (x: 0, y: 0, z: 160, r: 0, p: values[1].to_deg, w: 0)),
            .init(name: "d2", position: (x: 0, y: 0, z: 160, r: 0, p: values[2].to_deg, w: 0)),
            .init(name: "d3", position: (x: 0, y: 0, z: 80, r: 0, p: 0, w: values[3].to_deg)),
            .init(name: "d4", position: (x: 0, y: 0, z: 160, r: 0, p: values[4].to_deg, w: 0)),
            .init(name: "d5", position: (x: 0, y: 0, z: 50, r: 0, p: 0, w: values[5].to_deg))
        ]
        
        return entity_positions
    }
    
    private func inverse_kinematic_calculation(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float), origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)) -> [Float]
    {
        var angles = [Float]()
        var theta = [Float](repeating: 0, count: 6)
        var C3 = Float()
        
        do
        {
            var px, py, pz: Float
            var rx, ry, rz: Float
            var ax, ay, az, bx, by, bz: Float
            var asx, asy, asz, bsx, bsy, bsz: Float
            var p5x, p5y, p5z: Float
            var C1, C23, S1, S23: Float
            
            var M, N, A, B: Float
            
            px = -(pointer_position.x + origin_position.x)
            py = pointer_position.y + origin_position.y
            pz = pointer_position.z + origin_position.z
            
            rx = -(pointer_position.r.to_rad + origin_position.r.to_rad)
            ry = -(pointer_position.p.to_rad + origin_position.p.to_rad) + (.pi)
            rz = -(pointer_position.w.to_rad + origin_position.w.to_rad)
            
            bx = cos(rx) * sin(ry) * cos(rz) - sin(rx) * sin(rz)
            by = cos(rx) * sin(ry) * sin(rz) - sin(rx) * cos(rz)
            bz = cos(rx) * cos(ry)
            
            ax = cos(rz) * cos(ry)
            ay = sin(rz) * cos(ry)
            az = -sin(ry)
            
            p5x = px - (lengths[4] + lengths[5]) * ax
            p5y = py - (lengths[4] + lengths[5]) * ay
            p5z = pz - (lengths[4] + lengths[5]) * az
            
            C3 = (pow(p5x, 2) + pow(p5y, 2) + pow(p5z - lengths[0], 2) - pow(lengths[1], 2) - pow(lengths[2] + lengths[3], 2)) / (2 * lengths[1] * (lengths[2] + lengths[3]))
            
            // Joint 1
            theta[0] = Float(atan2(p5y, p5x))
            
            // Joints 3, 2
            theta[2] = Float(atan2(pow(abs(1 - pow(C3, 2)), 0.5), C3))
            
            M = lengths[1] + (lengths[2] + lengths[3]) * C3
            N = (lengths[2] + lengths[3]) * sin(Float(theta[2]))
            A = pow(p5x * p5x + p5y * p5y, 0.5)
            B = p5z - lengths[0]
            theta[1] = Float(atan2(M * A - N * B, N * A + M * B))
            
            // Joints 4, 5, 6
            C1 = cos(Float(theta[0]))
            C23 = cos(Float(theta[1]) + Float(theta[2]))
            S1 = sin(Float(theta[0]))
            S23 = sin(Float(theta[1]) + Float(theta[2]))
            
            asx = C23 * (C1 * ax + S1 * ay) - S23 * az
            asy = -S1 * ax + C1 * ay
            asz = S23 * (C1 * ax + S1 * ay) + C23 * az
            bsx = C23 * (C1 * bx + S1 * by) - S23 * bz
            bsy = -S1 * bx + C1 * by
            bsz = S23 * (C1 * bx + S1 * by) + C23 * bz
            
            theta[3] = Float(atan2(asy, asx))
            theta[4] = Float(atan2(cos(Float(theta[3])) * asx + sin(Float(theta[3])) * asy, asz))
            theta[5] = Float(atan2(cos(Float(theta[3])) * bsy - sin(Float(theta[3])) * bsx, -bsz / sin(Float(theta[4]))))
            
            angles.append(-(theta[0] + .pi))
            angles.append(-theta[1])
            angles.append(-theta[2])
            angles.append(-(theta[3] + .pi))
            angles.append(theta[4])
            angles.append(-theta[5])
        }
        
        return angles
    }
    
    // MARK: - Statistics
    private var charts = [StateChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 6)
    private var domain_index: Float = 0
    
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
        var components = [tool_entity?.position.x, tool_entity?.position.z, tool_entity?.position.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0)))
        }
        
        // Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_entity?.eulerAngles.z, tool_entity?.eulerAngles.x, tool_entity?.eulerAngles.y]
        for i in 0...axis_names.count - 1
        {
            charts[2].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0).to_deg))
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
