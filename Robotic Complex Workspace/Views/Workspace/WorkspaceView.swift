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
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    #if os(macOS) || os(iOS)
    @AppStorage("ViewMode") private var view_mode: ViewMode = .scene
    #else
    @AppStorage("ViewMode") private var view_mode: ViewMode = .immersive
    #endif
    
    @State private var worked = false
    @State private var registers_view_presented = false
    @State private var add_object_view_presented = false
    @State private var inspector_presented = false
    
    @State private var device_output_presented = false
    @State private var device_connector_presented = false
    @State private var performing_state_view_presented = false
    
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    #if os(visionOS)
    @Environment(\.dismiss) private var dismiss
    
    @State private var view_enabled = true
    #endif
    
    #if os(macOS) || os(iOS)
    @StateObject var pendant_controller = PendantController()
    #else
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var workspace_controller: WorkspaceSceneController
    @EnvironmentObject var inspector_controller: ObjectInspectorController
    #endif
    
    @State private var is_pan = false
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                WorkspaceSpatialView(
                    document: $document,
                    is_pan: $is_pan,
                    pendant_controller: pendant_controller
                )
                .onAppear { open_view() }
                #if os(visionOS)
                .opacity(add_object_view_presented || app_state.settings_view_presented ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: add_object_view_presented || app_state.settings_view_presented)
                #endif
                
                /*Rectangle()
                    .fill(.bar)
                    .frame(width: 100, height: 100)
                    .onHover { hover in toolbar_hover = hover }*/
            }
            #if os(macOS) || os(iOS)
            .inspector(isPresented: $inspector_presented)
            {
                if base_workspace.selected_object != nil
                {
                    #if os(macOS)
                    InspectorView(document: $document, workspace: base_workspace)
                    #else
                    if horizontal_size_class != .compact
                    {
                        InspectorView(document: $document, workspace: base_workspace)
                    }
                    else
                    {
                        InspectorView(document: $document, workspace: base_workspace)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                            .modifier(SheetCaption(is_presented: $inspector_presented, label: object_type_name))
                    }
                    #endif
                }
                else
                {
                    Text("Nothing selected")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                        .presentationDetents([.height(160)])
                    #endif
                }
            }
            #else
            .overlay(alignment: .bottomTrailing)
            {
                SpatialToolbar()
                    .padding(28)
            }
            #endif
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(id: "Workspace")
            {
                #if os(visionOS)
                ToolbarItem(id: "Documents", placement: .cancellationAction)
                {
                    Button(action: dismiss_view)
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
                
                #if os(macOS) || os(iOS)
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
                            .disabled(view_mode == .gallery)
                        }
                        
                        Divider()
                        
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
                            Button(action: { view_mode = mode })
                            {
                                Label(mode.rawValue, systemImage: mode.symbol_name)
                            }
                        }
                    }
                    label:
                    {
                        Label("View", systemImage: "camera")
                    }
                }
                #endif
                
                #if os(macOS)
                ToolbarSpacer()
                #endif
                
                #if os(macOS) || os(iOS)
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
                                case is Robot: document.preset.robots = base_workspace.file_data().robots
                                case is Tool: document.preset.tools = base_workspace.file_data().tools
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
                                case is Robot: document.preset.robots = base_workspace.file_data().robots
                                case is Tool: document.preset.tools = base_workspace.file_data().tools
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
                #endif
                
                #if os(macOS)
                ToolbarSpacer()
                #endif
                
                #if os(macOS) || os(iOS)
                ToolbarItem(id: "Add Object", placement: compact_primary_placement())
                {
                    Button(action: { add_object_view_presented = true })
                    {
                        Label("Add Object", systemImage: "plus")
                    }
                }
                
                ToolbarSpacer()
                
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
                }
                #else
                ToolbarItem(id: "Add Object", placement: .confirmationAction)
                {
                    Button(action: { add_object_view_presented = true })
                    {
                        Label("Add Object", systemImage: "plus")
                    }
                }
                #endif
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
            AddObjectView(is_presented: $add_object_view_presented, document: $document)
            #if os(macOS)
                .frame(minWidth: 420, maxWidth: 600, minHeight: 480, maxHeight: 600)
                //.frame(width: 420, height: 480)
            #elseif os(visionOS)
                .frame(width: 600, height: 600)
            #endif
        }
        #if os(visionOS)
        .opacity(view_enabled ? 1 : 0)
        #endif
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
    
    private func open_view()
    {
        pendant_controller.workspace = base_workspace
        #if os(visionOS)
        workspace_controller.workspace = base_workspace
        workspace_controller.is_opened = view_mode == .immersive //true
        
        inspector_controller.workspace = base_workspace
        
        //Set documen functions
        set_document_functions()
        
        inspector_controller.set_document_functions(
            document: $document,
            {
                document.preset.programs = base_workspace.file_data().programs
                document.preset.registers = base_workspace.file_data().registers
            },
            {
                document.preset.robots = base_workspace.file_data().robots
            },
            {
                document.preset.tools = base_workspace.file_data().tools
            },
            {
                document.preset.parts = base_workspace.file_data().parts
            }
        )
        
        view_enabled = true // Show view
        #endif
    }
    
    #if os(visionOS)
    private func set_document_functions()
    {
        pendant_controller.set_document_functions
        {
            document.preset.programs = base_workspace.file_data().programs
            document.preset.registers = base_workspace.file_data().registers
        }
        _:
        {
            document.preset.robots = base_workspace.file_data().robots
        }
        _:
        {
            document.preset.tools = base_workspace.file_data().tools
        }
    }
    
    private func dismiss_view()
    {
        workspace_controller.workspace = Workspace()
        pendant_controller.is_opened = false
        inspector_controller.is_opened = false
        
        if view_mode == .immersive { workspace_controller.is_opened = false }
        
        dismiss()
        
        view_enabled = false
    }
    #endif
}

#if os(visionOS)
struct SpatialToolbar: View
{
    @AppStorage("ViewMode") private var view_mode: ViewMode = .immersive
    
    @EnvironmentObject var base_workspace: Workspace
    
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var workspace_controller: WorkspaceSceneController
    @EnvironmentObject var inspector_controller: ObjectInspectorController
    
    @State private var is_expanded = false
    
    @Namespace private var pane_glass
    
    var body: some View
    {
        VStack(spacing: 16)
        {
            let view_mode_selection = Binding(
                get: { view_mode },
                set:
                    { new_value in
                        view_mode = new_value
                        set_view_mode(new_value)
                    }
            )
            
            let is_selected_mode = Binding(
                get: { view_mode },
                set:
                    { new_value in
                        view_mode = new_value
                        set_view_mode(new_value)
                    }
            )
            
            if is_expanded
            {
                VStack(spacing: 10)
                {
                    HStack
                    {
                        ForEach(ViewMode.allCases, id: \.self)
                        { mode in
                            ViewModeButton(
                                name: mode.rawValue,
                                symbol_name: mode.symbol_name,
                                bordered: view_mode == mode,
                                action: { set_view_mode(mode) }
                            )
                        }
                    }
                    .padding(.top, 10)
                    
                    HStack(spacing: 10)
                    {
                        Toggle(isOn: $base_workspace.shows_grid)
                        {
                            Text("Grid")
                        }
                        .disabled(view_mode == .gallery)
                        .toggleStyle(.button)
                        
                        Button(action: reset_immersive_view)
                        {
                            Text("Recenter Immersion")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(view_mode != .immersive)
                    }
                    .padding(.horizontal, 8)
                }
                .frame(width: 320)//, height: 240)
            }
            
            HStack
            {
                Toggle(isOn: Binding(
                    get: { is_expanded },
                    set: { newValue in withAnimation { is_expanded = newValue } }
                ))
                {
                    Image(systemName: "camera") //Image(systemName: is_expanded ? "chevron.down" : "camera")
                }
                .toggleStyle(.button)
                .buttonBorderShape(.circle)
                .buttonStyle(.borderless)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .help("View")
                
                Toggle(isOn: $pendant_controller.is_opened)
                {
                    if pendant_controller.is_opened
                    {
                        Image(systemName: "circlebadge")
                    }
                    else
                    {
                        Image(systemName: "circlebadge.fill")
                            .foregroundStyle(performing_state_color)
                    }
                }
                .toggleStyle(.button)
                .buttonBorderShape(.circle)
                .buttonStyle(.borderless)
                .help("Pendant")
                
                Toggle(isOn: $inspector_controller.is_opened)
                {
                    Image(systemName: "info")
                }
                .toggleStyle(.button)
                .buttonBorderShape(.circle)
                .buttonStyle(.borderless)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .help("Inspector")
            }
        }
        .padding(8)
        .glassBackgroundEffect()
    }
    
    private func set_view_mode(_ mode: ViewMode)
    {
        view_mode = mode
        
        switch mode
        {
        case .scene:
            workspace_controller.is_opened = false
        case .gallery:
            workspace_controller.is_opened = false
        case .immersive:
            workspace_controller.is_opened = true
        }
    }
    
    private func reset_immersive_view()
    {
        workspace_controller.is_opened = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1)
        {
            workspace_controller.is_opened = true
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
}

struct ViewModeButton: View
{
    let name: String
    let symbol_name: String
    
    let bordered: Bool
    
    let action: () -> ()
    
    var body: some View
    {
        if bordered
        {
            Button { action() }
            label:
            {
                VStack(spacing: 16)
                {
                    Image(systemName: symbol_name)
                    
                    Text(name)
                        .font(.system(size: 16, weight: .light))
                }
                .frame(width: 96, height: 96)
            }
            .frame(width: 96, height: 96)
            .buttonBorderShape(.roundedRectangle(radius: 24))
            .buttonStyle(.bordered)
        }
        else
        {
            Button { action() }
            label:
            {
                VStack(spacing: 16)
                {
                    Image(systemName: symbol_name)
                    
                    Text(name)
                        .font(.system(size: 16, weight: .light))
                }
                .frame(width: 96, height: 96)
            }
            .frame(width: 96, height: 96)
            .buttonBorderShape(.roundedRectangle(radius: 24))
            .buttonStyle(.borderless)
        }
    }
}
#endif

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
