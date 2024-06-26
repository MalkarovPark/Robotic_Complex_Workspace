//
//  SettingsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 18.08.2022.
//

import SwiftUI
#if os(iOS) || os(visionOS)
import UniformTypeIdentifiers
#endif
import IndustrialKit

struct SettingsView: View
{
    #if os(iOS) || os(visionOS)
    @Binding var setting_view_presented: Bool
    #endif
    
    private enum Tabs: Hashable
    {
        case general, properties, cell //Settings view tab bar items
    }
    
    var body: some View
    {
        TabView
        {
            GeneralSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(Caption(is_presented: $setting_view_presented, label: "General"))
            #endif
                .tabItem
            {
                Label("General", systemImage: "gear")
            }
            .tag(Tabs.general)
            
            PropertiesSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(Caption(is_presented: $setting_view_presented, label: "Properties"))
            #endif
                .tabItem
            {
                Label("Properties", systemImage: "doc.text")
            }
            
            CellSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(Caption(is_presented: $setting_view_presented, label: "Cell"))
            #endif
                .tabItem
            {
                Label("Cell", systemImage: "cube.transparent")
            }
            .tag(Tabs.cell)
        }
        #if os(macOS)
        .padding(20)
        #endif
    }
}

#if os(iOS) || os(visionOS)
struct Caption: ViewModifier
{
    @Binding var is_presented: Bool
    
    let label: String
    
    func body(content: Content) -> some View
    {
        VStack(spacing: 0)
        {
            ZStack
            {
                HStack(alignment: .center)
                {
                    Text(label)
                        .padding(0)
                    #if os(visionOS)
                        .font(.title2)
                        .padding(.vertical)
                    #endif
                }
                
                HStack(spacing: 0)
                {
                    Button(action: { is_presented = false })
                    {
                        Image(systemName: "xmark")
                    }
                    .keyboardShortcut(.cancelAction)
                    #if !os(visionOS)
                    .buttonStyle(.borderless)
                    .controlSize(.extraLarge)
                    #else
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    #endif
                    .padding()
                    
                    Spacer()
                }
            }
            
            #if !os(visionOS)
            Divider()
            #endif
            
            content
        }
    }
}
#endif

//MARK: - Settings view with tab bar
struct GeneralSettingsView: View
{
    @AppStorage("WorkspaceVisualModeling") private var workspace_visual_modeling: Bool = true
    
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @AppStorage("WorkspaceRegistersCount") private var workspace_registers_count: Int = 256
    
    #if os(visionOS)
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var sidebar_controller: SidebarController
    #endif
    
    var body: some View
    {
        Form
        {
            #if os(macOS)
            VStack(alignment: .leading, spacing: 0)
            {
                GroupBox(label: Text("View").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Use visual modeling for workspace")
                            
                            Spacer()
                            
                            Toggle("Visual", isOn: $workspace_visual_modeling)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    Divider()
                    
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Store robots previews")
                            
                            Spacer()
                            
                            Toggle("Visual", isOn: $workspace_images_store)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom)
                
                GroupBox(label: Text("Workspace").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Default registers count")
                                .frame(alignment: .leading)
                            
                            Spacer()
                            
                            TextField("", value: $workspace_registers_count, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                                .frame(width: 48)
                            
                            Stepper("", value: $workspace_registers_count, in: 1...1000)
                                .labelsHidden()
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            #else
            Section("View")
            {
                Toggle("Use visual modeling for workspace", isOn: $workspace_visual_modeling)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
                
                Toggle("Store robots previews", isOn: $workspace_images_store)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
            }
            #if os(visionOS)
            .onChange(of: workspace_visual_modeling)
            { _, new_value in
                if new_value
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        sidebar_controller.sidebar_selection = nil
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                        {
                            sidebar_controller.sidebar_selection = .WorkspaceView
                        }
                    }
                }
            }
            #endif
            
            Section("Workspace")
            {
                HStack(spacing: 0)
                {
                    Text("Default registers count")
                    
                    Spacer()
                    
                    TextField("Default registers count", value: $workspace_registers_count, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .frame(width: 64)
                        .padding(.trailing, 8)
                    
                    Stepper("", value: $workspace_registers_count, in: 1...1000)
                        .labelsHidden()
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 300)//, height: 256)
        #endif
    }
}

//MARK: - Property list settings view
struct PropertiesSettingsView: View
{
    //Bookmarks for the workspace objects model data
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    @AppStorage("ToolsBookmark") private var tools_bookmark: Data?
    @AppStorage("PartsBookmark") private var parts_bookmark: Data?
    
    //If data folder selected
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    @AppStorage("ToolsEmpty") private var tools_empty: Bool?
    @AppStorage("PartsEmpty") private var parts_empty: Bool?
    
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @State private var clear_message_presented = false
    #endif
    @State private var load_panel_presented = false
    @State private var folder_selection_type: WorkspaceObjectType = .robot
    
    var body: some View
    {
        Form
        {
            #if os(macOS)
            VStack(alignment: .leading, spacing: 0)
            {
                //MARK: Robots data handling view
                GroupBox(label: Text("Robots").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            VStack
                            {
                                Text(app_state.property_files_info.Brands)
                                    .foregroundColor(Color.gray)
                                Text("Brands")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.leading)
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_files_info.Series)
                                    .foregroundColor(Color.gray)
                                Text("Series")
                                    .foregroundColor(Color.gray)
                            }
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_files_info.Models)
                                    .foregroundColor(Color.gray)
                                Text("Models")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.trailing)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Picker(selection: $app_state.selected_plist_names.Robots, label: Text(app_state.selected_folder.Robots)
                                    .bold())
                            {
                                ForEach(app_state.avaliable_plist_names.Robots, id: \.self)
                                {
                                    Text($0)
                                }
                            }
                            .onChange(of: app_state.selected_plist_names.Robots)
                            { _, _ in
                                app_state.update_additive_data(type: .robot)
                                app_state.save_selected_plist_names(type: .robot)
                            }
                            .disabled(robots_empty ?? true)
                            
                            Spacer()
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .robot)
                            })
                            {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            Button(action: { show_load_panel(type: .robot) })
                            {
                                Image(systemName: "folder")
                            }
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom)
                
                //MARK: Tools data handling view
                GroupBox
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Tools")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text("–")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text(app_state.property_files_info.Tools)
                                .foregroundColor(Color.gray)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Picker(selection: $app_state.selected_plist_names.Tools, label: Text(app_state.selected_folder.Tools)
                                    .bold())
                            {
                                ForEach(app_state.avaliable_plist_names.Tools, id: \.self)
                                {
                                    Text($0)
                                }
                            }
                            .onChange(of: app_state.selected_plist_names.Tools)
                            { _, _ in
                                app_state.update_additive_data(type: .tool)
                                app_state.save_selected_plist_names(type: .tool)
                            }
                            .disabled(tools_empty ?? true)
                            
                            Spacer()
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .tool
                                )
                            })
                            {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            Button(action: { show_load_panel(type: .tool) })
                            {
                                Image(systemName: "folder")
                            }
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom)
                
                //MARK: Parts data handling view
                GroupBox
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Parts")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text("–")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text(app_state.property_files_info.Parts)
                                .foregroundColor(Color.gray)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Picker(selection: $app_state.selected_plist_names.Parts, label: Text(app_state.selected_folder.Parts)
                                    .bold())
                            {
                                ForEach(app_state.avaliable_plist_names.Parts, id: \.self)
                                {
                                    Text($0)
                                }
                            }
                            .onChange(of: app_state.selected_plist_names.Parts)
                            { _, _ in
                                app_state.update_additive_data(type: .part)
                                app_state.save_selected_plist_names(type: .part)
                            }
                            .disabled(parts_empty ?? true)
                            
                            Spacer()
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .part)
                            })
                            {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            Button(action: { show_load_panel(type: .part) })
                            {
                                Image(systemName: "folder")
                            }
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            #else
            //MARK: Robots data handling view
            Section(header: Text("Robots"))
            {
                HStack
                {
                    VStack
                    {
                        Text(app_state.property_files_info.Brands)
                            .foregroundColor(Color.gray)
                        Text("Brands")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.leading)
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.property_files_info.Series)
                            .foregroundColor(Color.gray)
                        Text("Series")
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.property_files_info.Models)
                            .foregroundColor(Color.gray)
                        Text("Models")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.trailing)
                }
                
                HStack
                {
                    if !(robots_empty ?? true)
                    {
                        Picker(selection: $app_state.selected_plist_names.Robots, label: Text(app_state.selected_folder.Robots)
                                .bold())
                        {
                            ForEach(app_state.avaliable_plist_names.Robots, id: \.self)
                            {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: app_state.selected_plist_names.Robots)
                        { _, _ in
                            app_state.update_additive_data(type: .robot)
                            app_state.save_selected_plist_names(type: .robot)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { show_load_panel(type: .robot) })
                    {
                        Image(systemName: "folder")
                    }
                }
            }
            
            //MARK: Tools data handling view
            Section
            {
                HStack
                {
                    Text("Tools")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text("–")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text(app_state.property_files_info.Tools)
                        .foregroundColor(Color.gray)
                }
                
                HStack
                {
                    if !(tools_empty ?? true)
                    {
                        Picker(selection: $app_state.selected_plist_names.Tools, label: Text(app_state.selected_folder.Tools)
                                .bold())
                        {
                            ForEach(app_state.avaliable_plist_names.Tools, id: \.self)
                            {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: app_state.selected_plist_names.Tools)
                        { _, _ in
                            app_state.update_additive_data(type: .tool)
                            app_state.save_selected_plist_names(type: .tool)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { show_load_panel(type: .tool) })
                    {
                        Image(systemName: "folder")
                    }
                }
            }
            
            //MARK: Parts data handling view
            Section
            {
                HStack
                {
                    Text("Parts")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text("–")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text(app_state.property_files_info.Parts)
                        .foregroundColor(Color.gray)
                }
                
                HStack
                {
                    if !(parts_empty ?? true)
                    {
                        Picker(selection: $app_state.selected_plist_names.Parts, label: Text(app_state.selected_folder.Parts)
                                .bold())
                        {
                            ForEach(app_state.avaliable_plist_names.Parts, id: \.self)
                            {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: app_state.selected_plist_names.Parts)
                        { _, _ in
                            app_state.update_additive_data(type: .part)
                            app_state.save_selected_plist_names(type: .part)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { show_load_panel(type: .part) })
                    {
                        Image(systemName: "folder")
                    }
                }
            }
            
            //Clear data elements
            Button("Clear", role: .destructive)
            {
                clear_message_presented = true
            }
            .confirmationDialog(Text("None"), isPresented: $clear_message_presented)
            {
                Button("Robots")
                {
                    app_state.clear_additive_data(type: .robot)
                }
                Button("Tools")
                {
                    app_state.clear_additive_data(type: .tool)
                }
                Button("Parts")
                {
                    app_state.clear_additive_data(type: .part)
                }
                Button("Cancel", role: .cancel) { }
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 256)
        #endif
        .onAppear
        {
            //Get plist names from user defults
            for type in WorkspaceObjectType.allCases
            {
                app_state.get_defaults_plist_names(type: type) //Get plist names from user defaults
            }
        }
        .fileImporter(isPresented: $load_panel_presented,
                              allowedContentTypes: [.folder],
                              allowsMultipleSelection: true)
        { result in
            switch result
            {
            case .success(let success):
                switch folder_selection_type
                {
                case .robot:
                    app_state.get_additive(bookmark_data: &robots_bookmark, url: success.first)
                    app_state.update_additive_data(type: .robot)
                    robots_empty = false
                case .tool:
                    app_state.get_additive(bookmark_data: &tools_bookmark, url: success.first)
                    app_state.update_additive_data(type: .tool)
                    tools_empty = false
                case .part:
                    app_state.get_additive(bookmark_data: &parts_bookmark, url: success.first)
                    app_state.update_additive_data(type: .part)
                    parts_empty = false
                }
            case .failure(_):
                break
            }
        }
    }
    
    //MARK: Save and load dialogs
    func show_load_panel(type: WorkspaceObjectType)
    {
        folder_selection_type = type
        load_panel_presented = true
    }
}

//MARK: - Advanced settings view
struct CellSettingsView: View
{
    //Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    //Default robot origion rotation properties from user defaults
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    var body: some View
    {
        VStack
        {
            Form
            {
                #if os(macOS)
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
                                .frame(width: 20)
                            TextField("0", value: $location_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_x, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_x)
                        { _, new_value in
                            Robot.default_origin_location[0] = Float(new_value)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20)
                            TextField("0", value: $location_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_y, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_y)
                        { _, new_value in
                            Robot.default_origin_location[1] = Float(new_value)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20)
                            TextField("0", value: $location_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_z, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_z)
                        { _, new_value in
                            Robot.default_origin_location[2] = Float(new_value)
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
                                .frame(width: 20)
                            TextField("0", value: $scale_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_x, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_x)
                        { _, new_value in
                            Robot.default_space_scale[0] = Float(new_value)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20)
                            TextField("0", value: $scale_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_y, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_y)
                        { _, new_value in
                            Robot.default_space_scale[1] = Float(new_value)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20)
                            TextField("0", value: $scale_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_z, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_z)
                        { _, new_value in
                            Robot.default_space_scale[2] = Float(new_value)
                        }
                    }
                    .padding(8)
                }
                .frame(width: 192)
                #else
                Section(header: Text("Origin location"))
                {
                    HStack(spacing: 8)
                    {
                        Text("X:")
                            .frame(width: 20)
                        TextField("0", value: $location_x, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_x, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_x)
                    { _, new_value in
                        Robot.default_origin_location[0] = Float(new_value)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y:")
                            .frame(width: 20)
                        TextField("0", value: $location_y, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_y, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_y)
                    { _, new_value in
                        Robot.default_origin_location[1] = Float(new_value)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z:")
                            .frame(width: 20)
                        TextField("0", value: $location_z, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_z, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_z)
                    { _, new_value in
                        Robot.default_origin_location[2] = Float(new_value)
                    }
                }
                
                Section(header: Text("Space scale"))
                {
                    HStack(spacing: 8)
                    {
                        Text("X:")
                            .frame(width: 20)
                        TextField("0", value: $scale_x, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_x, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_x)
                    { _, new_value in
                        Robot.default_space_scale[0] = Float(new_value)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y:")
                            .frame(width: 20)
                        TextField("0", value: $scale_y, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_y, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_y)
                    { _, new_value in
                        Robot.default_space_scale[1] = Float(new_value)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z:")
                            .frame(width: 20)
                        TextField("0", value: $scale_z, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_z, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_z)
                    { _, new_value in
                        Robot.default_space_scale[2] = Float(new_value)
                    }
                }
                #endif
            }
        }
    }
}

//MARK: - Previews
struct SettingsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            #if os(macOS)
            SettingsView()
                .environmentObject(AppState())
            #else
            SettingsView(setting_view_presented: .constant(true))
                .environmentObject(AppState())
            #endif
            GeneralSettingsView()
            PropertiesSettingsView()
                .environmentObject(AppState())
            CellSettingsView()
        }
    }
}
