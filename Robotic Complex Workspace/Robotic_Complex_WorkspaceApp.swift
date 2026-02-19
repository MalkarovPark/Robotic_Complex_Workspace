//
//  Robotic_Complex_WorkspaceApp.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 15.10.2021.
//

import SwiftUI
import SceneKit
import IndustrialKit
#if os(visionOS)
import IndustrialKitUI
#endif

@main
struct Robotic_Complex_WorkspaceApp: App
{
    @StateObject var app_state = AppState() // Init application state
    
    #if os(visionOS)
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @StateObject var base_workspace = Workspace() // Workspace object for opened file
    @StateObject var pendant_controller = PendantController()
    #endif
    
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        { file in
            ContentView(document: file.$document) // Pass document instance to main app view in closure
                .environmentObject(app_state)
            #if os(macOS)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            #endif
            #if os(visionOS)
                .environmentObject(base_workspace)
                .environmentObject(pendant_controller)
                .onAppear
                {
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
                    #endif
                }
            #endif
        }
        .commands
        {
            SidebarCommands() // Sidebar control items for view menu item
            
            #if os(iOS) || os(visionOS)
            CommandGroup(after: CommandGroupPlacement.appSettings) // Application settings commands
            {
                Button("Settings...")
                {
                    app_state.settings_view_presented = true
                }
                //.keyboardShortcut(",", modifiers: .command)
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
        
        #if !os(macOS)
        DocumentGroupLaunchScene("Robotic Complex Workspace")
        {
            NewDocumentButton("New Preset")
        }
        background:
        {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#39A8A1"), Color(hex: "#74C8C5")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .ignoresSafeArea()
        }
        overlayAccessoryView:
        { _ in
            //AccessoryView()
        }
        #endif
        
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
        
        /*WindowGroup("UwU", id: "StatisticsWindow")
        {
            EmptyView()
                .frame(maxWidth: 400, maxHeight: 300)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)*/
    }
}

// MARK: - View element propeties
#if os(macOS)
let quaternary_label_color: Color = Color(NSColor.quaternaryLabelColor)
#else
let quaternary_label_color: Color = Color(UIColor.quaternaryLabel)
#endif

// MARK: - Arrow edge positions
#if os(macOS)
let default_popover_edge: Edge = .top
#else
let default_popover_edge: Edge = .bottom
#endif

#if os(macOS)
let default_popover_edge_inv: Edge = .bottom
#else
let default_popover_edge_inv: Edge = .top
#endif

// MARK: - Representation enum
public enum RepresentationType: String, Equatable, CaseIterable
{
    case visual = "Visual"
    case gallery = "Gallery"
    case spatial = "Spatial"
}

// MARK: – Scene transparency parameter
#if !os(visionOS)
let is_scene_transparent = false
#else
let is_scene_transparent = true
#endif
