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
            file in ContentView(file_name: "\(file.fileURL!.deletingPathExtension().lastPathComponent)", document: file.$document)
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
    
    private var robots_dictionary: [String: [String: [String: [String: Any]]]]
    private var series_dictionary = [String: [String: [String: Any]]]()
    private var models_dictionary = [String: [String: Any]]()
    private var robot_model_dictionary = [String: Any]()
    
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
        
        robot_model_dictionary = models_dictionary[model_name]!
        
        for model_parameter in robot_model_dictionary.keys
        {
            let info = robot_model_dictionary[model_parameter] ?? "None"
            print("\(model_parameter) – \(info) 🍪")
        }
        
        did_updated = true
    }
    
    private func update_series_info()
    {
        series_dictionary = robots_dictionary[manufacturer_name]!
        series = Array(series_dictionary.keys).sorted(by: <)
        series_name = series.first ?? "None"
        
        print(series_dictionary.keys)
        
        update_models_info()
    }
    
    private func update_models_info()
    {
        models_dictionary = series_dictionary[series_name]!
        models = Array(models_dictionary.keys).sorted(by: <)
        model_name = models.first ?? "None"
        
        print(models_dictionary.keys)
        
        update_robot_info()
    }
    
    private func update_robot_info()
    {
        robot_model_dictionary = models_dictionary[model_name]!
        
        for model_parameter in robot_model_dictionary.keys
        {
            let info = robot_model_dictionary[model_parameter] ?? "None"
            print("\(model_parameter) – \(info) 🍪")
        }
    }
}
