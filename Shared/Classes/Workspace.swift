//
//  Workspace.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

class Workspace: ObservableObject
{
    //MARK: - Workspace objects data
    @Published public var robots = [Robot]()
    @Published public var elements = [WorkspaceProgramElement]()
    @Published public var tools = [Tool]()
    @Published public var details = [Detail]()
    
    //MARK: - Workspace visual handling functions
    public var scene = SCNScene() //Link to viewed workspace scene
    
    public var selected_object_type: WorkspaceObjectType? //Return selected object type
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
    
    public func update_pointer() //Set new pointer position by selected workspace object
    {
        switch selected_object_type
        {
        case .robot:
            update_object_pointer_position(location: selected_robot.location, rotation: selected_robot.rotation)
        case .tool:
            update_object_pointer_position(location: selected_tool.location, rotation: selected_tool.rotation)
            break
        case .detail:
            update_object_pointer_position(location: selected_detail.location, rotation: selected_detail.rotation)
        default:
            break
        }
    }
    
    private func update_object_pointer_position(location: [Float], rotation: [Float])
    {
        object_pointer_node?.isHidden = false
        #if os(macOS)
        object_pointer_node?.position = SCNVector3(x: CGFloat(location[1]), y: CGFloat(location[2]), z: CGFloat(location[0]))
        
        object_pointer_node?.eulerAngles.x = CGFloat(rotation[1].to_rad)
        object_pointer_node?.eulerAngles.y = CGFloat(rotation[2].to_rad)
        object_pointer_node?.eulerAngles.z = CGFloat(rotation[0].to_rad)
        #else
        object_pointer_node?.position = SCNVector3(x: location[1], y: location[2], z: location[0])
        
        object_pointer_node?.eulerAngles.x = rotation[1].to_rad
        object_pointer_node?.eulerAngles.y = rotation[2].to_rad
        object_pointer_node?.eulerAngles.z = rotation[0].to_rad
        #endif
    }
    
    public var edited_object_node: SCNNode?
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
        
        //Unhide pointer and move to object position
        object_pointer_node?.isHidden = false
        update_pointer()
        
        //Create editable node with name
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
    }
    
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
            break
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
        
        update_pointer()
    }
    
    public func place_viewed_object()
    {
        switch selected_object_type
        {
        case .robot:
            selected_robot.is_placed = true
            edited_object_node?.categoryBitMask = Workspace.robot_bit_mask //Apply categury bit mask
            
            deselect_robot()
        case .tool:
            selected_tool.is_placed = true
            edited_object_node?.categoryBitMask = Workspace.tool_bit_mask //Apply categury bit mask
            
            deselect_tool()
        case.detail:
            selected_detail.is_placed = true
            
            edited_object_node?.categoryBitMask = Workspace.detail_bit_mask //Apply category bit mask
            edited_object_node?.physicsBody = selected_detail.physics //Apply physics
            
            deselect_detail()
        default:
            break
        }
        
        //Disconnect from edited node
        edited_object_node = SCNNode() //Remove old reference
        edited_object_node?.removeFromParentNode() //Remove old node
        
        is_editing = false
    }
    
    public func dismiss_object()
    {
        object_pointer_node?.isHidden = true
        
        switch selected_object_type
        {
        case .robot:
            if !selected_robot.is_placed
            {
                edited_object_node?.removeFromParentNode()
                edited_object_node = SCNNode()
            }
        case .tool:
            if !selected_robot.is_placed
            {
                edited_object_node?.removeFromParentNode()
                edited_object_node = SCNNode()
            }
        case.detail:
            if !selected_detail.is_placed
            {
                edited_object_node?.removeFromParentNode()
                edited_object_node = SCNNode()
            }
        default:
            break
        }
        
        is_editing = false
        deselect_object()
        //update_view()
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
    
    public func select_object_in_scene(result: SCNHitTestResult) //Process robot node selection
    {
        print(result.localCoordinates)
        print("🍮 tapped – \(result.node.name!), category \(result.node.categoryBitMask)")
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
        
        func main_object_node(result_node: SCNNode, object_bit_mask: Int) -> SCNNode
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
            //If any object did selected
            switch type
            {
            case .robot:
                if node.name! != selected_robot.name //If not selected robot tapped
                {
                    //Change selected to new robot
                    deselect_robot()
                    deselect_tool()
                    deselect_detail()
                    
                    select_robot(name: node.name!)
                    update_pointer()
                }
                else
                {
                    //Deselect already selected robot
                    deselect_robot()
                    object_pointer_node?.isHidden = true
                }
            case .tool:
                if node.name! != selected_tool.name //If not selected robot tapped
                {
                    //Change selected to new robot
                    deselect_robot()
                    deselect_tool()
                    deselect_detail()
                    
                    select_tool(name: node.name!)
                    update_pointer()
                }
                else
                {
                    //Deselect already selected robot
                    deselect_tool()
                    object_pointer_node?.isHidden = true
                }
            case .detail:
                if node.name! != selected_detail.name //If not selected detail tapped
                {
                    old_detail_node.physicsBody = selected_detail.physics //Enable physics for deselctable node
                    
                    //Change selected to new detail
                    deselect_detail()
                    deselect_robot()
                    deselect_tool()
                    
                    select_detail(name: node.name!)
                    update_pointer()
                    
                    edited_object_node?.physicsBody = .none //Disable physics physics for selected node
                }
                else
                {
                    //Deselect already selected detail
                    edited_object_node?.physicsBody = selected_detail.physics
                    deselect_detail()
                    object_pointer_node?.isHidden = true
                }
            }
        }
        else
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
    }
    
    public func deselect_object_for_edit()
    {
        //Deselect selected object by type
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
                    //workspace.detail_node = nil
                }
                deselect_detail()
                //workspace.detail_node = nil
            default:
                break
            }
            
            //Disconnect from edited node
            edited_object_node = SCNNode() //Remove old reference
            edited_object_node?.removeFromParentNode() //Remove old node
        }
    }
    
    public func remove_selected_object()
    {
        if is_selected
        {
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
    public func add_robot(_ robot: Robot)
    {
        robot.name = mismatched_name(name: robot.name!, names: robots_names)
        robots.append(robot)
    }
    
    public func delete_robot(index: Int)
    {
        if robots.indices.contains(index)
        {
            robots.remove(at: index)
        }
    }
    
    public func delete_robot(index: String)
    {
        delete_robot(index: robot_index_by_name(index))
    }
    
    //MARK: Robot selection functions
    private var selected_robot_index = -1
    
    private func robot_index_by_name(_ name: String) -> Int //Get index number of robot by name
    {
        return robots.firstIndex(of: Robot(name: name)) ?? -1
    }
    
    public func select_robot(index: Int) //Select robot by number
    {
        selected_robot_index = index
    }
    
    public func select_robot(name: String) //Select robot by name
    {
        select_robot(index: robot_index_by_name(name))
    }
    
    public func deselect_robot()
    {
        selected_robot_index = -1
        //object_pointer_node?.isHidden = true
    }
    
    public var selected_robot: Robot //Return robot by selected index
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
    public func robot_by_name(_ name: String) -> Robot //Get index number of robot by name
    {
        return self.robots[robot_index_by_name(name)]
    }
    
    public var robots_names: [String] //Get names of all robots in workspace
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
    
    public var avaliable_robots_names: [String] //Array of robots names not added to workspace
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
    public func add_tool(_ tool: Tool)
    {
        tool.name = mismatched_name(name: tool.name!, names: tools_names)
        tools.append(tool)
    }

    public func delete_tool(index: Int)
    {
        if tools.indices.contains(index)
        {
            tools.remove(at: index)
        }
    }

    /*public func delete_tool(name: String)
    {
        delete_tool(number: number_by_name(name: name))
    }*/

    //MARK: Tools selection functions
    private var selected_tool_index = -1

    public var selected_tool: Tool //Return tool by selected index
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

    private func tool_index_by_name(_ name: String) -> Int //Get index number of robot by name
    {
        return tools.firstIndex(of: Tool(name: name)) ?? -1
    }

    public func select_tool(index: Int) //Select tool by number
    {
        selected_tool_index = index
    }

    public func select_tool(name: String) //Select tool by name
    {
        select_tool(index: tool_index_by_name(name))
    }

    public func deselect_tool()
    {
        selected_tool_index = -1
        //object_pointer_node?.isHidden = true
    }

    //MARK: Tools naming
    public var tools_names: [String] //Get names of all tools in workspace
    {
        var tools_names = [String]()
        if tools.count > 0
        {
            for tool in tools
            {
                tools_names.append(tool.name ?? "None")
            }
        }
        return tools_names
    }

    public var avaliable_tools_names: [String] //Array of tools names not added to workspace
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
    
    public func attach_tool_to(robot_name: String)
    {
        object_pointer_node?.isHidden = true
        edited_object_node?.constraints = [SCNConstraint]()
        edited_object_node?.constraints?.append(SCNReplicatorConstraint(target: robot_by_name(robot_name).tool_node))
    }
    
    public func remove_attachment()
    {
        edited_object_node?.constraints?.removeAll() //Remove constraint
        
        //Reset position
        edited_object_node?.position.x += 10
        edited_object_node?.position.x -= 10
        edited_object_node?.eulerAngles.x += 10
        edited_object_node?.eulerAngles.x -= 10
        
        //object_pointer_node?.isHidden = false
    }
    
    //MARK: - Details handling functions
    //MARK: Details manage funcions
    public func add_detail(_ detail: Detail)
    {
        detail.name = mismatched_name(name: detail.name!, names: details_names)
        details.append(detail)
    }
    
    public func delete_detail(index: Int)
    {
        if details.indices.contains(index)
        {
            details.remove(at: index)
        }
    }
    
    /*public func delete_detail(name: String)
    {
        delete_detail(number: number_by_name(name: name))
    }*/
    
    //MARK: Details selection functions
    private var selected_detail_index = -1
    
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
    
    private func detail_index_by_name(_ name: String) -> Int //Get index number of robot by name
    {
        return details.firstIndex(of: Detail(name: name)) ?? -1
    }
    
    public func select_detail(index: Int) //Select detail by number
    {
        selected_detail_index = index
    }
    
    public func select_detail(name: String) //Select detail by name
    {
        select_detail(index: detail_index_by_name(name))
    }
    
    public func deselect_detail()
    {
        selected_detail_index = -1
        //object_pointer_node?.isHidden = true
    }
    
    //MARK: Details naming
    public var details_names: [String] //Get names of all details in workspace
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
    
    public var avaliable_details_names: [String] //Array of details names not added to workspace
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
    var marks_names: [String] //Get names of all marks in workspace program
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
                    element_robot_check(element: element)
                case .tool:
                    break
                }
            case .modificator:
                break
            case .logic:
                switch element.element_data.logic_type
                {
                case .jump:
                    element_jump_check(element: element)
                default:
                    break
                }
            }
        }
        
        func element_robot_check(element: WorkspaceProgramElement) //Check element by selected robot exists
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
                            element.element_data.robot_program_name = robot_by_name(element.element_data.robot_name).programs_names.first!
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
                        element.element_data.robot_program_name = robot_by_name(element.element_data.robot_name).programs_names.first!
                    }
                }
                else
                {
                    element.element_data.robot_name = ""
                }
            }
        }
        
        func element_jump_check(element: WorkspaceProgramElement) //Check element by selected mark exists
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
    
    @Published var cycled = false //Cyclic program performance flag
    
    public var performed = false
    
    private var selected_element_index = 0
    
    public func start_pause_performing()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) //Delayed update view
        {
            self.update_view()
        }
        
        if performed == false
        {
            //Move to next point if moving was stop
            performed = true
            //object_pointer_node?.isHidden = true
            selected_robot_index = -1
            
            defining_elements_indexes()
            
            let queue = DispatchQueue.global(qos: .utility)
            queue.async
            {
                self.perfom_next_element()
            }
        }
        else
        {
            //Remove all action if moving was perform
            performed = false
            selected_robot.start_pause_moving()
            selected_robot_index = -1
        }
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
    
    public func perfom_next_element()
    {
        if selected_element_index < elements.count
        {
            update_view()
            
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
                    if selected_robot.programs_names.count > 0 && element.element_data.robot_program_name != ""
                    {
                        selected_robot.workcell_connect(scene: scene, name: selected_robot.name!, connect_camera: false)
                        selected_robot.select_program(name: element.element_data.robot_program_name)
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
                
                perfom_next_element()
            }
        }
        else
        {
            selected_element_index = 0
            selected_robot_index = -1
            
            if cycled == true
            {
                perfom_next_element()
            }
            else
            {
                performed = false
                update_view()
            }
        }
    }
    
    public func reset_performing()
    {
        elements[selected_element_index].is_selected = false //Deselect performed program element
        selected_robot.reset_moving()
        selected_element_index = 0 //Select firs program element
        deselect_robot()
        performed = false //Enable workspace program edit
    }
    
    //MARK: - Work with file system
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
    
    public var robots_bookmark: Data?
    public var details_bookmark: Data?
    public var tools_bookmark: Data?
    
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
    public var is_editing = false //Determines whether the robot can be selected if it is open for editing
    
    func update_view() //Force update SwiftUI view
    {
        self.objectWillChange.send()
    }
    
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
    
    public var reset_view_action: SCNAction //Reset camera position SCNAction
    {
        return SCNAction.group([SCNAction.move(to: camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: camera_node!.rotation, duration: 0.5)])
    }
    
    public var add_in_view_dismissed = true //If add in view presented or not dismissed state
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
    
    //MARK: - Visual functions
    public var camera_node: SCNNode? //Camera
    public var workcells_node: SCNNode? //Workcells
    public var tools_node: SCNNode? //Tools
    public var details_node: SCNNode? //Details
    public var unit_node: SCNNode? //Selected robot cell node
    public var object_pointer_node: SCNNode?
    
    static var robot_bit_mask = 2
    static var tool_bit_mask = 4
    static var detail_bit_mask = 6
    
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
        
        place_objects(scene: scene)
    }
    
    private func place_objects(scene: SCNScene)
    {
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
                    let tool_node = tool.node
                    apply_bit_mask(node: tool_node ?? SCNNode(), Workspace.tool_bit_mask)
                    tool_node?.name = tool.name
                    tools_node?.addChildNode(tool_node ?? SCNNode())
                    
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
            }
        }
        
        //Place details
        if self.avaliable_details_names.count < self.details.count //If there are placed details in workspace
        {
            for detail in details
            {
                if detail.is_placed
                {
                    let detail_node = detail.node
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
        
        func apply_bit_mask(node: SCNNode, _ code: Int)
        {
            node.categoryBitMask = code
            
            node.enumerateChildNodes
            { (_node, stop) in
                _node.categoryBitMask = code
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

//MARK: Functions
func mismatched_name(name: String, names: [String]) -> String
{
    var name_count = 1
    var name_postfix: String
    {
        return name_count > 1 ? " \(name_count)" : ""
    }
    
    if names.count > 0
    {
        for _ in 0..<names.count
        {
            for viewed_name in names
            {
                if viewed_name == name + name_postfix
                {
                    name_count += 1
                }
            }
        }
    }
    
    return name + name_postfix
}

//MARK: - Angles convertion extension
extension Float
{
    var to_deg: Float
    {
        return self * 180 / .pi
    }
    
    var to_rad: Float
    {
        return self * .pi / 180
    }
}
