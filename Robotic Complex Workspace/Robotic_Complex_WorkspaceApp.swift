//
//  Robotic_Complex_WorkspaceApp.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI
import SceneKit
import IndustrialKit

@main
struct Robotic_Complex_WorkspaceApp: App
{
    @StateObject var app_state = AppState() //Init application state
    @State var first_loaded = true //First flag for fade in workspace scene if app first loaded
    
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document) //Pass document instance to main app view in closure
                .environmentObject(app_state)
                .onAppear
                {
                    if first_loaded
                    {
                        for type in WorkspaceObjectType.allCases
                        {
                            app_state.get_defaults_plist_names(type: type) //Get plist names from user defaults
                            app_state.get_additive_data(type: type) //Get models data from property lists
                        }
                        
                        first_loaded = false
                    }
                }
        }
        .commands
        {
            SidebarCommands() //Sidebar control items for view menu item
            
            CommandGroup(after: CommandGroupPlacement.sidebar) //View commands for view menu item
            {
                Divider()
                Button("Reset Camera")
                {
                    app_state.reset_view = true //Begin reset camera process
                }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!app_state.reset_view_enabled) //Disable reset view item when camera is reseting
                Divider()
            }
            
            CommandMenu("Performing")
            {
                Button("Run/Pause")
                {
                    app_state.run_command.toggle()
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Button("Stop")
                {
                    app_state.stop_command.toggle()
                }
                .keyboardShortcut(".", modifiers: .command)
            }
        }
        #if os(macOS)
        Settings
        {
            SettingsView()
                .environmentObject(app_state)
        }
        #endif
    }
}

//MARK: - View element propeties
#if os(macOS)
let placement_trailing: ToolbarItemPlacement = .automatic
let quaternary_label_color: Color = Color(NSColor.quaternaryLabelColor)
#else
let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
let quaternary_label_color: Color = Color(UIColor.quaternaryLabel)
#endif
