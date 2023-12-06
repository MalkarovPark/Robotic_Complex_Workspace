//
//  VisualWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 06.12.2023.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct VisualWorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_in_view_presented = false
    @State private var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        ZStack
        {
            WorkspaceSceneView()
                .modifier(WorkspaceMenu())
                .disabled(add_in_view_presented)
            #if os(iOS) || os(visionOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            
            HStack
            {
                VStack
                {
                    Spacer()
                    VStack(spacing: 0)
                    {
                        Button(action: { add_in_view_presented.toggle() })
                        {
                            Image(systemName: "plus")
                                .imageScale(.large)
                                .padding()
                            #if os(iOS)
                                .foregroundColor((!base_workspace.add_in_view_disabled || base_workspace.performed) ? Color.secondary : Color.black)
                            #elseif os(visionOS)
                                .foregroundColor((!base_workspace.add_in_view_disabled || base_workspace.performed) ? Color.secondary : Color.primary)
                            #endif
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $add_in_view_presented)
                        {
                            #if os(macOS)
                            AddInWorkspaceView(document: $document, add_in_view_presented: $add_in_view_presented)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                            #else
                            AddInWorkspaceView(document: $document, add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                                .frame(maxWidth: 1024)
                            #endif
                        }
                        .disabled(!base_workspace.add_in_view_disabled || base_workspace.performed)
                        
                        Divider()
                        
                        Button(action: { info_view_presented.toggle() })
                        {
                            Image(systemName: "pencil")
                                .imageScale(.large)
                                .padding()
                            #if os(iOS)
                                .foregroundColor(base_workspace.add_in_view_disabled ? Color.secondary : Color.black)
                            #elseif os(visionOS)
                                .foregroundColor((!base_workspace.add_in_view_disabled || base_workspace.performed) ? Color.secondary : Color.primary)
                            #endif
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $info_view_presented)
                        {
                            #if os(macOS)
                            VisualInfoView(info_view_presented: $info_view_presented, document: $document)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                            #else
                            VisualInfoView(info_view_presented: $info_view_presented, document: $document, is_compact: horizontal_size_class == .compact)
                                .frame(maxWidth: 1024)
                            #endif
                        }
                        .disabled(base_workspace.add_in_view_disabled)
                    }
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(radius: 8)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding()
                }
                
                Spacer()
            }
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
            base_workspace.connect_scene(viewed_scene)
        }
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(sender:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
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
            if !workspace.is_editing && !workspace.performed
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
        if base_workspace.is_selected && base_workspace.performed
        {
            base_workspace.selected_robot.update_model()
            
            if base_workspace.selected_robot.moving_completed
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                {
                    base_workspace.selected_robot.moving_completed = false
                    base_workspace.update_view()
                }
            }
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
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
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
                    .padding()
                    .onChange(of: base_workspace.selected_tool.is_attached)
                    { _, new_value in
                        if !new_value
                        {
                            base_workspace.remove_attachment()
                        }
                        document.preset.tools = base_workspace.file_data().tools
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
                            document.preset.robots = base_workspace.file_data().robots
                        }
                case .tool:
                    if !base_workspace.selected_tool.is_attached
                    {
                        PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                            .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                            { _, _ in
                                base_workspace.update_object_position()
                                document.preset.tools = base_workspace.file_data().tools
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
                            document.preset.parts = base_workspace.file_data().parts
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
                Button(role: .destructive, action: remove_object)
                {
                    Text("Remove from workspace")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .onAppear
        {
            base_workspace.is_editing = true
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
                        document.preset.tools = base_workspace.file_data().tools
                    }
                }
                else
                {
                    base_workspace.remove_attachment()
                }
            }
            
            base_workspace.is_editing = false
        }
    }
    
    private func remove_object()
    {
        let type_for_save = base_workspace.selected_object_type
        base_workspace.remove_selected_object()
        
        switch type_for_save
        {
        case .robot:
            document.preset.robots = base_workspace.file_data().robots
        case .tool:
            if base_workspace.selected_tool.is_attached
            {
                base_workspace.remove_attachment()
                base_workspace.selected_tool.is_attached = false
            }
            document.preset.tools = base_workspace.file_data().tools
        case.part:
            document.preset.parts = base_workspace.file_data().parts
        default:
            break
        }
        
        info_view_presented.toggle()
    }
}

#Preview
{
    VisualWorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
