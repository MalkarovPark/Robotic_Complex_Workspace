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
    
    @AppStorage("RobotsPlistURL") private var plist_url: URL? //Robot property list location URL from user defaults
    
    var body: some Scene
    {
        #if os(macOS)
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
        }
        Settings
        {
            SettingsView()
                .environmentObject(app_state)
        }
        #else
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document, file_name: "\(file.fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled")", file_url: file.fileURL!)
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
                    app_state.reset_view = true
                }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!app_state.reset_view_enabled) //Disable reset view item when camera is reseting
                Divider()
            }
            
            CommandGroup(after: CommandGroupPlacement.appSettings) //Application settings commands
            {
                Button("Settings...")
                {
                    app_state.settings_view_presented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
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
