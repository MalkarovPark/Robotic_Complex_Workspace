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
import IndustrialKitUI

struct SettingsView: View
{
    #if os(iOS) || os(visionOS)
    @Binding var setting_view_presented: Bool
    #endif
    
    private enum Tabs: Hashable
    {
        case general, properties, cell // Settings view tab bar items
    }
    
    var body: some View
    {
        TabView
        {
            GeneralSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(SheetCaption(is_presented: $setting_view_presented, label: "General"))
            #endif
                .tabItem
            {
                Label("General", systemImage: "gear")
            }
            .tag(Tabs.general)
            
            ModulesSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(SheetCaption(is_presented: $setting_view_presented, label: "Modules"))
            #endif
                .tabItem
            {
                Label("Modules", systemImage: "puzzlepiece.extension")
            }
            
            CellSettingsView()
            #if os(iOS) || os(visionOS)
                .modifier(SheetCaption(is_presented: $setting_view_presented, label: "Cell"))
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

// MARK: - Settings view with tab bar
struct GeneralSettingsView: View
{
    @AppStorage("RepresentationType") private var representation_type: RepresentationType = .visual
    
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
                            Text("Representation")
                            
                            Spacer()
                            
                            Picker(selection: $representation_type, label: Text("Representation"))
                            {
                                ForEach(RepresentationType.allCases, id: \.self)
                                { representation in
                                    if representation != .spatial
                                    {
                                        Text(representation.rawValue).tag(representation)
                                    }
                                }
                            }
                            .labelsHidden()
                            .frame(width: 80)
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
                            Text("Default data registers count")
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
                Picker(selection: $representation_type, label: Text("Representation"))
                {
                    ForEach(RepresentationType.allCases, id: \.self)
                    { representation in
                        #if !os(visionOS)
                        if representation != .spatial
                        {
                            Text(representation.rawValue).tag(representation)
                        }
                        #else
                        Text(representation.rawValue).tag(representation)
                        #endif
                    }
                }
                .tint(.accentColor)
            }
            
            Section("Workspace")
            {
                HStack(spacing: 0)
                {
                    Text("Default data registers count")
                    
                    Spacer()
                    
                    TextField("Default data registers count", value: $workspace_registers_count, format: .number)
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

// MARK: - Modules settings view
struct ModulesSettingsView: View
{
    @EnvironmentObject var app_state: AppState
    
    @State private var folder_picker_is_presented: Bool = false
    
    #if os(macOS)
    @State private var pcm_view_presented: [Bool] = [false, false, false, false]
    
    @State private var pcm_view_hovered: [Bool] = [false, false, false, false]
    #endif
    
    var body: some View
    {
        Form
        {
            #if os(macOS)
            VStack(alignment: .leading, spacing: 0)
            {
                // MARK: External modules handling
                GroupBox(label: Text("External").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Button(action: { pcm_view_presented[0] = true })
                            {
                                VStack
                                {
                                    Text("\(app_state.external_modules_list.robot.count)")
                                        .foregroundColor(.secondary)
                                    Text("Robot")
                                        .foregroundColor(.secondary)
                                }
                                .overlay(alignment: .topTrailing)
                                {
                                    if pcm_view_hovered[0]
                                    {
                                        Image(systemName: "chevron.forward")
                                            .imageScale(.small)
                                            .foregroundStyle(.tertiary)
                                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 64)
                            .onHover
                            { hovered in
                                withAnimation
                                {
                                    pcm_view_hovered[0] = hovered
                                }
                            }
                            .popover(isPresented: $pcm_view_presented[0], arrowEdge: .trailing)
                            {
                                ProgramComponentsManagerView(module_type: .robot)
                                    .frame(width: 256, height: 384)
                            }
                            .help(app_state.external_robot_modules_names)
                            
                            Button(action: { pcm_view_presented[1] = true })
                            {
                                VStack
                                {
                                    Text("\(app_state.external_modules_list.tool.count)")
                                        .foregroundColor(.secondary)
                                    Text("Tool")
                                        .foregroundColor(.secondary)
                                }
                                .overlay(alignment: .topTrailing)
                                {
                                    if pcm_view_hovered[1]
                                    {
                                        Image(systemName: "chevron.forward")
                                            .imageScale(.small)
                                            .foregroundStyle(.tertiary)
                                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 64)
                            .onHover
                            { hovered in
                                withAnimation
                                {
                                    pcm_view_hovered[1] = hovered
                                }
                            }
                            .popover(isPresented: $pcm_view_presented[1], arrowEdge: .trailing)
                            {
                                ProgramComponentsManagerView(module_type: .tool)
                                    .frame(width: 256, height: 384)
                            }
                            .help(app_state.external_tool_modules_names)
                            
                            VStack
                            {
                                Text("\(app_state.external_modules_list.part.count)")
                                    .foregroundColor(.secondary)
                                Text("Part")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 64)
                            .help(app_state.external_part_modules_names)
                            
                            Button(action: { pcm_view_presented[3] = true })
                            {
                                VStack
                                {
                                    Text("\(app_state.external_modules_list.changer.count)")
                                        .foregroundColor(.secondary)
                                    Text("Changer")
                                        .foregroundColor(.secondary)
                                }
                                .overlay(alignment: .topTrailing)
                                {
                                    if pcm_view_hovered[3]
                                    {
                                        Image(systemName: "chevron.forward")
                                            .imageScale(.small)
                                            .foregroundStyle(.tertiary)
                                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 64)
                            .onHover
                            { hovered in
                                withAnimation
                                {
                                    pcm_view_hovered[3] = hovered
                                }
                            }
                            .popover(isPresented: $pcm_view_presented[3], arrowEdge: .trailing)
                            {
                                ProgramComponentsManagerView(module_type: .changer)
                                    .frame(width: 256, height: 384)
                            }
                            .help(app_state.external_changer_modules_names)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Text(app_state.modules_folder_name)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                .truncationMode(.head)
                                .help(app_state.modules_folder_name)
                            
                            Button(action: { folder_picker_is_presented = true })
                            {
                                Image(systemName: "folder")
                            }
                            
                            Button(action: { app_state.clear_modules() })
                            {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom)
                
                // MARK: Internal modules handling
                GroupBox(label: Text("Internal").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            VStack
                            {
                                Text("\(app_state.internal_modules_list.robot.count)")
                                    .foregroundColor(.secondary)
                                Text("Robot")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 64)
                            .help(app_state.internal_robot_modules_names)
                            
                            VStack
                            {
                                Text("\(app_state.internal_modules_list.tool.count)")
                                    .foregroundColor(.secondary)
                                Text("Tool")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 64)
                            .help(app_state.internal_tool_modules_names)
                            
                            VStack
                            {
                                Text("\(app_state.internal_modules_list.part.count)")
                                    .foregroundColor(.secondary)
                                Text("Part")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 64)
                            .help(app_state.internal_part_modules_names)
                            
                            VStack
                            {
                                Text("\(app_state.internal_modules_list.changer.count)")
                                    .foregroundColor(.secondary)
                                Text("Changer")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 64)
                            .help(app_state.internal_changer_modules_names)
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            #else
            // MARK: External modules handling
            Section(header: Text("External"))
            {
                HStack
                {
                    VStack
                    {
                        Text("\(app_state.external_modules_list.robot.count)")
                            .foregroundColor(.secondary)
                        Text("Robot")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.external_robot_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.external_modules_list.tool.count)")
                            .foregroundColor(.secondary)
                        Text("Tool")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.external_tool_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.external_modules_list.part.count)")
                            .foregroundColor(.secondary)
                        Text("Part")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.external_part_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.external_modules_list.changer.count)")
                            .foregroundColor(.secondary)
                        Text("Changer")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.external_changer_modules_names)
                }
                .padding(.horizontal)
                
                HStack(spacing: 16)
                {
                    Text("Modules Folder")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .help(app_state.modules_folder_name)
                    
                    Button(action: { folder_picker_is_presented = true })
                    {
                        Image(systemName: "folder")
                            .frame(height: 24)
                    }
                    #if !os(visionOS)
                    .modifier(ButtonBorderer())
                    #endif
                    
                    Button(action: { app_state.clear_modules() })
                    {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(height: 24)
                    }
                    #if !os(visionOS)
                    .modifier(ButtonBorderer())
                    #endif
                }
            }
            
            // MARK: Internal modules handling
            Section(header: Text("Internal"))
            {
                HStack
                {
                    VStack
                    {
                        Text("\(app_state.internal_modules_list.robot.count)")
                            .foregroundColor(.secondary)
                        Text("Robot")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.internal_robot_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.internal_modules_list.tool.count)")
                            .foregroundColor(.secondary)
                        Text("Tool")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.internal_tool_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.internal_modules_list.part.count)")
                            .foregroundColor(.secondary)
                        Text("Part")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.internal_part_modules_names)
                    Spacer()
                    
                    VStack
                    {
                        Text("\(app_state.internal_modules_list.changer.count)")
                            .foregroundColor(.secondary)
                        Text("Changer")
                            .foregroundColor(.secondary)
                    }
                    .help(app_state.internal_changer_modules_names)
                }
                .padding(.horizontal)
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 320)
        #endif
        .fileImporter(isPresented: $folder_picker_is_presented,
                              allowedContentTypes: [.folder],
                              allowsMultipleSelection: false)
        { result in
            switch result
            {
            case .success(let urls):
                if let url = urls.first
                {
                    app_state.update_external_modules_bookmark(url: url)
                }
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
        }
    }
}

// MARK: - Advanced settings view
struct CellSettingsView: View
{
    // Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 200
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 0
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    // Default robot origion rotation properties from user defaults
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
                GroupBox(label: Text("Default Parameters")
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

// MARK: - Previews
struct SettingsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            #if os(macOS)
            SettingsView()
                .environmentObject(AppState())
            
            ProgramComponentsManagerView(module_type: .robot)
                .environmentObject(AppState())
            #else
            SettingsView(setting_view_presented: .constant(true))
                .environmentObject(AppState())
            #endif
            GeneralSettingsView()
                .padding()
            ModulesSettingsView()
                .environmentObject(AppState())
                .padding()
            CellSettingsView()
        }
    }
}
