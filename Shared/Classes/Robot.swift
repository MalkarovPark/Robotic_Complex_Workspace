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
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    var id = UUID()
    
    public var name: String?
    private var manufacturer: String?
    private var model: String?
    
    private var kinematic: Kinematic?
    
    @Published private var programs = [PositionsProgram]()
    
    //MARK: - Robot init functions
    init()
    {
        robot_init(name: "None", manufacturer: "Default", model: "Model", lenghts: [Float](), kinematic: .vi_dof, scene: "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, robot_image_data: Data(), origin_location: [0, 0, 0], origin_rotation: [0, 0, 0], space_scale: [200, 200, 200])
    }
    
    init(name: String)
    {
        robot_init(name: name, manufacturer: "Default", model: "Model", lenghts: [Float](), kinematic: .vi_dof, scene: "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, robot_image_data: Data(), origin_location: [0, 0, 0], origin_rotation: [0, 0, 0], space_scale: [200, 200, 200])
    }
    
    init(name: String, kinematic: Kinematic)
    {
        robot_init(name: name, manufacturer: "Default", model: "Model", lenghts: [Float](), kinematic: kinematic, scene: "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, robot_image_data: Data(), origin_location: [0, 0, 0], origin_rotation: [0, 0, 0], space_scale: [200, 200, 200])
    }
    
    public static var default_origin_location = [Float](repeating: 0, count: 3)
    public static var default_space_scale = [Float](repeating: 200, count: 3)
    
    init(name: String, manufacturer: String, dictionary: [String: Any]) //Init robot by dictionary
    {
        var kinematic: Kinematic
        switch dictionary["Kinematic"] as? String ?? "" //Determination of the type of kinematics by string in the property
        {
        case "Portal":
            kinematic = .portal
        case "6DOF":
            kinematic = .vi_dof
        default:
            kinematic = .vi_dof
        }
        
        var lenghts = [Float]()
        if dictionary.keys.contains("Details Lengths") //Checking for the availability of lengths data property
        {
            let elements = dictionary["Details Lengths"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                lenghts.append((element as? Float) ?? 0)
            }
        }
        
        robot_init(name: name, manufacturer: manufacturer, model: dictionary["Name"] as? String ?? "", lenghts: lenghts, kinematic: kinematic, scene: dictionary["Scene"] as? String ?? "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, robot_image_data: Data(), origin_location: Robot.default_origin_location, origin_rotation: [0, 0, 0], space_scale: Robot.default_space_scale)
    }
    
    init(robot_struct: robot_struct) //Init by robot structure
    {
        robot_init(name: robot_struct.name, manufacturer: robot_struct.manufacturer, model: robot_struct.model, lenghts: robot_struct.lenghts, kinematic: robot_struct.kinematic, scene: robot_struct.scene, is_placed: robot_struct.is_placed, location: robot_struct.location, rotation: robot_struct.rotation, get_statistics: robot_struct.get_statistics, robot_image_data: robot_struct.image_data, origin_location: robot_struct.origin_location, origin_rotation: robot_struct.origin_rotation, space_scale: robot_struct.space_scale)
        read_programs(robot_struct: robot_struct)
    }
    
    func robot_init(name: String, manufacturer: String, model: String, lenghts: [Float], kinematic: Kinematic, scene: String, is_placed: Bool, location: [Float], rotation: [Float], get_statistics: Bool, robot_image_data: Data, origin_location: [Float], origin_rotation: [Float], space_scale: [Float])
    {
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        
        self.kinematic = kinematic
        switch self.kinematic //Set inverse kinematic calculate function by robot kinematic type
        {
        case .portal:
            self.ik_perform = ik_lenghts(pointer_location:pointer_roation:origin_location:origin_rotation:lenghts:)
            self.details_positions_update = update_portal_details(nodes:values:)
            self.details_connect = portal_connect(lenghts:node:details:with_lenghts:)
            self.update_details_lenghts = update_portal_lengths(node:details:lenghts:)
        case .vi_dof:
            self.ik_perform = ik_angles(pointer_location:pointer_rotation:origin_location:origin_rotation:lenghts:)
            self.details_positions_update = update_vidof_details(nodes:values:)
            self.details_connect = vidof_connect(lenghts:node:details:with_lenghts:)
            self.update_details_lenghts = update_vidof_lengths(node:details:lenghts:)
        default:
            break
        }
        
        self.robot_scene_address = scene
        
        //If robot dictionary contains list, then addres changed from default models to special model by key.
        if self.robot_scene_address == "" || self.robot_scene_address == "None"
        {
            switch self.kinematic
            {
            case .portal:
                robot_scene_address = "Components.scnassets/Robots/Default/Portal.scn"
            case .vi_dof:
                robot_scene_address = "Components.scnassets/Robots/Default/6DOF.scn"
            default:
                break
            }
        }
        robot_model_node = SCNScene(named: robot_scene_address)!.rootNode.childNode(withName: "robot", recursively: false)!
        
        if lenghts.count > 0
        {
            self.with_lenghts = true
            self.lenghts = lenghts
        }
        
        self.is_placed = is_placed
        self.location = location
        self.rotation = rotation
        
        self.get_statistics = get_statistics
        
        self.robot_image_data = robot_image_data
        self.origin_location = origin_location
        self.origin_rotation = origin_rotation
        self.space_scale = space_scale
    }
    
    //MARK: - Program manage functions
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop robot moving before program change
            selected_program.visual_clear()
            performed = false
            moving_completed = false
            target_point_index = 0
        }
        didSet
        {
            selected_program.visual_build()
        }
    }
    
    public func add_program(_ program: PositionsProgram)
    {
        program.name = mismatched_name(name: program.name!, names: programs_names)
        programs.append(program)
        selected_program.visual_clear()
    }
    
    public func update_program(number: Int, _ program: PositionsProgram) //Update program by number
    {
        if programs.indices.contains(number) //Checking for the presence of a position program with a given number to update
        {
            programs[number] = program
            selected_program.visual_clear()
        }
    }
    
    public func update_program(name: String, _ program: PositionsProgram) //Update program by name
    {
        update_program(number: number_by_name(name: name), program)
    }
    
    public func delete_program(number: Int) //Delete program by number
    {
        if programs.indices.contains(number) //Checking for the presence of a position program with a given number to delete
        {
            selected_program.visual_clear()
            programs.remove(at: number)
        }
    }
    
    public func delete_program(name: String) //Delete program by name
    {
        delete_program(number: number_by_name(name: name))
    }
    
    public func select_program(number: Int) //Delete program by number
    {
        selected_program_index = number
    }
    
    public func select_program(name: String) //Select program by name
    {
        select_program(number: number_by_name(name: name))
    }
    
    public var selected_program: PositionsProgram
    {
        get //Return positions program by selected index
        {
            if programs.count > 0
            {
                return programs[selected_program_index]
            }
            else
            {
                return PositionsProgram()
            }
        }
        set
        {
            programs[selected_program_index] = newValue
        }
    }
    
    private func number_by_name(name: String) -> Int //Get index number of program by name
    {
        return programs.firstIndex(of: PositionsProgram(name: name)) ?? -1
    }
    
    public var programs_names: [String] //Get all names of programs in robot
    {
        var prog_names = [String]()
        if programs.count > 0
        {
            for program in programs
            {
                prog_names.append(program.name ?? "None")
            }
        }
        return prog_names
    }
    
    public var programs_count: Int //Get count of programs in robot
    {
        return programs.count
    }
    
    public func inspector_point_color(point: PositionPoint) -> Color //Get point color for inspector view
    {
        var color = Color.gray //Gray point color if the robot is not reching the point
        let point_number = self.selected_program.points.firstIndex(of: point) //Number of selected point
        
        if performed
        {
            if point_number == target_point_index //Yellow color, if the robot is in the process of moving to the point
            {
                color = .yellow
            }
            else
            {
                if point_number ?? 0 < target_point_index //Green color, if the robot has reached this point
                {
                    color = .green
                }
            }
        }
        else
        {
            if moving_completed //Green color, if the robot has passed all points
            {
                color = .green
            }
        }
        
        return color
    }
    
    //MARK: - Moving functions
    public var move_time: Float?
    public var draw_path = false //Draw path of the robot tool point
    public var performed = false //Moving state of robot
    public var moving_completed = false //This flag set if the robot has passed all positions. Used for indication in GUI.
    public var target_point_index = 0 //Index of target point in points array
    
    public var pointer_location: [Float] = [0.0, 0.0, 0.0] //x, y, z
    {
        didSet
        {
            update_location()
        }
    }
    
    public var pointer_rotation: [Float] = [0.0, 0.0, 0.0] //r, p, w
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
    
    //Return robot pointer position
    public func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1] / 10, pointer_location[2] / 10, pointer_location[0] / 10), pointer_rotation[0].to_rad, pointer_rotation[1].to_rad, pointer_rotation[2].to_rad)
    }
    
    private func current_pointer_position_select() //Return current robot pointer position
    {
        pointer_location = [Float(pointer_node?.position.z ?? 0) * 10, Float(pointer_node?.position.x ?? 0) * 10, Float(pointer_node?.position.y ?? 0) * 10]
        pointer_rotation = [Float(tool_node?.eulerAngles.z ?? 0).to_deg, Float(pointer_node?.eulerAngles.x ?? 0).to_deg, Float(pointer_node?.eulerAngles.y ?? 0).to_deg]
    }
    
    public func move_to_next_point()
    {
        if demo_work == true
        {
            //Move to point for virtual robot
            pointer_node?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).moving[target_point_index], completionHandler: {
                self.moving_finished = true
                self.select_new_point()
            })
            tool_node?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).rotation[target_point_index], completionHandler: {
                self.rotation_finished = true
                self.select_new_point()
            })
        }
        else
        {
            //Move to point for real robot.
        }
    }
    
    private var moving_finished = false
    private var rotation_finished = false
    
    private func select_new_point() //Set new target point index
    {
        if moving_finished == true && rotation_finished == true //Waiting for the target point reach
        {
            moving_finished = false
            rotation_finished = false
            
            if target_point_index < selected_program.points_count - 1
            {
                //Select and move to next point
                target_point_index += 1
                move_to_next_point()
            }
            else
            {
                //Reset target point index if all points passed
                target_point_index = 0
                performed = false
                moving_completed = true
                current_pointer_position_select()
            }
        }
    }
    
    public func start_pause_moving() //Handling robot moving
    {
        if performed == false
        {
            clear_chart_data()
            
            //Move to next point if moving was stop
            performed = true
            move_to_next_point()
        }
        else
        {
            //Remove all action if moving was perform
            performed = false
            if demo_work == true
            {
                pointer_node?.removeAllActions()
                tool_node?.removeAllActions()
            }
            else
            {
                //Remove actions for real robot
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) //Delayed robot stop
            {
                self.current_pointer_position_select()
            }
        }
    }
    
    public func reset_moving() //Reset robot moving
    {
        pointer_node?.removeAllActions()
        tool_node?.removeAllActions()
        current_pointer_position_select()
        performed = false
        target_point_index = 0
    }
    
    //MARK: - Visual build functions
    private let pointer_node_color = Color.cyan
    
    public var unit_node: SCNNode? //Robot unit node
    public var unit_origin_node: SCNNode? //Node of robot workcell origin
    
    public var box_node: SCNNode? //Box bordered cell workspace
    public var camera_node: SCNNode? //Camera
    public var pointer_node: SCNNode? //Robot teach pointer
    public var tool_node: SCNNode? //Node for tool element
    public var points_node: SCNNode? //Teach points
    public var robot_node: SCNNode? //Current robot
    public var space_node:SCNNode? //Robot space
    
    private var robot_model_node: SCNNode? //Model of this robot
    
    public var robot_scene_address = "" //Adders of robot scene. If empty – this robot used defult model.
    
    private var with_lenghts = false //Flag that determines the presence of a lenghts array for a robot
    
    public func robot_workcell_connect(scene: SCNScene, name: String, connect_camera: Bool)
    {
        //Find scene elements from scene by names and connect to instance
        self.unit_node = scene.rootNode.childNode(withName: name, recursively: true)
        self.unit_origin_node = self.unit_node?.childNode(withName: "unit_pointer", recursively: true)
        self.box_node = self.unit_node?.childNode(withName: "box", recursively: true)
        self.space_node = self.box_node?.childNode(withName: "space", recursively: true)
        self.pointer_node = self.box_node?.childNode(withName: "pointer", recursively: true)
        self.tool_node = self.pointer_node?.childNode(withName: "tool", recursively: true)
        self.points_node = self.box_node?.childNode(withName: "points", recursively: true)
        
        self.unit_node?.addChildNode(robot_model_node ?? SCNNode())
        
        //Connect robot details
        self.robot_node = self.unit_node?.childNode(withName: "robot", recursively: true)
        robot_details_connect()
        
        //Connect robot camera
        if connect_camera
        {
            self.camera_node = scene.rootNode.childNode(withName: "camera", recursively: true)
        }
        
        //Place and scale cell box
        robot_location_place()
        update_space_scale() //Set space scale by connected robot parameters
        update_position() //Update robot details position on robot connection
    }
    
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
        #if os(macOS)
        pointer_node?.eulerAngles.x = CGFloat(get_pointer_position().rot_y)
        pointer_node?.eulerAngles.y = CGFloat(get_pointer_position().rot_z)
        tool_node?.eulerAngles.z = CGFloat(get_pointer_position().rot_x)
        #else
        pointer_node?.eulerAngles.x = get_pointer_position().rot_y
        pointer_node?.eulerAngles.y = get_pointer_position().rot_z
        tool_node?.eulerAngles.z = get_pointer_position().rot_x
        #endif
    }
    
    private var robot_details = [SCNNode]()

    private var theta = [Float](repeating: 0.0, count: 6)
    private var lenghts = [Float]()
    
    public var origin_location = [Float](repeating: 0, count: 3) //x, y, z
    public var origin_rotation = [Float](repeating: 0, count: 3) //r, p, w
    
    public var space_scale = [Float](repeating: 200, count: 3) //x, y, z
    
    private var modified_node = SCNNode()
    private var saved_material = SCNMaterial()
    
    public func robot_details_connect() //Connect robot instance to manipulator model details
    {
        robot_details.removeAll()
        
        details_connect!(&lenghts, robot_node!, &robot_details, with_lenghts)
        
        if with_lenghts
        {
            update_robot_base_height()
            update_details_lenghts!(&robot_node!, &robot_details, lenghts)
        }
        else
        {
            lenghts.append(Float(robot_details[0].position.y)) //Append base height [8]
        }
    }
    
    private var details_connect: ((_ lenghts: inout [Float], _ node: SCNNode, _ details: inout [SCNNode], _ with_lenghts: Bool) -> Void)? = nil //Connect robot instance function to model details
    private var update_details_lenghts: ((_ node: inout SCNNode, _ details: inout [SCNNode], _ lenghts: [Float]) -> Void)? = nil
    
    public func robot_location_place() //Place cell workspace relative to manipulator
    {
        let vertical_lenght = lenghts.last
        
        //MARK: Place workcell box
        #if os(macOS)
        box_node?.position.x = CGFloat(origin_location[1])
        box_node?.position.y = CGFloat(origin_location[2] + (vertical_lenght ?? 0)) //Add vertical base lenght
        box_node?.position.z = CGFloat(origin_location[0])
        
        box_node?.eulerAngles.x = CGFloat(origin_rotation[1].to_rad)
        box_node?.eulerAngles.y = CGFloat(origin_rotation[2].to_rad)
        box_node?.eulerAngles.z = CGFloat(origin_rotation[0].to_rad)
        #else
        box_node?.position.x = Float(origin_location[1])
        box_node?.position.y = Float(origin_location[2] + (vertical_lenght ?? 0))
        box_node?.position.z = Float(origin_location[0])
        
        box_node?.eulerAngles.x = origin_rotation[1].to_rad
        box_node?.eulerAngles.y = origin_rotation[2].to_rad
        box_node?.eulerAngles.z = origin_rotation[0].to_rad
        #endif
        
        //MARK: Place camera
        #if os(macOS)
        camera_node?.position.x += CGFloat(origin_location[1])
        camera_node?.position.y += CGFloat(origin_location[2] + (vertical_lenght ?? 0))
        camera_node?.position.z += CGFloat(origin_location[0])
        #else
        camera_node?.position.x += Float(origin_location[1])
        camera_node?.position.y += Float(origin_location[2] + (vertical_lenght ?? 0))
        camera_node?.position.z += Float(origin_location[0])
        #endif
    }
    
    public func update_space_scale()
    {
        //XY planes
        modified_node = space_node!.childNode(withName: "w0", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]) / 10, height: CGFloat(space_scale[0]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = -CGFloat(space_scale[2]) / 20
        #else
        modified_node.position.y = -space_scale[2] / 20
        #endif
        modified_node = space_node!.childNode(withName: "w1", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]) / 10, height: CGFloat(space_scale[0]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(space_scale[2]) / 20
        #else
        modified_node.position.y = space_scale[2] / 20
        #endif
        
        //YZ plane
        modified_node = space_node!.childNode(withName: "w2", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]) / 10, height: CGFloat(space_scale[2]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = -CGFloat(space_scale[0]) / 20
        #else
        modified_node.position.z = -space_scale[0] / 20
        #endif
        modified_node = space_node!.childNode(withName: "w3", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]) / 10, height: CGFloat(space_scale[2]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = CGFloat(space_scale[0]) / 20
        #else
        modified_node.position.z = space_scale[0] / 20
        #endif
        
        //XZ plane
        modified_node = space_node!.childNode(withName: "w4", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]) / 10, height: CGFloat(space_scale[2]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = -CGFloat(space_scale[1]) / 20
        #else
        modified_node.position.x = -space_scale[1] / 20
        #endif
        modified_node = space_node!.childNode(withName: "w5", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]) / 10, height: CGFloat(space_scale[2]) / 10)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = CGFloat(space_scale[1]) / 20
        #else
        modified_node.position.x = space_scale[1] / 20
        #endif
        
        #if os(macOS)
        space_node?.position = SCNVector3(x: CGFloat(space_scale[1]) / 20, y: CGFloat(space_scale[2]) / 20, z: CGFloat(space_scale[0]) / 20)
        #else
        space_node?.position = SCNVector3(x: space_scale[1] / 20, y: space_scale[2] / 20, z: space_scale[0] / 20)
        #endif
        
        position_points_spacing()
    }
    
    private func position_points_spacing()
    {
        if programs_count > 0
        {
            for program in programs
            {
                if program.points_count > 0
                {
                    for position_point in program.points
                    {
                        if position_point.x > Float(space_scale[0])
                        {
                            position_point.x = Float(space_scale[0])
                        }
                        
                        if position_point.y > Float(space_scale[1])
                        {
                            position_point.y = Float(space_scale[1])
                        }
                        
                        if position_point.z > Float(space_scale[2])
                        {
                            position_point.z = Float(space_scale[2])
                        }
                    }
                    
                    program.visual_build()
                }
            }
        }
    }
    
    private func update_robot_base_height()
    {
        //Change robot base
        modified_node = robot_node!.childNode(withName: "base", recursively: true)! //Select node to modifty
        saved_material = (modified_node.geometry?.firstMaterial)! //Save original material from node geometry
        modified_node.geometry = SCNCylinder(radius: 8, height: CGFloat(lenghts[lenghts.count - 1])) //Update geometry //(lenghts[6]))
        modified_node.geometry?.firstMaterial = saved_material //Apply saved original material
        
        //Change position of base model
        #if os(macOS)
        modified_node.position.y = CGFloat(lenghts[lenghts.count - 1] / 2)
        robot_details[0].position.y = CGFloat(lenghts[lenghts.count - 1])
        #else
        modified_node.position.y = Float(lenghts[lenghts.count - 1] / 2)
        robot_details[0].position.y = Float(lenghts[lenghts.count - 1])
        #endif
    }
    
    //MARK: Inverse kinematic calculations
    public func update_robot()
    {
        guard robot_details.count > 0 else //Robot details nodes exist checking
        {
            return
        }
        
        guard ik_perform != nil && details_positions_update != nil else //Funcion exist checking
        {
            return
        }
        
        details_positions_update!(&robot_details, ik_perform!(origin_transform(pointer_location: visual_scaling(pointer_location, factor: 0.1), origin_rotation: origin_rotation), pointer_rotation, origin_location, origin_rotation, lenghts)) //Update robot details position by target point position
        
        current_pointer_position_select()
    }
    
    private var ik_perform: ((_ pointer_location: [Float], _ pointer_roation: [Float], _ origin_location: [Float], _ origin_rotation: [Float], _ lenghts: [Float]) -> [Float])? = nil //Inverse kinematic calculate function
    private var details_positions_update: ((_ nodes: inout [SCNNode], _ values: [Float]) -> Void)? = nil //Update robot details positions function
    
    //MARK: Robot in workspace handling
    public var is_placed = false
    public var location = [Float](repeating: 0, count: 3) //[0, 0, 0] x, y, z
    public var rotation = [Float](repeating: 0, count: 3) //[0, 0, 0] r, p, w
    
    //MARK: Robot chart functions
    public var get_statistics = false
    public var chart_data = (robot_details_angles: [PositionChartInfo](), tool_location: [PositionChartInfo](), tool_rotation: [PositionChartInfo]())
    
    private var chart_element_index = 0
    private var axis_names = ["X", "Y", "Z"]
    private var rotation_axis_names = ["R", "P", "W"]
    
    func update_chart_data()
    {
        if get_statistics && performed //Get data if robot is moving and statistic collection enabled
        {
            let ik_angles = ik_angles(pointer_location: pointer_location, pointer_rotation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation, lenghts: lenghts)
            for i in 0...ik_angles.count - 1
            {
                chart_data.robot_details_angles.append(PositionChartInfo(index: chart_element_index, value: ik_angles[i], type: "J\(i + 1)"))
            }
            
            let pointer_location_chart = [Float(((pointer_node?.position.z ?? 0)) * 10), Float(((pointer_node?.position.x ?? 0)) * 10), Float(((pointer_node?.position.y ?? 0)) * 10)]
            for i in 0...axis_names.count - 1
            {
                chart_data.tool_location.append(PositionChartInfo(index: chart_element_index, value: pointer_location_chart[i], type: axis_names[i]))
            }
            
            let pointer_rotation_chart = [Float(tool_node?.eulerAngles.z ?? 0).to_deg, Float(pointer_node?.eulerAngles.x ?? 0).to_deg, Float(pointer_node?.eulerAngles.y ?? 0).to_deg]
            for i in 0...rotation_axis_names.count - 1
            {
                chart_data.tool_rotation.append(PositionChartInfo(index: chart_element_index, value: pointer_rotation_chart[i], type: rotation_axis_names[i]))
            }
            
            chart_element_index += 1
        }
    }
    
    func clear_chart_data()
    {
        if get_statistics
        {
            chart_data = (robot_details_angles: [PositionChartInfo](), tool_location: [PositionChartInfo](), tool_rotation: [PositionChartInfo]())
            chart_element_index = 0
        }
    }
    
    //MARK: - UI functions
    private var robot_image_data = Data()
    
    #if os(macOS)
    public var image: NSImage
    {
        get
        {
            return NSImage(data: robot_image_data) ?? NSImage()
        }
        set
        {
            robot_image_data = newValue.tiffRepresentation ?? Data()
        }
    }
    
    public func card_info() -> (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view (in RobotsView)
    {
        let color: Color
        switch self.manufacturer
        {
        case "Default":
            color = Color.green
        case "ABB":
            color = Color.red
        case "FANUC":
            color = Color.yellow
        case "KUKA":
            color = Color.orange
        default:
            color = Color.clear
        }
        
        return("\(self.name ?? "Robot Name")", "\(self.manufacturer ?? "Manufacturer") – \(self.model ?? "Model")", color, self.image)
    }
    #else
    public var image: UIImage
    {
        get
        {
            return UIImage(data: robot_image_data) ?? UIImage()
        }
        set
        {
            robot_image_data = newValue.pngData() ?? Data()
        }
    }
    
    public func card_info() -> (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        let color: Color
        switch self.manufacturer
        {
        case "Default":
            color = Color.green
        case "ABB":
            color = Color.red
        case "FANUC":
            color = Color.yellow
        case "KUKA":
            color = Color.orange
        default:
            color = Color.clear
        }
        
        return("\(self.name ?? "Robot Name")", "\(self.manufacturer ?? "Manufacturer") – \(self.model ?? "Model")", color, self.image)
    }
    #endif
    
    //MARK: - Work with file system
    public var file_info: robot_struct //Convert robot data to robot_struct
    {
        //Convert robot programs set to program_struct array
        var programs_array = [program_struct]()
        if programs_count > 0
        {
            for program in programs
            {
                programs_array.append(program.file_info)
            }
        }
        
        return robot_struct(name: name ?? "Robot Name", manufacturer: manufacturer ?? "Manufacturer", model: model ?? "Model", kinematic: self.kinematic ?? .vi_dof, scene: self.robot_scene_address, lenghts: with_lenghts ? self.lenghts : [Float](), is_placed: self.is_placed, location: self.location, rotation: self.rotation, get_statistics: self.get_statistics, image_data: self.robot_image_data, programs: programs_array, origin_location: self.origin_location, origin_rotation: self.origin_rotation, space_scale: self.space_scale)
    }
    
    private func read_programs(robot_struct: robot_struct) //Convert program_struct array to robot programs
    {
        var viewed_program: PositionsProgram?
        
        if robot_struct.programs.count > 0
        {
            for program_struct in robot_struct.programs
            {
                viewed_program = PositionsProgram(name: program_struct.name)
                viewed_program?.points = program_struct.points
                
                programs.append(viewed_program!)
            }
        }
    }
}

//MARK: - Robot structure for workspace preset document handling
struct robot_struct: Codable
{
    var name: String
    var manufacturer: String
    var model: String
    
    var kinematic: Kinematic
    var scene: String
    var lenghts: [Float]
    
    var is_placed: Bool
    var location: [Float]
    var rotation: [Float]
    
    var get_statistics: Bool
    
    var image_data: Data
    var programs: [program_struct]
    
    var origin_location: [Float]
    var origin_rotation: [Float]
    var space_scale: [Float]
}

//MARK: - Model connect functions
func portal_connect(lenghts: inout [Float], node: SCNNode, details: inout [SCNNode], with_lenghts: Bool)
{
    //Get lenghts from robot scene if they is not set in plist
    if !with_lenghts
    {
        lenghts = [Float]()
        
        lenghts.append(Float(node.childNode(withName: "frame2", recursively: true)!.position.y)) //Portal frame height [0]
        
        lenghts.append(Float(node.childNode(withName: "limit1_min", recursively: true)!.position.z)) //Position X shift [1]
        lenghts.append(Float(node.childNode(withName: "limit0_min", recursively: true)!.position.x + node.childNode(withName: "limit2_min", recursively: true)!.position.x)) //Position Y shift [2]
        lenghts.append(Float(-node.childNode(withName: "limit2_min", recursively: true)!.position.y)) //Position Z shift [3]
        lenghts.append(Float(node.childNode(withName: "target", recursively: true)!.position.y)) //Tool lenght for adding to Z shift [4]
        
        lenghts.append(Float(node.childNode(withName: "limit0_max", recursively: true)!.position.x)) //Limit for X [5]
        lenghts.append(Float(node.childNode(withName: "limit1_max", recursively: true)!.position.z)) //Limit for Y [6]
        lenghts.append(Float(-node.childNode(withName: "limit2_max", recursively: true)!.position.y)) //Limit for Z [7]
    }
    
    //Connect to detail nodes from robot scene
    details.append(node.childNode(withName: "frame", recursively: true)!) //Base position
    for i in 0...2
    {
        details.append(node.childNode(withName: "d\(i)", recursively: true)!)
    }
}

func vidof_connect(lenghts: inout [Float], node: SCNNode, details: inout [SCNNode], with_lenghts: Bool)
{
    //Create lenghts array if they is not set in plist
    if !with_lenghts
    {
        lenghts = [Float](repeating: 0, count: 6)
    }
    
    for i in 0...6
    {
        //Connect to detail nodes from robot scene
        details.append(node.childNode(withName: "d\(i)", recursively: true)!)
        
        //Get lenghts from robot scene if they is not set in plist
        if !with_lenghts
        {
            if i > 0
            {
                lenghts[i - 1] = Float(details[i].position.y)
            }
        }
    }
}

func update_portal_lengths(node: inout SCNNode, details: inout [SCNNode], lenghts: [Float])
{
    #if os(macOS)
    node.childNode(withName: "frame2", recursively: true)!.position.y = CGFloat(lenghts[0]) //Set vertical position for frame portal
    #else
    node.childNode(withName: "frame2", recursively: true)!.position.y = lenghts[0] //Set vertical position for frame portal
    #endif
    
    var modified_node = SCNNode()
    var saved_material = SCNMaterial()
    
    modified_node = node.childNode(withName: "detail_v", recursively: true)!
    if lenghts[0] - 4 > 0
    {
        saved_material = (modified_node.geometry?.firstMaterial)!
        
        modified_node.geometry = SCNBox(width: 8, height: CGFloat(lenghts[0]) - 4, length: 8, chamferRadius: 1)
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(lenghts[0] - 4) / 2
        #else
        modified_node.position.y = (lenghts[0] - 4) / 2
        #endif
    }
    else
    {
        modified_node.removeFromParentNode() //Remove the model of Z element if the frame is too low
    }
    
    var frame_element_length: CGFloat
    
    //X shift
    #if os(macOS)
    node.childNode(withName: "limit1_min", recursively: true)!.position.z = CGFloat(lenghts[1])
    node.childNode(withName: "limit1_max", recursively: true)!.position.z = CGFloat(lenghts[5])
    frame_element_length = CGFloat(lenghts[5] - lenghts[1]) + 16 //Calculate frame X length
    #else
    node!.childNode(withName: "limit1_min", recursively: true)!.position.z = lenghts[1]
    node!.childNode(withName: "limit1_max", recursively: true)!.position.z = lenghts[5]
    frame_element_length = CGFloat(lenghts[5] - lenghts[1] + 16) //Calculate frame X length
    #endif
    
    modified_node = node.childNode(withName: "detail_x", recursively: true)!
    saved_material = (modified_node.geometry?.firstMaterial)!
    modified_node.geometry = SCNBox(width: 6, height: 6, length: frame_element_length, chamferRadius: 1) //Update frame X geometry
    modified_node.geometry?.firstMaterial = saved_material
    #if os(macOS)
    modified_node.position.z = (frame_element_length + 8) / 2 //Frame X reposition
    #else
    modified_node.position.z = Float(frame_element_length + 8) / 2
    #endif
    
    //Y shift
    #if os(macOS)
    node.childNode(withName: "limit0_min", recursively: true)!.position.x = CGFloat(lenghts[2]) / 2
    node.childNode(withName: "limit0_max", recursively: true)!.position.x = CGFloat(lenghts[6])
    frame_element_length = CGFloat(lenghts[6] - lenghts[2]) + 16 //Calculate frame Y length
    #else
    node.childNode(withName: "limit0_min", recursively: true)!.position.x = lenghts[2] / 2
    node.childNode(withName: "limit0_max", recursively: true)!.position.x = lenghts[6]
    frame_element_length = CGFloat(lenghts[6] - lenghts[2] + 16) //Calculate frame Y length
    #endif
    
    modified_node = node.childNode(withName: "detail_y", recursively: true)!
    saved_material = (modified_node.geometry?.firstMaterial)!
    modified_node.geometry = SCNBox(width: 6, height: 6, length: frame_element_length, chamferRadius: 1) //Update frame Y geometry
    modified_node.geometry?.firstMaterial = saved_material
    #if os(macOS)
    modified_node.position.x = (frame_element_length + 8) / 2 //Frame Y reposition
    #else
    modified_node.position.x = Float(frame_element_length + 8) / 2
    #endif
    
    //Z shift
    #if os(macOS)
    node.childNode(withName: "limit2_min", recursively: true)!.position.y = CGFloat(-lenghts[3])
    node.childNode(withName: "limit2_max", recursively: true)!.position.y = CGFloat(lenghts[7])
    frame_element_length = CGFloat(lenghts[7])
    #else
    node.childNode(withName: "limit2_min", recursively: true)!.position.y = -lenghts[3]
    node.childNode(withName: "limit2_max", recursively: true)!.position.y = lenghts[7]
    frame_element_length = CGFloat(lenghts[7])
    #endif
    
    modified_node = node.childNode(withName: "detail_z", recursively: true)!
    saved_material = (modified_node.geometry?.firstMaterial)!
    modified_node.geometry = SCNBox(width: 6, height: frame_element_length, length: 6, chamferRadius: 1) //Update frame Z geometry
    modified_node.geometry?.firstMaterial = saved_material
    #if os(macOS)
    modified_node.position.y = (frame_element_length) / 2 //Frame Z reposition
    #else
    modified_node.position.y = Float(frame_element_length) / 2
    #endif
}

func update_vidof_lengths(node: inout SCNNode, details: inout [SCNNode], lenghts: [Float])
{
    var modified_node = SCNNode()
    var saved_material = SCNMaterial()
    
    saved_material = (details[0].childNode(withName: "box", recursively: false)!.geometry?.firstMaterial)! //Save material from detail box
    
    for i in 0..<details.count - 1
    {
        //Get lenght 0 if first robot detail selected and get previous lenght for all next details
        #if os(macOS)
        details[i].position.y = CGFloat(i > 0 ? lenghts[i - 1] : lenghts[lenghts.count - 1])
        #else
        details[i].position.y = Float(i > 0 ? lenghts[i - 1] : lenghts[lenghts.count - 1])
        #endif
        
        if i < 5
        {
            //Change box model size and move that node vertical for details 0-4
            modified_node = details[i].childNode(withName: "box", recursively: false)!
            if i < 3
            {
                modified_node.geometry = SCNBox(width: 6, height: CGFloat(lenghts[i]), length: 6, chamferRadius: 1) //Set geometry for 0-2 details with width 6 and chamfer
            }
            else
            {
                if i < 4
                {
                    modified_node.geometry = SCNBox(width: 5, height: CGFloat(lenghts[i]), length: 5, chamferRadius: 1) //Set geometry for 3th detail with width 5 and chamfer
                }
                else
                {
                    modified_node.geometry = SCNBox(width: 4, height: CGFloat(lenghts[i]), length: 4, chamferRadius: 0) //Set geometry for 4th detail with width 4 and without chamfer
                }
            }
            modified_node.geometry?.firstMaterial = saved_material //Apply saved material
            
            #if os(macOS)
            modified_node.position.y = CGFloat(lenghts[i] / 2)
            #else
            modified_node.position.y = Float(lenghts[i] / 2)
            #endif
        }
        else
        {
            //Set tool target (d6) position for 5th detail
            #if os(macOS)
            details[6].position.y = CGFloat(lenghts[i])
            #else
            details[6].position.y = Float(lenghts[i])
            #endif
        }
    }
}

//MARK: - Inverse kinematic functions
func origin_transform(pointer_location: [Float], origin_rotation: [Float]) -> [Float] //Transform position by origin rotation
{
    let new_x, new_y, new_z: Float
    if origin_rotation.reduce(0, +) > 0 //If at least one rotation angle of the origin is not equal to zero
    {
        //Calculate new values for coordinates components
        new_x = pointer_location[0] * cos(origin_rotation[1].to_rad) * cos(origin_rotation[2].to_rad) + pointer_location[2] * sin(origin_rotation[1].to_rad) - pointer_location[1] * sin(origin_rotation[2].to_rad)
        new_y = pointer_location[1] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[2].to_rad) - pointer_location[2] * sin(origin_rotation[0].to_rad) + pointer_location[0] * sin(origin_rotation[2].to_rad)
        new_z = pointer_location[2] * cos(origin_rotation[0].to_rad) * cos(origin_rotation[1].to_rad) + pointer_location[1] * sin(origin_rotation[0].to_rad) - pointer_location[0] * sin(origin_rotation[1].to_rad)
    }
    else
    {
        //Return original values
        new_x = pointer_location[0]
        new_y = pointer_location[1]
        new_z = pointer_location[2]
    }
    
    return [new_x, new_y, new_z]
}

func visual_scaling(_ numbers: [Float], factor: Float) -> [Float] //Scaling lenghts by divider
{
    var new_numbers = [Float]()
    for number in numbers
    {
        new_numbers.append(number * factor)
    }
    
    return new_numbers
}

//MARK: Calculate inverse kinematic details position for portal robot
func ik_lenghts(pointer_location: [Float], pointer_roation: [Float], origin_location: [Float], origin_rotation: [Float], lenghts: [Float]) -> [Float]
{
    var px, py, pz: Float
    
    px = pointer_location[0] + origin_location[0] - lenghts[1]
    py = pointer_location[1] + origin_location[1] - lenghts[2]
    pz = pointer_location[2] + origin_location[2] - lenghts[0] + lenghts[3] + lenghts[4]
    
    //Checking X detail limit
    if px < 0
    {
        px = 0
    }
    else
    {
        if px > lenghts[5]
        {
            px = lenghts[5]
        }
    }
    
    //Checking Y detail limit
    if py < 0
    {
        py = 0
    }
    else
    {
        if py > lenghts[6] - lenghts[2] / 2
        {
            py = lenghts[6] - lenghts[2] / 2
        }
    }
    
    //Checking Z detail limit
    if pz > 0
    {
        pz = 0
    }
    else
    {
        if pz < -lenghts[7]
        {
            pz = -lenghts[7]
        }
    }

    return [px, py, pz]
}

//MARK: Calculate inverse kinematic details roataion angles for 6DOF
func ik_angles(pointer_location: [Float], pointer_rotation: [Float], origin_location: [Float], origin_rotation: [Float], lenghts: [Float]) -> [Float]
{
    var angles = [Float]()
    var C3 = Float()
    var theta = [Float](repeating: 0.0, count: 6)
    
    do
    {
        var px, py, pz: Float
        var rx, ry, rz: Float
        var ax, ay, az, bx, by, bz: Float
        var asx, asy, asz, bsx, bsy, bsz: Float
        var p5x, p5y, p5z: Float
        var C1, C23, S1, S23: Float
        
        var M, N, A, B: Float
        
        px = -(pointer_location[0] + origin_location[0])
        py = pointer_location[1] + origin_location[1]
        pz = pointer_location[2] + origin_location[2]
        
        rx = -(pointer_rotation[0].to_rad + origin_rotation[0].to_rad)
        ry = -(pointer_rotation[1].to_rad + origin_rotation[1].to_rad) + (.pi)
        rz = -(pointer_rotation[2].to_rad + origin_rotation[2].to_rad)
        
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
        theta[0] = Float(atan2(p5y, p5x))
        
        //Joints 3, 2
        theta[2] = Float(atan2(pow(abs(1 - pow(C3, 2)), 0.5), C3))
        
        M = lenghts[1] + (lenghts[2] + lenghts[3]) * C3
        N = (lenghts[2] + lenghts[3]) * sin(Float(theta[2]))
        A = pow(p5x * p5x + p5y * p5y, 0.5)
        B = p5z - lenghts[0]
        theta[1] = Float(atan2(M * A - N * B, N * A + M * B))
        
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
        
        theta[3] = Float(atan2(asy, asx))
        theta[4] = Float(atan2(cos(Float(theta[3])) * asx + sin(Float(theta[3])) * asy, asz))
        theta[5] = Float(atan2(cos(Float(theta[3])) * bsy - sin(Float(theta[3])) * bsx, -bsz / sin(Float(theta[4]))))
        
        angles.append(-(theta[0] + .pi))
        angles.append(-theta[1])
        angles.append(-theta[2])
        angles.append(-(theta[3] + .pi))
        angles.append(theta[4])
        angles.append(-theta[5])
    }
    
    return angles
}

//MARK: - Update details psitions for robots models
func update_portal_details(nodes: inout [SCNNode], values: [Float])
{
    #if os(macOS)
    nodes[1].position.x = CGFloat(values[1])
    nodes[3].position.y = CGFloat(values[2])
    nodes[2].position.z = CGFloat(values[0])
    #else
    nodes[1].position.x = values[1]
    nodes[3].position.y = values[2]
    nodes[2].position.z = values[0]
    #endif
}

func update_vidof_details(nodes: inout [SCNNode], values: [Float])
{
    #if os(macOS)
    nodes[0].eulerAngles.y = CGFloat(values[0])
    nodes[1].eulerAngles.z = CGFloat(values[1])
    nodes[2].eulerAngles.z = CGFloat(values[2])
    nodes[3].eulerAngles.y = CGFloat(values[3])
    nodes[4].eulerAngles.z = CGFloat(values[4])
    nodes[5].eulerAngles.y = CGFloat(values[5])
    #else
    nodes[0].eulerAngles.y = Float(values[0])
    nodes[1].eulerAngles.z = Float(values[1])
    nodes[2].eulerAngles.z = Float(values[2])
    nodes[3].eulerAngles.y = Float(values[3])
    nodes[4].eulerAngles.z = Float(values[4])
    nodes[5].eulerAngles.y = Float(values[5])
    #endif
}

//MARK: - Charts structures
struct PositionChartInfo: Identifiable
{
    var id = UUID()
    var index: Int
    var value: Float
    var type: String
}

//MARK: - Kinematic types enums
enum Kinematic: String, Codable, Equatable, CaseIterable
{
    case vi_dof = "6DOF"
    case portal = "Portal"
}
