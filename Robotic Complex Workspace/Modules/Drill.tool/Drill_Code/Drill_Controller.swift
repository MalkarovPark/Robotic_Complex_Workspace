//
// Tool Model Controller
//

import Foundation
import RealityKit
import IndustrialKit

class Drill_Controller: ToolModelController, @unchecked Sendable
{
    // MARK: - Parameters
    override var entity_names: [String]
    {
        [
            "drill"
        ]
    }
    
    // MARK: - Performing
    private var rotated = [false, false]
    
    override func entity_animations(code: Int) -> [EntityAnimationData]
    {
        var entities_animations: [EntityAnimationData] = []
        
        switch code
        {
        case 0: // Clockwise rotation
            rotated[0] = true
            rotated[1] = false
            entities_animations = [
                EntityAnimationData(
                    entity_name: "drill",
                    position: (x: -325, y: -325, z: 0, r: 0, p: 0, w: -180),
                    duration: 1,
                    speed: 4
                )
            ]
        case 1: // Counter clockwise rotation
            rotated[0] = false
            rotated[1] = true
            entities_animations = [
                EntityAnimationData(
                    entity_name: "drill",
                    position: (x: -325, y: -325, z: 0, r: 0, p: 0, w: 180),
                    duration: 1,
                    speed: 4
                )
            ]
        default: // Stop
            rotated[0] = false
            rotated[1] = false
            
            entities_animations = [
                EntityAnimationData(
                    entity_name: "drill",
                    position: (x: -325, y: -325, z: 0, r: 0, p: 0, w: 0),
                    duration: 0,
                    speed: 1,
                    repeat_count: 1
                )
            ]
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
        
        charts[0].data.append(ChartDataItem(name: "Left (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw", default: Entity()].position.z)))
        charts[0].data.append(ChartDataItem(name: "Right (mm)", domain: ["": domain_index], codomain: Float(entities[safe: "jaw2", default: Entity()].position.z)))
        
        domain_index += 1
        
        return charts
    }
    
    var current_items: [StateItem]
    {
        var state = [StateItem]()
        
        if rotated[0]
        {
            return [StateItem(name: "Rotation", value: "Clockwise", symbol_name: "arrow.clockwise.circle")]
        }
        else if rotated[1]
        {
            return [StateItem(name: "Rotation", value: "Counter clockwise", symbol_name: "arrow.counterclockwise.circle")]
        }
        else
        {
            return [StateItem(name: "Rotation", value: "Stopped", symbol_name: "nosign")]
        }
    }
    
    override var current_device_output: DeviceOutputData
    {
        return DeviceOutputData(
            items: current_items
        )
    }
    
    var initial_items: [StateItem]
    {
        domain_index = 0
        charts = [StateChart]()
        
        return [StateItem(name: "Closed", value: "", symbol_name: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left")]
    }
    
    override var initial_device_output: DeviceOutputData?
    {
        return DeviceOutputData(
            items: initial_items
        )
    }
}
