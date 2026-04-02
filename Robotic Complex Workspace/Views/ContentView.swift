//
//  ContentView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 15.10.2021.
//

import SwiftUI
import IndustrialKit
#if os(visionOS)
import IndustrialKitUI
#endif

struct ContentView: View
{
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
    
    @State private var hover_state = false
    
    // MARK: Main view
    var body: some View
    {
        WorkspaceView(document: $document)
        #if os(iOS) || os(visionOS)
            .navigationBarHidden(true)
        #endif
        //#if !os(visionOS)
            .environmentObject(base_workspace)
        #if os(visionOS)
            .modifier(ViewPendantButton())
        #endif
        /*#else
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
        #endif*/
            .modifier(DocumentUpdateModifier(document: $document, base_workspace: base_workspace))
            .environmentObject(document_handler)
            .task//.onAppear
            {
                #if os(macOS)
                app_state.inc_documents_count()
                #endif
                update_preferences()
                
                base_workspace.file_view(preset: document.preset)
            }
        #if os(macOS)
            .onDisappear
            {
                base_workspace.stop_robot_external_connectors()
                base_workspace.stop_tool_external_connectors()
                app_state.dec_documents_count()
            }
        #endif
            .onHover
            { hovered in
                hover_state = hovered
                //app_state.apply_command_functions(by: base_workspace)
            }
            .onChange(of: hover_state)
            { _, new_value in
                if new_value
                {
                    app_state.apply_command_functions(by: base_workspace)
                }
            }
    }
    
    private func update_preferences()
    {
        Workspace.default_registers_count = workspace_registers_count
    }
}

// MARK: - Previews
#Preview
{
    ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
