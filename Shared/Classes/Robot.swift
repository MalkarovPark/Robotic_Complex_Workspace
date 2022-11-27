//
//  Robot.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

class Robot: WorkspaceObject
{
    private var manufacturer: String?
    private var model: String?
    
    //MARK: - Init functions
    override init()
    {
        super.init()
        robot_init(name: "None", manufacturer: "Default", model: "Model", lengths: [Float](), module_name: "None", scene: "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, image_data: Data(), origin_location: [0, 0, 0], origin_rotation: [0, 0, 0], space_scale: [200, 200, 200])
    }
    
    override init(name: String)
    {
        super.init()
        robot_init(name: name, manufacturer: "Default", model: "Model", lengths: [Float](), module_name: "None", scene: "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, image_data: Data(), origin_location: [0, 0, 0], origin_rotation: [0, 0, 0], space_scale: [200, 200, 200])
    }
    
    init(name: String, manufacturer: String, dictionary: [String: Any]) //Init by model dictionary
    {
        super.init()
        
        var lengths = [Float]()
        if dictionary.keys.contains("Lengths") //Checking for the availability of lengths data property
        {
            lengths = dictionary["Lengths"] as! Array<Float> //Add elements from NSArray to floats array
        }
        
        robot_init(name: name, manufacturer: manufacturer, model: dictionary["Name"] as? String ?? "", lengths: lengths, module_name: dictionary["Module"] as? String ?? "", scene: dictionary["Scene"] as? String ?? "", is_placed: false, location: [0, 0, 0], rotation: [0, 0, 0], get_statistics: false, image_data: Data(), origin_location: Robot.default_origin_location, origin_rotation: [0, 0, 0], space_scale: Robot.default_space_scale)
    }
    
    init(robot_struct: RobotStruct) //Init by robot structure
    {
        super.init()
        robot_init(name: robot_struct.name, manufacturer: robot_struct.manufacturer, model: robot_struct.model, lengths: robot_struct.lengths, module_name: robot_struct.module, scene: robot_struct.scene, is_placed: robot_struct.is_placed, location: robot_struct.location, rotation: robot_struct.rotation, get_statistics: robot_struct.get_statistics, image_data: robot_struct.image_data, origin_location: robot_struct.origin_location, origin_rotation: robot_struct.origin_rotation, space_scale: robot_struct.space_scale)
        read_programs(robot_struct: robot_struct) //Import programs if robot init by structure (from document file)
    }
    
    private func robot_init(name: String, manufacturer: String, model: String, lengths: [Float], module_name: String, scene: String, is_placed: Bool, location: [Float], rotation: [Float], get_statistics: Bool, image_data: Data, origin_location: [Float], origin_rotation: [Float], space_scale: [Float]) //Common init function
    {
        //Robot model names
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        
        //Robot position in workspace
        self.is_placed = is_placed
        self.location = location
        self.rotation = rotation
        
        //Statistic value
        self.get_statistics = get_statistics
        
        self.image_data = image_data
        self.origin_location = origin_location
        self.origin_rotation = origin_rotation
        self.space_scale = space_scale
        
        //Robot controller and connector modules
        self.module_name = module_name
        if self.module_name != ""
        {
            select_modules(name: module_name)
        }
        
        //Robot scene address
        self.scene_address = scene
        if scene_address != ""
        {
            get_node_from_scene()
        }
        else
        {
            self.lengths = lengths
            node_by_description()
        }
    }
    
    private func select_modules(name: String) //Select model visual controller an connector
    {
        switch name
        {
        case "Portal":
            model_controller = PortalController()
            connector = RobotConnector()
        case "6DOF":
            model_controller = _6DOFController()
            connector = RobotConnector()
        default:
            break
        }
    }
    
    //MARK: - Program manage functions
    @Published private var programs = [PositionsProgram]()
    
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
    
    public func update_program(index: Int, _ program: PositionsProgram) //Update program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to update
        {
            programs[index] = program
            selected_program.visual_clear()
        }
    }
    
    public func update_program(name: String, _ program: PositionsProgram) //Update program by name
    {
        update_program(index: index_by_name(name: name), program)
    }
    
    public func delete_program(index: Int) //Delete program by index
    {
        if programs.indices.contains(index) //Checking for the presence of a position program with a given number to delete
        {
            selected_program.visual_clear()
            programs.remove(at: index)
        }
    }
    
    public func delete_program(name: String) //Delete program by name
    {
        delete_program(index: index_by_name(name: name))
    }
    
    public func select_program(index: Int) //Delete program by index
    {
        selected_program_index = index
    }
    
    public func select_program(name: String) //Select program by name
    {
        select_program(index: index_by_name(name: name))
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
    
    private func index_by_name(name: String) -> Int //Get index of program by name
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
    
    //MARK: - Moving functions
    private var module_name = ""
    
    public var draw_path = false //Draw path of the robot tool point
    public var performed = false //Moving state of robot
    public var moving_completed = false //This flag set if the robot has passed all positions. Used for indication in GUI.
    public var target_point_index = 0 //Index of target point in points array
    
    public static var default_origin_location = [Float](repeating: 0, count: 3)
    public static var default_space_scale = [Float](repeating: 200, count: 3)
    
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
    
    public var move_time: Float?
    {
        return 1
        //return selected_program.points[target_point_index].move_speed
    }
    
    private var demo = true
    {
        didSet
        {
            reset_moving()
            
            if demo
            {
                connect()
            }
            else
            {
                disconnect()
            }
        }
    }
    
    //Return robot pointer position
    public func get_pointer_position() -> (location: SCNVector3, rot_x: Float, rot_y: Float, rot_z: Float)
    {
        return(SCNVector3(pointer_location[1], pointer_location[2], pointer_location[0]), pointer_rotation[0].to_rad, pointer_rotation[1].to_rad, pointer_rotation[2].to_rad)
    }
    
    private func current_pointer_position_select() //Return current robot pointer position
    {
        pointer_location = [Float(pointer_node?.position.z ?? 0), Float(pointer_node?.position.x ?? 0), Float(pointer_node?.position.y ?? 0)]
        pointer_rotation = [Float(pointer_node_internal?.eulerAngles.z ?? 0).to_deg, Float(pointer_node?.eulerAngles.x ?? 0).to_deg, Float(pointer_node?.eulerAngles.y ?? 0).to_deg]
    }
    
    public func move_to_point(_ position: PositionPoint) //Single position perform
    {
        
    }
    
    //MARK: Performation cycle
    public func move_to_next_point()
    {
        if demo == true
        {
            //Move to point for virtual robot
            pointer_node?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).moving[target_point_index], completionHandler: {
                self.moving_finished = true
                self.select_new_point()
            })
            pointer_node_internal?.runAction(programs[selected_program_index].points_moving_group(move_time: TimeInterval(move_time ?? 1)).rotation[target_point_index], completionHandler: {
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
    
    public var finish_handler: (() -> Void) = {}
    public func clear_finish_handler()
    {
        finish_handler = {}
    }
    
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
                
                finish_handler()
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
            if demo == true
            {
                pointer_node?.removeAllActions()
                pointer_node_internal?.removeAllActions()
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
        pointer_node_internal?.removeAllActions()
        current_pointer_position_select()
        performed = false
        target_point_index = 0
    }
    
    //MARK: - Connection functions
    private var connector = RobotConnector()
    
    private func connect()
    {
        connector.connect()
    }
    
    private func disconnect()
    {
        connector.disconnect()
    }
    
    //MARK: - Visual build functions
    override var scene_node_name: String { "robot" }
    
    private var model_controller = RobotModelController()
    
    override func node_by_description()
    {
        node = SCNNode()
        
        switch module_name
        {
        case "Portal":
            portal_model()
        case "6DOF":
            vidof_model()
        default:
            no_model()
        }
        
        func portal_model() //Use default portal manipulator model
        {
            node = SCNScene(named: "Components.scnassets/Robots/Default/Portal.scn")!.rootNode.childNode(withName: "robot", recursively: false)!
        }
        
        func vidof_model() //Usr default 6DOF manipulator model
        {
            node = SCNScene(named: "Components.scnassets/Robots/Default/6DOF.scn")!.rootNode.childNode(withName: "robot", recursively: false)!
        }
        
        func no_model()
        {
            node?.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
            
            #if os(macOS)
            node?.geometry?.firstMaterial?.diffuse.contents = NSColor.gray
            #else
            node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
            #endif
            
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
            node?.name = "robot"
        }
    }
    
    //Robot workcell unit nodes references
    public var unit_node: SCNNode? //Robot unit node with manipulator node
    public var box_node: SCNNode? //Box bordered cell workspace
    public var camera_node: SCNNode? //Camera
    public var pointer_node: SCNNode? //Robot teach pointer
    public var pointer_node_internal: SCNNode? //Node for internal element
    public var points_node: SCNNode? //Teach points
    public var robot_node: SCNNode? //Current robot
    public var space_node:SCNNode? //Robot space
    public var tool_node: SCNNode? //Node for tool attachment
    
    public func workcell_connect(scene: SCNScene, name: String, connect_camera: Bool)
    {
        //Find nodes from scene by names
        self.unit_node = scene.rootNode.childNode(withName: name, recursively: true)
        /*scene.rootNode.enumerateChildNodes
        { (_node, stop) in
            if _node.name == name, _node.categoryBitMask == Workspace.robot_bit_mask
            {
                unit_node = _node
                //print((_node.name ?? "") + "is tool")
            }
        }*/
        
        self.box_node = self.unit_node?.childNode(withName: "box", recursively: true)
        self.space_node = self.box_node?.childNode(withName: "space", recursively: true)
        self.pointer_node = self.box_node?.childNode(withName: "pointer", recursively: true)
        self.pointer_node_internal = self.pointer_node?.childNode(withName: "internal", recursively: true)
        self.points_node = self.box_node?.childNode(withName: "points", recursively: true)
        
        //Connect robot details
        self.tool_node = node?.childNode(withName: "tool", recursively: true)
        self.unit_node?.addChildNode(node ?? SCNNode())
        model_controller.nodes_disconnect()
        model_controller.nodes_connect(node ?? SCNNode())
        if lengths.count > 0
        {
            model_controller.lengths = lengths
            model_controller.nodes_transform()
        }
        
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
        pointer_node_internal?.eulerAngles.z = CGFloat(get_pointer_position().rot_x)
        #else
        pointer_node?.eulerAngles.x = get_pointer_position().rot_y
        pointer_node?.eulerAngles.y = get_pointer_position().rot_z
        pointer_node_internal?.eulerAngles.z = get_pointer_position().rot_x
        #endif
    }
    
    public func update_robot() //Manipulator details update by
    {
        model_controller.nodes_update(pointer_location: pointer_location, pointer_roation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation)
        
        current_pointer_position_select()
    }
    
    private var lengths = [Float]()
    
    //MARK: Cell box handling
    public var origin_location = [Float](repeating: 0, count: 3) //x, y, z
    public var origin_rotation = [Float](repeating: 0, count: 3) //r, p, w
    
    public var space_scale = [Float](repeating: 200, count: 3) //x, y, z
    
    private var modified_node = SCNNode()
    private var saved_material = SCNMaterial()
    
    public func robot_location_place() //Place cell workspace relative to manipulator
    {
        let vertical_length = model_controller.lengths.last
        
        //MARK: Place workcell box
        #if os(macOS)
        box_node?.position.x = CGFloat(origin_location[1])
        box_node?.position.y = CGFloat(origin_location[2] + (vertical_length ?? 0)) //Add vertical base length
        box_node?.position.z = CGFloat(origin_location[0])
        
        box_node?.eulerAngles.x = CGFloat(origin_rotation[1].to_rad)
        box_node?.eulerAngles.y = CGFloat(origin_rotation[2].to_rad)
        box_node?.eulerAngles.z = CGFloat(origin_rotation[0].to_rad)
        #else
        box_node?.position.x = Float(origin_location[1])
        box_node?.position.y = Float(origin_location[2] + (vertical_length ?? 0))
        box_node?.position.z = Float(origin_location[0])
        
        box_node?.eulerAngles.x = origin_rotation[1].to_rad
        box_node?.eulerAngles.y = origin_rotation[2].to_rad
        box_node?.eulerAngles.z = origin_rotation[0].to_rad
        #endif
        
        //MARK: Place camera
        #if os(macOS)
        camera_node?.position.x += CGFloat(origin_location[1])
        camera_node?.position.y += CGFloat(origin_location[2] + (vertical_length ?? 0))
        camera_node?.position.z += CGFloat(origin_location[0])
        #else
        camera_node?.position.x += Float(origin_location[1])
        camera_node?.position.y += Float(origin_location[2] + (vertical_length ?? 0))
        camera_node?.position.z += Float(origin_location[0])
        #endif
    }
    
    public func update_space_scale()
    {
        //XY planes
        modified_node = space_node!.childNode(withName: "w0", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[0]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = -CGFloat(space_scale[2]) / 2
        #else
        modified_node.position.y = -space_scale[2] / 2
        #endif
        modified_node = space_node!.childNode(withName: "w1", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[0]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.y = CGFloat(space_scale[2]) / 2
        #else
        modified_node.position.y = space_scale[2] / 2
        #endif
        
        //YZ plane
        modified_node = space_node!.childNode(withName: "w2", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = -CGFloat(space_scale[0]) / 2
        #else
        modified_node.position.z = -space_scale[0] / 2
        #endif
        modified_node = space_node!.childNode(withName: "w3", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[1]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.z = CGFloat(space_scale[0]) / 2
        #else
        modified_node.position.z = space_scale[0] / 2
        #endif
        
        //XZ plane
        modified_node = space_node!.childNode(withName: "w4", recursively: true)!
        saved_material = (modified_node.geometry?.firstMaterial)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = -CGFloat(space_scale[1]) / 2
        #else
        modified_node.position.x = -space_scale[1] / 2
        #endif
        modified_node = space_node!.childNode(withName: "w5", recursively: true)!
        modified_node.geometry = SCNPlane(width: CGFloat(space_scale[0]), height: CGFloat(space_scale[2]))
        modified_node.geometry?.firstMaterial = saved_material
        #if os(macOS)
        modified_node.position.x = CGFloat(space_scale[1]) / 2
        #else
        modified_node.position.x = space_scale[1] / 2
        #endif
        
        #if os(macOS)
        space_node?.position = SCNVector3(x: CGFloat(space_scale[1]) / 2, y: CGFloat(space_scale[2]) / 2, z: CGFloat(space_scale[0]) / 2)
        #else
        space_node?.position = SCNVector3(x: space_scale[1] / 2, y: space_scale[2] / 2, z: space_scale[0] / 2)
        #endif
        
        position_points_shift()
    }
    
    private func position_points_shift() //Shift positions when reducing the workcell area
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
    
    //MARK: - Chart functions
    public var state: [String: Any]?
    
    public var get_statistics = false
    public var chart_data = (robot_details_angles: [PositionChartInfo](), tool_location: [PositionChartInfo](), tool_rotation: [PositionChartInfo]())
    
    private var chart_element_index = 0
    private var axis_names = ["X", "Y", "Z"]
    private var rotation_axis_names = ["R", "P", "W"]
    
    func update_chart_data()
    {
        if get_statistics && performed //Get data if robot is moving and statistic collection enabled
        {
            /*let ik_angles = ik_angles(pointer_location: pointer_location, pointer_rotation: pointer_rotation, origin_location: origin_location, origin_rotation: origin_rotation, lengths: lengths)
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
            
            chart_element_index += 1*/
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
    #if os(macOS)
    override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
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
    override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
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
    
    //MARK: - Work with file system
    public var file_info: RobotStruct //Convert robot data to robot_struct
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
        
        return RobotStruct(name: name ?? "Robot Name", manufacturer: manufacturer ?? "Manufacturer", model: model ?? "Model", module: self.module_name, scene: self.scene_address, lengths: self.scene_address == "" ? self.lengths : [Float](), is_placed: self.is_placed, location: self.location, rotation: self.rotation, get_statistics: self.get_statistics, image_data: self.image_data, programs: programs_array, origin_location: self.origin_location, origin_rotation: self.origin_rotation, space_scale: self.space_scale)
    }
    
    private func read_programs(robot_struct: RobotStruct) //Convert program_struct array to robot programs
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
struct RobotStruct: Codable
{
    var name: String
    var manufacturer: String
    var model: String
    
    var module: String
    var scene: String
    var lengths: [Float]
    
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

//MARK: - Conversion functions for space parameters
func visual_scaling(_ numbers: [Float], factor: Float) -> [Float] //Scaling lengths by divider
{
    var new_numbers = [Float]()
    for number in numbers
    {
        new_numbers.append(number * factor)
    }
    
    return new_numbers
}

//MARK: - Charts structures
struct PositionChartInfo: Identifiable
{
    var id = UUID()
    var index: Int
    var value: Float
    var type: String
}
