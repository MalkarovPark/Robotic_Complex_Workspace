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
    @Published public var elements = [WorkspaceProgramElement]() //var program = WorkspaceProgram()
    @Published private var objects = [SCNNode]()
    
    //MARK: - Initialization
    init()
    {
        //test_card_build()
    }
    
    //MARK: - Robot manage functions
    private var selected_robot_index = 0
    
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
    
    private func number_by_name(name: String) -> Int
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
    
    public var selected_robot: Robot
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
    
    func update_view()
    {
        //objectWillChange.send()
        self.objectWillChange.send()
    }
    
    //MARK: - Control program functions
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
    
    public func delete_element(number: Int)
    {
        if elements.indices.contains(number) == true
        {
            elements.remove(at: number)
        }
    }
    
    public func elements_check()
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
    
    private func element_robot_check(element: WorkspaceProgramElement)
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
    
    private func element_jump_check(element: WorkspaceProgramElement)
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
            
            if mark_founded == false || element.element_data.mark_name == ""
            {
                element.element_data.target_mark_name = marks_names[0]
            }
        }
        else
        {
            element.element_data.target_mark_name = ""
        }
    }
    
    var marks_names: [String]
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
    
    //MARK: - Work with file system
    public func file_data() -> (robots: [robot_struct], count: Int)
    {
        var robots_file_info = [robot_struct]()
        for robot in robots
        {
            robots_file_info.append(robot.robot_info)
        }
        
        return(robots_file_info, self.robots.count)
    }
    
    public func file_view(preset: WorkspacePreset)
    {
        robots.removeAll()
        for robot_struct in preset.robots
        {
            robots.append(Robot(robot_struct: robot_struct))
        }
    }
    
    //MARK: - UI Functions
    public struct card_data_item: Identifiable, Equatable
    {
        static func == (lhs: Self, rhs: Self) -> Bool
        {
            lhs.id == rhs.id
        }
        
        let id = UUID()
        let card_color: Color
        let card_title: String
        let card_subtitle: String
        let card_number: Int
    }
    
    //MARK: - Visual functions
    public var camera_node: SCNNode?
}

struct WorkspacePreset: Codable
{
    var robots = [robot_struct]()
    var robots_count = Int()
}
