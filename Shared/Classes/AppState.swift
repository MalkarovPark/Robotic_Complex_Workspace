//
//  AppState.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 20.05.2022.
//

import Foundation
import SceneKit
import SwiftUI
import IndustrialKit

//MARK: - Class for work with various application data
class AppState : ObservableObject
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
    @Published var reset_view = false //Flag for return camera position to default in scene views
    @Published var reset_view_enabled = true //Reset menu item availability flag
    
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
    
    //Other
    @Published var get_scene_image = false //Flag for getting a snapshot of the scene view
    
    public var previewed_object: WorkspaceObject? //Part for preview view
    public var preview_update_scene = false //Flag for update previewed part node in scene
    public var object_view_was_open = false //Flag for provide model controller for model in scene
    
    @Published var view_update_state = false //Flag for update parts view grid
    @Published var add_selection = 0 //Selected item of object type for AddInWorkspace view
    
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
        
        register_colors = colors_by_seed(seed: 5433) //Generate colors for registers data view
    }
    
    //MARK: - Get additive workspace objects data from external property list
    //MARK: Data functions
    func get_additive(bookmark_data: inout Data?, url: URL?)
    {
        guard url!.startAccessingSecurityScopedResource() else
        {
            return
        }
        
        defer { url?.stopAccessingSecurityScopedResource() }
        
        do
        {
            bookmark_data = try url!.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        catch
        {
            print("Bookmark error \(error)")
        }
    }
    
    @Published var selected_plist_names: (Robots: String, Tools: String, Parts: String) = (Robots: "", Tools: "", Parts: "") //Plist names for settings view
    
    public func save_selected_plist_names(type: WorkspaceObjectType) //Save selected plist names to user defaults
    {
        switch type
        {
        case .robot:
            robots_plist_name = selected_plist_names.Robots
        case .tool:
            tools_plist_name = selected_plist_names.Tools
        case .part:
            parts_plist_name = selected_plist_names.Parts
        }
    }
    
    public var avaliable_plist_names: (Robots: [String], Tools: [String], Parts: [String]) //Plist names from bookmarked folder for settings menus
    {
        var plist_names = (Robots: [String](), Tools: [String](), Parts: [String]())
        
        //Get robot plists names
        if !(robots_empty ?? true)
        {
            plist_names.Robots = get_plist_filenames(bookmark_data: robots_bookmark)
        }
        else
        {
            plist_names.Robots = [String]()
        }
        
        //Get tools plists names
        if !(tools_empty ?? true)
        {
            plist_names.Tools = get_plist_filenames(bookmark_data: tools_bookmark)
        }
        else
        {
            plist_names.Tools = [String]()
        }
        
        //Get parts plists names
        if !(parts_empty ?? true)
        {
            plist_names.Parts = get_plist_filenames(bookmark_data: parts_bookmark)
        }
        else
        {
            plist_names.Parts = [String]()
        }
        
        func get_plist_filenames(bookmark_data: Data?) -> [String] //Return array of property list files names
        {
            var names = [String]()
            
            do
            {
                var is_stale = false
                
                for plist_url in directory_contents(url: try URL(resolvingBookmarkData: parts_bookmark ?? Data(), bookmarkDataIsStale: &is_stale))
                {
                    names.append(plist_url.lastPathComponent) //Append file name
                }
                names = names.filter{ $0.contains(".plist") } //Remove non-plist files names
                names = names.compactMap { $0.components(separatedBy: ".").first } //Remove extension from names
            }
            catch
            {
                print(error.localizedDescription)
            }
            
            return names
        }
        
        return plist_names
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
    
    public func get_defaults_plist_names(type: WorkspaceObjectType) //Pass plist names from user defaults to AppState variables
    {
        switch type
        {
        case .robot:
            selected_plist_names.Robots = robots_plist_name ?? ""
        case .tool:
            selected_plist_names.Tools = tools_plist_name ?? ""
        case .part:
            selected_plist_names.Parts = parts_plist_name ?? ""
        }
    }
    
    public func get_additive_data(type: WorkspaceObjectType) //Get and add additive dictionaries from bookmarked URL
    {
        var new_objects = Array<String>()
        
        switch type
        {
        case .robot:
            //MARK: Manufacturers data
            if !(robots_empty ?? true)
            {
                do
                {
                    //URL access by bookmark
                    var is_stale = false
                    let url = try URL(resolvingBookmarkData: robots_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
                    guard !is_stale else
                    {
                        return
                    }
                    
                    let plist_url = URL(string: url.absoluteString + selected_plist_names.Robots + ".plist") //Make file URL with extension
                    let additive_data = try Data(contentsOf: plist_url!) //Get additive data from plist
                    
                    additive_robots_dictionary = try PropertyListSerialization.propertyList(from: additive_data, options: .mutableContainers, format: nil) as? [String: [String: [String: [String: Any]]]] ?? ["String": ["String": ["String": ["String": "Any"]]]] //Convert plist data to dictionary
                    
                    //Append new elements names
                    new_objects = Array(additive_robots_dictionary.keys).sorted(by: <)
                    manufacturers.append(contentsOf: new_objects)
                    
                    //Append imported dictionary to main
                    for i in 0..<new_objects.count
                    {
                        robots_dictionary.updateValue(additive_robots_dictionary[new_objects[i]]!, forKey: new_objects[i])
                    }
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
            update_series_info()
        case .tool:
            //MARK: Tools data
            if !(tools_empty ?? true)
            {
                do
                {
                    var is_stale = false
                    let url = try URL(resolvingBookmarkData: tools_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
                    guard !is_stale else
                    {
                        return
                    }
                    
                    let plist_url = URL(string: url.absoluteString + selected_plist_names.Tools + ".plist")
                    let additive_data = try Data(contentsOf: plist_url!)
                    
                    additive_tools_dictionary = try PropertyListSerialization.propertyList(from: additive_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
                    new_objects = Array(additive_tools_dictionary.keys).sorted(by: <)
                    tools.append(contentsOf: new_objects)
                    
                    for i in 0..<new_objects.count
                    {
                        tools_dictionary.updateValue(additive_tools_dictionary[new_objects[i]]!, forKey: new_objects[i])
                    }
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
            update_tool_info()
        case .part:
            //MARK: Parts data
            if !(parts_empty ?? true)
            {
                do
                {
                    var is_stale = false
                    let url = try URL(resolvingBookmarkData: parts_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
                    guard !is_stale else
                    {
                        return
                    }
                    
                    let plist_url = URL(string: url.absoluteString + selected_plist_names.Parts + ".plist")
                    let additive_data = try Data(contentsOf: plist_url!)
                    
                    additive_parts_dictionary = try PropertyListSerialization.propertyList(from: additive_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
                    new_objects = Array(additive_parts_dictionary.keys).sorted(by: <)
                    parts.append(contentsOf: new_objects)
                    
                    for i in 0..<new_objects.count
                    {
                        parts_dictionary.updateValue(additive_parts_dictionary[new_objects[i]]!, forKey: new_objects[i])
                    }
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
            update_part_info()
        }
        
        did_updated = true
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
        
        get_additive_data(type: type)
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
                print(error.localizedDescription)
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
                print(error.localizedDescription)
            }
        }
        preview_update_scene = true
    }
    
    //MARK: - Info for settings view
    public var property_files_info: (Brands: String, Series: String, Models: String, Tools: String, Parts: String) //Count of models by object type
    {
        var brands = 0
        var series = 0
        var models = 0
        
        var tools = 0
        var parts = 0
        
        if !(robots_empty ?? true)
        {
            brands = additive_robots_dictionary.keys.count
            for key_name in additive_robots_dictionary.keys
            {
                series += additive_robots_dictionary[key_name]?.keys.count ?? 0
                
                for key_name2 in additive_robots_dictionary[key_name]!.keys
                {
                    models += additive_robots_dictionary[key_name]?[key_name2]?.keys.count ?? 0
                }
            }
        }
        
        if !(tools_empty ?? true)
        {
            tools = additive_tools_dictionary.keys.count
        }
        
        if !(parts_empty ?? true)
        {
            parts = additive_parts_dictionary.keys.count
        }
        
        return (Brands: String(brands), Series: String(series), Models: String(models), Tools: String(tools), Parts: String(parts))
    }
    
    public var selected_folder: (Robots: String, Tools: String, Parts: String) //Selected folder name for object data
    {
        var folder_names = (Robots: String(), Tools: String(), Parts: String())
        var url: URL
        
        if !(robots_empty ?? true)
        {
            do
            {
                var is_stale = false
                url = try URL(resolvingBookmarkData: robots_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                folder_names.Robots = url.lastPathComponent
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            folder_names.Robots = "None"
        }
        
        if !(tools_empty ?? true)
        {
            do
            {
                var is_stale = false
                url = try URL(resolvingBookmarkData: tools_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                folder_names.Tools = url.lastPathComponent
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            folder_names.Tools = "None"
        }
        
        if !(parts_empty ?? true)
        {
            do
            {
                var is_stale = false
                url = try URL(resolvingBookmarkData: parts_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                folder_names.Parts = url.lastPathComponent
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            folder_names.Parts = "None"
        }
        
        return folder_names
    }
    
    //MARK: - Visual functions
    func reset_camera_view_position(workspace: Workspace, view: SCNView)
    {
        if reset_view && reset_view_enabled
        {
            let reset_action = workspace.reset_view_action
            reset_view = false
            reset_view_enabled = false
            
            view.defaultCameraController.pointOfView?.runAction(
                reset_action, completionHandler: {
                    self.reset_view_enabled = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        workspace.update_view()
                    }
                })
        }
    }
    
    func reset_previewed_node_position()
    {
        clear_constranints(node: previewed_object?.node ?? SCNNode())
        
        previewed_object?.node?.position = SCNVector3(x: 0, y: 0, z: 0)
        previewed_object?.node?.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
    }
    
    //MARK: - Register colors
    public var register_colors = Array(repeating: Color.clear, count: 256)
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
            { _ in
                toggle_perform()
            }
            .onChange(of: app_state.stop_command)
            { _ in
                stop_perform()
            }
            .onAppear
            {
                app_state.reset_view = false
                app_state.reset_view_enabled = true
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
