//
//  Workspace.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit

class Workspace: ObservableObject
{
    private var workspace_name: String?
    private var robots = [Robot]()
    private var objects = [SCNNode]()
    
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
        let comparison_robot = Robot(name: name, ip_address: "127.0.0.1")
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
}