//
//  Robotic_Complex_WorkspaceApp.swift
//  Shared
//
//  Created by Artem on 15.10.2021.
//

import SwiftUI
import SceneKit
import IndustrialKit

@main
struct Robotic_Complex_WorkspaceApp: App
{
    @StateObject var app_state = AppState() //Init application state
    
    @State var first_loaded = true //First flag for fade in workspace scene if app first loaded
    
    #if os(visionOS)
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @StateObject var base_workspace = Workspace() //Workspace object for opened file
    @StateObject var pendant_controller = PendantController()
    @StateObject var sidebar_controller = SidebarController()
    #endif
    
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document) //Pass document instance to main app view in closure
                .environmentObject(app_state)
            #if os(visionOS)
                .environmentObject(base_workspace)
                .environmentObject(pendant_controller)
                .environmentObject(sidebar_controller)
            #endif
                .onAppear
                {
                    /*if first_loaded
                    {
                        for type in WorkspaceObjectType.allCases
                        {
                            app_state.get_defaults_plist_names(type: type) //Get plist names from user defaults
                            app_state.get_additive_data(type: type) //Get models data from property lists
                        }
                        
                        first_loaded = false
                    }*/
                    
                    #if os(visionOS)
                    pendant_controller.set_windows_functions
                    {
                        openWindow(id: SPendantDefaultID)
                    }
                    _:
                    {
                        dismissWindow(id: SPendantDefaultID)
                    }
                    
                    pendant_controller.workspace = base_workspace
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        sidebar_controller.flip_workspace_selection()
                        //sidebar_controller.sidebar_selection = .WorkspaceView
                    }
                    #endif
                }
            #if os(visionOS)
                .onDisappear
                {
                    sidebar_controller.sidebar_selection = .WorkspaceView
                }
            #endif
        }
        .commands
        {
            SidebarCommands() //Sidebar control items for view menu item
            
            #if os(iOS) || os(visionOS)
            CommandGroup(after: CommandGroupPlacement.appSettings) //Application settings commands
            {
                Button("Settings...")
                {
                    app_state.settings_view_presented = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            #endif
            
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
        
        #if os(visionOS)
        SpatialPendant(controller: pendant_controller, workspace: base_workspace)
        #endif
    }
}

//MARK: - View element propeties
#if os(macOS)
let toolbar_item_placement_trailing: ToolbarItemPlacement = .automatic
let toolbar_item_placement_leading: ToolbarItemPlacement = .navigation
let quaternary_label_color: Color = Color(NSColor.quaternaryLabelColor)
#else
let toolbar_item_placement_trailing: ToolbarItemPlacement = .navigation
let toolbar_item_placement_leading: ToolbarItemPlacement = .cancellationAction
let quaternary_label_color: Color = Color(UIColor.quaternaryLabel)
#endif
