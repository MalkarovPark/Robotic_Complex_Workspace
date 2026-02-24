//
// Tool Model Controller
//

import Foundation
import SceneKit
import IndustrialKit

class Gripper_Controller: ToolModelController
{
    // MARK: - Parameters
    override var entities_names: [String]
    {
        [
            "jaw",
            "jaw2"
        ]
    }
    
    // MARK: - Performing
    private var closed = false
    private var moved = false
    
    override func entity_animations(code: Int) -> [EntityAnimationData]
    {
        var entities_animations: [EntityAnimationData] = []
        
        switch code
        {
        case 0: // Close
            entities_animations = [
                EntityAnimationData(
                    entity_name: "jaw",
                    position: (x: 20000, y: 0, z: 0, r: 0, p: 0, w: 0),
                    duration: 1
                ),
                EntityAnimationData(
                    entity_name: "jaw2",
                    position: (x: -20000, y: 0, z: 0, r: 0, p: 0, w: 0),
                    duration: 1
                )
            ]
        case 1: // Open
            entities_animations = [
                EntityAnimationData(
                    entity_name: "jaw",
                    position: (x: 46000, y: 0, z: 0, r: 0, p: 0, w: 0),
                    duration: 1
                ),
                EntityAnimationData(
                    entity_name: "jaw2",
                    position: (x: -46000, y: 0, z: 0, r: 0, p: 0, w: 0),
                    duration: 1
                )
            ]
        default:
            break
        }
        
        return entities_animations
    }
    
    // MARK: - Statistics
    private var charts = [StateChart]()
    private var domain_index: Float = 0
    
    var current_charts: [StateChart]
    {
        guard entities.count == 2
        else
        {
            return []
        }
        
        if charts.count == 0
        {
            charts.append(StateChart(name: "Fingers Positions", style: .line))
        }
        
        charts[0].data.append(ChartDataItem(name: "Left (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw", default: SCNNode()].position.z)))
        charts[0].data.append(ChartDataItem(name: "Right (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw2", default: SCNNode()].position.z)))
        
        domain_index += 1
        
        return charts
    }
    
    var current_items: [StateItem]
    {
        var state = [StateItem]()
        
        if !moved
        {
            if closed
            {
                state.append(StateItem(name: "Closed", value: "", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left"))
            }
            else
            {
                state.append(StateItem(name: "Opened", value: "", symbol_name: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"))
            }
        }
        else
        {
            if closed
            {
                state.append(StateItem(name: "Opening", value: "", symbol_name: "arrow.left.and.line.vertical.and.arrow.right"))
            }
            else
            {
                state.append(StateItem(name: "Closing", value: "", symbol_name: "arrow.right.and.line.vertical.and.arrow.left"))
            }
        }
        
        return state
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
        charts = [StateChart]()
        
        return charts
    }
    
    var initial_items: [StateItem]
    {
        domain_index = 0
        charts = [StateChart]()
        
        return [StateItem(name: "Closed", value: "", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left")]
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
