import Foundation
import SceneKit
import IndustrialKit

class _6DOF_Controller: RobotModelController
{
    // MARK: - Parameters
    override var nodes_names: [String]
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
    override open func update_nodes_positions(pointer_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float), origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float))
    {
        apply_nodes_positions(values: inverse_kinematic_calculation(pointer_position: pointer_position, origin_position: origin_position))
    }
    
    let lengths: [Float] = [
        160.0,
        160.0,
        80.0,
        160.0,
        50.0,
        20.0,
        160.0
    ]
    
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
    
    private func apply_nodes_positions(values: [Float])
    {
        #if os(macOS)
        nodes[safe: "d0", default: SCNNode()].eulerAngles.y = CGFloat(values[0])
        nodes[safe: "d1", default: SCNNode()].eulerAngles.z = CGFloat(values[1])
        nodes[safe: "d2", default: SCNNode()].eulerAngles.z = CGFloat(values[2])
        nodes[safe: "d3", default: SCNNode()].eulerAngles.y = CGFloat(values[3])
        nodes[safe: "d4", default: SCNNode()].eulerAngles.z = CGFloat(values[4])
        nodes[safe: "d5", default: SCNNode()].eulerAngles.y = CGFloat(values[5])
        #else
        nodes[safe: "d0", default: SCNNode()].eulerAngles.y = Float(values[0])
        nodes[safe: "d1", default: SCNNode()].eulerAngles.z = Float(values[1])
        nodes[safe: "d2", default: SCNNode()].eulerAngles.z = Float(values[2])
        nodes[safe: "d3", default: SCNNode()].eulerAngles.y = Float(values[3])
        nodes[safe: "d4", default: SCNNode()].eulerAngles.z = Float(values[4])
        nodes[safe: "d5", default: SCNNode()].eulerAngles.y = Float(values[5])
        #endif
        
        if get_statistics
        {
            chart_ik_values = values // Store new parts angles array for chart
        }
    }
    
    // MARK: - Statistics
    private var charts = [WorkspaceObjectChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 6)
    private var domain_index: Float = 0
    
    override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Parts Rotation", style: .line))
            charts.append(WorkspaceObjectChart(name: "Tool Location", style: .line))
            charts.append(WorkspaceObjectChart(name: "Tool Rotation", style: .line))
        }
        
        // Update parts angles rotation chart
        for i in 0...chart_ik_values.count - 1
        {
            charts[0].data.append(ChartDataItem(name: "J\(i + 1)", domain: ["": domain_index], codomain: chart_ik_values[i]))
        }
        
        // Update tool location chart
        let tool_node = pointer_node
        
        var axis_names = ["X", "Y", "Z"]
        var components = [tool_node?.worldPosition.x, tool_node?.worldPosition.z, tool_node?.worldPosition.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0)))
        }
        
        // Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_node?.eulerAngles.z, tool_node?.eulerAngles.x, tool_node?.eulerAngles.y]
        for i in 0...axis_names.count - 1
        {
            charts[2].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0).to_deg))
        }
        
        domain_index += 1
        
        return charts
    }
    
    override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        chart_ik_values = [Float](repeating: 0, count: 6)
        domain_index = 0
        charts.removeAll()
        
        charts.append(WorkspaceObjectChart(name: "Parts Rotation", style: .line))
        charts.append(WorkspaceObjectChart(name: "Tool Location", style: .line))
        charts.append(WorkspaceObjectChart(name: "Tool Rotation", style: .line))
        
        return charts
    }
    
    override func updated_states_data() -> [StateItem]?
    {
        var states = [StateItem]()
        states.append(StateItem(name: "Temperature", value: "+10º", image: "thermometer"))
        states[0].children = [StateItem(name: "Еngine", value: "+50º", image: "thermometer.transmission"),
                             StateItem(name: "Fridge", value: "-40º", image: "thermometer.snowflake.circle")]
        
        states.append(StateItem(name: "Speed", value: "10 mm/sec", image: "windshield.front.and.wiper.intermittent"))
        
        return states
    }
    
    override func initial_states_data() -> [StateItem]?
    {
        var states = [StateItem]()
        
        states.append(StateItem(name: "Temperature", value: "0º", image: "thermometer"))
        states[0].children = [StateItem(name: "Еngine", value: "0º", image: "thermometer.transmission"),
                             StateItem(name: "Fridge", value: "0º", image: "thermometer.snowflake.circle")]
        
        states.append(StateItem(name: "Speed", value: "10 mm/sec", image: "windshield.front.and.wiper.intermittent"))
        
        return states
    }
}
