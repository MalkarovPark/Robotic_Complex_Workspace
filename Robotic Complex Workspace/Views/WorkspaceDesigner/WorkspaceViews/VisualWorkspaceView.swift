//
//  VisualWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct VisualWorkspaceView: View
{
    @State private var add_in_view_presented = false
    @State private var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var sidebar_controller: SidebarController
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        WorkspaceSceneView()
            .modifier(WorkspaceMenu(flip_func: sidebar_controller.flip_workspace_selection))
            .disabled(add_in_view_presented)
        #if os(iOS) || os(visionOS)
            .onDisappear
            {
                app_state.locked = false
            }
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if !os(visionOS)
            .overlay(alignment: .bottomLeading)
            {
                VStack(spacing: 0)
                {
                    Button(action: { add_in_view_presented.toggle() })
                    {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .padding()
                        #if os(iOS)
                            .foregroundColor((add_in_view_disabled || base_workspace.performed) ? Color.secondary : Color.black)
                        #endif
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
                    {
                        #if os(macOS)
                        AddInWorkspaceView(add_in_view_presented: $add_in_view_presented)
                            .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                        #else
                        AddInWorkspaceView(add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                            .frame(maxWidth: 1024)
                        #endif
                    }
                    .disabled(add_in_view_disabled || base_workspace.performed)
                    
                    Divider()
                    
                    Button(action: { info_view_presented.toggle() })
                    {
                        Image(systemName: "pencil")
                            .imageScale(.large)
                            .padding()
                        #if os(iOS)
                            .foregroundColor(!add_in_view_disabled ? Color.secondary : Color.black)
                        #endif
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $info_view_presented, arrowEdge: default_popover_edge)
                    {
                        #if os(macOS)
                        VisualInfoView(info_view_presented: $info_view_presented)
                            .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                        #else
                        VisualInfoView(info_view_presented: $info_view_presented, is_compact: horizontal_size_class == .compact)
                            .frame(maxWidth: 1024)
                        #endif
                    }
                    .disabled(!add_in_view_disabled)
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
                Button(action: { add_in_view_presented.toggle() })
                {
                    Image(systemName: "plus")
                        .imageScale(.large)
                        .padding()
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
                {
                    AddInWorkspaceView(add_in_view_presented: $add_in_view_presented)
                        .frame(maxWidth: 1024)
                }
                .disabled(add_in_view_disabled || base_workspace.performed)
                .padding(.trailing)
                
                Button(action: { info_view_presented.toggle() })
                {
                    Image(systemName: "pencil")
                        .imageScale(.large)
                        .padding()
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .popover(isPresented: $info_view_presented, arrowEdge: default_popover_edge)
                {
                    VisualInfoView(info_view_presented: $info_view_presented)
                        .frame(maxWidth: 1024)
                }
                .disabled(!add_in_view_disabled)
            }
            .padding()
            .labelStyle(.iconOnly)
            .glassBackgroundEffect()
        }
        #endif
        .onDisappear
        {
            base_workspace.deselect_object()
        }
    }
    
    private var add_in_view_disabled: Bool
    {
        if base_workspace.any_object_selected && app_state.add_in_view_dismissed && !base_workspace.performed
        {
            return true
        }
        else
        {
            return false
        }
    }
}

struct WorkspaceSceneView: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workspace.scn")!
    
    #if os(macOS)
    private let base_camera_position_node = SCNNode()
    #endif
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        
        #if os(macOS)
        base_camera_position_node.position = base_workspace.camera_node?.position ?? SCNVector3(0, 0, 2)
        base_camera_position_node.rotation = base_workspace.camera_node?.rotation ?? SCNVector4Zero
        #endif
        
        #if os(visionOS)
        scene_view.scene?.background.contents = UIColor.clear
        #endif
        
        return scene_view
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> SCNView
    {
        //Connect scene to class and add placed robots and parts in workspace
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
        {
            base_workspace.connect_scene(viewed_scene)
        }
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(sender:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        //Add reset double tap recognizer for macOS
        let double_tap_gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_reset_double_tap(_:)))
        double_tap_gesture.numberOfClicksRequired = 2
        scene_view.addGestureRecognizer(double_tap_gesture)
        
        base_workspace.scene = viewed_scene
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }
    #else
    func makeUIView(context: Context) -> SCNView
    {
        //Connect scene to class and add placed robots and parts in workspace
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
        {
            if !app_state.locked
            {
                base_workspace.connect_scene(viewed_scene)
                app_state.locked = true
            }
        }
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(sender:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        #if os(visionOS)
        scene_view.backgroundColor = UIColor.clear
        #endif
        
        base_workspace.scene = viewed_scene
        
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
        
    }
    #else
    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
    }
    #endif
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view, workspace: base_workspace, app_state: app_state)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate, ObservableObject
    {
        var control: WorkspaceSceneView
        var workspace: Workspace
        var app_state: AppState
        
        init(_ control: WorkspaceSceneView, _ scn_view: SCNView, workspace: Workspace, app_state: AppState)
        {
            self.control = control
            
            self.scn_view = scn_view
            self.workspace = workspace
            self.app_state = app_state
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
        
        @objc func handle_tap(sender: UITapGestureRecognizer)
        {
            if !workspace.in_visual_edit_mode && !workspace.performed
            {
                let tap_location = sender.location(in: scn_view)
                let hit_results = scn_view.hitTest(tap_location, options: [:])
                //var result = SCNHitTestResult()
                
                if hit_results.count > 0
                {
                    workspace.select_object_in_scene(result: hit_results.first!)
                }
                else
                {
                    workspace.deselect_object_for_edit()
                }
            }
        }
        
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
        switch base_workspace.selected_object_type
        {
        case .robot:
            base_workspace.selected_robot.update()
        case .tool:
            base_workspace.selected_tool.update()
        case .part:
            break
        case .none:
            break
        }
        
        if base_workspace.element_changed
        {
            DispatchQueue.main.asyncAfter(deadline: .now())
            {
                base_workspace.update_view()
                base_workspace.element_changed = false
            }
        }
    }
}

struct VisualInfoView: View
{
    @Binding var info_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State private var avaliable_attachments = [String]()
    @State private var attach_robot_name = String()
    @State private var old_attachment: String?
    
    @State var is_compact = false
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            //Info view title
            switch base_workspace.selected_object_type
            {
            case .robot:
                Text("\(base_workspace.selected_robot.name)")
                    .font(.title3)
                    .padding([.horizontal, .top])
            case .tool:
                HStack(spacing: 0)
                {
                    Text(base_workspace.selected_tool.name)
                        .font(.title3)
                        .padding([.horizontal, .top])
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing)
                {
                    Toggle(isOn: $base_workspace.selected_tool.is_attached)
                    {
                        Image(systemName: "pin.fill")
                    }
                    .toggleStyle(.button)
                    .disabled(base_workspace.placed_robots_names.count == 0)
                    .padding()
                    .onChange(of: base_workspace.selected_tool.is_attached)
                    { _, new_value in
                        if !new_value
                        {
                            base_workspace.remove_attachment()
                        }
                        document_handler.document_update_tools()
                    }
                }
            case .part:
                Text(base_workspace.selected_part.name)
                    .font(.title3)
                    .padding([.horizontal, .top])
            default:
                Text("None")
            }
            
            //Selected object position editor
            DynamicStack(content: {
                switch base_workspace.selected_object_type
                {
                case .robot:
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                        .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
                        { _, _ in
                            base_workspace.update_object_position()
                            document_handler.document_update_robots()
                        }
                case .tool:
                    if !base_workspace.selected_tool.is_attached
                    {
                        PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                            .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                            { _, _ in
                                base_workspace.update_object_position()
                                document_handler.document_update_tools()
                            }
                    }
                    else
                    {
                        ZStack
                        {
                            if avaliable_attachments.count > 0
                            {
                                Picker("Attach to", selection: $attach_robot_name) //Select object name for place in workspace
                                {
                                    ForEach(avaliable_attachments, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                .onChange(of: attach_robot_name)
                                { _, new_value in
                                    base_workspace.attach_tool_to(robot_name: new_value)
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                #if os(iOS) || os(visionOS)
                                .buttonStyle(.bordered)
                                #endif
                            }
                            else
                            {
                                Text("No robots for attach")
                                    .padding([.horizontal, .top])
                            }
                        }
                        .onAppear
                        {
                            if !base_workspace.selected_tool.is_attached
                            {
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            else
                            {
                                old_attachment = base_workspace.selected_tool.attached_to
                                base_workspace.selected_tool.attached_to = nil
                                avaliable_attachments = base_workspace.attachable_robots_names
                                
                                if old_attachment == nil
                                {
                                    attach_robot_name = avaliable_attachments.first!
                                    base_workspace.attach_tool_to(robot_name: attach_robot_name)
                                }
                                else
                                {
                                    attach_robot_name = old_attachment!
                                }
                            }
                        }
                    }
                case .part:
                    PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
                        .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
                        { _, _ in
                            base_workspace.update_object_position()
                            document_handler.document_update_parts()
                        }
                default:
                    Text("None")
                }
            }, is_compact: $is_compact, spacing: 12)
            .padding([.horizontal, .top])
            
            #if os(iOS) || os(visionOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            HStack
            {
                Button(role: .destructive, action: unplace_object)
                {
                    Text("Unplace from workspace")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .onAppear
        {
            base_workspace.in_visual_edit_mode = true
        }
        .onDisappear
        {
            if base_workspace.selected_object_type == .tool
            {
                if base_workspace.selected_tool.is_attached
                {
                    if old_attachment != attach_robot_name
                    {
                        base_workspace.selected_tool.attached_to = attach_robot_name
                        document_handler.document_update_tools()
                    }
                }
                else
                {
                    base_workspace.remove_attachment()
                }
            }
            
            base_workspace.in_visual_edit_mode = false
        }
    }
    
    private func unplace_object()
    {
        let type_for_save = base_workspace.selected_object_type
        base_workspace.unplace_selected_object()
        
        switch type_for_save
        {
        case .robot:
            document_handler.document_update_robots()
        case .tool:
            if base_workspace.selected_tool.is_attached
            {
                base_workspace.remove_attachment()
                base_workspace.selected_tool.is_attached = false
            }
            document_handler.document_update_tools()
        case.part:
            document_handler.document_update_parts()
        default:
            break
        }
        
        info_view_presented.toggle()
    }
}

#Preview
{
    VisualWorkspaceView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
