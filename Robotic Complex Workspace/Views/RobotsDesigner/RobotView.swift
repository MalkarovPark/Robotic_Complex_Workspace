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

// MARK: - Cell scene views
struct RobotSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @State private var space_origin_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    //@EnvironmentObject var app_state: AppState
    //@EnvironmentObject var document_handler: DocumentUpdateHandler
    
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
        .overlay(alignment: .bottomLeading)
        {
            Button(action: { space_origin_view_presented = true })
            {
                Image(systemName: "cube")
                    .imageScale(.large)
                    #if os(macOS)
                    .frame(width: 16, height: 16)
                    #else
                    .frame(width: 24, height: 24)
                    #endif
                    .padding(8)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            .popover(isPresented: $space_origin_view_presented)
            {
                SpaceOriginView(is_presented: $space_origin_view_presented, origin_position: $base_workspace.selected_robot.origin_position, space_scale: $base_workspace.selected_robot.space_scale)
            }
            .padding()
        }
    }
}

// MARK: Origin settings
struct SpaceOriginView: View
{
    @Binding var is_presented: Bool
    
    @Binding var origin_position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float)
    @Binding var space_scale: (x: Float, y: Float, z: Float)
    
    @State private var editor_selection = 0
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Picker(selection: $editor_selection, label: Text("Editor"))
            {
                /*Image(systemName: "move.3d").tag(0)
                Image(systemName: "rotate.3d").tag(1)
                Image(systemName: "scale.3d").tag(2)*/
                
                Label("Location", systemImage: "move.3d").tag(0)
                Label("Rotation", systemImage: "rotate.3d").tag(1)
                Label("Scale", systemImage: "scale.3d").tag(2)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
            .padding()
            
            switch editor_selection
            {
            case 0:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("X")
                            .frame(width: 20)
                        TextField("0", value: $origin_position.x, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.x, in: -20000...20000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y")
                            .frame(width: 20)
                        TextField("0", value: $origin_position.y, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.y, in: -20000...20000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z")
                            .frame(width: 20)
                        TextField("0", value: $origin_position.z, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.z, in: -20000...20000)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #else
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #endif
            case 1:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("R")
                            .frame(width: label_width)
                        TextField("0", value: $origin_position.r, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.r, in: -180...180)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("P")
                            .frame(width: label_width)
                        TextField("0", value: $origin_position.p, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.p, in: -180...180)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("W")
                            .frame(width: label_width)
                        TextField("0", value: $origin_position.w, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $origin_position.w, in: -180...180)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #elseif os(iOS)
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #else
                .frame(minWidth: 256, idealWidth: 288, maxWidth: 320)
                #endif
            case 2:
                VStack(spacing: 12)
                {
                    HStack(spacing: 8)
                    {
                        Text("X")
                            .frame(width: 20)
                        TextField("0", value: $space_scale.x, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $space_scale.x, in: 2...1000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y")
                            .frame(width: 20)
                        TextField("0", value: $space_scale.y, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $space_scale.y, in: 2...1000)
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z")
                            .frame(width: 20)
                        TextField("0", value: $space_scale.z, format: .number)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                            .keyboardType(.decimalPad)
                        #endif
                        Stepper("Enter", value: $space_scale.z, in: 2...1000)
                            .labelsHidden()
                    }
                }
                .padding([.horizontal, .bottom])
                #if os(macOS)
                .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
                #else
                .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
                #endif
            default:
                EmptyView()
            }
        }
        .onChange(of: PositionSnapshot(base_workspace.selected_robot.origin_position))
        { _, _ in
            //base_workspace.update_view()
            document_handler.document_update_robots()
        }
        .onChange(of: ScaleSnapshot(base_workspace.selected_robot.space_scale))
        { _, _ in
            base_workspace.selected_robot.update_space_scale()
            //base_workspace.update_view()
            document_handler.document_update_robots()
        }
        .onChange(of: PositionSnapshot(base_workspace.selected_robot.position))
        { _, _ in
            base_workspace.update_object_position()
        }
    }
}

#if !os(visionOS)
let label_width = 20.0
#else
let label_width = 26.0
#endif

public struct ScaleSnapshot: Equatable
{
    let x: Float, y: Float, z: Float
    
    public init(_ tuple: (x: Float, y: Float, z: Float))
    {
        self.x = tuple.x
        self.y = tuple.y
        self.z = tuple.z
    }
}

// MARK: - Previews
#Preview
{
    RobotView(robot: Robot())
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
