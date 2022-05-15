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
    @Published public var robots = [Robot]()
    @Published public var elements = [WorkspaceProgramElement]()
    @Published private var objects = [SCNNode]()
    
    //MARK: - Initialization
    init()
    {
        
    }
    
    //MARK: - Robot manage functions
    public func add_robot(robot: Robot)
    {
        var name_count = 1
        for viewed_robot in robots
        {
            if viewed_robot.robot_info.name == robot.robot_info.name
            {
                name_count += 1
            }
        }
        
        if name_count > 1
        {
            robot.name! += " \(name_count)"
        }
        robots.append(robot)
    }
    
    public func delete_robot(number: Int)
    {
        if robots.indices.contains(number) == true
        {
            robots.remove(at: number)
        }
    }
    
    public func delete_robot(name: String)
    {
        delete_robot(number: number_by_name(name: name))
    }
    
    //MARK: Robot selection functions
    public var selected_robot_index = -1
    
    private func number_by_name(name: String) -> Int //Get index number of robot by name
    {
        let comparison_robot = Robot(name: name)
        let robot_number = robots.firstIndex(of: comparison_robot)
        
        return robot_number ?? -1
    }
    
    public func select_robot(number: Int)
    {
        selected_robot_index = number
    }
    
    public func select_robot(name: String)
    {
        selected_robot_index = number_by_name(name: name)
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
    
    public func robot_by_name(name: String) -> Robot
    {
        return self.robots[number_by_name(name: name)]
    }
    
    public var avaliable_robots_names: [String]
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && robot.is_placed == false
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    public var placed_robots_names: [String]
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && robot.is_placed == true
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    //MARK: - Control program functions
    public var robots_names: [String] //Get names of robots in workspace
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
    
    var marks_names: [String] //Get names of marks in workspace program
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
    
    public func delete_element(number: Int)
    {
        if elements.indices.contains(number) == true
        {
            elements.remove(at: number)
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
    }
    
    private func element_robot_check(element: WorkspaceProgramElement) //Check element by selected robot exists
    {
        if self.robot_by_name(name: element.element_data.robot_name).is_placed == false
        {
            if self.placed_robots_names.count > 0
            {
                element.element_data.robot_name = self.placed_robots_names.first!
                
                if robot_by_name(name: element.element_data.robot_name).programs_count > 0
                {
                    element.element_data.robot_program_name = robot_by_name(name: element.element_data.robot_name).programs_names.first!
                }
            }
            else
            {
                element.element_data.robot_name = ""
            }
        }
    }
    
    private func element_jump_check(element: WorkspaceProgramElement) //Check element by selected mark exists
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
    
    @Published var cycled = false
    
    public var is_performing = false
    public var selected_element_index = 0
    public var workspace_scene = SCNScene()
    
    public func start_pause_perform()
    {
        if is_performing == false
        {
            //Move to next point if moving was stop
            is_performing = true
            selected_robot.unit_origin_node?.isHidden = true
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
            is_performing = false
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
        print(marks_associations)
        
        //Set target element indexes of marks to jump elements.
        var target_mark_name: String
        for element in elements
        {
            if element.element_data.element_type == .logic && element.element_data.logic_type == .jump
            {
                target_mark_name = element.element_data.target_mark_name
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
                        selected_robot.robot_workcell_connect(scene: workspace_scene, name: selected_robot.name!, connect_camera: false)
                        selected_robot.select_program(name: element.element_data.robot_program_name)
                        selected_robot.start_pause_moving()
                        while selected_robot.moving_completed == false && self.is_performing == true
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
                    jumped = true
                default:
                    break
                }
            }
            
            if is_performing == true
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
                is_performing = false
            }
            print("Finished")
        }
    }
    
    public func reset_perform()
    {
        elements[selected_element_index].is_selected = false
        selected_robot.reset_moving()
        selected_element_index = 0
        selected_robot_index = -1
        
        is_performing = false
        print("Finished")
    }
    
    //MARK: - Work with file system
    public func file_data() -> (robots: [robot_struct], elements: [workspace_program_element_struct])
    {
        //Get robots info for save to file
        var robots_file_info = [robot_struct]()
        for robot in robots
        {
            robots_file_info.append(robot.robot_info)
        }
        
        //Get workspace program elements info for save to file
        var elements_file_info = [workspace_program_element_struct]()
        for element in elements
        {
            elements_file_info.append(element.element_data)
        }
        
        return(robots_file_info, elements_file_info)
    }
    
    public func file_view(preset: WorkspacePreset)
    {
        //Update robots data from file
        robots.removeAll()
        for robot_struct in preset.robots
        {
            robots.append(Robot(robot_struct: robot_struct))
        }
        
        //Update workspace program elements data from file
        elements.removeAll()
        for element_struct in preset.elements
        {
            elements.append(WorkspaceProgramElement(element_struct: element_struct))
        }
    }
    
    //MARK: - UI Functions
    public var is_robot_editing = false
    
    func update_view() //Force update SwiftUI view
    {
        self.objectWillChange.send()
    }
    
    //MARK: - Visual functions
    public var camera_node: SCNNode?
    public var workcells_node: SCNNode?
    public var unit_node: SCNNode?
    
    public func place_robots(scene: SCNScene)
    {
        if self.avaliable_robots_names.count < self.robots.count
        {
        	var connect_camera = true
            for robot in robots
            {
                if robot.is_placed == true
                {
                    workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!)
                    unit_node = workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
                    
                    unit_node?.name = robot.name
                    robot.robot_workcell_connect(scene: scene, name: robot.name!, connect_camera: connect_camera)
                    robot.update_robot()
                    
                    connect_camera = false
                    
                    #if os(macOS)
                    unit_node?.worldPosition = SCNVector3(x: CGFloat(robot.location[0]), y: CGFloat(robot.location[2]), z: CGFloat(robot.location[1]))
                    
                    unit_node?.eulerAngles.x = to_rad(in_angle: CGFloat(robot.rotation[1]))
                    unit_node?.eulerAngles.y = to_rad(in_angle: CGFloat(robot.rotation[2]))
                    unit_node?.eulerAngles.z = to_rad(in_angle: CGFloat(robot.rotation[0]))
                    #else
                    unit_node?.worldPosition = SCNVector3(x: robot.location[0], y: robot.location[2], z: robot.location[1])

                    unit_node?.eulerAngles.x = Float(to_rad(in_angle: CGFloat(robot.rotation[1])))
                    unit_node?.eulerAngles.y = Float(to_rad(in_angle: CGFloat(robot.rotation[2])))
                    unit_node?.eulerAngles.z = Float(to_rad(in_angle: CGFloat(robot.rotation[0])))
                    #endif
                }
            }
        }
    }
}

//MARK: - Structure for workspace preset document handling
struct WorkspacePreset: Codable
{
    var robots = [robot_struct]()
    var elements = [workspace_program_element_struct]()
}
