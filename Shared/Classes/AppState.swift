//
//  AppState.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 20.05.2022.
//

import Foundation
import SceneKit
import SwiftUI

//MARK: - Class for work with various application data
class AppState : ObservableObject
{
    //Bookmarks for the workspace objects model data
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    @AppStorage("ToolsBookmark") private var tools_bookmark: Data?
    @AppStorage("DetailsBookmark") private var details_bookmark: Data?
    
    //Saved names of property list files for workspace objects
    @AppStorage("RobotsPlistName") private var robots_plist_name: String?
    @AppStorage("ToolsPlistName") private var tools_plist_name: String?
    @AppStorage("DetailsPlistName") private var details_plist_name: String?
    
    //If data folder selected
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    @AppStorage("ToolsEmpty") private var tools_empty: Bool?
    @AppStorage("DetailsEmpty") private var details_empty: Bool?
    
    @Published var reset_view = false //Flag for return camera position to default in scene views
    @Published var reset_view_enabled = true //Reset menu item availability flag
    @Published var get_scene_image = false //Flag for getting a snapshot of the scene view
    #if os(iOS)
    @Published var settings_view_presented = false //Flag for showing setting view for iOS and iPadOS
    #endif
    
    public var previewed_object: WorkspaceObject? //Detail for preview view
    public var preview_update_scene = false //Flag for update previewed detail node in scene
    public var object_view_was_open = false //Flag for provide model controller for model in scene
    
    @Published var view_update_state = false //Flag for update details view grid
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
    
    @Published var detail_name = "None" //Displayed model string for menu
    {
        didSet
        {
            if did_updated
            {
                did_updated = false
                update_detail_info()
                did_updated = true
            }
        }
    }
    
    private var did_updated = false //Objects data from property lists update state
    
    //MARK: Robots models dictionaries
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    public var robot_dictionary = [String: Any]()
    
    private var additive_robots_dictionary = [String: [String: [String: [String: Any]]]]()
    
    //Names of robots manufacturers, series and models
    public var manufacturers: [String]
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
    
    //MARK: Details dictionaries
    public var details_dictionary = [String: [String: Any]]()
    public var detail_dictionary = [String: Any]()
    
    //Names of details models
    public var details = [String]()
    
    private var details_data: Data //Data store from details property list
    private var additive_details_dictionary = [String: [String: Any]]() //Details dictionary from plist file
    
    //MARK: - Application state init function
    init()
    {
        //Get robots data from internal propery list file
        robots_data = try! Data(contentsOf: Bundle.main.url(forResource: "RobotsInfo", withExtension: "plist")!)
        
        robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]] //Convert robots data to dictionary
        
        manufacturers = Array(robots_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of robots
        manufacturer_name = manufacturers.first ?? "None" //Set first array element as selected manufacturer name
        
        //Get details data from internal propery list file
        tools_data = try! Data(contentsOf: Bundle.main.url(forResource: "ToolsInfo", withExtension: "plist")!)
        
        tools_dictionary = try! PropertyListSerialization.propertyList(from: tools_data, options: .mutableContainers, format: nil) as! [String: [String: Any]] //Convert tools data to dictionary
        
        tools = Array(tools_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of tools
        tool_name = tools.first ?? "None" //Set first array element as selected tool name
        
        //Get tools data from internal propery list file
        details_data = try! Data(contentsOf: Bundle.main.url(forResource: "DetailsInfo", withExtension: "plist")!)
        
        details_dictionary = try! PropertyListSerialization.propertyList(from: details_data, options: .mutableContainers, format: nil) as! [String: [String: Any]] //Convert details data to dictionary
        
        details = Array(details_dictionary.keys).sorted(by: <) //Get names array ordered by first element from dictionary of details
        detail_name = details.first ?? "None" //Set first array element as selected detail name
    }
    
    //MARK: - Get additive robots data from external property list
    //MARK: Data functions
    func get_additive(bookmark_data: inout Data?, url: URL?)
    {
        guard url!.startAccessingSecurityScopedResource() else
        {
            return
        }
        
        // Make sure you release the security-scoped resource when you finish.
        defer { url?.stopAccessingSecurityScopedResource() }
        
        do
        {
            //Make sure the bookmark is minimal!
            bookmark_data = try url!.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        catch
        {
            print("Bookmark error \(error)")
        }
    }
    
    @Published var selected_plist_names: (Robots: String, Tools: String, Details: String) = (Robots: "", Tools: "", Details: "") //Plist names for settings view
    
    public func save_selected_plist_names(type: WorkspaceObjectType) //Save selected plist names to user defaults
    {
        switch type
        {
        case .robot:
            robots_plist_name = selected_plist_names.Robots
        case .tool:
            tools_plist_name = selected_plist_names.Tools
        case .detail:
            details_plist_name = selected_plist_names.Details
        }
    }
    
    public var avaliable_plist_names: (Robots: [String], Tools: [String], Details: [String]) //Plist names from bookmarked folder for settings menus
    {
        var plist_names = (Robots: [String](), Tools: [String](), Details: [String]())
        
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
        
        //Get details plists names
        if !(details_empty ?? true)
        {
            plist_names.Details = get_plist_filenames(bookmark_data: details_bookmark)
        }
        else
        {
            plist_names.Details = [String]()
        }
        
        func get_plist_filenames(bookmark_data: Data?) -> [String] //Return array of property list files names
        {
            var names = [String]()
            
            do
            {
                var is_stale = false
                
                for plist_url in directory_contents(url: try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale))
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
        case .detail:
            selected_plist_names.Details = details_plist_name ?? ""
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
                    let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
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
                    let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
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
        case .detail:
            //MARK: Details data
            if !(details_empty ?? true)
            {
                do
                {
                    var is_stale = false
                    let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
                    guard !is_stale else
                    {
                        return
                    }
                    
                    let plist_url = URL(string: url.absoluteString + selected_plist_names.Details + ".plist")
                    let additive_data = try Data(contentsOf: plist_url!)
                    
                    additive_details_dictionary = try PropertyListSerialization.propertyList(from: additive_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
                    new_objects = Array(additive_details_dictionary.keys).sorted(by: <)
                    details.append(contentsOf: new_objects)
                    
                    for i in 0..<new_objects.count
                    {
                        details_dictionary.updateValue(additive_details_dictionary[new_objects[i]]!, forKey: new_objects[i])
                    }
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
            update_detail_info()
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
        case .detail:
            clear_additive_data(type: type)
            details_empty = false
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
        case .detail:
            details_dictionary = try! PropertyListSerialization.propertyList(from: details_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
            details = Array(details_dictionary.keys).sorted(by: <)
            detail_name = details.first ?? "None"
            details_empty = true
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
            previewed_object = Detail(name: "None")
        }
        else
        {
            do
            {
                var is_stale = false
                let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                
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
    
    //MARK: Get details
    public func update_detail_info()
    {
        detail_dictionary = details_dictionary[detail_name]!
        
        //Get detail model by selected item for preview
        if details_empty ?? true
        {
            previewed_object = Detail(name: "None")
        }
        else
        {
            do
            {
                var is_stale = false
                let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                
                guard !is_stale else
                {
                    return
                }
                
                previewed_object = Detail(name: "None", dictionary: detail_dictionary)
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        preview_update_scene = true
    }
    
    //MARK: - Info for settings view
    public var property_files_info: (Brands: String, Series: String, Models: String, Tools: String, Details: String) //Count of models by object type
    {
        var brands = 0
        var series = 0
        var models = 0
        
        var tools = 0
        var details = 0
        
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
        
        if !(details_empty ?? true)
        {
            details = additive_details_dictionary.keys.count
        }
        
        return (Brands: String(brands), Series: String(series), Models: String(models), Tools: String(tools), Details: String(details))
    }
    
    public var selected_folder: (Robots: String, Tools: String, Details: String) //Selected folder name for object data
    {
        var folder_names = (Robots: String(), Tools: String(), Details: String())
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
        
        if !(details_empty ?? true)
        {
            do
            {
                var is_stale = false
                url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                folder_names.Details = url.lastPathComponent
            }
            catch
            {
                print(error.localizedDescription)
            }
        }
        else
        {
            folder_names.Details = "None"
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
}
