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
    
    @State private var origin_move_view_presented = false
    @State private var origin_rotate_view_presented = false
    @State private var space_scale_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
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
        #if !os(visionOS)
            .overlay(alignment: .bottomLeading)
            {
                VStack(spacing: 0)
                {
                    Button(action: { origin_rotate_view_presented.toggle() })
                    {
                        Image(systemName: "rotate.3d")
                            .imageScale(.large)
                        #if os(macOS)
                            .frame(width: 16, height: 16)
                        #else
                            .frame(width: 24, height: 24)
                        #endif
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_rotate_view_presented, arrowEdge: default_popover_edge)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        origin_rotate_view_presented.toggle()
                    }
                    Divider()
                    
                    Button(action: { origin_move_view_presented.toggle() })
                    {
                        Image(systemName: "move.3d")
                            .imageScale(.large)
                        #if os(macOS)
                            .frame(width: 16, height: 16)
                        #else
                            .frame(width: 24, height: 24)
                        #endif
                            .padding()
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_move_view_presented, arrowEdge: default_popover_edge)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        origin_move_view_presented.toggle()
                    }
                    Divider()
                    
                    Button(action: { space_scale_view_presented.toggle() })
                    {
                        Image(systemName: "scale.3d")
                            .imageScale(.large)
                        #if os(macOS)
                            .frame(width: 16, height: 16)
                        #else
                            .frame(width: 24, height: 24)
                        #endif
                            .padding()
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $space_scale_view_presented, arrowEdge: default_popover_edge)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        space_scale_view_presented.toggle()
                    }
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(radius: 8)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
            }
        #else
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, style: .continuous))
            .ornament(attachmentAnchor: .scene(.bottom))
            {
                HStack(spacing: 0)
                {
                    Button(action: { origin_rotate_view_presented.toggle() })
                    {
                        Image(systemName: "rotate.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $origin_rotate_view_presented, arrowEdge: default_popover_edge)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        origin_rotate_view_presented.toggle()
                    }
                    
                    Button(action: { origin_move_view_presented.toggle() })
                    {
                        Image(systemName: "move.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $origin_move_view_presented, arrowEdge: default_popover_edge)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        origin_move_view_presented.toggle()
                    }
                    
                    Button(action: { space_scale_view_presented.toggle() })
                    {
                        Image(systemName: "scale.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $space_scale_view_presented, arrowEdge: default_popover_edge)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                        }
                    }
                    .onDisappear
                    {
                        space_scale_view_presented.toggle()
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .labelStyle(.iconOnly)
                .glassBackgroundEffect()
            }
        #endif
    }
}

// MARK: Scale elements
struct SpaceScaleView: View
{
    @Binding var space_scale_view_presented: Bool
    @Binding var space_scale: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Space Scale")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("X:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[0], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[1], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[2], in: 2...1000)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #endif
    }
}

// MARK: Move elements
struct OriginMoveView: View
{
    @Binding var origin_move_view_presented: Bool
    @Binding var origin_view_pos_location: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Origin Location")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("X:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[0], in: -20000...20000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[1], in: -20000...20000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[2], in: -20000...20000)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #endif
    }
}

// MARK: Rotate elements
struct OriginRotateView: View
{
    @Binding var origin_rotate_view_presented: Bool
    @Binding var origin_view_pos_rotation: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Origin Rotation")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("R:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[0], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("P:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[1], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("W:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[2], in: -180...180)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #elseif os(iOS)
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #else
        .frame(minWidth: 256, idealWidth: 288, maxWidth: 320)
        #endif
    }
}

#if !os(visionOS)
let label_width = 20.0
#else
let label_width = 26.0
#endif

// MARK: - Previews
#Preview
{
    RobotView(robot: Robot())
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
