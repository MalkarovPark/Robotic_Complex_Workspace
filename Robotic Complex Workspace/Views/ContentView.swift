//
//  ContentView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 15.10.2021.
//

import SwiftUI
import IndustrialKit

struct ContentView: View
{
    //Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    //Default robot origion rotation properties from user defaults
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    //Default components resouces bookmarks
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    @AppStorage("ToolsBookmark") private var tools_bookmark: Data?
    @AppStorage("PartsBookmark") private var parts_bookmark: Data?
    
    //If resources not defined
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    @AppStorage("ToolsEmpty") private var tools_empty: Bool?
    @AppStorage("PartsEmpty") private var parts_empty: Bool?
    
    //Default count of new registers
    @AppStorage("WorkspaceRegistersCount") private var workspace_registers_count: Int = 256
    
    @Binding var document: Robotic_Complex_WorkspaceDocument //Opened document
    
    @State var first_loaded = true //Fade in workspace scene property
    
    #if !os(visionOS)
    @StateObject private var base_workspace = Workspace() //Workspace object for opened file
    #else
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    @EnvironmentObject var app_state: AppState
    
    @StateObject private var document_handler = DocumentUpdateHandler()
    
    //MARK: Main view
    @ViewBuilder var body: some View
    {
        Sidebar(document: $document)
        #if !os(visionOS)
            .environmentObject(base_workspace)
        #else
            .onChange(of: pendant_controller.elements_document_data_update)
            { _, _ in
                document.preset.elements = base_workspace.file_data().elements
            }
            .onChange(of: pendant_controller.robots_document_data_update)
            { _, _ in
                document.preset.robots = base_workspace.file_data().robots
            }
            .onChange(of: pendant_controller.tools_document_data_update)
            { _, _ in
                document.preset.tools = base_workspace.file_data().tools
            }
        #endif
            .modifier(DocumentUpdateModifier(document: $document, base_workspace: base_workspace))
            .environmentObject(document_handler)
            .onAppear
            {
                set_internal_scenes_address()
                set_selection_functions()
                get_file_data()
                update_preferences()
            }
    }
    
    private func set_internal_scenes_address()
    {
        Workspace.workcell_scene_address = "Components.scnassets/Workcell.scn"
        Workspace.default_registers_count = workspace_registers_count
        
        Robot.scene_folder = "Components.scnassets/Robots"
        Tool.scene_folder = "Components.scnassets/Tools"
        Part.scene_folder = "Components.scnassets/Parts"
    }
    
    private func set_selection_functions()
    {
        //Workspace.change_by = change_by(name: registers:)
        Workspace.changer_modules = changer_modules_names //["Module", "Module 2"]
        
        Robot.select_modules = select_robot_modules(name:model_controller:connector:)
        Tool.select_modules = select_tool_modules(name:model_controller:connector:)
    }
    
    private func get_file_data() //Store preset file data into workspace
    {
        //Pass bookmarks data into workspace for the models access
        Workspace.robots_bookmark = robots_empty ?? true ? nil : robots_bookmark
        Workspace.tools_bookmark = tools_empty ?? true ? nil : tools_bookmark
        Workspace.parts_bookmark = parts_empty ?? true ? nil : parts_bookmark
        
        base_workspace.file_view(preset: document.preset) //Get file data from document
    }
    
    private func update_preferences() //Pass default parameters from preferences
    {
        Robot.default_origin_location[0] = Float(location_x)
        Robot.default_origin_location[1] = Float(location_y)
        Robot.default_origin_location[2] = Float(location_z)
        
        Robot.default_space_scale[0] = Float(scale_x)
        Robot.default_space_scale[1] = Float(scale_y)
        Robot.default_space_scale[2] = Float(scale_z)
    }
}

//MARK: - Previews
#Preview
{
    ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
