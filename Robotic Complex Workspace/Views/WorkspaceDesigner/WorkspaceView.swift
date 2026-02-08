//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.10.2021.
//

import SwiftUI
import UniformTypeIdentifiers
import IndustrialKit
import IndustrialKitUI

struct WorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @AppStorage("RepresentationType") private var representation_type: RepresentationType = .visual
    
    @State private var worked = false
    @State private var registers_view_presented = false
    @State private var add_object_view_presented = false
    @State private var inspector_presented = false
    
    @State private var statistics_view_presented = false
    @State private var performing_state_view_presented = false
    
    #if !os(macOS)
    @State var settings_view_presented = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    @StateObject var pendant_controller = PendantController()
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                switch representation_type
                {
                case .visual:
                    VisualWorkspaceView()
                        //.onDisappear(perform: stop_perform)
                        //.onAppear(perform: update_constrainted_positions)
                case .gallery:
                    GalleryWorkspaceView()
                case .spatial:
                    EmptyView()
                }
                
                /*FloatingView(alignment: .trailing)
                {
                    RobotControlView(robot: robot)
                        .padding(8)
                }
                .padding([.horizontal, .bottom], 10)*/
                SpatialPendantView(controller: pendant_controller, workspace: base_workspace)
                    .ignoresSafeArea(.container, edges: [.bottom])
                    .padding(10)
                    //.padding([.horizontal, .bottom], 10)
            }
            #if !os(visionOS)
            .inspector(isPresented: $inspector_presented)
            {
                if base_workspace.selected_object != nil
                {
                    InspectorView(object: base_workspace.selected_object ?? WorkspaceObject())
                }
                else
                {
                    Text("Nothing selected")
                        .foregroundStyle(.secondary)
                }
            }
            #endif
            #if os(macOS)
            .frame(minWidth: 800, idealWidth: 800, minHeight: 576, idealHeight: 600) // Window sizes for macOS
            #endif
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(id: "workspace")
            {
                #if !os(macOS)
                ToolbarItem(id: "Settings", placement: .cancellationAction)
                {
                    HStack(alignment: .center)
                    {
                        Button (action: { app_state.settings_view_presented = true })
                        {
                            Label("Settings", systemImage: "gear")
                        }
                        #if os(visionOS)
                        .buttonBorderShape(.circle)
                        #endif
                    }
                }
                #endif
                
                ToolbarItem(id: "Add Object", placement: compact_placement())
                {
                    ControlGroup
                    {
                        Button(action: { add_object_view_presented = true })
                        {
                            Label("Add Object", systemImage: "plus")
                        }
                    }
                }
                
                /*ToolbarItem(id: "Controls", placement: compact_placement())
                {
                    ControlGroup
                    {
                        Button(action: change_cycle)
                        {
                            if base_workspace.cycled
                            {
                                Label("Cycle", systemImage: "repeat")
                            }
                            else
                            {
                                Label("Cycle", systemImage: "repeat.1")
                            }
                        }
                        
                        Button(action: stop_perform)
                        {
                            Label("Stop", systemImage: "stop")
                        }
                        
                        Button(action: toggle_perform)
                        {
                            Label("Perform", systemImage: "playpause")
                        }
                    }
                }*/
                
                ToolbarItem(id: "Grid", placement: compact_placement(), showsByDefault: false)
                {
                    ControlGroup
                    {
                        Button(action: { base_workspace.toggle_grid_visiblity() })
                        {
                            Label("Grid", systemImage: base_workspace.is_grid_visible ? "squareshape.split.2x2" : "squareshape.split.2x2.dotted.inside")
                                //.contentTransition(.symbolEffect(.replace.offUp.byLayer))
                                //.animation(.easeInOut(duration: 0.3), value: base_workspace.is_grid_visible)
                        }
                    }
                }
                
                ToolbarItem(id: "Inspector", placement: compact_placement())
                {
                    ControlGroup
                    {
                        Button(action: { inspector_presented.toggle() })
                        {
                            #if os(macOS)
                            Label("Inspector", systemImage: "sidebar.right")
                            #else
                            Label("Inspector", systemImage: horizontal_size_class != .compact ? "sidebar.right" : "inset.filled.bottomthird.rectangle.portrait")
                            #endif
                        }
                    }
                }
            }
            .toolbarRole(.editor)
            #if !os(macOS)
            .sheet(isPresented: $app_state.settings_view_presented)
            {
                SettingsView(setting_view_presented: $app_state.settings_view_presented)
                    .environmentObject(app_state)
                    .onDisappear
                {
                    app_state.settings_view_presented = false
                }
                #if os(visionOS)
                .frame(width: 512, height: 512)
                #endif
            }
            #endif
        }
        .sheet(isPresented: $add_object_view_presented)
        {
            AddObjectView(is_presented: $add_object_view_presented)
            #if os(macOS)
                .frame(minWidth: 420, maxWidth: 600, minHeight: 480, maxHeight: 600)
                //.frame(width: 420, height: 480)
            #elseif os(visionOS)
                .frame(width: 600, height: 600)
            #endif
        }
    }
    
    private func stop_perform()
    {
        base_workspace.reset_performing()
        
        if base_workspace.performed
        {
            base_workspace.update_view()
        }
        
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
    }
    
    private func toggle_perform()
    {
        #if !os(visionOS)
        app_state.view_program_as_text = false
        #endif
        base_workspace.start_pause_performing()
    }
    
    private func change_cycle()
    {
        base_workspace.cycled.toggle()
    }
    
    private func compact_placement() -> ToolbarItemPlacement
    {
        #if os(macOS)
        return .primaryAction
        #elseif os(iOS)
        if horizontal_size_class == .compact
        {
            return .bottomBar
        }
        else
        {
            return .topBarTrailing
        }
        #else
        return .topBarTrailing
        #endif
    }
}

// MARK: - Previews
struct WorkspaceView_Previews: PreviewProvider
{
    @EnvironmentObject var base_workspace: Workspace
    
    static var previews: some View
    {
        Group
        {
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            /*AddInWorkspaceView(add_in_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())*/
            /*VisualInfoView(info_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())*/
        }
    }
}
