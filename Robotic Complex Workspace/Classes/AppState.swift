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
    //Bookmarks for the workspace objects model data
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    @AppStorage("ToolsBookmark") private var tools_bookmark: Data?
    @AppStorage("PartsBookmark") private var parts_bookmark: Data?
    
    //Saved names of property list files for workspace objects
    @AppStorage("RobotsPlistName") private var robots_plist_name: String?
    @AppStorage("ToolsPlistName") private var tools_plist_name: String?
    @AppStorage("PartsPlistName") private var parts_plist_name: String?
    
    //If data folder selected
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    @AppStorage("ToolsEmpty") private var tools_empty: Bool?
    @AppStorage("PartsEmpty") private var parts_empty: Bool?
    
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
    
    @Published var manufacturer_name = "None" //Manufacturer's display string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_series_info()
                did_updated = true
            }
        }
    }
    
    public var hold_card_image = UIImage() //Test hold variable
    
    @Published var series_name = "None" //Series display string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_models_info()
                did_updated = true
            }
        }
    }
    
    @Published var model_name = "None" //Displayed model string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_robot_info()
                did_updated = true
            }
        }
    }
    
    @Published var tool_name = "None" //Displayed model string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_tool_info()
                did_updated = true
            }
        }
    }
    
    @Published var part_name = "None" //Displayed model string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_part_info()
                did_updated = true
            }
        }
    }
    
    private var did_updated = false //Objects data from property lists update state
    
    //MARK: Robots models dictionaries
    private var robots_dictionary = [String: [String: [String: [String: Any]]]]()
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    public var robot_dictionary = [String: Any]()
    
    private var additive_robots_dictionary = [String: [String: [String: [String: Any]]]]()
    
    //Names of robots manufacturers, series and models
    public var manufacturers = [String]()
    public var series = [String]()
    public var models = [String]()
    
    private var robots_data: Data //Data store from robots property list
    
    //MARK: Tools dictionaries
    public var tools_dictionary = [String: [String: Any]]()
    public var tool_dictionary = [String: Any]()
    
    //Names of tools models
    public var tools = [String]()
    
    private var tools_data: Data //Data store from tools property list
    private var additive_tools_dictionary = [String: [String: Any]]() //Tools dictionary from plist file
    
    //MARK: Parts dictionaries
    public var parts_dictionary = [String: [String: Any]]()
    public var part_dictionary = [String: Any]()
    
    //Names of parts models
    public var parts = [String]()
    
    private var parts_data: Data //Data store from parts property list
    private var additive_parts_dictionary = [String: [String: Any]]() //Parts dictionary from plist file
    
    //MARK: - Application state init function
    init()
    {
        //
        //
        
        robots_data = Data()
        tools_data = Data()
        parts_data = Data()
        
        var viewed_info: URL?
        
        //Get robots data from internal propery list file
        viewed_info = Bundle.main.url(forResource: "RobotsInfo", withExtension: "plist")
        if viewed_info != nil
        {
            robots_data = try! Data(contentsOf: viewed_info!)
            
            robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]] //Convert robots data to dictionary
            
            manufacturers = Array(robots_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of robots
            manufacturer_name = manufacturers.first ?? "None" //Set first array element as selected manufacturer name
        }
        
        //Get tools data from internal propery list file
        viewed_info = Bundle.main.url(forResource: "ToolsInfo", withExtension: "plist")
        if viewed_info != nil
        {
            tools_data = try! Data(contentsOf: viewed_info!)
            
            tools_dictionary = try! PropertyListSerialization.propertyList(from: tools_data, options: .mutableContainers, format: nil) as! [String: [String: Any]] //Convert tools data to dictionary
            
            tools = Array(tools_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of tools
            tool_name = tools.first ?? "None" //Set first array element as selected tool name
        }
        
        //Get parts data from internal propery list file
        viewed_info = Bundle.main.url(forResource: "PartsInfo", withExtension: "plist")
        if viewed_info != nil
        {
            parts_data = try! Data(contentsOf: viewed_info!)
            
            parts_dictionary = try! PropertyListSerialization.propertyList(from: parts_data, options: .mutableContainers, format: nil) as! [String: [String: Any]] //Convert parts data to dictionary
            
            parts = Array(parts_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of parts
            part_name = parts.first ?? "None" //Set first array element as selected part name
        }
        
        //
        //
        
        import_internal_modules()
        import_external_modules(bookmark: modules_folder_bookmark)
    }
    
    //MARK: - Modules handling functions
    //MARK: Internal
    @Published public var internal_modules_list: [String: [String]] = [
        "Robot": [String](),
        "Tool": [String](),
        "Part": [String](),
        "Changer": [String]()
    ]
    
    public func import_internal_modules()
    {
        Robot.modules = internal_modules.robot
        Tool.modules = internal_modules.tool
        Part.modules = internal_modules.part
        ChangerModifierElement.modules = internal_modules.changer
        
        for module in internal_modules.robot
        {
            internal_modules_list["Robot"]?.append(module.name)
        }
        
        for module in internal_modules.tool
        {
            internal_modules_list["Tool"]?.append(module.name)
        }
        
        for module in internal_modules.part
        {
            internal_modules_list["Part"]?.append(module.name)
        }
        
        for module in internal_modules.changer
        {
            internal_modules_list["Changer"]?.append(module.name)
        }
    }
    
    //MARK: External
    @AppStorage("ModulesFolderBookmark") private var modules_folder_bookmark: Data?
    
    public var modules_folder_url: URL? = nil
    
    @Published public var external_modules_list: [String: [String]] = [
        "Robot": [String](),
        "Tool": [String](),
        "Part": [String](),
        "Changer": [String]()
    ]
    
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
            
            external_modules_list["Robot"] = modules_names.filter{ $0.contains(".robot") }
            external_modules_list["Tool"] = modules_names.filter{ $0.contains(".tool") }
            external_modules_list["Part"] = modules_names.filter{ $0.contains(".part") }
            external_modules_list["Changer"] = modules_names.filter{ $0.contains(".changer") }
            
            WorkspaceObject.modules_folder_bookmark = bookmark
            
            Robot.modules.append(contentsOf: external_robot_modules)
            Tool.modules.append(contentsOf: external_tool_modules)
            Part.modules.append(contentsOf: external_part_modules)
            ChangerModifierElement.modules.append(contentsOf: external_changer_modules)
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
        return [RobotModule]()
    }
    
    private var external_tool_modules: [ToolModule]
    {
        return [ToolModule]()
    }
    
    private var external_part_modules: [PartModule]
    {
        return [PartModule]()
    }
    
    private var external_changer_modules: [ChangerModule]
    {
        return [ChangerModule]()
    }
    
    public func clear_modules()
    {
        modules_folder_bookmark = nil
        
        external_modules_list.removeAll()
        Robot.modules.removeAll()
        Tool.modules.removeAll()
        Part.modules.removeAll()
        ChangerModifierElement.modules.removeAll()
        
        modules_folder_url = nil
    }
    
    //MARK: UI Output
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
        guard let names = internal_modules_list["Robot"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var internal_tool_modules_names: String
    {
        guard let names = internal_modules_list["Tool"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var internal_part_modules_names: String
    {
        guard let names = internal_modules_list["Part"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var internal_changer_modules_names: String
    {
        guard let names = internal_modules_list["Changer"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    //External
    
    public var external_robot_modules_names: String
    {
        guard let names = external_modules_list["Robot"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var external_tool_modules_names: String
    {
        guard let names = external_modules_list["Tool"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var external_part_modules_names: String
    {
        guard let names = external_modules_list["Part"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public var external_changer_modules_names: String
    {
        guard let names = external_modules_list["Changer"], !names.isEmpty else { return "No Modules" }
        return names_to_list(names)
    }
    
    public func update_additive_data(type: WorkspaceObjectType)
    {
        switch type
        {
        case .robot:
            clear_additive_data(type: type)
            robots_empty = false
        case .tool:
            clear_additive_data(type: type)
            tools_empty = false
        case .part:
            clear_additive_data(type: type)
            parts_empty = false
        }
    }
    
    public func clear_additive_data(type: WorkspaceObjectType)
    {
        switch type
        {
        case .robot:
            robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
            manufacturers = Array(robots_dictionary.keys).sorted(by: <)
            manufacturer_name = manufacturers.first ?? "None"
            robots_empty = true
        case .tool:
            tools_dictionary = try! PropertyListSerialization.propertyList(from: tools_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
            tools = Array(tools_dictionary.keys).sorted(by: <)
            tool_name = tools.first ?? "None"
            tools_empty = true
        case .part:
            parts_dictionary = try! PropertyListSerialization.propertyList(from: parts_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
            parts = Array(parts_dictionary.keys).sorted(by: <)
            part_name = parts.first ?? "None"
            parts_empty = true
        }
    }
    
    //MARK: - Get info from dictionaries
    private func update_series_info() //Convert dictionary of robots to array
    {
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        update_models_info()
    }
    
    private func update_models_info() //Convert dictionary of series to array
    {
        models_dictionary = series_dictionary[series_name]!
        models = Array(models_dictionary.keys).sorted(by: <)
        model_name = models.first ?? "None"
        
        update_robot_info()
    }
    
    private func update_robot_info() //Convert dictionary of models to array
    {
        robot_dictionary = models_dictionary[model_name]!
    }
    
    //MARK: Get tools
    public func update_tool_info()
    {
        tool_dictionary = tools_dictionary[tool_name]!
        
        //Get tool model by selected item for preview
        if tools_empty ?? true
        {
            previewed_object = Tool(name: "None", dictionary: tool_dictionary)
        }
        else
        {
            do
            {
                var is_stale = false
                let url = try URL(resolvingBookmarkData: tools_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                
                guard !is_stale else
                {
                    return
                }
                
                previewed_object = Tool(name: "None", dictionary: tool_dictionary)
            }
            catch
            {
                //print(error.localizedDescription)
            }
        }
        preview_update_scene = true
    }
    
    //MARK: Get parts
    public func update_part_info()
    {
        part_dictionary = parts_dictionary[part_name]!
        
        //Get part model by selected item for preview
        if parts_empty ?? true
        {
            previewed_object = Part(name: "None", dictionary: part_dictionary)
        }
        else
        {
            do
            {
                var is_stale = false
                let url = try URL(resolvingBookmarkData: parts_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                
                guard !is_stale else
                {
                    return
                }
                
                previewed_object = Part(name: "None", dictionary: part_dictionary)
            }
            catch
            {
                //print(error.localizedDescription)
            }
        }
        preview_update_scene = true
    }
    
    //MARK: - Program elements functions
    @Published var new_program_element: WorkspaceProgramElement = RobotPerformerElement()
}

//MARK - Control modifier
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
