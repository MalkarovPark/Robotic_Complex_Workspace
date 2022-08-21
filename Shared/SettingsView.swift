//
//  SettingsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 18.08.2022.
//

import SwiftUI

struct SettingsView: View
{
    private enum Tabs: Hashable
    {
        case general, properties, advanced
    }
    
    var body: some View
    {
        TabView
        {
            GeneralSettingsView()
                .tabItem
            {
                Label("General", systemImage: "gear")
            }
            .tag(Tabs.general)
            
            PropertiesSettingsView()
                .tabItem
            {
                Label("Properties", systemImage: "doc.text")
            }
            
            AdvancedSettingsView()
                .tabItem
            {
                Label("Advanced", systemImage: "star")
            }
            .tag(Tabs.advanced)
        }
        .padding(20)
        //.frame(width: 375, height: 256)
    }
}

struct GeneralSettingsView: View
{
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    var body: some View
    {
        VStack
        {
            Form
            {
                GroupBox(label: Text("Default Values")
                            .font(.headline))
                {
                    VStack(alignment: .leading)
                    {
                        Text("Origin location")
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_x, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_x)
                        { _ in
                            Robot.default_origin_location[0] = Float(location_x)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_y, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_y)
                        { _ in
                            Robot.default_origin_location[1] = Float(location_y)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_z, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_z)
                        { _ in
                            Robot.default_origin_location[2] = Float(location_z)
                        }
                    }
                    .padding(8)
                    
                    VStack(alignment: .leading)
                    {
                        Text("Space scale")
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_x, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_x)
                        { _ in
                            Robot.default_space_scale[0] = Float(scale_x)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_y, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_y)
                        { _ in
                            Robot.default_space_scale[1] = Float(scale_y)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_z, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_z)
                        { _ in
                            Robot.default_space_scale[2] = Float(scale_z)
                        }
                    }
                    .padding(8)
                }
                .frame(width: 192)
            }
        }
    }
}

struct PropertiesSettingsView: View
{
    @AppStorage("RobotsPlistURL") private var plist_url: URL?
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        Form
        {
            VStack(alignment: .leading)
            {
                HStack
                {
                    Text("File – " + (plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                    Spacer()
                    
                    Button("Save", action: show_save_panel)
                    Button("Load", action: show_load_panel)
                }
                
                GroupBox
                {
                    VStack
                    {
                        HStack
                        {
                            VStack
                            {
                                Text(app_state.property_file_info.Brands)
                                    .foregroundColor(Color.gray)
                                Text("Brands")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.leading)
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_file_info.Series)
                                    .foregroundColor(Color.gray)
                                Text("Series")
                                    .foregroundColor(Color.gray)
                            }
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_file_info.Models)
                                    .foregroundColor(Color.gray)
                                Text("Models")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.trailing)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.vertical, 8.0)
                
                HStack
                {
                    Spacer()
                    Button("Clear Data")
                    {
                        app_state.clear_additive_data()
                        plist_url = nil
                        additive_robots_data = nil
                    }
                }
            }
        }
        .frame(width: 256)
    }
    
    func show_load_panel()
    {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["plist"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        
        plist_url = response == .OK ? openPanel.url : nil
        do
        {
            if ((plist_url?.startAccessingSecurityScopedResource()) != nil)
            {
                additive_robots_data = try Data(contentsOf: plist_url!)
                app_state.update_additive_data()
            }
        }
        catch
        {
            print ("error reading")
            print (error.localizedDescription)
        }
    }
    
    func show_save_panel()
    {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["plist"]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save your text"
        savePanel.message = "Choose a folder and a name to store your text."
        savePanel.nameFieldLabel = "File name:"
        
        let response = savePanel.runModal()
        print(response == .OK ? savePanel.url : nil)
    }
}

struct AdvancedSettingsView: View
{
    var body: some View
    {
        Form
        {
            
        }
        .padding(20)
        .frame(width: 400, height: 256)
    }
}

struct SettingsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            SettingsView()
            GeneralSettingsView()
            PropertiesSettingsView()
                .environmentObject(AppState())
            AdvancedSettingsView()
        }
    }
}
