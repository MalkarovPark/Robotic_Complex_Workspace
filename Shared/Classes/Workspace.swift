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
        test_card_build()
    }
    
    //MARK: - Robot manage functions
    private var selected_robot_index = 0
    
    public func add_robot(robot: Robot)
    {
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
    
    public func robots_count() -> Int
    {
        return robots.count
    }
    
    func update_view()
    {
        //objectWillChange.send()
        self.objectWillChange.send()
    }
    
    //MARK: - Control program functions
    private func test_card_build()
    {
        for i in 1...4
        {
            self.elements.append(WorkspaceProgramElement(name: "\(i)"))
        }
    }
    
    public func delete_element(number: Int)
    {
        if elements.indices.contains(number) == true
        {
            elements.remove(at: number)
        }
    }
    
    //MARK: - Work with file system
    public func file_data() -> (robots: [robot_struct], count: Int)
    {
        var robots_file_info = [robot_struct]()
        for robot in robots
        {
            robots_file_info.append(robot.robot_info)
        }
        
        return(robots_file_info, robots_count())
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

struct WorkspaceProgramElement: Codable, Hashable, Identifiable
{
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    var id = UUID()
    var name = String()
    
    var type: ProgramElementType = .perofrmer
    {
        didSet
        {
            type_data[0] = type.rawValue
            //print("🚪 \(type_data[0])")
        }
    }
    var type_info: String
    {
        var info = "\(self.type.rawValue) – "
        
        switch type
        {
        case .perofrmer:
            info += "\(self.performer_type.rawValue)"
        case .modificator:
            info += "\(self.modificator_type.rawValue)"
        case .logic:
            info += "\(self.logic_type.rawValue)"
        }
        
        return info
    }
    var type_data = ["Perforemer", "Robot"]
    
    //For Performer
    var performer_type: PerformerType = .robot
    {
        didSet
        {
            type_data[1] = performer_type.rawValue
        }
    }
    
    var robot_name = String()
    var tool_name = String()
    
    var program_index = Int()
    
    //For Modififcator
    var modificator_type: ModificatorType = .observer
    {
        didSet
        {
            type_data[1] = modificator_type.rawValue
        }
    }

    //For logic
    var logic_type: LogicType = .jump
    {
        didSet
        {
            type_data[1] = logic_type.rawValue
        }
    }
}

enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modificator = "Modificator"
    case logic = "Logic"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum ModificatorType: String, Codable, Equatable, CaseIterable
{
    case observer = "Observer"
    case changer = "Changer"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case equal = "Equal"
    case unequal = "Unequal"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
