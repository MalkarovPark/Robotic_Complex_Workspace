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
    
    @AppStorage("ViewMode") private var view_mode: ViewMode = .scene
    
    @State private var worked = false
    @State private var registers_view_presented = false
    @State private var add_object_view_presented = false
    @State private var inspector_presented = false
    
    @State private var device_output_presented = false
    
    @State private var device_connector_presented = false
    
    @State private var performing_state_view_presented = false
    
    #if !os(macOS)
    @State var settings_view_presented = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    #if os(visionOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    
    #if os(macOS) || os(iOS)
    @StateObject var pendant_controller = PendantController()
    #else
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var workspace_controller: WorkspaceSceneController
    #endif
    
    @State private var is_pan = false
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                WorkspaceSpatialView(is_pan: $is_pan, pendant_controller: pendant_controller)
                /*#if os(visionOS)
                    .frame(depth: 0)
                    .overlay(alignment: .bottomLeading)
                    {
                        Button("Workspace") { workspace_controller.is_opened.toggle() }
                            .padding()
                    }
                #endif*/
                .onAppear
                {
                    pendant_controller.workspace = base_workspace
                    #if os(visionOS)
                    workspace_controller.workspace = base_workspace
                    #endif
                }
                #if os(visionOS)
                .onDisappear
                {
                    workspace_controller.workspace = Workspace()
                }
                #endif
            }
            .inspector(isPresented: $inspector_presented)
            {
                if base_workspace.selected_object != nil
                {
                    #if os(macOS) || os(visionOS)
                    InspectorView(object: base_workspace.selected_object ?? ProductionObject())
                    #else
                    if horizontal_size_class != .compact
                    {
                        InspectorView(object: base_workspace.selected_object ?? ProductionObject())
                    }
                    else
                    {
                        InspectorView(object: base_workspace.selected_object ?? ProductionObject())
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                            .modifier(SheetCaption(is_presented: $inspector_presented, label: object_type_name))
                    }
                    #endif
                }
                else
                {
                    Text("Nothing Selected")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                        .presentationDetents([.height(160)])
                    #elseif os(visionOS)
                        .frame(minWidth: 300, maxHeight: .infinity)
                    #endif
                }
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(id: "Workspace")
            {
                #if os(visionOS)
                ToolbarItem(id: "Documents", placement: .cancellationAction)
                {
                    Button(action: { dismiss(); pendant_controller.is_opened = false })
                    {
                        Label("Documents", systemImage: "chevron.left")
                    }
                    .buttonBorderShape(.circle)
                }
                #endif
                #if !os(macOS)
                ToolbarItem(id: "Settings", placement: .cancellationAction)
                {
                    Button (action: { app_state.settings_view_presented = true })
                    {
                        Label("Settings", systemImage: "gear")
                    }
                    #if os(visionOS)
                    .buttonBorderShape(.circle)
                    #endif
                }
                #endif
                
                ToolbarItem(id: "View", placement: compact_primary_placement())
                {
                    Menu
                    {
                        Section("Visibility")
                        {
                            Toggle(isOn: $base_workspace.shows_grid)
                            {
                                Text("Grid")
                            }
                            #if !os(visionOS)
                            .disabled(view_mode == .gallery)
                            #endif
                        }
                        
                        Divider()
                        
                        #if os(macOS) || os(iOS)
                        Button(action: { is_pan = false })
                        {
                            Label("Oribit Mode", systemImage: "rotate.3d")
                        }
                        .disabled(view_mode == .gallery)
                        
                        Button(action: { is_pan = true })
                        {
                            Label("Pan Mode", systemImage: "move.3d")
                        }
                        .disabled(view_mode == .gallery)
                        
                        Divider()
                        
                        ForEach(ViewMode.allCases, id: \.self)
                        { mode in
                            if mode != .immersive
                            {
                                Button(action: { view_mode = mode })
                                {
                                    Label(mode.rawValue, systemImage: mode.symbol_name)
                                }
                            }
                        }
                        #else
                        Button(action: { workspace_controller.is_opened.toggle() })
                        {
                            Label(ViewMode.immersive.rawValue, systemImage: ViewMode.immersive.symbol_name)
                        }
                        #endif
                    }
                    label:
                    {
                        Label("View", systemImage: "camera")
                    }
                }
                
                #if os(macOS)
                ToolbarSpacer()
                #endif
                
                ToolbarItem(id: "State", placement: compact_primary_placement())
                {
                    Button(action: { device_output_presented = true })
                    {
                        Label("Device Output", systemImage: "chart.pie")
                    }
                    .sheet(isPresented: $device_output_presented)
                    {
                        if let selected_object = base_workspace.selected_object
                        {
                            DeviceOutputView(object: selected_object, shows_output_indices: true)
                            {
                                switch base_workspace.selected_object
                                {
                                case is Robot: document_handler.document_update_robots()
                                case is Tool: document_handler.document_update_tools()
                                default: break
                                }
                            }
                            .modifier(SheetCaption(is_presented: $device_output_presented, label: "Device Output", plain: false, clear_background: true))
                        }
                    }
                    .disabled(!(base_workspace.selected_object is any StateOutputCapable))
                }
                
                ToolbarItem(id: "Connector", placement: compact_primary_placement())
                {
                    Button(action: { device_connector_presented.toggle() })
                    {
                        Label("Connector", systemImage: "link")
                    }
                    .sheet(isPresented: $device_connector_presented)
                    {
                        if let selected_object = base_workspace.selected_object
                        {
                            ConnectorView(object: selected_object)
                            {
                                switch base_workspace.selected_object
                                {
                                case is Robot: document_handler.document_update_robots()
                                case is Tool: document_handler.document_update_tools()
                                default: break
                                }
                            }
                            .padding(.top, -16)
                            .modifier(SheetCaption(is_presented: $device_connector_presented, label: "Real Device Connection"))
                            #if os(macOS)
                            .frame(minWidth: 320, idealWidth: 320, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
                            #elseif os(visionOS)
                            .frame(width: 512, height: 512)
                            #endif
                        }
                    }
                    .disabled(!(base_workspace.selected_object is any DeviceTwin))
                }
                
                #if os(macOS)
                ToolbarSpacer()
                #endif
                
                ToolbarItem(id: "Add Object", placement: compact_primary_placement())
                {
                    //ControlGroup
                    //{
                        Button(action: { add_object_view_presented = true })
                        {
                            Label("Add Object", systemImage: "plus")
                        }
                    //}
                }
                
                #if !os(visionOS)
                ToolbarSpacer()
                #endif
                
                ToolbarItem(id: "Pendant", placement: .confirmationAction)
                {
                    Button
                    {
                        pendant_controller.is_opened.toggle()
                    }
                    label:
                    {
                        if pendant_controller.is_opened
                        {
                            #if os(macOS)
                            Label("Pendant", systemImage: "circlebadge")
                            #else
                            Image(systemName: "circlebadge")
                            #endif
                        }
                        else
                        {
                            #if os(macOS)
                            Label("Pendant", systemImage: "circlebadge.fill")
                                .foregroundStyle(performing_state_color)
                            #else
                            Image(systemName: "circlebadge.fill")
                                .foregroundStyle(performing_state_color)
                            #endif
                        }
                    }
                    #if os(visionOS)
                    .buttonBorderShape(.circle)
                    #endif
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .animation(.easeInOut(duration: 0.3), value: pendant_controller.is_opened)
                }
                
                ToolbarItem(id: "Inspector", placement: compact_confirmation_placement())
                {
                    Button(action: { inspector_presented.toggle() })
                    {
                        #if os(macOS)
                        Label("Inspector", systemImage: "sidebar.right")
                        #else
                        Image(systemName: horizontal_size_class != .compact ? "sidebar.right" : "inset.filled.bottomthird.rectangle.portrait")
                        #endif
                    }
                    #if os(visionOS)
                    .buttonBorderShape(.circle)
                    #endif
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
    
    private var performing_state_color: Color
    {
        switch base_workspace.selected_object
        {
        case let robot as Robot: return robot.performing_state.color
        case let tool as Tool: return tool.performing_state.color
        case let part as Part: return .black
        default: return base_workspace.performing_state.color
        }
    }
    
    private func compact_primary_placement() -> ToolbarItemPlacement
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
            return .automatic
        }
        #elseif os(visionOS)
        return .automatic
        #endif
    }
    
    private func compact_confirmation_placement() -> ToolbarItemPlacement
    {
        #if os(macOS)
        return .confirmationAction
        #elseif os(iOS)
        if horizontal_size_class == .compact
        {
            return .bottomBar
        }
        else
        {
            return .confirmationAction
        }
        #else
        return .confirmationAction
        #endif
    }
    
    #if os(iOS)
    private var object_type_name: String
    {
        switch base_workspace.selected_object
        {
        case is Robot:
            return "Robot"
        case is Tool:
            return "Tool"
        case is Part:
            return "Part"
        default:
            return "None"
        }
    }
    #endif
}

/*struct OutputGroupView: View
{
    var body: some View
    {
        
    }
}*/

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
        }
    }
}
