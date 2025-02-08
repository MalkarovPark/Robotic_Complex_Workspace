//
//  ToolView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct ToolView: View
{
    @Binding var tool: Tool
    
    @State private var selection_finished = false
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State private var new_operation_code = OperationCodeInfo()
    
    #if os(iOS)
    // MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var sidebar_controller: SidebarController
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            if selection_finished
            {
                ToolSceneView(tool: $tool)
                    .onDisappear(perform: close_view)
                #if !os(visionOS)
                    .overlay(alignment: .bottomTrailing)
                    {
                        ViewPendantButton(operation: { inspector_presented.toggle() })
                    }
                #endif
                #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                #if os(iOS)
                    .ignoresSafeArea(.container, edges: !(horizontal_size_class == .compact) ? .bottom : .leading)
                #elseif os(visionOS)
                    .ignoresSafeArea(.container, edges: .bottom)
                #endif
            }
        }
        #if !os(visionOS)
        .inspector(isPresented: $inspector_presented)
        {
            if selection_finished
            {
                ToolInspectorView(tool: $tool)
                    .disabled(base_workspace.selected_tool.performed)
            }
        }
        #endif
        .onAppear()
        {
            base_workspace.select_tool(index: base_workspace.tools.firstIndex(of: tool) ?? 0)
            
            selection_finished = true
            
            #if os(visionOS)
            pendant_controller.view_tool()
            #endif
            
            base_workspace.selected_tool.clear_finish_handler()
            if base_workspace.selected_tool.programs_count > 0
            {
                base_workspace.selected_tool.select_program(index: 0)
            }
        }
        .toolbar(id: "tool")
        {
            ToolbarItem(id: "Connector", placement: compact_placement())
            {
                Button(action: { connector_view_presented.toggle() })
                {
                    Label("Connector", systemImage:"link")
                }
                .sheet(isPresented: $connector_view_presented)
                {
                    ConnectorView(demo: $base_workspace.selected_tool.demo, update_model: $base_workspace.selected_tool.update_model_by_connector, connector: base_workspace.selected_tool.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_tools() })
                        .modifier(SheetCaption(is_presented: $connector_view_presented, label: "Link"))
                    #if os(macOS)
                        .frame(minWidth: 320, idealWidth: 320, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
                    #elseif os(visionOS)
                        .frame(width: 512, height: 512)
                    #endif
                }
            }
            
            ToolbarItem(id: "Statistics", placement: compact_placement())
            {
                Button(action: { statistics_view_presented.toggle()
                })
                {
                    Label("Statistics", systemImage:"chart.bar")
                }
                .sheet(isPresented: $statistics_view_presented)
                {
                    StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_tool.get_statistics, charts_data: base_workspace.selected_tool.charts_binding(), states_data: base_workspace.selected_tool.states_binding(), clear_chart_data: { base_workspace.selected_tool.clear_chart_data() }, clear_states_data: base_workspace.selected_tool.clear_states_data, update_file_data: { document_handler.document_update_tools() })
                    #if os(visionOS)
                        .frame(width: 512, height: 512)
                    #endif
                }
            }
            
            #if !os(visionOS)
            ToolbarItem(id: "Controls", placement: compact_placement())
            {
                ControlGroup
                {
                    Button(action: { base_workspace.selected_tool.reset_performing()
                    })
                    {
                        Label("Stop", systemImage: "stop")
                    }
                    Button(action: { base_workspace.selected_tool.start_pause_performing()
                    })
                    {
                        Label("Perform", systemImage: "playpause")
                    }
                }
            }
            #endif
        }
        .toolbarRole(.editor)
        .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
        .onAppear
        {
            app_state.preview_update_scene = true
            
            if tool.codes.count > 0
            {
                new_operation_code = tool.codes.first ?? OperationCodeInfo()
            }
            
            #if os(visionOS)
            pendant_controller.view_tool()
            #endif
        }
    }
    
    private func close_view()
    {
        base_workspace.selected_tool.reset_performing()
        #if os(visionOS)
        if sidebar_controller.sidebar_selection != .WorkspaceView
        {
            pendant_controller.view_dismiss()
        }
        else
        {
            pendant_controller.view_workspace()
        }
        #endif
        base_workspace.selected_tool.reset_performing()
        base_workspace.deselect_tool()
    }
    
    func close_tool()
    {
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
        
        base_workspace.deselect_tool()
    }
    
    private func compact_placement() -> ToolbarItemPlacement
    {
        #if os(iOS)
        if horizontal_size_class == .compact
        {
            return .bottomBar
        }
        else
        {
            return .automatic
        }
        #else
        return .automatic
        #endif
    }
}

//MARK: - Scene views
struct ToolSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @Binding var tool: Tool
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, node: tool.node ?? SCNNode(), transparent: is_scene_transparent)
        { scene_view in
            update_view_node(scene_view: scene_view)
        }
        on_init:
        { scene_view in
            on_init(scene_view: scene_view)
        }
        #if os(visionOS)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, style: .continuous))
        #endif
    }
    
    private func on_init(scene_view: SCNView)
    {
        let viewed_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
        
        apply_bit_mask(node: viewed_node ?? SCNNode(), Workspace.tool_bit_mask)
        
        viewed_node?.remove_all_constraints()
        viewed_node?.position = SCNVector3(x: 0, y: 0, z: 0)
        viewed_node?.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
        
        tool.workcell_connect(scene: scene_view.scene!, name: "Node")
    }
    
    private func update_view_node(scene_view: SCNView)
    {
        if base_workspace.selected_object_type == .tool
        {
            if tool.performing_completed
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    tool.performing_completed = false
                    base_workspace.update_view()
                }
            }
            
            if tool.code_changed
            {
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    base_workspace.update_view()
                    tool.code_changed = false
                }
            }
        }
    }
}

//MARK: - Previews
#Preview
{
    ToolView(tool: .constant(Tool()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
