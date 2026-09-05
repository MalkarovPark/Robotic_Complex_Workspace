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
    @Environment(\.openWindow) var open_window
    @Environment(\.dismissWindow) var dismiss_window
    
    @Environment(\.openImmersiveSpace) private var open_immersive_space
    @Environment(\.dismissImmersiveSpace) private var dismiss_immersive_space
    
    @Environment(\.scenePhase) private var scene_phase
    
    @StateObject var pendant_controller = PendantController()
    @StateObject var workspace_controller = WorkspaceSceneController()
    @StateObject var inspector_controller = ObjectInspectorController(workspace: Workspace(), document: .constant(Robotic_Complex_WorkspaceDocument()))
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
                .environmentObject(inspector_controller)
                .onDisappear
                {
                    dismiss_window(id: SPendantDefaultID)
                    dismiss_window(id: ObjectInspectorDefaultID)
                    
                    //dismiss_window(id: WorkspaceImmersiveSpaceDefaultID)
                    dismiss_window(id: WorkspacePortalWindowDefaultID)
                    Task { await dismiss_immersive_space() }
                }
                /*.onChange(of: scene_phase)
                {
                    if scene_phase == .active && !document_is_open()
                    {
                        reopen_document_picker()
                    }
                }*/
                .onAppear
                {
                    set_window_functions()
                }
                //.onDisappear { exit(0) }
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
        WorkspaceImmersiveSpace(controller: workspace_controller, inspector_controller: inspector_controller)
        WorkspacePortalWindow(controller: workspace_controller, inspector_controller: inspector_controller)
        ObjectInspector(controller: inspector_controller)
        #endif
    }
    
    #if os(visionOS)
    private func set_window_functions()
    {
        pendant_controller.set_window_functions
        {
            open_window(id: SPendantDefaultID)
        }
        _:
        {
            dismiss_window(id: SPendantDefaultID)
        }
        
        workspace_controller.set_space_functions
        {
            Task { await open_immersive_space(id: WorkspaceImmersiveSpaceDefaultID) }
        }
        _:
        {
            Task { await dismiss_immersive_space() }
        }
        
        workspace_controller.set_window_functions
        {
            open_window(id: WorkspacePortalWindowDefaultID)
        }
        _:
        {
            dismiss_window(id: WorkspacePortalWindowDefaultID)
        }
        
        inspector_controller.set_window_functions
        {
            open_window(id: ObjectInspectorDefaultID)
        }
        _:
        {
            dismiss_window(id: ObjectInspectorDefaultID)
        }
    }
    
    private func document_is_open() -> Bool
    {
        UIApplication.shared.connectedScenes.contains
        {
            ($0 as? UIWindowScene)?.windows.contains
            {
                $0.rootViewController is UINavigationController
            } ?? false
        }
    }
    #endif
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
    #if os(iOS) || os(visionOS)
    case immersive = "Immersive"
    #endif
    
    var symbol_name: String
    {
        switch self
        {
        case .scene: "view.3d"
        case .gallery: "square.grid.2x2"
            #if os(iOS) || os(visionOS)
        case .immersive: "visionpro"
            #endif
        }
    }
}

// MARK: – Scene transparency parameter
#if !os(visionOS)
let is_scene_transparent = false
#else
let is_scene_transparent = true
#endif

// MARK: - Document Reopener
#if os(visionOS)
import UIKit

public func reopen_document_picker()
{
    guard let scene = UIApplication.shared.connectedScenes.first(where:
    {
        $0.session.role == .windowApplication
    })
    else { return }

    UIApplication.shared.requestSceneSessionDestruction(
        scene.session,
        options: nil
    )

    DispatchQueue.main.async
    {
        UIApplication.shared.requestSceneSessionActivation(
            nil,
            userActivity: nil,
            options: nil
        )
    }
}
#endif
