//
//  AppState.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.05.2022.
//

import Foundation
import SceneKit
import SwiftUI
import IndustrialKit

//MARK: - Class for work with various application data
class AppState: ObservableObject
{
    //Commands
    @Published var run_command = false
    @Published var stop_command = false
    
    #if os(iOS) || os(visionOS)
    @Published var settings_view_presented = false //Flag for showing setting view for iOS and iPadOS
    #endif
    
    //Pass data
    @Published var preferences_pass_mode = false
    @Published var programs_pass_mode = false
    
    public var robot_from = Robot()
    public var robots_to_names = [String]()
    
    public var origin_location_flag = false
    public var origin_rotation_flag = false
    public var space_scale_flag = false
    
    public var passed_programs_names_list = [String]()
    
    public func clear_pass()
    {
        if preferences_pass_mode || programs_pass_mode
        {
            robot_from = Robot()
            robots_to_names.removeAll()
            
            origin_location_flag = false
            origin_rotation_flag = false
            space_scale_flag = false
            
            passed_programs_names_list = [String]()
        }
    }
    
    //Visual workspace view
    //If add in view presented or not dismissed state.
    public var add_in_view_dismissed = true
    
    //Gallery workspace view
    @Published var gallery_disabled = false
    #if os(iOS) || os(visionOS)
    @Published var locked = false //Does not allow you to make a duplicate connection to the scene caused by unknown reasons
    #endif
    
    //Other
    @Published var get_scene_image = false //Flag for getting a snapshot of the scene view
    
    public var previewed_object: WorkspaceObject? //Part for preview view
    public var preview_update_scene = false //Flag for update previewed part node in scene
    public var object_view_was_open = false //Flag for provide model pendant_controller for model in scene
    
    @Published var view_update_state = false //Flag for update parts view grid
    @Published var add_selection = 0 //Selected item of object type for AddInWorkspace view
    
    #if os(macOS)
    @Published var force_resize_view = true
    #endif
    
    @Published var previewed_robot_module_name = "None" //Displayed model string for menu
    {
        didSet
        {
            update_robot_info()
        }
    }
    
    @Published var previewed_tool_module_name = "None" //Displayed model string for menu
    {
        didSet
        {
            update_tool_info()
        }
    }
    
    @Published var previewed_part_module_name = "None" //Displayed model string for menu
    {
        didSet
        {
            update_part_info()
        }
    }
    
    private var did_updated = false //Objects data from property lists update state
    
    //MARK: - Application state init function
    init()
    {
        import_internal_modules()
        import_external_modules(bookmark: modules_folder_bookmark)
    }
    
    //MARK: - Modules handling functions
    //MARK: Internal
    @Published public var internal_modules_list: (robot: [String], tool: [String], part: [String], changer: [String]) = (robot: [], tool: [], part: [], changer: [])
    
    public func import_internal_modules()
    {
        Robot.modules = internal_modules.robot
        Tool.modules = internal_modules.tool
        Part.modules = internal_modules.part
        Changer.modules = internal_modules.changer
        
        for module in internal_modules.robot
        {
            internal_modules_list.robot.append(module.name)
        }
        
        previewed_robot_module_name = internal_modules.robot.first?.name ?? "None"
        
        for module in internal_modules.tool
        {
            internal_modules_list.tool.append(module.name)
        }
        
        previewed_tool_module_name = internal_modules.tool.first?.name ?? "None"
        
        for module in internal_modules.part
        {
            internal_modules_list.part.append(module.name)
        }
        
        previewed_part_module_name = internal_modules.part.first?.name ?? "None"
        
        for module in internal_modules.changer
        {
            internal_modules_list.changer.append(module.name)
        }
        
        Changer.internal_modules_list = internal_modules_list.changer
    }
    
    //MARK: External
    @AppStorage("ModulesFolderBookmark") private var modules_folder_bookmark: Data?
    
    public var modules_folder_url: URL? = nil
    
    @Published public var external_modules_list: (robot: [String], tool: [String], part: [String], changer: [String]) = (robot: [], tool: [], part: [], changer: [])
    
    public func update_external_modules_bookmark(url: URL?)
    {
        guard url!.startAccessingSecurityScopedResource() else
        {
            return
        }
        
        do
        {
            modules_folder_bookmark = try url!.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            //modules_folder_url = url
            import_external_modules(bookmark: modules_folder_bookmark)
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        do { url?.stopAccessingSecurityScopedResource() }
    }
    
    public func import_external_modules(bookmark: Data?)
    {
        do
        {
            var is_stale = false
            modules_folder_url = try URL(resolvingBookmarkData: bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return
            }
            
            var modules_names: [String] = []
            
            for plist_url in directory_contents(url: try URL(resolvingBookmarkData: bookmark ?? Data(), bookmarkDataIsStale: &is_stale))
            {
                modules_names.append(plist_url.lastPathComponent) //Append file name
            }
            
            external_modules_list.robot = modules_names.filter { $0.contains(".robot") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.tool = modules_names.filter { $0.contains(".tool") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.part = modules_names.filter { $0.contains(".part") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.changer = modules_names.filter { $0.contains(".changer") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            
            Changer.external_modules_list = external_modules_list.changer
            
            WorkspaceObject.modules_folder_bookmark = bookmark
            
            Robot.modules.append(contentsOf: external_robot_modules)
            Tool.modules.append(contentsOf: external_tool_modules)
            Part.modules.append(contentsOf: external_part_modules)
            Changer.modules.append(contentsOf: external_changer_modules)
        }
        catch
        {
            //print(error.localizedDescription)
        }
    }
    
    public func directory_contents(url: URL) -> [URL] //Get all files URLs from frolder url
    {
        do
        {
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        }
        catch
        {
            print(error)
            return []
        }
    }
    
    private var external_robot_modules: [RobotModule]
    {
        var modules: [RobotModule] = []
        
        for module_name in external_modules_list.robot
        {
            modules.append(RobotModule(external_name: module_name))
        }
        
        return modules
    }
    
    private var external_tool_modules: [ToolModule]
    {
        var modules: [ToolModule] = []
        
        for module_name in external_modules_list.tool
        {
            modules.append(ToolModule(external_name: module_name))
        }
        
        return modules
    }
    
    private var external_part_modules: [PartModule]
    {
        var modules: [PartModule] = []
        
        for module_name in external_modules_list.part
        {
            modules.append(PartModule(external_name: module_name))
        }
        
        return modules
    }
    
    private var external_changer_modules: [ChangerModule]
    {
        var modules: [ChangerModule] = []
        
        for module_name in external_modules_list.changer
        {
            modules.append(ChangerModule(external_name: module_name))
        }
        
        return modules
    }
    
    public func clear_modules()
    {
        modules_folder_bookmark = nil
        external_modules_list = (robot: [], tool: [], part: [], changer: [])
        
        Robot.modules.removeAll()
        Tool.modules.removeAll()
        Part.modules.removeAll()
        Changer.modules.removeAll()
        
        modules_folder_url = nil
    }
    
    //MARK: - UI Output
    public var modules_folder_name: String
    {
        return get_relative_path(from: modules_folder_url) ?? "No folder selected"
        //return modules_folder_url?.lastPathComponent ?? "<no selected>"
    }
    
    private func get_relative_path(from urlString: URL?) -> String?
    {
        if let fileURL = URL(string: urlString?.absoluteString ?? "")
        {
            let pathComponents = fileURL.pathComponents
            let filteredComponents = pathComponents.dropFirst(2)
            return filteredComponents.joined(separator: "/")
        }
        return nil
    }
    
    private func names_to_list(_ names: [String]) -> String
    {
        return "· " + names.map { $0.components(separatedBy: ".")[0] }.joined(separator: "\n· ")
    }
    
    //Internal
    
    public var internal_robot_modules_names: String
    {
        return internal_modules_list.robot.count > 0 ? names_to_list(internal_modules_list.robot) : "No Modules"
    }
    
    public var internal_tool_modules_names: String
    {
        return internal_modules_list.tool.count > 0 ? names_to_list(internal_modules_list.tool) : "No Modules"
    }
    
    public var internal_part_modules_names: String
    {
        return internal_modules_list.part.count > 0 ? names_to_list(internal_modules_list.part) : "No Modules"
    }
    
    public var internal_changer_modules_names: String
    {
        return internal_modules_list.changer.count > 0 ? names_to_list(internal_modules_list.changer) : "No Modules"
    }
    
    //External
    
    public var external_robot_modules_names: String
    {
        external_modules_list.robot.count > 0 ? names_to_list(external_modules_list.robot) : "No Modules"
    }
    
    public var external_tool_modules_names: String
    {
        external_modules_list.tool.count > 0 ? names_to_list(external_modules_list.tool) : "No Modules"
    }
    
    public var external_part_modules_names: String
    {
        external_modules_list.part.count > 0 ? names_to_list(external_modules_list.part) : "No Modules"
    }
    
    public var external_changer_modules_names: String
    {
        external_modules_list.changer.count > 0 ? names_to_list(external_modules_list.changer) : "No Modules"
    }
    
    //MARK: - Get info from dictionaries
    //MARK: Get robots
    public func update_robot_info() //Convert dictionary of models to array
    {
        //Get tool model by selected item for preview
        previewed_object = Robot(name: "None", module_name: previewed_robot_module_name)
        preview_update_scene = true
    }
    
    //MARK: Get tools
    public func update_tool_info()
    {
        //Get tool model by selected item for preview
        previewed_object = Tool(name: "None", module_name: previewed_tool_module_name)
        preview_update_scene = true
    }
    
    //MARK: Get parts
    public func update_part_info()
    {
        //Get part model by selected item for preview
        previewed_object = Part(name: "None", module_name: previewed_part_module_name)
        preview_update_scene = true
    }
    
    //MARK: - Program elements functions
    @Published var new_program_element: WorkspaceProgramElement = RobotPerformerElement()
}

//MARK: - Control modifier
struct MenuHandlingModifier: ViewModifier
{
    @EnvironmentObject var app_state: AppState
    
    @Binding var performed: Bool
    
    let toggle_perform: () -> ()
    let stop_perform: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
            .onChange(of: app_state.run_command)
            { _, _ in
                toggle_perform()
            }
            .onChange(of: app_state.stop_command)
            { _, _ in
                stop_perform()
            }
    }
}

func colors_by_seed(seed: Int) -> [Color]
{
    var colors = [Color]()

    srand48(seed)
    
    for _ in 0..<256
    {
        var color = [Double]()
        for _ in 0..<3
        {
            let random_number = Double(drand48() * Double(128) + 64)
            
            color.append(random_number)
        }
        colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
    }

    return colors
}

let registers_colors = colors_by_seed(seed: 5433)

typealias Changer = ChangerModifierElement
