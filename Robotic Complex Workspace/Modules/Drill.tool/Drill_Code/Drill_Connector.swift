//
// Tool Connector
//

import Foundation
import RealityKit
import IndustrialKit

class Drill_Connector: ToolConnector, @unchecked Sendable
{
    // MARK: - Connection
    override var default_parameters: [ConnectionParameter]
    {
        [
            .init(name: "String", value: "Text"),
            .init(name: "Int", value: 8),
            .init(name: "Float", value: Float(0.5)),
            .init(name: "Bool", value: true)
        ]
    }
    
    override func connection_process() async -> Bool
    {
        sleep(1)
        
        let result = parameters[safe: 3]?.value as? Bool ?? false
        
        if result
        {
            connection_output_string = "Connected"
        }
        else
        {
            connection_output_string = "Failed"
            connection_error = NSError(domain: "Connection failed", code: 0, userInfo: nil)
        }
        
        return result
    }
    
    override func disconnection_process()
    {
        
    }
    
    // MARK: - Performing
    private var performing_task: Task<Void, Never>?
    private var current_performing_state: PerformingState = .none
    
    private var current_code = 0
    private var rotated = [false, false]
    
    open override func start_process(code: Int)
    {
        performing_task = Task
        {
            current_performing_state = .processing
            new_animation_avaliable = true
            
            sleep(1)
            
            current_performing_state = .completed
            
            current_code = code
        }
    }
    
    open override func reset_device()
    {
        model_controller?.reset_entities()
        
        rotated = [false, false]
        
        performing_task?.cancel()
    }
    
    open override var current_device_state: ToolState?
    {
        return ToolState(
            performing_state: current_performing_state,
            entity_animations: current_entity_animations
        )
    }
    
    // MARK: - Modeling
    private var new_animation_avaliable = false
    
    private var current_entity_animations: [EntityAnimationData]?
    {
        guard new_animation_avaliable else { return nil }
        
        var entities_animations: [EntityAnimationData] = []
        
        switch current_code
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
        
        new_animation_avaliable = false
        return entities_animations
    }
    
    // MARK: - Statistics
    var current_items: [StateItem]
    {
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
}
