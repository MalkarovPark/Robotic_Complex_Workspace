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
    // Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 200
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 0
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    // Default robot origion rotation properties from user defaults
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    // Default components resouces bookmarks
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    
    // If resources not defined
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    
    // Default count of new registers
    @AppStorage("WorkspaceRegistersCount") private var workspace_registers_count: Int = 256
    
    @Binding var document: Robotic_Complex_WorkspaceDocument // Opened document
    
    @State var first_loaded = true // Fade in workspace scene property
    
    #if !os(visionOS)
    @StateObject private var base_workspace = Workspace() // Workspace object for opened file
    #else
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    @EnvironmentObject var app_state: AppState
    
    @StateObject private var document_handler = DocumentUpdateHandler()
    
    // MARK: Main view
    var body: some View
    {
        WorkspaceNavigationView(document: $document)
        #if os(iOS) || os(visionOS)
            .navigationBarHidden(true)
        #endif
        #if !os(visionOS)
            .environmentObject(base_workspace)
        #else
            .modifier(ViewPendantButton())
            .onChange(of: pendant_controller.elements_document_data_update)
            { _, _ in
                document.preset.elements = base_workspace.file_data().elements
            }
            .onChange(of: pendant_controller.registers_document_data_update)
            { _, _ in
                document.preset.registers = base_workspace.file_data().registers
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
                update_preferences()
                base_workspace.file_view(preset: document.preset)
                #if os(macOS)
                app_state.inc_documents_count()
                #endif
            }
        #if os(macOS)
            .onDisappear
            {
                app_state.dec_documents_count()
            }
        #endif
    }
    
    private func update_preferences()
    {
        Workspace.workcell_scene_address = "Components.scnassets/Workcell.scn"
        Workspace.default_registers_count = workspace_registers_count
        
        Robot.default_origin_location[0] = Float(location_x)
        Robot.default_origin_location[1] = Float(location_y)
        Robot.default_origin_location[2] = Float(location_z)
        
        Robot.default_space_scale[0] = Float(scale_x)
        Robot.default_space_scale[1] = Float(scale_y)
        Robot.default_space_scale[2] = Float(scale_z)
    }
}

// MARK: - Previews
#Preview
{
    ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
