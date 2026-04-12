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
    
    @StateObject private var base_workspace = Workspace() // Workspace object for opened file
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    @EnvironmentObject var app_state: AppState
    
    @State private var hover_state = false
    
    // MARK: Main View
    var body: some View
    {
        WorkspaceView(document: $document)
        #if os(iOS) || os(visionOS)
            .navigationBarHidden(true)
        #endif
            .environmentObject(base_workspace)
            .task//.onAppear
            {
                /*#if os(macOS)
                app_state.inc_documents_count()
                #endif*/
                update_preferences()
                
                base_workspace.file_view(preset: document.preset)
            }
        #if os(macOS)
            .onDisappear
            {
                base_workspace.stop_robot_external_connectors()
                base_workspace.stop_tool_external_connectors()
                //app_state.dec_documents_count()
            }
        #endif
            .onHover
            { hovered in
                hover_state = hovered
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
