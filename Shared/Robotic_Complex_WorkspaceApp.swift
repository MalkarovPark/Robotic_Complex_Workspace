//
//  Robotic_Complex_WorkspaceApp.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

@main
struct Robotic_Complex_WorkspaceApp: App
{
    @StateObject var app_state = AppState()
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document, file_name: "\(file.fileURL!.deletingPathExtension().lastPathComponent)")
                .environmentObject(app_state)
        }
        .commands
        {
            SidebarCommands()
            
            CommandGroup(after: CommandGroupPlacement.sidebar)
            {
                Divider()
                Button("Reset Camera")
                {
                    app_state.reset_view = true
                }
                .keyboardShortcut("r", modifiers: .command)
                Divider()
            }
        }
    }
}

class AppState : ObservableObject
{
    @Published var reset_view = false
    @Published var manufacturer_name = "None"
    {
        didSet
        {
            if did_updated == true
            {
                did_updated = false
                
                series_dictionary = robots_dictionary[manufacturer_name]!
                series = Array(series_dictionary.keys).sorted(by: <)
                series_name = series.first ?? "None"
                
                models_dictionary = series_dictionary[series_name]!
                models = Array(models_dictionary.keys).sorted(by: <)
                model_name = models.first ?? "None"
                
                print(series_dictionary.keys)
                
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
                
                models_dictionary = series_dictionary[series_name]!
                models = Array(models_dictionary.keys).sorted(by: <)
                model_name = models.first ?? "None"
                
                print(models_dictionary.keys)
                
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
                //update_robot_info()
            }
        }
    }
    
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    
    public var manufacturers: [String]
    public var series = [String]()
    public var models = [String]()
    
    private var robots_data: Data
    private var did_updated = false
    
    init()
    {
        let url = Bundle.main.url(forResource: "RobotsInfo", withExtension: "plist")!
        robots_data = try! Data(contentsOf: url)
        
        robots_dictionary = try! PropertyListSerialization.propertyList(from: robots_data, options: .mutableContainers, format: nil) as! [String: [String: [String: [String: Any]]]]
        
        manufacturers = Array(robots_dictionary.keys).sorted(by: <)
        manufacturer_name = manufacturers.first ?? "None"
        
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        models_dictionary = series_dictionary[series_name]!
        models = Array(models_dictionary.keys).sorted(by: <)
        model_name = models.first ?? "None"
        
        did_updated = true
        
        //print(manufacturers)
        
        //let series_dictionary = robots_dictionary["ABB"]
        //print(series_dictionary)
        //print(robots_dictionary.keys)
        
        /*for manufacturer_name in robots_dictionary.keys
        {
            let series_dictionary = (robots_dictionary as AnyObject).object(forKey: manufacturer_name) as! NSDictionary
            
            //print("Series of \(manufacturer_name) robots:")
            
            for series_name in series_dictionary.allKeys
            {
                print("  Models of \(series_name):")
                let models_dictionary = (series_dictionary as AnyObject).object(forKey: series_name) as! NSDictionary
                
                //print(models_dictionary.allKeys)
                
                for model_name in models_dictionary.allKeys
                {
                    print("    \(model_name)")
                    
                    let current_model_dictionary = (models_dictionary as AnyObject).object(forKey: model_name) as! NSDictionary
                    
                    //print(current_model_dictionary.allKeys)
                    
                    for model_parameter in current_model_dictionary.allKeys
                    {
                        let parameter_name_info = (current_model_dictionary as AnyObject).object(forKey: model_parameter) as? String
                        /*guard let parameter_name_info = (current_model_dictionary as AnyObject).object(forKey: model_parameter) as? String
                                else
                                {
                                    return
                                }*/
                        print("      Named – \(parameter_name_info ?? "None")")
                    }
                }
            }
        }*/
    }
    
    /*func update_robot_info()
    {
        did_updated = false
        
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        print(series_dictionary.keys)
        
        did_updated = true
    }*/
}
