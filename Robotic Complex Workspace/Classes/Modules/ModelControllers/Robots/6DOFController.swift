//
//  6DOFController.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 16.11.2022.
//

import Foundation
import SceneKit
import IndustrialKit

class _6DOFController: RobotModelController
{
    //MARK: - 6DOF nodes connect
    override func nodes_connect(_ node: SCNNode)
    {
        let without_lengths = lengths.count == 0
        if without_lengths
        {
            lengths = [Float](repeating: 0, count: 6)
        }
        
        for i in 0...6
        {
            //Connect to part nodes from robot scene
            nodes.append(node.childNode(withName: "d\(i)", recursively: true)!)
            
            //Get lengths from robot scene if they is not set in plist
            if without_lengths
            {
                if i > 0
                {
                    lengths[i - 1] = Float(nodes[i].position.y)
                }
            }
        }
        
        if without_lengths
        {
            lengths.append(Float(nodes[0].position.y)) //Append base height [6]
        }
        
        nodes.append(node.childNode(withName: "base", recursively: true)!) //Base pillar node [7]
    }
    
    //MARK: - Inverse kinematic parts calculation for roataion angles of 6DOF
    override func inverse_kinematic_calculate(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float]) -> [Float]
    {
        var angles = [Float]()
        var C3 = Float()
        var theta = [Float](repeating: 0, count: 6)
        
        do
        {
            var px, py, pz: Float
            var rx, ry, rz: Float
            var ax, ay, az, bx, by, bz: Float
            var asx, asy, asz, bsx, bsy, bsz: Float
            var p5x, p5y, p5z: Float
            var C1, C23, S1, S23: Float
            
            var M, N, A, B: Float
            
            px = -(pointer_location[0] + origin_location[0])
            py = pointer_location[1] + origin_location[1]
            pz = pointer_location[2] + origin_location[2]
            
            rx = -(pointer_rotation[0].to_rad + origin_rotation[0].to_rad)
            ry = -(pointer_rotation[1].to_rad + origin_rotation[1].to_rad) + (.pi)
            rz = -(pointer_rotation[2].to_rad + origin_rotation[2].to_rad)
            
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
            
            //Joint 1
            theta[0] = Float(atan2(p5y, p5x))
            
            //Joints 3, 2
            theta[2] = Float(atan2(pow(abs(1 - pow(C3, 2)), 0.5), C3))
            
            M = lengths[1] + (lengths[2] + lengths[3]) * C3
            N = (lengths[2] + lengths[3]) * sin(Float(theta[2]))
            A = pow(p5x * p5x + p5y * p5y, 0.5)
            B = p5z - lengths[0]
            theta[1] = Float(atan2(M * A - N * B, N * A + M * B))
            
            //Jionts 4, 5, 6
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
    
    override func nodes_update(values: [Float])
    {
        #if os(macOS)
        nodes[0].eulerAngles.y = CGFloat(values[0])
        nodes[1].eulerAngles.z = CGFloat(values[1])
        nodes[2].eulerAngles.z = CGFloat(values[2])
        nodes[3].eulerAngles.y = CGFloat(values[3])
        nodes[4].eulerAngles.z = CGFloat(values[4])
        nodes[5].eulerAngles.y = CGFloat(values[5])
        #else
        nodes[0].eulerAngles.y = Float(values[0])
        nodes[1].eulerAngles.z = Float(values[1])
        nodes[2].eulerAngles.z = Float(values[2])
        nodes[3].eulerAngles.y = Float(values[3])
        nodes[4].eulerAngles.z = Float(values[4])
        nodes[5].eulerAngles.y = Float(values[5])
        #endif
        
        if get_statistics
        {
            chart_ik_values = values //Store new parts angles array for chart
        }
    }
    
    override var description_lengths_count: Int { 7 }
    
    override func update_nodes_lengths()
    {
        var modified_node = SCNNode()
        var saved_material = SCNMaterial()
        
        //Change height of base
        modified_node = nodes[7]
        saved_material = (modified_node.geometry?.firstMaterial)!
        
        modified_node.geometry = SCNCylinder(radius: 80, height: CGFloat(lengths[6]))
        #if os(macOS)
        modified_node.position.y = CGFloat(lengths[6] / 2)
        #else
        modified_node.position.y = lengths[6] / 2
        #endif
        
        modified_node.geometry?.firstMaterial = saved_material
        
        //Change other lengths
        saved_material = (nodes[0].childNode(withName: "box", recursively: false)!.geometry?.firstMaterial) ?? SCNMaterial() //Save material from part box
        
        for i in 0..<nodes.count - 2
        {
            //Get length 0 if first robot part selected and get previous length for all next parts
            #if os(macOS)
            nodes[i].position.y = CGFloat(i > 0 ? lengths[i - 1] : lengths[lengths.count - 1])
            #else
            nodes[i].position.y = Float(i > 0 ? lengths[i - 1] : lengths[lengths.count - 1])
            #endif
            
            if i < 5
            {
                //Change box model size and move that node vertical for parts 0-4
                modified_node = nodes[i].childNode(withName: "box", recursively: false) ?? SCNNode()
                if i < 3
                {
                    modified_node.geometry = SCNBox(width: 60, height: CGFloat(lengths[i]), length: 60, chamferRadius: 10) //Set geometry for 0-2 parts with width 6 and chamfer
                }
                else
                {
                    if i < 4
                    {
                        modified_node.geometry = SCNBox(width: 50, height: CGFloat(lengths[i]), length: 50, chamferRadius: 10) //Set geometry for 3th part with width 5 and chamfer
                    }
                    else
                    {
                        modified_node.geometry = SCNBox(width: 40, height: CGFloat(lengths[i]), length: 40, chamferRadius: 0) //Set geometry for 4th part with width 4 and without chamfer
                    }
                }
                modified_node.geometry?.firstMaterial = saved_material //Apply saved material
                
                #if os(macOS)
                modified_node.position.y = CGFloat(lengths[i] / 2)
                #else
                modified_node.position.y = Float(lengths[i] / 2)
                #endif
            }
            else
            {
                //Set tool target (d6) position for 5th part
                #if os(macOS)
                nodes[6].position.y = CGFloat(lengths[i])
                #else
                nodes[6].position.y = Float(lengths[i])
                #endif
            }
        }
    }
    
    //MARK: - Statistics
    private var charts = [WorkspaceObjectChart]()
    private var chart_ik_values = [Float](repeating: 0, count: 6)
    private var domain_index: Float = 0
    
    override func charts_data() -> [WorkspaceObjectChart]?
    {
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Parts Rotation", style: .line))
            charts.append(WorkspaceObjectChart(name: "Tool Location", style: .line))
            charts.append(WorkspaceObjectChart(name: "Tool Rotation", style: .line))
        }
        
        //Update parts angles rotation chart
        for i in 0...chart_ik_values.count - 1
        {
            charts[0].data.append(ChartDataItem(name: "J\(i + 1)", domain: ["": domain_index], codomain: chart_ik_values[i]))
        }
        
        //Update tool location chart
        let tool_node = nodes.last
        
        var axis_names = ["X", "Y", "Z"]
        var components = [tool_node?.worldPosition.x, tool_node?.worldPosition.z, tool_node?.worldPosition.y]
        for i in 0...axis_names.count - 1
        {
            charts[1].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0)))
        }
        
        //Update tool rotation chart
        axis_names = ["R", "P", "W"]
        components = [tool_node?.eulerAngles.z, tool_node?.eulerAngles.x, tool_node?.eulerAngles.y]
        for i in 0...axis_names.count - 1
        {
            charts[2].data.append(ChartDataItem(name: axis_names[i], domain: ["": domain_index], codomain: Float(components[i] ?? 0).to_deg))
        }
        
        domain_index += 1
        
        return charts
    }
    
    override func clear_charts_data()
    {
        domain_index = 0
        chart_ik_values = [Float](repeating: 0, count: 6)
        charts = [WorkspaceObjectChart]()
    }
    
    override func state_data() -> [StateItem]?
    {
        var state = [StateItem]()
        state.append(StateItem(name: "Temperature", value: "+10º", image: "thermometer"))
        state[0].children = [StateItem(name: "Еngine", value: "+50º", image: "thermometer.transmission"),
                             StateItem(name: "Fridge", value: "-40º", image: "thermometer.snowflake.circle")]
        
        state.append(StateItem(name: "Speed", value: "10 mm/sec", image: "windshield.front.and.wiper.intermittent"))
        
        return state
    }
}
