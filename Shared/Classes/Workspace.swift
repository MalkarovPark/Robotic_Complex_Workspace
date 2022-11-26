//
//  Workspace.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

/**
 A basis of industrial technological complex including production equipment.
 
 Performs management of the production complex.
 
 Builds a visual model of the production system.
 */
class Workspace: ObservableObject
{
    //MARK: - Workspace objects data
    @Published public var robots = [Robot]()
    @Published public var elements = [WorkspaceProgramElement]()
    @Published public var tools = [Tool]()
    @Published public var details = [Detail]()
    
    //MARK: - Workspace visual handling functions
    ///A SceneKit scene for complex visual model of workspace.
    public var scene = SCNScene()
    
    ///A selected workspace object type value in industrial complex.
    public var selected_object_type: WorkspaceObjectType?
    {
        if selected_robot_index > -1 && selected_detail_index == -1 && selected_tool_index == -1
        {
            return .robot
        }
        
        if selected_tool_index > -1 && selected_robot_index == -1 && selected_detail_index == -1
        {
            return .tool
        }
        
        if selected_detail_index > -1 && selected_robot_index == -1 && selected_tool_index == -1
        {
            return .detail
        }
        
        return nil
    }
    
    ///Sets new pointer position by selected workspace object.
    public func update_pointer()
    {
        update_object_pointer_position(by_node: edited_object_node ?? SCNNode())
    }
    
    private func update_object_pointer_position(by_node: SCNNode)
    {
        //Remove old and add new constraint
        object_pointer_node?.constraints?.removeAll()
        object_pointer_node?.constraints?.append(SCNReplicatorConstraint(target: by_node))
        
        //Refresh pointer node position
        object_pointer_node?.position.x += 1
        object_pointer_node?.position.x -= 1
        //object_pointer_node?.rotation.x += 1
        //object_pointer_node?.rotation.x -= 1
        
        object_pointer_node?.isHidden = false //Unhide pointer node
    }
    
    ///Link to edited object node.
    public var edited_object_node: SCNNode?
    
    ///Gets new object node model for previewing position.
    public func view_object_node(type: WorkspaceObjectType, name: String)
    {
        //Reset dismissed object by type
        switch selected_object_type
        {
        case .robot:
            selected_robot.location = [0, 0, 0]
            selected_robot.rotation = [0, 0, 0]
        case .tool:
            selected_tool.location = [0, 0, 0]
            selected_tool.rotation = [0, 0, 0]
        case .detail:
            selected_detail.location = [0, 0, 0]
            selected_detail.rotation = [0, 0, 0]
        default:
            break
        }
        
        edited_object_node?.removeFromParentNode() //Remove old node
        edited_object_node = SCNNode() //Remove old reference
        
        switch type
        {
        case .robot:
            //Deselect other
            deselect_detail()
            deselect_tool()
            
            //Get new node
            select_robot(name: name) //Select robot in workspace
            workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!) //Get workcell from Workcell.scn and add it to Workspace.scn
            
            edited_object_node = workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
            
            edited_object_node?.name = name
            selected_robot.workcell_connect(scene: scene, name: name, connect_camera: false)
            selected_robot.update_robot()
        case .tool:
            //Deselect other
            deselect_robot()
            deselect_detail()
            
            //Get new node
            select_tool(name: name)
            
            edited_object_node = selected_tool.node?.clone()
            edited_object_node?.name = name
            
            tools_node?.addChildNode(edited_object_node ?? SCNNode())
        case .detail:
            //Deselect other
            deselect_robot()
            deselect_tool()
            
            //Get new node
            select_detail(name: name)
            selected_detail.model_position_reset()
            
            edited_object_node = selected_detail.node?.clone()
            edited_object_node?.name = name
            
            details_node?.addChildNode(edited_object_node ?? SCNNode())
        }
        
        //Unhide pointer and move to object position
        object_pointer_node?.isHidden = false
        update_pointer()
    }
    
    ///Updates model position of selected object in workspace scene by its positional values.
    public func update_object_position()
    {
        //Get position by selected object type
        var location = [Float](repeating: 0, count: 3)
        var rotation = [Float](repeating: 0, count: 3)
        
        switch selected_object_type
        {
        case .robot:
            location = selected_robot.location
            rotation = selected_robot.rotation
        case .tool:
            location = selected_tool.location
            rotation = selected_tool.rotation
        case.detail:
            location = selected_detail.location
            rotation = selected_detail.rotation
        default:
            break
        }
        
        //Apply position to node
        #if os(macOS)
        edited_object_node?.worldPosition = SCNVector3(x: CGFloat(location[1]), y: CGFloat(location[2]), z: CGFloat(location[0]))
        
        edited_object_node?.eulerAngles.x = CGFloat(rotation[1].to_rad)
        edited_object_node?.eulerAngles.y = CGFloat(rotation[2].to_rad)
        edited_object_node?.eulerAngles.z = CGFloat(rotation[0].to_rad)
        #else
        edited_object_node?.worldPosition = SCNVector3(x: location[1], y: location[2], z: location[0])
        
        edited_object_node?.eulerAngles.x = rotation[1].to_rad
        edited_object_node?.eulerAngles.y = rotation[2].to_rad
        edited_object_node?.eulerAngles.z = rotation[0].to_rad
        #endif
    }
    
    ///Places object in workspace.
    public func place_viewed_object()
    {
        switch selected_object_type
        {
        case .robot:
            selected_robot.is_placed = true
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.robot_bit_mask) //Apply categury bit mask
            
            deselect_robot()
        case .tool:
            selected_tool.is_placed = true
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.tool_bit_mask) //Apply categury bit mask
            
            deselect_tool()
        case.detail:
            selected_detail.is_placed = true
            
            apply_bit_mask(node: edited_object_node ?? SCNNode(), Workspace.detail_bit_mask) //Apply categury bit mask
            edited_object_node?.physicsBody = selected_detail.physics //Apply physics
            
            deselect_detail()
        default:
            break
        }
        
        //Disconnecting from edited node
        edited_object_node = SCNNode() //Remove old reference
        edited_object_node?.removeFromParentNode() //Remove old node
        
        is_editing = false
    }
    
    ///Removes selected object model from workspace scene.
    public func dismiss_object()
    {
        object_pointer_node?.isHidden = true
        
        edited_object_node?.removeFromParentNode() //Remove edited object node
        edited_object_node = SCNNode() //Remove scnnode link
        
        is_editing = false
        deselect_object()
    }
    
    public var selected_object_unavaliable: Bool?
    {
        var unavaliable = true
        switch selected_object_type
        {
        case .robot:
            if avaliable_robots_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        case .tool:
            if avaliable_tools_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        case.detail:
            if avaliable_details_names.count == 0
            {
                unavaliable = true
            }
            else
            {
                unavaliable = false
            }
        default:
            unavaliable = true
        }
        
        return unavaliable
    }
    
    ///Process object node selection in workspace scene.
    public func select_object_in_scene(result: SCNHitTestResult)
    {
        //print(result.localCoordinates)
        //print("🍮 tapped – \(result.node.name!), category \(result.node.categoryBitMask)")
        var object_node: SCNNode?
        
        switch result.node.categoryBitMask //Switch object node bit mask
        {
        case Workspace.robot_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.robot_bit_mask)
            select_object_for_edit(node: object_node!, type: .robot)
        case Workspace.tool_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.tool_bit_mask)
            select_object_for_edit(node: object_node!, type: .tool)
        case Workspace.detail_bit_mask:
            object_node = main_object_node(result_node: result.node, object_bit_mask: Workspace.detail_bit_mask)
            select_object_for_edit(node: object_node!, type: .detail)
        default:
            deselect_object_for_edit()
        }
        update_view()
        
        func main_object_node(result_node: SCNNode, object_bit_mask: Int) -> SCNNode //Find top level node of selectable object
        {
            var current_node = result_node
            var saved_node = SCNNode()
            
            while current_node.categoryBitMask == object_bit_mask
            {
                saved_node = current_node
                current_node = current_node.parent!
            }
            
            return saved_node
        }
    }
    
    private var previous_selected_type: WorkspaceObjectType = .robot //Current selected object type for new selection
    
    private func select_object_for_edit(node: SCNNode, type: WorkspaceObjectType) //Create editable node with name
    {
        //Connect to old detail node
        var old_detail_node = SCNNode()
        if selected_object_type == .detail
        {
            old_detail_node = edited_object_node!
        }
        edited_object_node = node //Connect to tapped node
        
        if is_selected
        {
            switch type //Switch new selected objec type
            {
            case .robot:
                if type == previous_selected_type
                {
                    if node.name! == selected_robot.name
                    {
                        //Deselect already selected robot
                        deselect_robot()
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        //Change selected to new robot
                        select_robot(name: node.name!)
                        update_pointer()
                    }
                }
                else
                {
                    deselect_all()
                    select_new()
                }
            case .tool:
                if type == previous_selected_type
                {
                    if node.name! == selected_tool.name
                    {
                        //Deselect already selected tool
                        deselect_tool()
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        //Change selected to new tool
                        select_tool(name: node.name!)
                        update_pointer()
                    }
                }
                else
                {
                    deselect_all()
                    select_new()
                }
            case .detail:
                if type == previous_selected_type
                {
                    if node.name! == selected_detail.name
                    {
                        //Deselect already selected detail
                        deselect_detail()
                        edited_object_node?.physicsBody = selected_detail.physics
                        object_pointer_node?.isHidden = true
                    }
                    else
                    {
                        old_detail_node.physicsBody = selected_detail.physics //Enable physics for deselctable node
                        
                        //Change selected to new detail
                        select_detail(name: node.name!)
                        update_pointer()
                        
                        edited_object_node?.physicsBody = .none //Disable physics physics for selected node
                    }
                }
                else
                {
                    edited_object_node?.physicsBody = selected_detail.physics
                    deselect_all()
                    select_new()
                }
            }
            
            previous_selected_type = type
        }
        else
        {
            select_new() //If nothing object selected – select new
        }
        
        func select_new() //Select new object by type
        {
            switch type
            {
            case .robot:
                select_robot(name: node.name!)
            case .tool:
                select_tool(name: node.name!)
            case .detail:
                select_detail(name: node.name!)
                edited_object_node?.physicsBody = .none
                
                //Get detail node position after physics calculation
                #if os(macOS)
                selected_detail.location = [Float((edited_object_node?.presentation.worldPosition.z)!), Float((edited_object_node?.presentation.worldPosition.x)!), Float((edited_object_node?.presentation.worldPosition.y)!)]
                selected_detail.rotation = [Float((edited_object_node?.presentation.eulerAngles.z)!).to_deg, Float((edited_object_node?.presentation.eulerAngles.x)!).to_deg, Float((edited_object_node?.presentation.eulerAngles.y)!).to_deg]
                #else
                selected_detail.location = [(edited_object_node?.presentation.worldPosition.z)!, (edited_object_node?.presentation.worldPosition.x)!, (edited_object_node?.presentation.worldPosition.y)!]
                selected_detail.rotation = [(edited_object_node?.presentation.eulerAngles.z.to_deg)!, (edited_object_node?.presentation.eulerAngles.x.to_deg)!, (edited_object_node?.presentation.eulerAngles.y.to_deg)!]
                #endif
            }
            
            //Unhide pointer and move to object position
            object_pointer_node?.isHidden = false
            update_pointer()
        }
        
        func deselect_all()
        {
            deselect_robot()
            deselect_tool()
            deselect_detail()
        }
    }
    
    ///Deselects edited object node.
    public func deselect_object_for_edit()
    {
        if is_selected
        {
            update_view()
            object_pointer_node?.isHidden = true
            
            switch selected_object_type
            {
            case .robot:
                deselect_robot()
            case .tool:
                deselect_tool()
            case .detail:
                if selected_detail.is_placed
                {
                    edited_object_node?.physicsBody = selected_detail.physics
                }
                deselect_detail()
            default:
                break
            }
            
            //Disconnect from edited node
            edited_object_node = SCNNode() //Remove old reference
            edited_object_node?.removeFromParentNode() //Remove old node
        }
    }
    
    ///Remove selected object.
    public func remove_selected_object()
    {
        if is_selected
        {
            //Toggle selection state and deselect by object type
            switch selected_object_type
            {
            case .robot:
                selected_robot.is_placed = false
                deselect_robot()
            case .tool:
                selected_tool.is_placed = false
                deselect_tool()
            case .detail:
                selected_detail.is_placed = false
                deselect_detail()
            default:
                break
            }
        }
        
        //Disconnect from edited node
        edited_object_node?.removeFromParentNode() //Remove old node
        edited_object_node = SCNNode() //Remove old reference
        
        object_pointer_node?.isHidden = true
    }
    
    ///Deselects selected object.
    public func deselect_object()
    {
        switch selected_object_type
        {
        case .robot:
            deselect_robot()
        case .tool:
            deselect_tool()
        case .detail:
            deselect_detail()
        default:
            break
        }
    }
    
    //MARK: - Robots handling functions
    //MARK: Robots manage functions
    ///Adds robot in workspace.
    public func add_robot(_ robot: Robot)
    {
        robot.name = mismatched_name(name: robot.name!, names: robots_names)
        robots.append(robot)
    }
    
    /**
     Deletes robot from workspace.
     
     - Parameters:
        - index: An index of robot to be deleted.
     */
    public func delete_robot(index: Int)
    {
        if robots.indices.contains(index)
        {
            robots.remove(at: index)
        }
    }
    
    /**
     Deletes robot from workspace.
     
     - Parameters:
        - name: A name of robot to be deleted.
     */
    public func delete_robot(name: String)
    {
        delete_robot(index: robot_index_by_name(name))
    }
    
    //MARK: Robot selection functions
    private var selected_robot_index = -1
    
    private func robot_index_by_name(_ name: String) -> Int //Get index number of robot by name
    {
        return robots.firstIndex(of: Robot(name: name)) ?? -1
    }
    
    /**
     Selects robot by index.
     
     - Parameters:
        - index: An index of robot to be selected.
     */
    public func select_robot(index: Int)
    {
        selected_robot_index = index
    }
    
    /**
     Selects robot by name.
     
     - Parameters:
        - name: A name of robot to be selected.
     */
    public func select_robot(name: String)
    {
        select_robot(index: robot_index_by_name(name))
    }
    
    ///Deselects selected robot.
    public func deselect_robot()
    {
        selected_robot_index = -1
    }
    
    ///Selected robot.
    public var selected_robot: Robot
    {
        get
        {
            if selected_robot_index > -1
            {
                return robots[selected_robot_index]
            }
            else
            {
                return Robot()
            }
        }
        set
        {
            if selected_robot_index > -1
            {
                robots[selected_robot_index] = newValue
            }
        }
    }
    
    //MARK: Robots naming
    /**
     Returns index number of robot by name.
     
     - Parameters:
        - name: A name of tobot for index find.
     */
    public func robot_by_name(_ name: String) -> Robot
    {
        return self.robots[robot_index_by_name(name)]
    }
    
    ///Names of all robots in workspace.
    public var robots_names: [String]
    {
        var robots_names = [String]()
        if robots.count > 0
        {
            for robot in robots
            {
                robots_names.append(robot.name ?? "None")
            }
        }
        return robots_names
    }
    
    ///Names of robots avaliable to place in workspace.
    public var avaliable_robots_names: [String]
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && !robot.is_placed
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    ///Names of robots placed in workspace.
    public var placed_robots_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && robot.is_placed
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    ///Names of robots avaliable to tool attachment.
    public var attachable_robots_names: [String]
    {
        var names = placed_robots_names
        
        if names.count > 0
        {
            //Find attached robots names by tools
            var attached_robots_names = [String]()
            for tool in tools
            {
                if tool.is_attached == true
                {
                    attached_robots_names.append(tool.attached_to ?? "")
                }
            }
            
            names = names.filter{ !attached_robots_names.contains($0) } //Substract attached robots names from all placed robots
        }
        
        return names
    }
    
    //MARK: - Tools handling functions
    //MARK: Tools manage funcions
    ///Adds tool in workspace.
    public func add_tool(_ tool: Tool)
    {
        tool.name = mismatched_name(name: tool.name!, names: tools_names)
        tools.append(tool)
    }
    
    /**
     Deletes tool from workspace.
     
     - Parameters:
        - index: An index of tool to be deleted.
     */
    public func delete_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            tools.remove(at: index)
        }
    }
    
    /**
     Deletes tool from workspace.
     
     - Parameters:
        - name: A name of tool to be deleted.
     */
    public func delete_tool(name: String)
    {
        delete_tool(index: tool_index_by_name(name))
    }

    //MARK: Tools selection functions
    private var selected_tool_index = -1
    
    ///Selected tool.
    public var selected_tool: Tool
    {
        get
        {
            if selected_tool_index > -1
            {
                return tools[selected_tool_index]
            }
            else
            {
                return Tool(name: "None")
            }
        }
        set
        {
            if selected_tool_index > -1
            {
                tools[selected_tool_index] = newValue
            }
        }
    }
    
    /**
     Selects tool by index.
     
     - Parameters:
        - index: An index of tool to be selected.
     */
    public func select_tool(index: Int) //Select tool by number
    {
        selected_tool_index = index
    }
    
    /**
     Selects tool by name.
     
     - Parameters:
        - name: A name of tool to be selected.
     */
    public func select_tool(name: String) //Select tool by name
    {
        select_tool(index: tool_index_by_name(name))
    }
    
    ///Deselects selected tool.
    public func deselect_tool()
    {
        selected_tool_index = -1
    }
    
    //MARK: Tools naming
    /**
     Returns index number of tool by name.
     
     - Parameters:
        - name: A name of tool for index find.
     */
    private func tool_index_by_name(_ name: String) -> Int
    {
        return tools.firstIndex(of: Tool(name: name)) ?? -1
    }
    
    /**
     Returns index number of robot by name.
     
     - Parameters:
        - name: A name of tobot for index find.
     */
    public func tool_by_name(_ name: String) -> Tool
    {
        return self.tools[tool_index_by_name(name)]
    }
    
    ///Names of all tools in workspace.
    public var tools_names: [String] //Get names of all tools in workspace
    {
        var names = [String]()
        if tools.count > 0
        {
            for tool in tools
            {
                names.append(tool.name ?? "None")
            }
        }
        return names
    }
    
    ///Names of tools avaliable to place in workspace.
    public var avaliable_tools_names: [String]
    {
        var names = [String]()
        for tool in tools
        {
            if tool.name != nil && !tool.is_placed
            {
                names.append(tool.name!)
            }
        }
        return names
    }
    
    ///Names of tools placed in workspace.
    public var placed_tools_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for tool in tools
        {
            if tool.name != nil && tool.is_placed
            {
                names.append(tool.name!)
            }
        }
        return names
    }
    
    //MARK: Tool attachment functions
    /**
     Attaches tool to robot.
     
     - Parameters:
        - robot_name: A name of the robot that the tool is attached to.
     */
    public func attach_tool_to(robot_name: String)
    {
        update_pointer()
        
        edited_object_node?.constraints = [SCNConstraint]()
        edited_object_node?.constraints?.append(SCNReplicatorConstraint(target: robot_by_name(robot_name).tool_node))
    }
    
    ///Removes attachment for edited tool and reset it position in workspace.
    public func remove_attachment()
    {
        clear_constranints(node: edited_object_node ?? SCNNode())
        selected_tool.attached_to = nil
    }
    
    //MARK: - Details handling functions
    //MARK: Details manage funcions
    ///Adds detail in workspace.
    public func add_detail(_ detail: Detail)
    {
        detail.name = mismatched_name(name: detail.name!, names: details_names)
        details.append(detail)
    }
    
    /**
     Deletes detail from workspace.
     
     - Parameters:
        - index: An index of detail to be deleted.
     */
    public func delete_detail(index: Int)
    {
        if details.indices.contains(index)
        {
            details.remove(at: index)
        }
    }
    
    /**
     Deletes detail from workspace.
     
     - Parameters:
        - name: A name of detail to be deleted.
     */
    public func delete_detail(name: String)
    {
        delete_detail(index: detail_index_by_name(name))
    }
    
    //MARK: Details selection functions
    private var selected_detail_index = -1
    
    ///Selected detail.
    public var selected_detail: Detail //Return detail by selected index
    {
        get
        {
            if selected_detail_index > -1
            {
                return details[selected_detail_index]
            }
            else
            {
                return Detail(name: "None")
            }
        }
        set
        {
            if selected_detail_index > -1
            {
                details[selected_detail_index] = newValue
            }
        }
    }
    
    /**
     Selects detail by index.
     
     - Parameters:
        - index: An index of detail to be selected.
     */
    public func select_detail(index: Int)
    {
        selected_detail_index = index
    }
    
    /**
     Selects detail by name.
     
     - Parameters:
        - name: A name of detail to be selected.
     */
    public func select_detail(name: String)
    {
        select_detail(index: detail_index_by_name(name))
    }
    
    ///Deselects selected detail.
    public func deselect_detail()
    {
        selected_detail_index = -1
    }
    
    //MARK: Details naming
    /**
     Returns index number of detail by name.
     
     - Parameters:
        - name: A name of detail for index find.
     */
    private func detail_index_by_name(_ name: String) -> Int
    {
        return details.firstIndex(of: Detail(name: name)) ?? -1
    }
    
    ///Names of all details in workspace.
    public var details_names: [String]
    {
        var details_names = [String]()
        if details.count > 0
        {
            for detail in details
            {
                details_names.append(detail.name ?? "None")
            }
        }
        return details_names
    }
    
    ///Names of details avaliable to place in workspace.
    public var avaliable_details_names: [String]
    {
        var names = [String]()
        for detail in details
        {
            if detail.name != nil && !detail.is_placed
            {
                names.append(detail.name!)
            }
        }
        return names
    }
    
    //MARK: - Control program functions
    //MARK: Workspace program elements handling
    public var marks_names: [String] //Get names of all marks in workspace program
    {
        var marks_names = [String]()
        for program_element in self.elements
        {
            if program_element.element_data.logic_type == .mark && program_element.element_data.mark_name != ""
            {
                marks_names.append(program_element.element_data.mark_name)
            }
        }
        
        return marks_names
    }
    
    public func delete_element(index: Int) //Delete program element by number
    {
        if elements.indices.contains(index)
        {
            elements.remove(at: index)
        }
    }
    
    //MARK: Workspace progem elements checking functions
    public func elements_check() //Select check by element type
    {
        for element in elements
        {
            switch element.element_data.element_type
            {
            case .perofrmer:
                switch element.element_data.performer_type
                {
                case .robot:
                    robot_element_check(element: element)
                case .tool:
                    break
                }
            case .modificator:
                break
            case .logic:
                switch element.element_data.logic_type
                {
                case .jump:
                    jump_element_check(element: element)
                case .mark:
                    break
                default:
                    break
                }
            }
        }
        
        func robot_element_check(element: WorkspaceProgramElement) //Check element by selected robot exists
        {
            if element.element_data.robot_name != ""
            {
                if self.robot_by_name(element.element_data.robot_name).is_placed == false
                {
                    if self.placed_robots_names.count > 0
                    {
                        element.element_data.robot_name = self.placed_robots_names.first!
                        
                        if robot_by_name(element.element_data.robot_name).programs_count > 0
                        {
                            element.element_data.program_name = robot_by_name(element.element_data.robot_name).programs_names.first!
                        }
                    }
                    else
                    {
                        element.element_data.robot_name = ""
                    }
                }
            }
            else
            {
                if self.placed_robots_names.count > 0
                {
                    element.element_data.robot_name = robots.first?.name ?? "None"
                    if robots.first?.programs_count ?? 0 > 0
                    {
                        element.element_data.program_name = robot_by_name(element.element_data.robot_name).programs_names.first!
                    }
                }
                else
                {
                    element.element_data.robot_name = ""
                }
            }
        }
        
        func tool_element_check(element: WorkspaceProgramElement)
        {
            if element.element_data.tool_name != ""
            {
                if self.tool_by_name(element.element_data.tool_name).is_placed == false
                {
                    if self.placed_tools_names.count > 0
                    {
                        element.element_data.tool_name = self.placed_tools_names.first!
                        
                        if robot_by_name(element.element_data.tool_name).programs_count > 0
                        {
                            element.element_data.program_name = tool_by_name(element.element_data.tool_name).programs_names.first!
                        }
                    }
                    else
                    {
                        element.element_data.tool_name = ""
                    }
                }
            }
            else
            {
                if self.placed_tools_names.count > 0
                {
                    element.element_data.tool_name = tools.first?.name ?? "None"
                    if tools.first?.programs_count ?? 0 > 0
                    {
                        element.element_data.program_name = tool_by_name(element.element_data.tool_name).programs_names.first!
                    }
                }
                else
                {
                    element.element_data.tool_name = ""
                }
            }
        }
        
        func jump_element_check(element: WorkspaceProgramElement) //Check element by selected mark exists
        {
            if marks_names.count > 0
            {
                var mark_founded = false
                
                for mark_name in self.marks_names
                {
                    if mark_name == element.element_data.target_mark_name
                    {
                        mark_founded = true
                    }
                    
                    if mark_founded == true
                    {
                        break
                    }
                }
                
                if mark_founded == false && element.element_data.mark_name == ""
                {
                    element.element_data.target_mark_name = marks_names[0]
                }
            }
            else
            {
                element.element_data.target_mark_name = ""
            }
        }
    }
    
    //MARK: Performation functions
    ///Program performating cycle state.
    @Published var cycled = false
    
    ///Workspace performing state.
    public var performed = false
    
    private var selected_element_index = 0
    
    public var element_changed = false //This flag perform update if performed element changed
    
    public func start_pause_performing()
    {
        deselect_object_for_edit()
        
        prepare_program()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) //Delayed view update
        {
            self.update_view()
        }
        
        if !performed
        {
            //Move to next point if moving was stop
            performed = true
            
            perform_next_element()
            element_changed = true
        }
        else
        {
            //Remove all action if moving was perform
            performed = false
            
            //Stop perfomed objects
            pause_performing()
            //selected_robot.start_pause_moving()
        }
    }
    
    private var selected_program_element: WorkspaceProgramElement
    {
        return elements[selected_element_index]
    }
    
    public func perform_next_element()
    {
        let element = selected_program_element
        
        switch element.element_data.element_type
        {
        case .perofrmer:
            switch element.element_data.performer_type
            {
            case .robot:
                perform_robot(name: element.element_data.robot_name, program: element.element_data.program_name)
                {
                    self.select_new_element()
                }
            case .tool:
                perform_tool(name: element.element_data.tool_name, program: element.element_data.program_name)
                {
                    self.select_new_element()
                }
            }
        case .modificator:
            break
        case .logic:
            switch element.element_data.logic_type
            {
            case .jump:
                jump_to(index: element.target_element_index)
            case .mark:
                select_new_element()
            default:
                break
            }
        }
    }
    
    private func select_new_element()
    {
        if performed
        {
            selected_element_index += 1
        }
        else
        {
            return
        }
        
        element_changed = true
        
        if selected_element_index < elements.count
        {
            //Select and move to next point
            perform_next_element()
        }
        else
        {
            selected_element_index = 0
            
            if cycled == true
            {
                perform_next_element()
            }
            else
            {
                performed = false
                //update_view()
            }
        }
    }
    
    public func pause_performing()
    {
        let element = selected_program_element
        
        switch element.element_data.element_type
        {
        case .perofrmer:
            switch element.element_data.performer_type
            {
            case .robot:
                break
            case .tool:
                break
            }
        case .modificator:
            break
        case .logic:
            switch element.element_data.logic_type
            {
            case .jump:
                break
            default:
                break
            }
        }
    }
    
    private func jump_to(index: Int)
    {
        selected_element_index = index
        perform_next_element()
        
        /*if element.element_data.target_mark_name != ""
        {
            jumped = true
        }
        
        if jumped == false
        {
            selected_element_index += 1
        }
        else
        {
            selected_element_index = element.target_element_index
        }*/
    }
    
    private func mark_step()
    {
        if selected_element_index < elements.count
        {
            selected_element_index += 1
        }
        else
        {
            if cycled
            {
                selected_element_index = 0
            }
            else
            {
                
            }
        }
        select_new_element()
    }
    
    ///Resets workspace performing.
    public func reset_performing()
    {
        //selected_robot.reset_moving()
        //deselect_robot()
        
        performed = false //Enable workspace program edit
        selected_element_index = 0 //Select firs program element
    }
    
    private func prepare_program()
    {
        defining_elements_indexes()
        models_connect()
    }
    
    private func defining_elements_indexes()
    {
        //Find mark elements indexes
        var marks_associations = [(String, Int)]()
        var element_data = workspace_program_element_struct()
        for i in 0..<elements.count
        {
            element_data = elements[i].element_data
            if element_data.element_type == .logic && element_data.logic_type == .mark
            {
                marks_associations.append((element_data.mark_name, i))
            }
        }
        
        //Set target element indexes of marks to jump elements.
        var target_mark_name: String
        for element in elements
        {
            if element.element_data.element_type == .logic && element.element_data.logic_type == .jump
            {
                target_mark_name = element.element_data.target_mark_name
                if target_mark_name != ""
                {
                    for marks_association in marks_associations
                    {
                        if marks_association.0 == target_mark_name
                        {
                            element.target_element_index = marks_association.1
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func models_connect()
    {
        for element in elements
        {
            if element.element_data.element_type == .perofrmer
            {
                switch element.element_data.performer_type
                {
                case .robot:
                    robot_by_name(element.element_data.robot_name).workcell_connect(scene: scene, name: element.element_data.robot_name, connect_camera: false)
                case.tool:
                    tool_by_name(element.element_data.tool_name).workcell_connect(scene: scene, name: element.element_data.tool_name)
                }
            }
        }
    }
    
    //MARK: Elements processing
    private func perform_robot(name: String, program: String, completion: @escaping () -> Void)
    {
        select_robot(name: name)
        selected_robot.finish_handler = completion
        
        selected_robot.start_pause_moving()
    }
    
    private func perform_tool(name: String, program: String, completion: @escaping () -> Void)
    {
        completion()
    }
    
    /*private func element_definition()
    {
        //update_view()
        
        let element = elements[selected_element_index]
        var jumped = false
        
        element.is_selected = true
        
        switch element.element_data.element_type
        {
        case .perofrmer:
            switch element.element_data.performer_type
            {
            case .robot:
                select_robot(name: element.element_data.robot_name)
                if selected_robot.programs_names.count > 0 && element.element_data.program_name != ""
                {
                    selected_robot.workcell_connect(scene: scene, name: selected_robot.name!, connect_camera: false)
                    selected_robot.select_program(name: element.element_data.program_name)
                    selected_robot.start_pause_moving()
                    while selected_robot.moving_completed == false && self.performed == true
                    {
                        
                    }
                }
                break
            case .tool:
                break
            }
        case .modificator:
            break
        case .logic:
            switch element.element_data.logic_type
            {
            case .jump:
                if element.element_data.target_mark_name != ""
                {
                    jumped = true
                }
            default:
                break
            }
        }
        
        if performed == true
        {
            update_view()
            elements[selected_element_index].is_selected = false
            
            if jumped == false
            {
                selected_element_index += 1
            }
            else
            {
                selected_element_index = element.target_element_index
            }
            
            perform_next_element()
        }
    }*/
    
    //MARK: - Work with file system
    /**
     Returns arrays of document structures by workspace objects type.
     
     - Returns: Codable structures for robots, tools, details and elements ordered as control program.
     */
    public func file_data() -> (robots: [RobotStruct], tools: [ToolStruct], details: [DetailStruct], elements: [workspace_program_element_struct])
    {
        //Get robots info for save to file
        var robots_file_info = [RobotStruct]()
        for robot in robots
        {
            robots_file_info.append(robot.file_info)
        }
        
        //Get tools info for save to file
        var tools_file_info = [ToolStruct]()
        for tool in tools
        {
            tools_file_info.append(tool.file_info)
        }
        
        //Get details info for save to file
        var details_file_info = [DetailStruct]()
        for detail in details
        {
            details_file_info.append(detail.file_info)
        }
        
        //Get workspace program elements info for save to file
        var elements_file_info = [workspace_program_element_struct]()
        for element in elements
        {
            elements_file_info.append(element.element_data)
        }
        
        return(robots_file_info, tools_file_info, details_file_info, elements_file_info)
    }
    
    ///File bookmark for robots models.
    public var robots_bookmark: Data?
    
    ///File bookmark for tools models.
    public var tools_bookmark: Data?
    
    ///File bookmark for details models.
    public var details_bookmark: Data?
    
    /**
     Imports file data to workspace from preset structure.
     
     - Parameters:
        - preset: Imported workspace preset.
     */
    public func file_view(preset: WorkspacePreset)
    {
        //Update robots data from file
        robots.removeAll()
        for robot_struct in preset.robots
        {
            robots.append(Robot(robot_struct: robot_struct))
        }
        
        //Update tools data from file
        tools.removeAll()
        if tools_bookmark != nil
        {
            Tool.folder_bookmark = tools_bookmark
        }
        
        for tool_struct in preset.tools
        {
            tools.append(Tool(tool_struct: tool_struct))
        }
        
        //Update details data from file
        details.removeAll()
        if details_bookmark != nil
        {
            Detail.folder_bookmark = details_bookmark
        }
        
        for detail_struct in preset.details
        {
            details.append(Detail(detail_struct: detail_struct))
        }
        
        //Update workspace program elements data from file
        elements.removeAll()
        for element_struct in preset.elements
        {
            elements.append(WorkspaceProgramElement(element_struct: element_struct))
        }
    }
    
    //MARK: - UI Functions
    ///Determines whether the robot can be selected if it is open for editing.
    public var is_editing = false
    
    ///Force updates SwiftUI view.
    func update_view()
    {
        self.objectWillChange.send()
    }
    
    ///Selection workspace object state.
    public var is_selected: Bool
    {
        if selected_robot_index == -1 && selected_detail_index == -1 && selected_tool_index == -1
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    ///Resets camera position SCNAction
    public var reset_view_action: SCNAction
    {
        return SCNAction.group([SCNAction.move(to: camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: camera_node!.rotation, duration: 0.5)])
    }
    
    ///If add in view presented or not dismissed state.
    public var add_in_view_dismissed = true
    
    ///Disabled add new object button.
    public var add_in_view_disabled: Bool
    {
        if !is_selected || !add_in_view_dismissed || performed
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    public func is_current_element(element: WorkspaceProgramElement) -> Bool //Get point color for inspector view
    {
        var flag = false
        let element_index = self.elements.firstIndex(of: element) //Number of selected code
        
        if performed
        {
            if element_index == selected_element_index //Yellow color, if the tool is in the process of moving to the code
            {
                flag = true
            }
        }
        
        return flag
    }
    
    //MARK: - Visual functions
    ///Scene camera node.
    public var camera_node: SCNNode?
    
    ///Robots workcells node.
    public var workcells_node: SCNNode?
    
    ///Tools node.
    public var tools_node: SCNNode?
    
    ///Details node.
    public var details_node: SCNNode?
    
    ///Viusal object pointer node.
    public var object_pointer_node: SCNNode?
    
    ///Robot node category bit mask.
    public static var robot_bit_mask = 2
    
    ///Tool node category bit mask.
    public static var tool_bit_mask = 4
    
    ///Detail node category bit mask.
    public static var detail_bit_mask = 6
    
    ///Connects and places objects to workspace scene.
    public func connect_scene(_ scene: SCNScene)
    {
        deselect_robot()
        deselect_tool()
        deselect_detail()
        
        camera_node = scene.rootNode.childNode(withName: "camera", recursively: true)
        
        workcells_node = scene.rootNode.childNode(withName: "workcells", recursively: true)
        tools_node = scene.rootNode.childNode(withName: "tools", recursively: false)
        details_node = scene.rootNode.childNode(withName: "details", recursively: false)
        
        object_pointer_node = scene.rootNode.childNode(withName: "object_pointer", recursively: false)
        object_pointer_node?.constraints = [SCNConstraint]()
        
        place_objects(scene: scene)
    }
    
    private func place_objects(scene: SCNScene)
    {
        //Nodes for placement operations
        var unit_node: SCNNode?
        var tool_node: SCNNode?
        var detail_node: SCNNode?
        
        //Place robots
        if self.avaliable_robots_names.count < self.robots.count //If there are placed robots in workspace
        {
        	var connect_camera = true
            for robot in robots
            {
                if robot.is_placed == true
                {
                    workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!)
                    unit_node = workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
                    
                    unit_node?.name = robot.name //Select robot cell node
                    robot.workcell_connect(scene: scene, name: robot.name!, connect_camera: connect_camera) //Connect to robot model, place manipulator
                    robot.update_robot() //Update robot by current position
                    
                    apply_bit_mask(node: robot.unit_node ?? SCNNode(), Workspace.robot_bit_mask)
                    
                    connect_camera = false //Disable camera connect for next robots in array
                    
                    //Set robot cell node position
                    #if os(macOS)
                    unit_node?.worldPosition = SCNVector3(x: CGFloat(robot.location[1]), y: CGFloat(robot.location[2]), z: CGFloat(robot.location[0]))
                    
                    unit_node?.eulerAngles.x = CGFloat(robot.rotation[1].to_rad)
                    unit_node?.eulerAngles.y = CGFloat(robot.rotation[2].to_rad)
                    unit_node?.eulerAngles.z = CGFloat(robot.rotation[0].to_rad)
                    #else
                    unit_node?.worldPosition = SCNVector3(x: robot.location[1], y: robot.location[2], z: robot.location[0])

                    unit_node?.eulerAngles.x = robot.rotation[1].to_rad
                    unit_node?.eulerAngles.y = robot.rotation[2].to_rad
                    unit_node?.eulerAngles.z = robot.rotation[0].to_rad
                    #endif
                }
            }
        }
        
        //Place tools
        if self.avaliable_tools_names.count < self.tools.count //If there are placed tools in workspace
        {
            for tool in tools
            {
                if tool.is_placed
                {
                    tool_node = tool.node
                    apply_bit_mask(node: tool_node ?? SCNNode(), Workspace.tool_bit_mask)
                    tool_node?.name = tool.name
                    tools_node?.addChildNode(tool_node ?? SCNNode())
                    
                    if !tool.is_attached
                    {
                        //Set tool node position
                        #if os(macOS)
                        tool_node?.position = SCNVector3(x: CGFloat(tool.location[1]), y: CGFloat(tool.location[2]), z: CGFloat(tool.location[0]))
                        
                        tool_node?.eulerAngles.x = CGFloat(tool.rotation[1].to_rad)
                        tool_node?.eulerAngles.y = CGFloat(tool.rotation[2].to_rad)
                        tool_node?.eulerAngles.z = CGFloat(tool.rotation[0].to_rad)
                        #else
                        tool_node?.position = SCNVector3(x: Float(tool.location[1]), y: Float(tool.location[2]), z: Float(tool.location[0]))
                        
                        tool_node?.eulerAngles.x = tool.rotation[1].to_rad
                        tool_node?.eulerAngles.y = tool.rotation[2].to_rad
                        tool_node?.eulerAngles.z = tool.rotation[0].to_rad
                        #endif
                    }
                    else
                    {
                        tool_node?.constraints = [SCNConstraint]()
                        //clear_constranints(node: tool_node ?? SCNNode())
                        tool_node?.constraints?.append(SCNReplicatorConstraint(target: robot_by_name(tool.attached_to ?? "").tool_node))
                        //tool_node?.position.x += 1
                        //tool_node?.position.x -= 1
                    }
                }
            }
        }
        
        //Place details
        if self.avaliable_details_names.count < self.details.count //If there are placed details in workspace
        {
            for detail in details
            {
                if detail.is_placed
                {
                    detail_node = detail.node
                    detail.enable_physics = true
                    apply_bit_mask(node: detail_node ?? SCNNode(), Workspace.detail_bit_mask)
                    detail_node?.name = detail.name
                    details_node?.addChildNode(detail_node ?? SCNNode())
                    
                    //Set detail node position
                    #if os(macOS)
                    detail_node?.position = SCNVector3(x: CGFloat(detail.location[1]), y: CGFloat(detail.location[2]), z: CGFloat(detail.location[0]))
                    
                    detail_node?.eulerAngles.x = CGFloat(detail.rotation[1].to_rad)
                    detail_node?.eulerAngles.y = CGFloat(detail.rotation[2].to_rad)
                    detail_node?.eulerAngles.z = CGFloat(detail.rotation[0].to_rad)
                    #else
                    detail_node?.position = SCNVector3(x: Float(detail.location[1]), y: Float(detail.location[2]), z: Float(detail.location[0]))
                    
                    detail_node?.eulerAngles.x = detail.rotation[1].to_rad
                    detail_node?.eulerAngles.y = detail.rotation[2].to_rad
                    detail_node?.eulerAngles.z = detail.rotation[0].to_rad
                    #endif
                }
            }
        }
    }
}

enum WorkspaceObjectType: String, Equatable, CaseIterable
{
    case robot = "Robot"
    case detail = "Detail"
    case tool = "Tool"
}

enum PositionComponents: String, Equatable, CaseIterable
{
    case location = "Location"
    case rotation = "Rotation"
}

enum LocationComponents: Equatable, CaseIterable
{
    case x
    case y
    case z
    
    var info: (text: String, index: Int)
    {
        switch self
        {
        case .x:
            return("X: ", 0)
        case .y:
            return("Y: ", 1)
        case .z:
            return("Z: ", 2)
        }
    }
}

enum RotationComponents: Equatable, CaseIterable
{
    case r
    case p
    case w
    
    var info: (text: String, index: Int)
    {
        switch self
        {
        case .r:
            return("R: ", 0)
        case .p:
            return("P: ", 1)
        case .w:
            return("W: ", 2)
        }
    }
}

//MARK: - Structure for workspace preset document handling
struct WorkspacePreset: Codable
{
    var robots = [RobotStruct]()
    var elements = [workspace_program_element_struct]()
    var tools = [ToolStruct]()
    var details = [DetailStruct]()
}
