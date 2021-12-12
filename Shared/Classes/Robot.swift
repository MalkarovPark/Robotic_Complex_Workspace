//
//  Robot.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit

class Robot: Equatable, ObservableObject
{
    static func == (lhs: Robot, rhs: Robot) -> Bool
    {
        return lhs.robot_name == rhs.robot_name
    }
    
    private var robot_name: String?
    private var ip_address: String?
    private var programs = [PositionsProgram]()
    
    //MARK: - Initialization
    init()
    {
        robot_init(name: "None", ip_address: "127.0.0.1")
    }
    
    init(name: String)
    {
        robot_init(name: name, ip_address: "127.0.0.1")
    }
    
    init(name: String, ip_address: String)
    {
        robot_init(name: name, ip_address: ip_address)
    }
    
    func robot_init(name: String, ip_address: String)
    {
        self.robot_name = name
        self.ip_address = ip_address
        
        build_robot()
    }
    
    //MARK: - Program manage functions
    private var selected_program_index = 0
    
    public func add_program(prog: PositionsProgram)
    {
        programs.append(prog)
    }
    
    public func update_program(number: Int, prog: PositionsProgram)
    {
        if programs.indices.contains(number) == true
        {
            programs[number] = prog
        }
    }
    
    public func update_program(name: String, prog: PositionsProgram)
    {
        update_program(number: number_by_name(name: name), prog: prog)
    }
    
    public func delete_program(number: Int)
    {
        if programs.indices.contains(number) == true
        {
            programs.remove(at: number)
        }
    }
    
    public func delete_program(name: String)
    {
        delete_program(number: number_by_name(name: name))
    }
    
    public func select_program(number: Int)
    {
        selected_program_index = number
    }
    
    public func select_program(name: String)
    {
        select_program(number: number_by_name(name: name))
    }
    
    private func number_by_name(name: String) -> Int
    {
        let comparison_program = PositionsProgram(name: name)
        let prog_number = programs.firstIndex(of: comparison_program)
        
        return prog_number ?? -1
    }
    
    //MARK: - Moving functions
    public var move_time: Double?
    
    public var demo_work = true
    {
        didSet
        {
            if demo_work == false
            {
                reset_moving()
            }
        }
    }
    
    public func update_position()
    {
        
    }
    
    public func move_to_point()
    {
        
    }
    
    public func start_moving()
    {
        if demo_work == true
        {
            pointer_node.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)))
        }
        else
        {
            
        }
    }
    
    public func pause_moving()
    {
        
    }
    
    public func reset_moving()
    {
        
    }
    
    //MARK: - Build functions
    private var pointer_node: SCNNode!
    #if os(macOS)
    private let pointer_node_color = NSColor.systemPurple
    #else
    private let pointer_node_color = UIColor.systemCyan
    #endif
    
    public var poiner_visible = true
    {
        didSet
        {
            pointer_node.isHidden = poiner_visible
        }
    }
    
    private func build_robot()
    {
        pointer_node = SCNNode()
        pointer_node.geometry = SCNSphere(radius: 1)
        pointer_node.geometry?.firstMaterial?.diffuse.contents = pointer_node_color
        pointer_node.opacity = 0.5
    }
    
    private func to_rad(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * .pi / 180
    }
    
    private func to_deg(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * 180 / .pi
    }
}