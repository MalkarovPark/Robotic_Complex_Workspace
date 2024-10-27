import Foundation
import SceneKit
import IndustrialKit

class Portal_Controller: RobotModelController
{
    //MARK: - Portal nodes connect
    override func connect_nodes(of node: SCNNode)
    {
        let without_lengths = lengths.count == 0
        
        //Get lengths from robot scene if they is not set in plist
        if without_lengths
        {
            lengths = [Float]()
            
            lengths.append(Float(node.childNode(withName: "frame2", recursively: true)!.position.y)) //Portal frame height [0]
            
            lengths.append(Float(node.childNode(withName: "limit1_min", recursively: true)!.position.z)) //Position X shift [1]
            lengths.append(Float(node.childNode(withName: "limit0_min", recursively: true)!.position.x + node.childNode(withName: "limit2_min", recursively: true)!.position.x)) //Position Y shift [2]
            lengths.append(Float(-node.childNode(withName: "limit2_min", recursively: true)!.position.y)) //Position Z shift [3]
            lengths.append(Float(node.childNode(withName: "target", recursively: true)!.position.y)) //Tool length for adding to Z shift [4]
            
            lengths.append(Float(node.childNode(withName: "limit0_max", recursively: true)!.position.x)) //Limit for X [5]
            lengths.append(Float(node.childNode(withName: "limit1_max", recursively: true)!.position.z)) //Limit for Y [6]
            lengths.append(Float(-node.childNode(withName: "limit2_max", recursively: true)!.position.y)) //Limit for Z [7]
        }
        
        //Connect to part nodes from robot scene
        nodes["frame"] = node.childNode(withName: "frame", recursively: true) ?? nodes["frame"] //Base position
        for i in 0...2
        {
            nodes["d\(i)"] = node.childNode(withName: "d\(i)", recursively: true) ?? nodes["d\(i)"]
        }
        
        if without_lengths
        {
            lengths.append(Float(node.childNode(withName: "frame", recursively: true)!.position.y)) //Append base height [8]
        }
        
        nodes["base"] = node.childNode(withName: "base", recursively: true) ?? nodes["base"] //Base pillar node [4]
    }
    
    //MARK: - Inverse kinematic parts calculation for roataion angles of portal
    override func inverse_kinematic_calculation(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float]) -> [Float]
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
    
    override func update_nodes(values: [Float])
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
    
    override var description_lengths_count: Int { 9 }
    
    override func update_nodes_lengths()
    {
        var modified_node = SCNNode()
        var saved_material = SCNMaterial()
        
        //Base
        modified_node = nodes[safe: "base", default: SCNNode()]
        saved_material = (modified_node.geometry?.firstMaterial)!
        
        modified_node.geometry = SCNCylinder(radius: 80, height: CGFloat(lengths[8]))
        #if os(macOS)
        modified_node.position.y = CGFloat(lengths[8] / 2)
        #else
        modified_node.position.y = lengths[8] / 2
        #endif
        
        modified_node.geometry?.firstMaterial = saved_material
        
        //Frames
        var node = nodes[safe: "frame", default: SCNNode()]
        
        modified_node = node.childNode(withName: "part_v", recursively: true)!
        
        saved_material = (modified_node.geometry?.firstMaterial)!
        
        let vf_length = lengths[0] - 40
        modified_node.geometry = SCNBox(width: 80, height: CGFloat(vf_length), length: 80, chamferRadius: 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(vf_length / 2)
        #else
        modified_node.position.y = vf_length / 2
        #endif
        
        node = nodes[safe: "frame", default: SCNNode()]
        #if os(macOS)
        node.position.y = CGFloat(lengths[8])
        node.childNode(withName: "frame2", recursively: true)!.position.y = CGFloat(lengths[0]) //Set vertical position for frame portal
        #else
        node.position.y = lengths[8]
        node.childNode(withName: "frame2", recursively: true)!.position.y = lengths[0] //Set vertical position for frame portal
        #endif
        
        var frame_element_length: CGFloat
        
        //X shift
        #if os(macOS)
        node.childNode(withName: "limit1_min", recursively: true)!.position.z = CGFloat(lengths[1])
        node.childNode(withName: "limit1_max", recursively: true)!.position.z = CGFloat(lengths[5])
        frame_element_length = CGFloat(lengths[5] + lengths[1]) //Calculate frame X length
        #else
        node.childNode(withName: "limit1_min", recursively: true)!.position.z = lengths[1]
        node.childNode(withName: "limit1_max", recursively: true)!.position.z = lengths[5]
        frame_element_length = CGFloat(lengths[5] + lengths[1]) //Calculate frame X length
        #endif
        
        modified_node = node.childNode(withName: "part_x", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNBox(width: 60, height: 60, length: frame_element_length, chamferRadius: 10) //Update frame X geometry
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = (frame_element_length + 80) / 2 //Frame X reposition
        #else
        modified_node.position.z = Float(frame_element_length + 80) / 2
        #endif
        
        //Y shift
        #if os(macOS)
        node.childNode(withName: "limit0_min", recursively: true)!.position.x = CGFloat(lengths[2]) / 2
        node.childNode(withName: "limit0_max", recursively: true)!.position.x = CGFloat(lengths[6])
        frame_element_length = CGFloat(lengths[6] + lengths[2] - 80) //Calculate frame Y length
        #else
        node.childNode(withName: "limit0_min", recursively: true)!.position.x = lengths[2] / 2
        node.childNode(withName: "limit0_max", recursively: true)!.position.x = lengths[6]
        frame_element_length = CGFloat(lengths[6] + lengths[2] - 80) //Calculate frame Y length
        #endif
        
        modified_node = node.childNode(withName: "part_y", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNBox(width: 60, height: 60, length: frame_element_length, chamferRadius: 10) //Update frame Y geometry
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = (frame_element_length + 80) / 2 //Frame Y reposition
        #else
        modified_node.position.x = Float(frame_element_length + 80) / 2
        #endif
        
        //Z shift
        #if os(macOS)
        node.childNode(withName: "limit2_min", recursively: true)!.position.y = CGFloat(-lengths[3])
        node.childNode(withName: "limit2_max", recursively: true)!.position.y = CGFloat(lengths[7])
        frame_element_length = CGFloat(lengths[7] + 80)
        #else
        node.childNode(withName: "limit2_min", recursively: true)!.position.y = -lengths[3]
        node.childNode(withName: "limit2_max", recursively: true)!.position.y = lengths[7]
        frame_element_length = CGFloat(lengths[7] + 80)
        #endif
        
        modified_node = node.childNode(withName: "part_z", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNBox(width: 60, height: frame_element_length, length: 60, chamferRadius: 10) //Update frame Z geometry
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = (frame_element_length) / 2 //Frame Z reposition
        #else
        modified_node.position.y = Float(frame_element_length) / 2
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
        
        /*if let initial_charts_data = updated_charts_data()
        {
            charts = initial_charts_data
        }*/
        
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
