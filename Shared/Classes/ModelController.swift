//
//  ModelController.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 11.11.2022.
//

import Foundation
import SceneKit

///Provides control over visual model for workspace object.
///
///In a workspace class of controllable object, such as a robot, this controller provides control functionality for the linked node in instance of the workspace object.
///Controller can add SCNaction or update position, angles for any nodes nested in object visual model root node.
/// > Model controller does not build the visual model, but can change it according to instance lengths.
class ModelController
{
    ///Model nodes from connected root node.
    public var nodes = [SCNNode]()
    
    ///Model nodes lengths.
    public var lengths = [Float]()
    
    ///Gets details nodes links from model root node and pass to array.
    public func nodes_connect(_ node: SCNNode)
    {
        
    }
    
    ///Removes all nodes to object model from controller.
    public final func nodes_disconnect()
    {
        nodes.removeAll()
    }
    
    ///Resets nodes position of connected visual model.
    public func reset_model()
    {
        
    }
    
    ///Stops connected model actions performation.
    public final func remove_all_model_actions()
    {
        for node in nodes //Remove all node actions
        {
            node.removeAllActions()
        }
        
        reset_model()
    }
    
    ///Required count of lengths to transform the connected model.
    ///
    ///Сan be overridden depending on the number of lengths used in the transformation.
    public var description_lengths_count: Int { 0 }
    
    ///Updates connected model nodes scales by instance lengths.
    internal final func nodes_transform()
    {
        guard lengths.count == description_lengths_count //Return if current lengths count is not equal required one
        else
        {
            return
        }
        
        update_nodes_lengths()
    }
    
    ///Sets new values for connected nodes geometries.
    public func update_nodes_lengths()
    {
        
    }
    
    ///Retruns perfroming state info.
    public var state: [[String: Any]]?
}

//MARK: - Model controller implementations
///Provides control over visual model for robot.
class RobotModelController: ModelController
{
    final func nodes_update(pointer_location: [Float], pointer_roation: [Float], origin_location: [Float], origin_rotation: [Float])
    {
        nodes_update(values: inverse_kinematic_calculate(pointer_location: origin_transform(pointer_location: pointer_location, origin_rotation: origin_rotation), pointer_rotation: pointer_roation, origin_location: origin_location, origin_rotation: origin_rotation))
    }
    
    public func inverse_kinematic_calculate(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float]) -> [Float]
    {
        return [Float]()
    }
    
    public func nodes_update(values: [Float])
    {
        
    }
}

///Transforms input position by origin rotation.
/// - Warning: All input/output arrays have only 3 values.
/// - Parameters:
///     - pointer_location: Input point location components – *x*, *y*, *z*.
///     - pointer_rotation: Input origin rotation components – *r*, *p*, *w*.
/// - Returns: Transformed inputed point location components – *x*, *y*, *z*.
func origin_transform(pointer_location: [Float], origin_rotation: [Float]) -> [Float]
{
    let new_x, new_y, new_z: Float
    if origin_rotation.reduce(0, +) > 0 //If at least one rotation angle of the origin is not equal to zero
    {
        //Calculate new values for coordinates components by origin rotation angles
        new_x = pointer_location[0] * cos(origin_rotation[1].to_rad) * cos(origin_rotation[2].to_rad) + pointer_location[2] * sin(origin_rotation[1].to_rad) - pointer_location[1] * sin(origin_rotation[2].to_rad)
        new_y = pointer_location[1] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[2].to_rad) - pointer_location[2] * sin(origin_rotation[0].to_rad) + pointer_location[0] * sin(origin_rotation[2].to_rad)
        new_z = pointer_location[2] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[1].to_rad) + pointer_location[1] * sin(origin_rotation[0].to_rad) - pointer_location[0] * sin(origin_rotation[1].to_rad)
    }
    else
    {
        //Return original values
        new_x = pointer_location[0]
        new_y = pointer_location[1]
        new_z = pointer_location[2]
    }
    
    return [new_x, new_y, new_z]
}

///Provides control over visual model for robot.
class ToolModelController: ModelController
{
    ///Performs node action by operation code.
    /// - Parameters:
    ///     - code: The information code of the operation performed by the tool visual model.
    public func nodes_perform(code: Int)
    {
        
    }
    
    ///Performs node action by operation code with completion handler.
    /// - Parameters:
    ///     - code: The information code of the operation performed by the tool visual model.
    ///     - completion: A completion block that is calls when the action completes.
    public func nodes_perform(code: Int, completion: @escaping () -> Void)
    {
        nodes_perform(code: code)
        completion()
    }
    
    ///Inforamation code updated by model controller.
    public var info_code: Int?
}
