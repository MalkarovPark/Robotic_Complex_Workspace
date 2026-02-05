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
            //closed = false
            //moved = false
        }
        
        return entities_animations
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
        guard entities.count == 2
        else
        {
            return nil
        }
        
        if charts.count == 0
        {
            charts.append(WorkspaceObjectChart(name: "Jaws Positions", style: .line))
        }
        
        charts[0].data.append(ChartDataItem(name: "Left (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw", default: SCNNode()].position.z)))
        charts[0].data.append(ChartDataItem(name: "Right (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw2", default: SCNNode()].position.z)))
        
        usleep(100000)
        
        domain_index += 1
        
        return charts
    }
    
    override func initial_charts_data() -> [WorkspaceObjectChart]?
    {
        domain_index = 0
        charts = [WorkspaceObjectChart]()
        
        return charts
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
