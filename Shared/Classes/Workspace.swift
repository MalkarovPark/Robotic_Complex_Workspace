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
    private var selected_robot_index = 0
    
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
            return robots[selected_robot_index]
        }
        set
        {
            robots[selected_robot_index] = newValue
        }
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
    public func elements_check() //Selec check by element type
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
        if self.number_by_name(name: element.element_data.robot_name) == -1
        {
            if self.robots.count > 0
            {
                element.element_data.robot_name = self.robots_names[0]
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
    func update_view() //Force update SwiftUI view
    {
        self.objectWillChange.send()
    }
    
    //MARK: - Visual functions
    public var camera_node: SCNNode?
    public var workcells_node: SCNNode?
    public var unit_node: SCNNode?
    //public var unit_origin_node: SCNNode?
    
    public func place_robots(scene: SCNScene)
    {
        if self.avaliable_robots_names.count != self.robots.count
        {
            for robot in robots
            {
                if robot.is_placed == true
                {
                    workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!)
                    unit_node = workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
                    
                    unit_node?.name = robot.name
                    robot.robot_workcell_connect(scene: scene, name: robot.name!)
                    robot.update_robot()
                    
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
