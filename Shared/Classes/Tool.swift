//
//  Tool.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation
import SceneKit
import SwiftUI

class Tool: WorkspaceObject
{
    //MARK: - Init functions
    override init(name: String)
    {
        super.init(name: name)
    }
    
    init(name: String, dictionary: [String: Any]) //Init detail by dictionary and use models folder
    {
        super.init()
        
        if dictionary.keys.contains("Operations Codes") //Import tool opcodes values from dictionary
        {
            let dict = dictionary["Operations Codes"] as! [String : Int]
            
            self.codes = dict.map { $0.value }
            self.codes_names = dict.map { $0.key }
        }
        
        if dictionary.keys.contains("Module") //Select model visual controller an connector
        {
            self.module_name = dictionary["Module"] as? String ?? ""
            select_model_modules(name: module_name, controller: model_controller, connector: &connector)
        }
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
    }
    
    init(tool_struct: ToolStruct) //Init by tool structure
    {
        super.init(name: tool_struct.name!)
        
        self.codes = tool_struct.codes
        self.codes_names = tool_struct.names
        
        self.scene_address = tool_struct.scene ?? ""
        self.programs = tool_struct.programs
        self.image_data = tool_struct.image_data
        
        if scene_address != ""
        {
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
        
        self.module_name = tool_struct.module ?? ""
        if module_name != ""
        {
            select_model_modules(name: module_name, controller: model_controller, connector: &connector)
        }
    }
    
    private func select_model_modules(name: String, controller: ToolModelController, connector: inout ToolConnector) //Select model visual controller an connector
    {
        switch name
        {
        case "gripper":
            model_controller = GripperController()
        case "drill":
            model_controller = DrillController()
        default:
            break
        }
    }
    
    //MARK: - Program manage functions
    @Published private var programs = [OperationsProgram]()
    
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop tool moving before program change
            performed = false
            performing_completed = false
            target_code_index = 0
        }
        didSet
        {
            //selected_program.visual_build()
        }
    }
    
    public func add_program(_ program: OperationsProgram)
    {
        program.name = mismatched_name(name: program.name!, names: programs_names)
        programs.append(program)
    }
    
    public func update_program(number: Int, _ program: OperationsProgram) //Update program by number
    {
        if programs.indices.contains(number) //Checking for the presence of a position program with a given number to update
        {
            programs[number] = program
        }
    }
    
    public func update_program(name: String, _ program: OperationsProgram) //Update program by name
    {
        update_program(number: number_by_name(name: name), program)
    }
    
    public func delete_program(number: Int) //Delete program by number
    {
        if programs.indices.contains(number) //Checking for the presence of a position program with a given number to delete
        {
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
    
    public var selected_program: OperationsProgram
    {
        get //Return positions program by selected index
        {
            if programs.count > 0
            {
                return programs[selected_program_index]
            }
            else
            {
                return OperationsProgram()
            }
        }
        set
        {
            programs[selected_program_index] = newValue
        }
    }
    
    private func number_by_name(name: String) -> Int //Get index number of program by name
    {
        return programs.firstIndex(of: OperationsProgram(name: name)) ?? -1
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
    
    //MARK: - Control functions
    public var codes = [Int]()
    
    public var operation_code: Int? = 0
    {
        didSet
        {
            //Checking for positive value of operation code number
            if operation_code! > 0
            {
                //Perform function by opcode as array number
                //print("\(operation_code ?? 0) 🍩")
            }
            else
            {
                //Reset tool perfroming by negative code
                //print("\(operation_code ?? 0) 🍷")
                if operation_code! < 0
                {
                    operation_code = 0
                }
            }
        }
    }
    
    private(set) var info_code: Int? = 0
    
    public var performed = false //Performing state of tool
    
    public var codes_count: Int
    {
        return codes.count
    }
    
    //MARK: - Moving functions
    public var performing_completed = false //This flag set if the robot has passed all positions. Used for indication in GUI
    public var code_changed = false //This flag perform update if performed code changed
    public var target_code_index = 0 //Index of target point in points array
    
    private var module_name = ""
    private var connector = ToolConnector()
    private var continue_selection = true
    
    private var demo_work = true
    {
        didSet
        {
            if demo_work == false
            {
                reset_performing()
            }
        }
    }
    
    public func perform_next_code()
    {
        if demo_work == true
        {
            //Move to point for virtual tool
            model_controller.nodes_perform(code: selected_program.codes[target_code_index].value)
            {
                self.select_new_code()
            }
        }
        else
        {
            //Move to point for real tool
        }
    }
    
    private func select_new_code() //Set new target point index
    {
        if performed
        {
            target_code_index += 1
        }
        else
        {
            return
        }
        
        code_changed = true
        
        if target_code_index < selected_program.codes_count
        {
            //Select and move to next point
            perform_next_code()
        }
        else
        {
            //Reset target point index if all points passed
            target_code_index = 0
            performed = false
            performing_completed = true
        }
    }
    
    public func start_pause_performing() //Handling robot moving
    {
        if performed == false
        {
            //Move to next point if moving was stop
            performed = true
            perform_next_code()
            
            code_changed = true
        }
        else
        {
            //Pause moving if tool perform
            performed = false
        }
    }
    
    public func reset_performing() //Reset robot moving
    {
        performed = false
        target_code_index = 0
    }
    
    //MARK: - Visual build functions
    override var scene_node_name: String { "tool" }
    
    private var model_controller = ToolModelController()
    private var tool_details = [SCNNode]()
    
    override func node_by_description()
    {
        node = SCNNode()
        node?.geometry = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor.gray
        #else
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        #endif
        
        node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        node?.name = "Tool"
    }
    
    public func connect_details_nodes(_ nodes: inout [SCNNode])
    {
        
    }
    
    public func perform_operation(_ code: Int)
    {
        
    }
    
    public func workcell_connect(scene: SCNScene, name: String)
    {
        //Connect tool details
        let unit_node = scene.rootNode.childNode(withName: name, recursively: true)
        model_controller.nodes_disconnect()
        model_controller.nodes_connect(unit_node ?? SCNNode()) //(node ?? SCNNode())
        
        //Connect robot camera
        /*if connect_camera
        {
            self.camera_node = scene.rootNode.childNode(withName: "camera", recursively: true)
        }*/
        
        //Place and scale cell box
        //robot_location_place()
        //update_space_scale() //Set space scale by connected robot parameters
        //update_position() //Update robot details position on robot connection
    }
    
    public func workcell_disconnect()
    {
        model_controller.nodes_perform(code: 0)
        model_controller.nodes_disconnect()
    }
    
    //MARK: - UI functions
    #if os(macOS)
    override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #else
    override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", self.codes.count > 0 ? "\(self.codes.count) code tool" : "Static tool", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #endif
    
    public func inspector_code_color(code: OperationCode) -> Color //Get point color for inspector view
    {
        var color = Color.gray //Gray point color if the robot is not reching the code
        let code_number = self.selected_program.codes.firstIndex(of: code) //Number of selected code
        
        if performed
        {
            if code_number == target_code_index //Yellow color, if the tool is in the process of moving to the code
            {
                color = .yellow
            }
            else
            {
                if code_number ?? 0 < target_code_index //Green color, if the tool has reached this code
                {
                    color = .green
                }
            }
        }
        else
        {
            if performing_completed //Green color, if the robot has passed all points
            {
                color = .green
            }
        }
        
        return color
    }
    
    public func code_info(_ code: Int) -> (label: String, image: Image)
    {
        var image = Image("")
        
        if codes_count > 0
        {
            let info_names = codes_names[codes.firstIndex(of: code) ?? 0].components(separatedBy: "#")
            
            if info_names.count == 2
            {
                image = Image(systemName: info_names[1])
            }
            else
            {
                if info_names.count == 3
                {
                    image = Image(info_names[1])
                }
            }
            
            if info_names.count > 0
            {
                return (info_names[0], image)
            }
            else
            {
                return ("Unnamed", image)
            }
        }
        else
        {
            return ("Unnamed", image)
        }
    }
    
    private var codes_names = [String]()
    
    //MARK: - Work with file system
    public var file_info: ToolStruct
    {
        return ToolStruct(name: self.name, codes: self.codes, names: self.codes_names, scene: self.scene_address, programs: self.programs, image_data: self.image_data, module: self.module_name)
    }
}

//MARK: - Tool structure for workspace preset document handling
struct ToolStruct: Codable
{
    var name: String?
    var codes: [Int]
    var names: [String]
    
    var scene: String?
    var programs: [OperationsProgram]
    var image_data: Data
    
    var module: String?
}
