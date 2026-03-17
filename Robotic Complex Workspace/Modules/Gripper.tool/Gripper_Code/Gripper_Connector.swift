//
// Tool Connector
//

import Foundation
import IndustrialKit
import SceneKit
import RealityKit

class Gripper_Connector: ToolConnector
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
    
    private var closed = false
    private var moved = false
    
    open override func start_process(code: Int)
    {
        performing_task = Task
        {
            print("Perform code \(code)")
            moved = true
            current_performing_state = .processing
            new_animation_avaliable = true
            
            sleep(2)
            
            moved = false
            current_performing_state = .completed
            
            closed = code == 0
            print("Finished")
        }
    }
    
    open override func reset_device()
    {
        //
    }
    
    open override var current_tool_state: ToolState?
    {
        return ToolState(
            performing_state: current_performing_state,
            entity_animations: current_entity_animations
        )
    }
    
    /*open override func perform(code: Int) throws
    {
        print("Perform code \(code)")
        moved = true
        new_animation_avaliable = true
        
        sleep(2)
        
        moved = false
        
        closed = code == 0
        print("Finished")
    }*/
    
    // MARK: - Modeling
    private var new_animation_avaliable = false
    
    private var current_entity_animations: [EntityAnimationData]?
    {
        guard new_animation_avaliable else { return nil }
        
        var entities_animations: [EntityAnimationData] = []
        
        switch closed
        {
        case false: // Closed
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
        case true: // Opened
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
        }
        
        new_animation_avaliable = false
        return entities_animations
    }
    
    // MARK: - Statistics
    private var charts = [StateChart]()
    private var domain_index: Float = 0
    
    private var entities: [String : Entity]
    {
        if let model_controller = model_controller
        {
            return model_controller.entities
        }
        else
        {
            return [:]
        }
    }
    
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
