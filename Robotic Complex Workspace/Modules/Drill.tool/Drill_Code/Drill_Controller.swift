//
// Tool Model Controller
//

import Foundation
import SceneKit
import IndustrialKit

class Drill_Controller: ToolModelController
{
    // MARK: - Parameters
    override var nodes_names: [String]
    {
        [
            "drill"
        ]
    }
    
    // MARK: - Performing
    private var rotated = [false, false]
    
    override func nodes_perform(code: Int)
    {
        info = [256, 256, 64, 64]
        
        if nodes.count == 1 //Drill has one rotated node
        {
            nodes[safe_name: "drill"].removeAllActions()
            
            switch code
            {
            case 0: // Strop rotation
                rotated[0] = false
                rotated[1] = false
            case 1: // Clockwise rotation
                if !rotated[0]
                {
                    nodes[safe_name: "drill"].runAction(.repeatForever(.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                    rotated[0] = true
                    rotated[1] = false
                }
            case 2: // Counter clockwise rotation
                if !rotated[1]
                {
                    nodes[safe_name: "drill"].runAction(.repeatForever(.rotate(by: -.pi, around: SCNVector3(0, 1, 0), duration: 0.1)))
                    rotated[1] = true
                    rotated[0] = false
                }
            default:
                rotated[0] = false
                rotated[1] = false
            }
        }
    }
    
    override func reset_nodes()
    {
        rotated[0] = false
        rotated[1] = false
    }
    
    // MARK: - Info
    var info = [Float]()
    
    override var info_output: [Float]?
    {
        return info
    }
    
    // MARK: - Statistics
    private var charts = [WorkspaceObjectChart]()
    private var domain_index: Float = 0
    
    override func updated_charts_data() -> [WorkspaceObjectChart]?
    {
        guard nodes.count == 1 else
        {
            return nil
        }
        
        var acceleration = [Float]()
        var velocity = [Float]()
        
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Rotation", style: .line))
        }
        
        sleep(1)
        
        if rotated[0] || rotated[1]
        {
            if rotated[0]
            {
                acceleration = acceleration_data(acceleration: 8).acceleration_values
                velocity = acceleration_data(acceleration: 8).velocity_values
            }
            
            if rotated[1]
            {
                acceleration = acceleration_data(acceleration: -8).acceleration_values
                velocity = acceleration_data(acceleration: -8).velocity_values
            }
        }
        else
        {
            acceleration = acceleration_data(acceleration: 0).acceleration_values
            velocity = acceleration_data(acceleration: 0).velocity_values
        }
        
        for i in 0..<velocity.count
        {
            charts[0].data.append(ChartDataItem(name: "Velocity", domain: ["": domain_index], codomain: velocity[i]))
            charts[0].data.append(ChartDataItem(name: "Acceleration", domain: ["": domain_index], codomain: acceleration[i]))
            domain_index += 1
        }
        
        return charts
    }
    
    private func acceleration_data(acceleration: Float) -> (acceleration_values: [Float], velocity_values: [Float])
    {
        var acceleration_values: [Float] = []
        var velocity_values: [Float] = []
        var velocity: Float = 0
        
        for i in 0..<10
        {
            acceleration_values.append(acceleration)
            velocity = acceleration + velocity
            velocity_values.append(velocity)
        }

        return (acceleration_values, velocity_values)
    }
    
    override func initial_charts_data() -> [WorkspaceObjectChart]
    {
        domain_index = 0
        return [WorkspaceObjectChart]()
    }
    
    override func updated_states_data() -> [StateItem]?
    {
        var state = [StateItem]()
        
        if rotated[0] || rotated[1]
        {
            if rotated[0]
            {
                state.append(StateItem(name: "Direction", value: "Clockwise", image: "arrow.clockwise.circle"))
                state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "windshield.front.and.wiper"))
            }
            
            if rotated[1]
            {
                state.append(StateItem(name: "Direction", value: "Counter clockwise", image: "arrow.counterclockwise.circle"))
                state.append(StateItem(name: "Rotation frequency", value: "40 Hz", image: "windshield.front.and.wiper"))
            }
        }
        else
        {
            state.append(StateItem(name: "Direction", value: "None", image: "stop.circle"))
            state.append(StateItem(name: "Rotation frequency", value: "0 Hz", image: "windshield.front.and.wiper"))
        }
        
        return state
    }
}
