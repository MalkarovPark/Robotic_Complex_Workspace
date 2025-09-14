//
//  RobotView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit
import IndustrialKitUI

struct RobotView: View
{
    let robot: Robot
    
    @State private var selection_finished = false
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    // MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var sidebar_controller: SidebarController
    #endif
    
    public init(robot: Robot)
    {
        self.robot = robot
    }
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            if selection_finished
            {
                RobotSceneView()
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
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        #if !os(visionOS)
        .inspector(isPresented: $inspector_presented)
        {
            if selection_finished
            {
                RobotInspectorView(robot: $base_workspace.selected_robot)
                    .disabled(base_workspace.selected_robot.performed)
            }
        }
        #endif
        .onAppear()
        {
            base_workspace.select_robot(index: base_workspace.robots.firstIndex(of: robot) ?? 0)
            
            selection_finished = true
            
            #if os(visionOS)
            pendant_controller.view_robot()
            #endif
            
            base_workspace.selected_robot.clear_finish_handler()
            base_workspace.selected_robot.perform_update()
            
            if base_workspace.selected_robot.programs_count > 0
            {
                base_workspace.selected_robot.select_program(index: 0)
            }
        }
        .toolbar(id: "robot")
        {
            ToolbarItem(id: "Connector", placement: compact_placement())
            {
                Button(action: { connector_view_presented.toggle() })
                {
                    Label("Connector", systemImage:"link")
                }
            }
            
            ToolbarItem(id: "Statistics", placement: compact_placement())
            {
                Button(action: { statistics_view_presented.toggle() })
                {
                    Label("Statistics", systemImage:"chart.bar")
                }
            }
            
            #if !os(visionOS)
            ToolbarItem(id: "Controls", placement: compact_placement())
            {
                ControlGroup
                {
                    Button(action: { base_workspace.selected_robot.reset_moving()
                    })
                    {
                        Label("Stop", systemImage: "stop")
                    }
                    Button(action: { base_workspace.selected_robot.start_pause_moving()
                    })
                    {
                        Label("Perform", systemImage: "playpause")
                    }
                }
            }
            #endif
        }
        .toolbarRole(.editor)
        .modifier(MenuHandlingModifier(performed: $base_workspace.selected_robot.performed, toggle_perform: base_workspace.selected_robot.start_pause_moving, stop_perform: base_workspace.selected_robot.reset_moving))
        .sheet(isPresented: $connector_view_presented)
        {
            ConnectorView(demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_robots() })
                .modifier(SheetCaption(is_presented: $connector_view_presented, label: "Link"))
            #if os(macOS)
                .frame(minWidth: 320, idealWidth: 320, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
            #elseif os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
        .sheet(isPresented: $statistics_view_presented)
        {
            StatisticsView(
                is_presented: $statistics_view_presented,
                get_statistics: $base_workspace.selected_robot.get_statistics,
                charts_data: base_workspace.selected_robot.charts_binding(),
                states_data: base_workspace.selected_robot.states_binding(),
                scope_type: $base_workspace.selected_robot.scope_type,
                update_interval: $base_workspace.selected_robot.update_interval,
                clear_chart_data: { base_workspace.selected_robot.clear_chart_data() },
                clear_states_data: base_workspace.selected_robot.clear_states_data,
                update_file_data: { document_handler.document_update_robots() }
            )
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
    }
    
    private func close_view()
    {
        //base_workspace.selected_robot.reset_moving()
        base_workspace.selected_robot.disable_update()
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
        base_workspace.selected_robot.reset_moving()
        base_workspace.deselect_robot()
    }
    
    private func compact_placement() -> ToolbarItemPlacement
    {
        #if os(macOS)
        return .automatic
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

// MARK: - Cell scene views
struct RobotSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @State private var space_origin_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/Workcell.scn")!, transparent: is_scene_transparent)
        { scene_view in
            
        }
        on_init:
        { scene_view in
            base_workspace.selected_robot.workcell_connect(scene: scene_view.scene ?? SCNScene(), name: "unit", connect_camera: true)
        }
        #if os(macOS) || os(iOS)
        .modifier(BackgroundExtensionModifier(color: Color(red: 142/255, green: 142/255, blue: 147/255)))
        #else
        .modifier(BackgroundExtensionModifier())
        #endif
        .overlay(alignment: .bottomLeading)
        {
            Button(action: { space_origin_view_presented = true })
            {
                Image(systemName: "cube")
                #if !os(visionOS)
                    .modifier(CircleButtonImageFramer())
                #endif
            }
            .popover(isPresented: $space_origin_view_presented)
            {
                SpaceOriginView(robot: $base_workspace.selected_robot, on_update: { document_handler.document_update_robots() })
            }
            .modifier(CircleButtonGlassBorderer())
            #if !os(visionOS)
            .padding()
            #else
            .padding(32)
            #endif
        }
    }
}

// MARK: - Previews
#Preview
{
    RobotView(robot: Robot())
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
