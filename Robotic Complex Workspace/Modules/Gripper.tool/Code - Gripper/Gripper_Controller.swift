//
//  GripperController.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 15.11.2022.
//

import Foundation
import SceneKit
import IndustrialKit

class Gripper_Controller: ToolModelController
{
    override func connect_nodes(_ node: SCNNode)
    {
        guard let jaw_node = node.childNode(withName: "jaw", recursively: true)
        else
        {
            return
        }
        
        guard let jaw2_node = node.childNode(withName: "jaw2", recursively: true)
        else
        {
            return
        }
        
        nodes += [jaw_node, jaw2_node]
    }
    
    private var closed = false
    private var moved = false
    
    override func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        if nodes.count == 2 //Gripper model has two nodes of jaws
        {
            switch code
            {
            case 0: //Grip
                if !closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    {
                        self.moved = false
                        self.closed = true
                        
                        self.info_output = [16, 64]
                        
                        completion()
                    }
                }
                else
                {
                    completion()
                }
            case 1: //Release
                if closed && !moved
                {
                    moved = true
                    nodes[0].runAction(.move(by: SCNVector3(x: 0, y: 0, z: 26), duration: 1))
                    nodes[1].runAction(.move(by: SCNVector3(x: 0, y: 0, z: -26), duration: 1))
                    {
                        self.moved = false
                        self.closed = false
                        
                        self.info_output = [64, 16]
                        
                        completion()
                    }
                }
                else
                {
                    completion()
                }
            default:
                closed = false
                moved = false
                
                //remove_all_model_actions()
                completion()
            }
        }
        else
        {
            completion()
        }
    }
    
    override func reset_nodes()
    {
        closed = false
        moved = false
        
        if nodes.count == 2
        {
            nodes[0].position.z = 46
            nodes[1].position.z = -46
        }
    }
    
    //MARK: - Statistics
    private var charts = [WorkspaceObjectChart]()
    private var domain_index: Float = 0
    
    override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        guard nodes.count == 2 else
        {
            return nil
        }
        
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Jaws Positions", style: .line))
        }
        
        charts[0].data.append(ChartDataItem(name: "Left (mm)", domain: ["": domain_index], codomain: Float(nodes[0].position.z)))
        charts[0].data.append(ChartDataItem(name: "Right (mm)", domain: ["": domain_index], codomain: Float(nodes[1].position.z)))
        
        usleep(100000)
        
        domain_index += 1
        
        return charts
    }
    
    override func reset_charts_data()
    {
        domain_index = 0
        charts = [WorkspaceObjectChart]()
        charts_data = nil
    }
    
    override func updated_states_data() -> [StateItem]?
    {
        var state = [StateItem]()
        
        if !moved
        {
            if closed
            {
                state.append(StateItem(name: "Closed", value: "", image: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left"))
            }
            else
            {
                state.append(StateItem(name: "Opened", value: "", image: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"))
            }
        }
        else
        {
            if closed
            {
                state.append(StateItem(name: "Opening", value: "", image: "arrow.left.and.line.vertical.and.arrow.right"))
            }
            else
            {
                state.append(StateItem(name: "Closing", value: "", image: "arrow.right.and.line.vertical.and.arrow.left"))
            }
        }
        
        return state
    }
}
