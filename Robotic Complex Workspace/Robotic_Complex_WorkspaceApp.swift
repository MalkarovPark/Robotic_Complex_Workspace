//
//  Robotic_Complex_WorkspaceApp.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 15.10.2021.
//

import SwiftUI
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
    
    @StateObject var pendant_controller = PendantController()
    //#endif
    //@Environment(\.openWindow) var openWindow
    //@Environment(\.dismissWindow) var dismissWindow
    
    @StateObject var workspace_controller = WorkspaceSceneController()
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
                .environmentObject(pendant_controller)
                .environmentObject(workspace_controller)
                .onAppear
                {
                    pendant_controller.set_windows_functions
                    {
                        openWindow(id: SPendantDefaultID)
                    }
                    _:
                    {
                        dismissWindow(id: SPendantDefaultID)
                    }
                    
                    workspace_controller.set_windows_functions
                    {
                        openWindow(id: WorkspaceSceneDefaultID)
                    }
                    _:
                    {
                        dismissWindow(id: WorkspaceSceneDefaultID)
                    }
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
                    app_state.start_pause_performing()
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Button("Stop")
                {
                    app_state.reset_performing()
                }
                .keyboardShortcut(".", modifiers: .command)
            }
        }
        #if os(visionOS)
        .windowStyle(.volumetric)
        #endif
        
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
        SpatialPendantScene(controller: pendant_controller)
        WorkspaceScene(controller: workspace_controller)
        #endif
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
public enum ViewMode: String, Equatable, CaseIterable
{
    case scene = "Scene"
    case gallery = "Gallery"
    case immersive = "Immersive"
    
    var symbol_name: String
    {
        switch self
        {
        case .scene: "view.3d"
        case .gallery: "square.grid.2x2"
        case .immersive: "visionpro"
        }
    }
}

// MARK: – Scene transparency parameter
#if !os(visionOS)
let is_scene_transparent = false
#else
let is_scene_transparent = true
#endif
