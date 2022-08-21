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
    
    @Published var reset_view = false
    @Published var reset_view_enabled = true
    @Published var get_scene_image = false
    
    public var workspace_scene = SCNScene()
    public var camera_light_node = SCNNode()
    
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
    
    //MARK: Robots models dictionaries
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    public var robot_model_dictionary = [String: Any]()
    
    private var additive_robots_dictionary = [String: [String: [String: [String: Any]]]]()
    
    //MARK: Names of manufacturers, series and models
    public var manufacturers: [String]
    public var series = [String]()
    public var models = [String]()
    
    private var robots_data: Data //Data store from robots property list
    private var did_updated = false //Robots data from .plist updated state
    
    //MARK: - App State class init function
    init()
    {
        //Get data about robots from internal propery list file
        robots_data = try! Data(contentsOf: Bundle.main.url(forResource: "RobotsInfo", withExtension: "plist")!)
        
        robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
        
        //Convert dictionary of robots to array by first element
        manufacturers = Array(robots_dictionary.keys).sorted(by: <)
        manufacturer_name = manufacturers.first ?? "None"
    }
    
    //MARK: - Get additive robots data from external property list
    public func get_additive_data()
    {
        do
        {
            additive_robots_dictionary = try PropertyListSerialization.propertyList(from: additive_robots_data ?? Data(), options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
            
            let new_manufacturers = Array(additive_robots_dictionary.keys).sorted(by: <)
            manufacturers.append(contentsOf: new_manufacturers)
            
            for i in 0..<new_manufacturers.count
            {
                robots_dictionary.updateValue(additive_robots_dictionary[new_manufacturers[i]]!, forKey: new_manufacturers[i])
            }
        }
        catch
        {
            print (error.localizedDescription)
        }
        
        update_series_info()
        did_updated = true
    }
    
    public func update_additive_data()
    {
        clear_additive_data()
        get_additive_data()
    }
    
    public func clear_additive_data()
    {
        robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
        manufacturers = Array(robots_dictionary.keys).sorted(by: <)
        manufacturer_name = manufacturers.first ?? "None"
    }
    
    //MARK: - Get robots info from dictionaries
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
        robot_model_dictionary = models_dictionary[model_name]!
    }
    
    //MARK: - Info for settings view
    public var property_file_info: (Brands: String, Series: String, Models: String)
    {
        var brands = 0
        var series = 0
        var models = 0
        
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
        
        return (Brands: String(brands), Series: String(series), Models: String(models))
    }
}
