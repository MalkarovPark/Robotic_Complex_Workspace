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
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    @AppStorage("AdditiveToolsData") private var additive_tools_data: Data?
    @AppStorage("AdditiveDetailsData") private var additive_details_data: Data?
    
    @Published var reset_view = false
    @Published var reset_view_enabled = true
    @Published var get_scene_image = false
    #if os(iOS)
    @Published var settings_view_presented = false
    @Published var is_compact_view = false
    public var plist_file_type: WorkspaceObjecTypes?
    #endif
    
    public var workspace_scene = SCNScene()
    public var previewed_detail: Detail?
    public var preview_update_scene = false
    
    @Published var view_update_state = false
    @Published var add_selection = 0
    
    @Published var manufacturer_name = "None" //Manufacturer's display string for the menu
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
    
    @Published var series_name = "None" //Series display string for the menu
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
    
    @Published var model_name = "None" //Display model value for menu
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
    
    @Published var tool_name = "None" //Display model value for menu
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
    
    @Published var detail_name = "None" //Display model value for menu
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
    
    //MARK: Robots models dictionaries
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    public var robot_dictionary = [String: Any]()
    
    private var additive_robots_dictionary = [String: [String: [String: [String: Any]]]]()
    
    //MARK: Names of manufacturers, series and models
    public var manufacturers: [String]
    public var series = [String]()
    public var models = [String]()
    
    private var robots_data: Data //Data store from robots property list
    private var did_updated = false //Robots data from .plist updated state
    
    //MARK: Tools and details dictionaries, names
    public var tools_dictionary = [String: [String: Any]]()
    public var tool_dictionary = [String: Any]()
    public var tools = [String]()
    
    private var tools_data: Data //Data store from robots property list
    private var additive_tools_dictionary = [String: [String: Any]]()
    
    public var details_dictionary = [String: [String: Any]]()
    public var detail_dictionary = [String: Any]()
    public var details = [String]()
    
    private var details_data: Data //Data store from robots property list
    private var additive_details_dictionary = [String: [String: Any]]()
    
    //MARK: - App State class init function
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
    public func get_additive_data()
    {
        var new_objects = Array<String>()
        
        //MARK: Manufacturers data
        do
        {
            additive_robots_dictionary = try PropertyListSerialization.propertyList(from: additive_robots_data ?? Data(), options: .mutableContainers, format: nil) as? [String: [String: [String: [String: Any]]]] ?? ["String": ["String": ["String": ["String": "Any"]]]]
            
            new_objects = Array(additive_robots_dictionary.keys).sorted(by: <)
            manufacturers.append(contentsOf: new_objects)
            
            for i in 0..<new_objects.count
            {
                robots_dictionary.updateValue(additive_robots_dictionary[new_objects[i]]!, forKey: new_objects[i])
            }
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        //MARK: Tools data
        do
        {
            additive_tools_dictionary = try PropertyListSerialization.propertyList(from: additive_tools_data ?? Data(), options: .mutableContainers, format: nil) as! [String: [String: Any]]
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
        
        //MARK: Details data
        do
        {
            additive_details_dictionary = try PropertyListSerialization.propertyList(from: additive_details_data ?? Data(), options: .mutableContainers, format: nil) as! [String: [String: Any]]
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
        
        update_series_info()
        update_tool_info()
        update_detail_info()
        
        did_updated = true
    }
    
    public func update_additive_data()
    {
        for object_type in WorkspaceObjecTypes.allCases
        {
            clear_additive_data(type: object_type)
        }
        //clear_additive_data()
        get_additive_data()
    }
    
    public func clear_additive_data(type: WorkspaceObjecTypes)
    {
        switch type
        {
        case .robot:
            robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
            manufacturers = Array(robots_dictionary.keys).sorted(by: <)
            manufacturer_name = manufacturers.first ?? "None"
        case .tool:
            tools_dictionary = try! PropertyListSerialization.propertyList(from: tools_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
            tools = Array(tools_dictionary.keys).sorted(by: <)
            tool_name = tools.first ?? "None"
        case .detail:
            details_dictionary = try! PropertyListSerialization.propertyList(from: details_data, options: .mutableContainers, format: nil) as! [String: [String: Any]]
            details = Array(details_dictionary.keys).sorted(by: <)
            detail_name = details.first ?? "None"
        }
    }
    
    //MARK: - Get info from dictionaries
    //MARK: Get robots
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
    private func update_tool_info()
    {
        tool_dictionary = tools_dictionary[tool_name]!
    }
    
    //MARK: Get details
    public func update_detail_info()
    {
        detail_dictionary = details_dictionary[detail_name]!
        previewed_detail = Detail(name: "None", dictionary: detail_dictionary)
        preview_update_scene = true
    }
    
    //MARK: - Info for settings view
    public var property_files_info: (Brands: String, Series: String, Models: String, Tools: String, Details: String)
    {
        var brands = 0
        var series = 0
        var models = 0
        
        var tools = 0
        var details = 0
        
        if additive_robots_data != nil
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
        
        if additive_tools_data != nil
        {
            tools = additive_tools_dictionary.keys.count
        }
        
        if additive_details_data != nil
        {
            details = additive_details_dictionary.keys.count
        }
        
        return (Brands: String(brands), Series: String(series), Models: String(models), Tools: String(tools), Details: String(details))
    }
}
