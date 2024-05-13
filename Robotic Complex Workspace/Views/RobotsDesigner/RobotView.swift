//
//  RobotView.swift
//  Robotic Complex Workspace
//
//  Created by Artem Malkarov on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct RobotView: View
{
    @Binding var robot_view_presented: Bool
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    //MARK: Horizontal window size handler
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
            RobotSceneView()
                .onDisappear(perform: close_view)
            #if os(iOS) || os(visionOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
                .ignoresSafeArea(.container, edges: !(horizontal_size_class == .compact) ? .bottom : .leading)
            #elseif os(visionOS)
                .ignoresSafeArea(.container, edges: .bottom)
            #endif
        }
        #if !os(visionOS)
        .inspector(isPresented: $inspector_presented)
        {
            RobotInspectorView()
                .disabled(base_workspace.selected_robot.performed)
        }
        #endif
        .onAppear()
        {
            base_workspace.selected_robot.clear_finish_handler()
            if base_workspace.selected_robot.programs_count > 0
            {
                base_workspace.selected_robot.select_program(index: 0)
            }
            
            #if os(macOS)
            app_state.force_resize_view = false
            #endif
        }
        .toolbar
        {
            //MARK: Toolbar items
            ToolbarItem(placement: toolbar_item_placement_leading)
            {
                Button(action: close_robot)
                {
                    #if os(macOS)
                    Image(systemName: "chevron.left")
                    #else
                    Image(systemName: "xmark")
                    #endif
                }
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
            }
            
            ToolbarItem(placement: compact_placement())
            {
                #if !os(visionOS)
                HStack(alignment: .center)
                {
                    
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                    }
                    
                    Button(action: { statistics_view_presented.toggle()
                    })
                    {
                        Image(systemName: "chart.bar")
                    }
                    .sheet(isPresented: $connector_view_presented)
                    {
                        ConnectorView(is_presented: $connector_view_presented, demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_robots() })
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document_handler.document_update_robots() })
                    }
                    
                    Button(action: { base_workspace.selected_robot.reset_moving()
                    })
                    {
                        Image(systemName: "stop")
                    }
                    Button(action: { base_workspace.selected_robot.start_pause_moving()
                    })
                    {
                        Image(systemName: "playpause")
                    }
                    
                    Divider()
                    
                    Button(action: { inspector_presented.toggle() })
                    {
                        #if os(macOS)
                        Image(systemName: "sidebar.right")
                        #else
                        if !(horizontal_size_class == .compact)
                        {
                            Image(systemName: "sidebar.right")
                        }
                        else
                        {
                            Image(systemName: "rectangle.portrait.bottomthird.inset.filled")
                        }
                        #endif
                    }
                }
                #else
                HStack(alignment: .center, spacing: 0)
                {
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                    }
                    .buttonBorderShape(.circle)
                    .padding(.trailing)
                    
                    Button(action: { statistics_view_presented.toggle()
                    })
                    {
                        Image(systemName: "chart.bar")
                    }
                    .buttonBorderShape(.circle)
                    .sheet(isPresented: $connector_view_presented)
                    {
                        ConnectorView(is_presented: $connector_view_presented, demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_robots() })
                            .frame(width: 512, height: 512)
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document_handler.document_update_robots() })
                            .frame(width: 512, height: 512)
                    }
                }
                #endif
            }
        }
        .modifier(MenuHandlingModifier(performed: $base_workspace.selected_robot.performed, toggle_perform: base_workspace.selected_robot.start_pause_moving, stop_perform: base_workspace.selected_robot.reset_moving))
    }
    
    private func close_view()
    {
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
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
        #if os(macOS)
        app_state.force_resize_view = true
        #endif
        base_workspace.deselect_robot()
    }
    
    private func close_robot()
    {
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
        #if os(macOS)
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        base_workspace.deselect_robot()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
        {
            app_state.force_resize_view = true
            robot_view_presented = false
        }
        #else
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
        base_workspace.deselect_robot()
        #endif
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

//MARK: - Cell scene views
struct RobotSceneView: View
{
    @State private var origin_move_view_presented = false
    @State private var origin_rotate_view_presented = false
    @State private var space_scale_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        CellSceneView()
        #if !os(visionOS)
            .overlay(alignment: .bottomLeading)
            {
                VStack(spacing: 0)
                {
                    Button(action: { origin_rotate_view_presented.toggle() })
                    {
                        Image(systemName: "rotate.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_rotate_view_presented)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
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
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_move_view_presented)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
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
                            .padding()
                    }
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $space_scale_view_presented)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        space_scale_view_presented.toggle()
                    }
                    .buttonStyle(.borderless)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(radius: 8)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
            }
        #else
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
                    .popover(isPresented: $origin_rotate_view_presented)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
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
                    .popover(isPresented: $origin_move_view_presented)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
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
                    .popover(isPresented: $space_scale_view_presented)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
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

struct CellSceneView: UIViewRepresentable
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    
    #if os(macOS)
    private let base_camera_position_node = SCNNode()
    #endif
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        
        #if os(macOS)
        base_camera_position_node.position = scene_view.pointOfView?.position ?? SCNVector3(0, 0, 2)
        base_camera_position_node.rotation = scene_view.pointOfView?.rotation ?? SCNVector4Zero
        #endif
        
        #if os(visionOS)
        scene_view.scene?.background.contents = UIColor.clear
        #endif
        
        return scene_view
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        //let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        
        //Add reset double tap recognizer for macOS
        let double_tap_gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_reset_double_tap(_:)))
        double_tap_gesture.numberOfClicksRequired = 2
        scene_view.addGestureRecognizer(double_tap_gesture)
        
        //scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }
    #else
    func makeUIView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        //let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        //scene_view.addGestureRecognizer(tap_gesture_recognizer)
        #if os(visionOS)
        scene_view.backgroundColor = UIColor.clear
        #endif
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }
    #endif
    
    #if os(macOS)
    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    #else
    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    #endif
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: CellSceneView
        
        init(_ control: CellSceneView, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        
        #if os(macOS)
        private var on_reset_view = false
        #endif
        
        /*@objc func handle_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            let tap_location = gesture_recognize.location(in: scn_view)
            let hit_results = scn_view.hitTest(tap_location, options: [:])
            var result = SCNHitTestResult()
            
            if hit_results.count > 0
            {
                result = hit_results[0]
                
                print(result.localCoordinates)
                print("🍮 tapped – \(result.node.name!)")
            }
        }*/
        
        #if os(macOS)
        @objc func handle_reset_double_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            reset_camera_view_position(locataion: SCNVector3(0, 0, 2), rotation: SCNVector4Zero, view: scn_view)
            
            func reset_camera_view_position(locataion: SCNVector3, rotation: SCNVector4, view: SCNView)
            {
                if !on_reset_view
                {
                    on_reset_view = true
                    
                    let reset_action = SCNAction.group([SCNAction.move(to: control.base_camera_position_node.position, duration: 0.5), SCNAction.rotate(toAxisAngle: control.base_camera_position_node.rotation, duration: 0.5)])
                    scn_view.defaultCameraController.pointOfView?.runAction(
                        reset_action, completionHandler: { self.on_reset_view = false })
                }
            }
        }
        #endif
    }
    
    func scene_check() //Render functions
    {
        //base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
        
        if base_workspace.selected_robot.moving_completed
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        
        if base_workspace.selected_robot.performed
        {
            base_workspace.selected_robot.update_model()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}

//MARK: Scale elements
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

//MARK: Move elements
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

//MARK: Rotate elements
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

//MARK: - Previews
#Preview
{
    RobotView(robot_view_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
