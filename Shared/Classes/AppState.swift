//
//  AppState.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 20.05.2022.
//

import Foundation
import SceneKit

//MARK: - Class for work with various application data
class AppState : ObservableObject
{
    @Published var reset_view = false
    @Published var get_scene_image = false
    var workspace_scene = SCNScene()
    
    var camera_light_node = SCNNode()
    
    @Published var manufacturer_name = "None"
    {
        didSet
        {
            if did_updated == true
            {
                did_updated = false
                
                update_series_info()
                
                did_updated = true
            }
        }
    }
    
    @Published var series_name = "None"
    {
        didSet
        {
            if did_updated == true
            {
                did_updated = false
                
                update_models_info()
                
                did_updated = true
            }
        }
    }
    
    @Published var model_name = "None"
    {
        didSet
        {
            if did_updated == true
            {
                update_robot_info()
            }
        }
    }
    
    //MARK: Robots models dictionaries
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    private var robot_model_dictionary = [String: Any]()
    
    //MARK: Names of manufacturers, series and models
    public var manufacturers: [String]
    public var series = [String]()
    public var models = [String]()
    
    private var robots_data: Data //Data store from robots property list
    private var did_updated = false //Robots data updated state
    
    //MARK: - App State class init function
    init()
    {
        //Get data from robots propery list file
        let url = Bundle.main.url(forResource: "RobotsInfo", withExtension: "plist")!
        robots_data = try! Data(contentsOf: url)
        
        robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
        
        //Convert dictionary of robots to array by first element
        manufacturers = Array(robots_dictionary.keys).sorted(by: <)
        manufacturer_name = manufacturers.first ?? "None"
        
        //Convert dictionary of series to array by first element
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        //Convert dictionary of models to array by first element
        models_dictionary = series_dictionary[series_name]!
        models = Array(models_dictionary.keys).sorted(by: <)
        model_name = models.first ?? "None"
        
        robot_model_dictionary = models_dictionary[model_name]!
        
        for model_parameter in robot_model_dictionary.keys
        {
            let info = robot_model_dictionary[model_parameter] ?? "None"
            //print("\(model_parameter) – \(info) 🍪")
        }
        
        did_updated = true
    }
    
    //MARK: - Get robots info from dictionaries
    private func update_series_info() //Convert dictionary of robots to array
    {
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        print(series_dictionary.keys)
        
        update_models_info()
    }
    
    private func update_models_info() //Convert dictionary of series to array
    {
        models_dictionary = series_dictionary[series_name]!
        models = Array(models_dictionary.keys).sorted(by: <)
        model_name = models.first ?? "None"
        
        //print(models_dictionary.keys)
        
        update_robot_info()
    }
    
    private func update_robot_info() //Convert dictionary of models to array
    {
        robot_model_dictionary = models_dictionary[model_name]!
        
        for model_parameter in robot_model_dictionary.keys
        {
            let info = robot_model_dictionary[model_parameter] ?? "None"
            //print("\(model_parameter) – \(info) 🍪")
        }
    }
}
