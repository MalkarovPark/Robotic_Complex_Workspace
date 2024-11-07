import Foundation
import SceneKit
import IndustrialKit

class Portal_Controller: RobotModelController
{
    //MARK: - Inverse kinematic parts calculation for roataion angles of portal
    override open func update_nodes_positions(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        apply_nodes_positions(values: inverse_kinematic_calculation(pointer_location: pointer_location, pointer_rotation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation))
    }
    
    let lengths: [Float] = [
        440.0,
        80.0,
        160.0,
        40.0,
        30.0,
        320.0,
        320.0,
        320.0,
        160.0
    ]
    
    private func inverse_kinematic_calculation(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float]) -> [Float]
    {
        var px, py, pz: Float
        
        px = pointer_location[0] + origin_location[0] - lengths[1]
        py = pointer_location[1] + origin_location[1] - lengths[2]
        pz = pointer_location[2] + origin_location[2] - lengths[0] + lengths[3] + lengths[4]
        
        //Checking X part limit
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
        
        //Checking Y part limit
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
        
        //Checking Z part limit
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
    
    public func apply_nodes_positions(values: [Float])
    {
        #if os(macOS)
        nodes[safe: "d0", default: SCNNode()].position.x = CGFloat(values[1])
        nodes[safe: "d2", default: SCNNode()].position.y = CGFloat(values[2])
        nodes[safe: "d1", default: SCNNode()].position.z = CGFloat(values[0])
        #else
        nodes[safe: "d0", default: SCNNode()].position.x = values[1]
        nodes[safe: "d2", default: SCNNode()].position.y = values[2]
        nodes[safe: "d1", default: SCNNode()].position.z = values[0]
        #endif
    }
    
    //MARK: - Statistics
    private var charts = [WorkspaceObjectChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 3)
    private var domain_index: Float = 0
    
    override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Tool Location", style: .line))
            charts.append(WorkspaceObjectChart(name: "Tool Rotation", style: .line))
        }
        
        //Update tool location chart
        let tool_node = pointer_node
        
        var axis_names = ["X", "Y", "Z"]
        var components = [tool_node?.worldPosition.x, tool_node?.worldPosition.z, tool_node?.worldPosition.y]
        for i in 0...axis_names.count - 1
        {
            charts[0].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0)))
        }
        
        //Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_node?.eulerAngles.z, tool_node?.eulerAngles.x, tool_node?.eulerAngles.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0).to_deg))
        }
        
        domain_index += 1
        
        return charts
    }
    
    override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        domain_index = 0
        chart_ik_values = [Float](repeating: 0, count: 3)
        charts = [WorkspaceObjectChart]()
        
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
