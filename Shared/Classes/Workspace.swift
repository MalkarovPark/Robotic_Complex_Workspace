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
    @Published private var workspace_name: String?
    @Published private var robots = [Robot]()
    @Published private var objects = [SCNNode]()
    
    //MARK: - Initialization
    init()
    {
        self.workspace_name = "None"
    }
    
    init(name: String?)
    {
        self.workspace_name = name ?? "None"
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
    
    public func selected_robot() -> Robot
    {
        return robots[selected_robot_index]
    }
    
    public func robots_count() -> Int
    {
        return robots.count
    }
    
    //MARK: - Work with file
    public func update_file()
    {
        //print(<#T##items: Any...##Any#>)
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
