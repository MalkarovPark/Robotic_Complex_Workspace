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
    @Published private var objects = [SCNNode]()
    
    //MARK: - Initialization
    init()
    {
        
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
    
    public func select_robot(name: String)
    {
        select_robot(number: number_by_name(name: name))
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
    
    public var robots_cards_info: [card_data_item]
    {
        var cards = [card_data_item]()
        var index = 0
        for robot in robots
        {
            cards.append(card_data_item(card_color: robot.card_info().color, card_title: robot.card_info().title, card_subtitle: robot.card_info().subtitle, card_number: index))
            index += 1
        }
        return cards
    }
    
    public func get_robot_info(robot_index: Int) -> Robot
    {
        return robots[robot_index]
    }
}
