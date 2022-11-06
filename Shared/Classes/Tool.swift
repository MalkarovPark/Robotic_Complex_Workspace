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
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
    }
    
    init(tool_struct: ToolStruct) //Init by detail structure
    {
        super.init(name: tool_struct.name!)
        self.scene_address = tool_struct.scene!
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
    }
    
    //MARK: - Program manage functions
    @Published private var programs = [OperationsProgram]()
    
    public var selected_program_index = 0
    {
        willSet
        {
            //Stop robot moving before program change
            performed = false
            moving_completed = false
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
    public var operation_code: Int? = -1
    {
        didSet
        {
            //Checking for positive value of operation code number
            if operation_code! >= 0
            {
                //Perform function by opcode as array number
                print("\(operation_code ?? 0) 🍩")
            }
            else
            {
                //Reset tool perfroming by negative code
                print("\(operation_code ?? 0) 🍷")
            }
        }
    }
    
    private(set) var info_code: Int? = 0
    
    public var performed: Bool //Performing state of tool
    {
        get
        {
            if operation_code ?? 0 >= 0
            {
                return true
            }
            else
            {
                return false
            }
        }
        set
        {
            if newValue
            {
                operation_code = -1
            }
        }
    }
    
    //MARK: - Moving functions
    public var move_time: Float?
    public var draw_path = false //Draw path of the robot tool point
    public var moving_completed = false //This flag set if the robot has passed all positions. Used for indication in GUI.
    public var target_code_index = 0 //Index of target point in points array
    
    //MARK: - Visual build functions
    override func node_by_description()
    {
        node = SCNNode()
        node?.geometry = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 1)
        
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor.gray
        #else
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        #endif
        
        node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        node?.name = "Tool"
    }
    
    //MARK: - UI functions
    #if os(macOS)
    override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", "Subtitle", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #else
    override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Tool")", "Subtitle", Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255), self.image)
    }
    #endif
    
    public func inspector_code_color(code: Int) -> Color //Get point color for inspector view
    {
        var color = Color.gray //Gray point color if the robot is not reching the code
        let point_number = self.selected_program.codes.firstIndex(of: code) //Number of selected code
        
        if performed
        {
            if point_number == target_code_index //Yellow color, if the tool is in the process of moving to the point
            {
                color = .yellow
            }
            else
            {
                if point_number ?? 0 < target_code_index //Green color, if the tool has reached this point
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
    public var file_info: ToolStruct
    {
        return ToolStruct(name: self.name, scene: self.scene_address, programs: self.programs, image_data: self.image_data)
    }
}

//MARK: - Tool structure for workspace preset document handling
struct ToolStruct: Codable
{
    var name: String?
    var scene: String?
    var programs: [OperationsProgram]
    var image_data: Data
}
