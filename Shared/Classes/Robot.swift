//
//  Robot.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

class Robot: Identifiable, Equatable, Hashable, ObservableObject
{
    static func == (lhs: Robot, rhs: Robot) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(robot_name)
    }
    
    private var robot_name: String?
    private var manufacturer: String?
    private var model: String?
    private var ip_address: String?
    @Published private var programs = [PositionsProgram]()
    
    //MARK: - Initialization
    init()
    {
        robot_init(name: "None", manufacturer: "Fanuc", model: "LR-Mate", ip_address: "127.0.0.1")
    }
    
    init(name: String)
    {
        robot_init(name: name, manufacturer: "Fanuc", model: "LR-Mate", ip_address: "127.0.0.1")
    }
    
    init(name: String, manufacturer: String, model: String, ip_address: String)
    {
        robot_init(name: name, manufacturer: manufacturer, model: model, ip_address: ip_address)
    }
    
    init(robot_struct: robot_struct)
    {
        robot_init(name: robot_struct.name, manufacturer: robot_struct.manufacturer, model: robot_struct.model, ip_address: robot_struct.ip_addrerss)
        read_programs(robot_struct: robot_struct)
    }
    
    func robot_init(name: String, manufacturer: String, model: String, ip_address: String)
    {
        self.robot_name = name
        self.manufacturer = manufacturer
        self.model = model
        self.ip_address = ip_address
    }
    
    //MARK: - Program manage functions
    public var selected_program_index = 0
    {
        willSet
        {
            selected_program.visual_clear()
            moving_started = false
            moving_completed = true
            target_point_index = 0
        }
        didSet
        {
            selected_program.visual_build()
        }
    }
    
    public func add_program(prog: PositionsProgram)
    {
        programs.append(prog)
        selected_program.visual_clear()
    }
    
    public func update_program(number: Int, prog: PositionsProgram)
    {
        if programs.indices.contains(number) == true
        {
            programs[number] = prog
            selected_program.visual_clear()
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
            selected_program.visual_clear()
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
        //selected_program.visual_clear()
    }
    
    public func select_program(name: String)
    {
        select_program(number: number_by_name(name: name))
    }
    
    public var selected_program: PositionsProgram
    {
        var sprogram: PositionsProgram?
        if programs.indices.contains(selected_program_index) == true
        {
            sprogram = programs[selected_program_index]
        }
        
        return sprogram ?? PositionsProgram()
    }
    
    private func number_by_name(name: String) -> Int
    {
        let comparison_program = PositionsProgram(name: name)
        let prog_number = programs.firstIndex(of: comparison_program)
        
        return prog_number ?? -1
    }
    
    public var programs_names: [String]
    {
        var prog_names = [String]() //: [String]?
        if programs.count > 0
        {
            for program in programs
            {
                prog_names.append(program.program_name ?? "None")
            }
        }
        return prog_names
    }
    
    public var programs_count: Int
    {
        return programs.count
    }
    
    //MARK: - Moving functions
    public var move_time: Double?
    public var trail_draw = false
    public var moving_started = false
    public var moving_completed = true
    public var target_point_index = 0
    
    public var pointer_location = [0.0, 0.0, 0.0] //x, y, z
    {
        didSet
        {
            update_location()
        }
    }
    
    public var pointer_rotation = [0.0, 0.0, 0.0] //r, p, w
    {
        didSet
        {
            update_rotation()
        }
    }
    
    private var demo_work = true
    {
        didSet
        {
            if demo_work == false
            {
                reset_moving()
            }
        }
    }
    
    #if os(macOS)
    public func get_pointer_position() -> (location: SCNVector3, rot_x: Double, rot_y: Double, rot_z: Double)
    {
        return(SCNVector3(pointer_location[1] / 10, pointer_location[2] / 10, pointer_location[0] / 10), to_rad(in_angle: pointer_rotation[0]), to_rad(in_angle: pointer_rotation[1]), to_rad(in_angle: pointer_rotation[2]))
    }
    #else
    public func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1] / 10, pointer_location[2] / 10, pointer_location[0] / 10), Float(to_rad(in_angle: pointer_rotation[0])), Float(to_rad(in_angle: pointer_rotation[1])), Float(to_rad(in_angle: pointer_rotation[2])))
    }
    #endif
    
    private func current_pointer_position_select()
    {
        pointer_location = [Double(((pointer_node?.position.z ?? 0)) * 10), Double(((pointer_node?.position.x ?? 0)) * 10), Double(((pointer_node?.position.y ?? 0)) * 10)]
        pointer_rotation = [to_deg(in_angle: Double(tool_node?.eulerAngles.z ?? 0)), to_deg(in_angle: Double(pointer_node?.eulerAngles.x ?? 0)), to_deg(in_angle: Double(pointer_node?.eulerAngles.y ?? 0))]
    }
    
    public func move_to_next_point()
    {
        if demo_work == true
        {
            pointer_node?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).moving[target_point_index], completionHandler: {
                self.moving_finished = true
                self.select_new_point()
            })
            tool_node?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).rotation[target_point_index], completionHandler: {
                self.rotation_finished = true
                self.select_new_point()
            })
            //print("\(target_point_index) ☕️")
        }
        else
        {
            //Move to point for real robot.
        }
    }
    
    private var moving_finished = false
    private var rotation_finished = false
    
    private func select_new_point()
    {
        if moving_finished == true && rotation_finished == true
        {
            moving_finished = false
            rotation_finished = false
            
            if target_point_index < selected_program.points_count - 1
            {
                target_point_index += 1
                move_to_next_point()
            }
            else
            {
                target_point_index = 0
                moving_started = false
                moving_completed = true
                current_pointer_position_select()
            }
        }
    }
    
    public func start_pause_moving()
    {
        if moving_started == false
        {
            moving_started = true
            
            move_to_next_point()
        }
        else
        {
            moving_started = false
            pointer_node?.removeAllActions()
            tool_node?.removeAllActions()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
            {
                self.current_pointer_position_select()
            }
        }
    }
    
    public func reset_moving()
    {
        pointer_node?.removeAllActions()
        tool_node?.removeAllActions()
        current_pointer_position_select()
        moving_started = false
        target_point_index = 0
    }
    
    //MARK: - Build functions
    private let pointer_node_color = Color.cyan
    
    public var box_node: SCNNode?
    public var camera_node: SCNNode?
    public var pointer_node: SCNNode?
    public var tool_node: SCNNode?
    public var points_node: SCNNode?
    public var robot_node: SCNNode?
    
    public var poiner_visible = true
    {
        didSet
        {
            pointer_node?.isHidden = poiner_visible
        }
    }
    
    public func update_position()
    {
        update_location()
        update_rotation()
    }
    
    private func update_location()
    {
        pointer_node?.position = get_pointer_position().location
    }
    
    private func update_rotation()
    {
        pointer_node?.eulerAngles.x = get_pointer_position().rot_y
        pointer_node?.eulerAngles.y = get_pointer_position().rot_z
        tool_node?.eulerAngles.z = get_pointer_position().rot_x
    }
    
    private func to_rad(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * .pi / 180
    }
    
    private func to_deg(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * 180 / .pi
    }
    
    var robot_details = [SCNNode]()

    var theta = [Double](repeating: 0.0, count: 6)
    var lenghts = [Float](repeating: 0, count: 6)
    var origin_location: [Float] = [32, 0, 0] //x, y, z 32 0 0
    
    public func robot_details_connect()
    {
        robot_details.removeAll()
        for i in 0...6
        {
            robot_details.append(robot_node!.childNode(withName: "d\(i)", recursively: true)!)
            
            if i > 0
            {
                lenghts[i - 1] = Float(robot_details[i].position.y)
                //print(robot_details[i].position.y)
            }
        }
    }
    
    public func robot_location_place()
    {
        box_node?.position.y += robot_details[0].position.y
        
        #if os(macOS)
        box_node?.position.x += CGFloat(origin_location[1])
        box_node?.position.y += CGFloat(origin_location[2])
        box_node?.position.z += CGFloat(origin_location[0])
        #else
        box_node?.position.x += Float(origin_location[1])
        box_node?.position.y += Float(origin_location[2])
        box_node?.position.z += Float(origin_location[0])
        #endif
    }
    
    public var ik_angles: [Double]
    {
        var angles = [Double]()
        var C3 = Float()
        do
        {
            var px, py, pz: Float
            var rx, ry, rz: Float
            var ax, ay, az, bx, by, bz: Float
            var asx, asy, asz, bsx, bsy, bsz: Float
            var p5x, p5y, p5z: Float
            var C1, C23, S1, S23: Float
            
            var M, N, A, B: Float
            
            px = -(Float(pointer_node?.position.z ?? 0) + origin_location[0]) // - 32
            py = Float(pointer_node?.position.x ?? 0) + origin_location[1]
            pz = Float(pointer_node?.position.y ?? 0) + origin_location[2]
            
            //print(pointer_node?.position)
            //print(robot_details[6].worldPosition)
            
            rx = -Float(tool_node?.eulerAngles.z ?? 0)
            ry = -Float(pointer_node?.eulerAngles.x ?? 0) + (.pi)
            rz = -Float(pointer_node?.eulerAngles.y ?? 0)
            
            //print(pointer_node.eulerAngles)
            //print(tool_node.eulerAngles)
            
            bx = cos(rx) * sin(ry) * cos(rz) - sin(rx) * sin(rz)
            by = cos(rx) * sin(ry) * sin(rz) - sin(rx) * cos(rz)
            bz = cos(rx) * cos(ry)
            
            ax = cos(rz) * cos(ry)
            ay = sin(rz) * cos(ry)
            az = -sin(ry)
            
            p5x = px - (lenghts[4] + lenghts[5]) * ax
            p5y = py - (lenghts[4] + lenghts[5]) * ay
            p5z = pz - (lenghts[4] + lenghts[5]) * az
            
            C3 = (pow(p5x, 2) + pow(p5y, 2) + pow(p5z - lenghts[0], 2) - pow(lenghts[1], 2) - pow(lenghts[2] + lenghts[3], 2)) / (2 * lenghts[1] * (lenghts[2] + lenghts[3]))
            
            //Joint 1
            theta[0] = Double(atan2(p5y, p5x))
            
            //Joints 3, 2
            theta[2] = Double(atan2(pow(abs(1 - pow(C3, 2)), 0.5), C3))
            
            M = lenghts[1] + (lenghts[2] + lenghts[3]) * C3
            N = (lenghts[2] + lenghts[3]) * sin(Float(theta[2]))
            A = pow(p5x * p5x + p5y * p5y, 0.5)
            B = p5z - lenghts[0]
            theta[1] = Double(atan2(M * A - N * B, N * A + M * B))
            
            //Jionts 4, 5, 6
            C1 = cos(Float(theta[0]))
            C23 = cos(Float(theta[1]) + Float(theta[2]))
            S1 = sin(Float(theta[0]))
            S23 = sin(Float(theta[1]) + Float(theta[2]))
            
            asx = C23 * (C1 * ax + S1 * ay) - S23 * az
            asy = -S1 * ax + C1 * ay
            asz = S23 * (C1 * ax + S1 * ay) + C23 * az
            bsx = C23 * (C1 * bx + S1 * by) - S23 * bz
            bsy = -S1 * bx + C1 * by
            bsz = S23 * (C1 * bx + S1 * by) + C23 * bz
            
            theta[3] = Double(atan2(asy, asx))
            theta[4] = Double(atan2(cos(Float(theta[3])) * asx + sin(Float(theta[3])) * asy, asz))
            theta[5] = Double(atan2(cos(Float(theta[3])) * bsy - sin(Float(theta[3])) * bsx, -bsz / sin(Float(theta[4]))))
            
            angles.append(-(theta[0] + .pi))
            angles.append(-theta[1])
            angles.append(-theta[2])
            angles.append(-(theta[3] + .pi))
            angles.append(theta[4])
            angles.append(-theta[5])
        }
        return angles
    }
    
    public func update_robot()
    {
        #if os(macOS)
        robot_details[0].eulerAngles.y = CGFloat(ik_angles[0])
        robot_details[1].eulerAngles.z = CGFloat(ik_angles[1])
        robot_details[2].eulerAngles.z = CGFloat(ik_angles[2])
        robot_details[3].eulerAngles.y = CGFloat(ik_angles[3])
        robot_details[4].eulerAngles.z = CGFloat(ik_angles[4])
        robot_details[5].eulerAngles.y = CGFloat(ik_angles[5])
        #else
        robot_details[0].eulerAngles.y = Float(ik_angles[0])
        robot_details[1].eulerAngles.z = Float(ik_angles[1])
        robot_details[2].eulerAngles.z = Float(ik_angles[2])
        robot_details[3].eulerAngles.y = Float(ik_angles[3])
        robot_details[4].eulerAngles.z = Float(ik_angles[4])
        robot_details[5].eulerAngles.y = Float(ik_angles[5])
        #endif
    }
    
    //MARK: - UI functions
    public func card_info() -> (title: String, subtitle: String, color: Color)
    {
        let color: Color
        switch self.manufacturer
        {
        case "ABB":
            color = Color.red
        case "FANUC":
            color = Color.yellow
        case "KUKA":
            color = Color.orange
        default:
            color = Color.clear
        }
        
        return("\(self.robot_name ?? "Robot Name")", "\(self.manufacturer ?? "Manufacturer") – \(self.model ?? "Model")", color)
    }
    
    //MARK: - Work with file system
    public var robot_info: robot_struct
    {
        var programs_array = [program_struct]()
        for program in programs
        {
            programs_array.append(program.program_info)
        }
        
        return robot_struct(name: robot_name ?? "Robot Name", manufacturer: manufacturer ?? "Manufacturer", model: model ?? "Model", ip_addrerss: ip_address ?? "127.0.0.1", programs: programs_array)
    }
    
    private func read_programs(robot_struct: robot_struct)
    {
        var viewed_program: PositionsProgram?
        
        if robot_struct.programs.count > 0
        {
            for program_struct in robot_struct.programs
            {
                viewed_program = PositionsProgram(name: program_struct.name)
                for point_struct in program_struct.points
                {
                    viewed_program?.add_point(pos_x: point_struct[0], pos_y: point_struct[1], pos_z: point_struct[2], rot_x: point_struct[3], rot_y: point_struct[4], rot_z: point_struct[5])
                }
                programs.append(viewed_program!)
            }
        }
    }
}
