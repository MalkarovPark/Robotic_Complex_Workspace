//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct WorkspaceView: View
{
    @AppStorage("WorkspaceVisualModeling") private var workspace_visual_modeling: Bool = true
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    #if os(iOS)
    @Binding var file_name: String
    @Binding var file_url: URL
    #endif
    
    @State var worked = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class //Horizontal window size handler
    
    @State private var program_view_presented = false //Picker data for thin window size
    #endif
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        HStack(spacing: 0)
        {
            #if os(macOS)
            if workspace_visual_modeling
            {
                ComplexWorkspaceView(document: $document)
                    .onDisappear(perform: stop_perform)
            }
            else
            {
                WorkspaceCardsView(document: $document)
            }
            
            Divider()
            
            ControlProgramView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    if workspace_visual_modeling
                    {
                        ComplexWorkspaceView(document: $document)
                            .onDisappear(perform: stop_perform)
                    }
                    else
                    {
                        WorkspaceCardsView(document: $document)
                    }
                    
                    HStack
                    {
                        Button(action: { program_view_presented.toggle() })
                        {
                            Text("Inspector")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .padding()
                        .popover(isPresented: $program_view_presented)
                        {
                            VStack
                            {
                                ControlProgramView(document: $document)
                                    .presentationDetents([.medium, .large])
                            }
                            .onDisappear()
                            {
                                program_view_presented = false
                            }
                        }
                    }
                }
            }
            else
            {
                if workspace_visual_modeling
                {
                    ComplexWorkspaceView(document: $document)
                        .onDisappear(perform: stop_perform)
                }
                else
                {
                    WorkspaceCardsView(document: $document)
                }
                
                ControlProgramView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .frame(width: 288)
            }
            #endif
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #else
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #endif
        
        //MARK: Toolbar
        .toolbar
        {
            /*#if os(iOS)
            if horizontal_size_class == .compact
            {
                ToolbarItem(placement: .cancellationAction)
                {
                    dismiss_document_button()
                }
            }
            #endif*/
            ToolbarItem(placement: placement_trailing)
            {
                //MARK: Workspace performing elements
                HStack(alignment: .center)
                {
                    Button(action: change_cycle)
                    {
                        if base_workspace.cycled
                        {
                            Label("Repeat", systemImage: "repeat")
                        }
                        else
                        {
                            Label("One", systemImage: "repeat.1")
                        }
                    }
                    Button(action: stop_perform)
                    {
                        Label("Reset", systemImage: "stop")
                    }
                    Button(action: toggle_perform)
                    {
                        Label("PlayPause", systemImage: "playpause")
                    }
                }
            }
        }
        .modifier(MenuHandlingModifier(performed: $base_workspace.performed, toggle_perform: toggle_perform, stop_perform: stop_perform))
        #if os(iOS)
        .navigationTitle($file_name)
        .onChange(of: file_name)
        { _ in
            print(file_name)
        }
        .navigationDocument(file_url)
        #endif
    }
    
    func stop_perform()
    {
        if base_workspace.performed
        {
            base_workspace.reset_performing()
            base_workspace.update_view()
        }
    }
    
    func toggle_perform()
    {
        base_workspace.start_pause_performing()
    }
    
    func change_cycle()
    {
        base_workspace.cycled.toggle()
    }
}

//MARK: - Workspace scene views
struct ComplexWorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var add_in_view_presented = false
    @State var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        ZStack
        {
            #if os(macOS)
            WorkspaceSceneView_macOS()
            #else
            if !(horizontal_size_class == .compact)
            {
                WorkspaceSceneView_iOS()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))
                    .navigationBarTitleDisplayMode(.inline)
            }
            else
            {
                WorkspaceSceneView_iOS()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
            }
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
                                .frame(maxWidth: 512)
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
                            #endif
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $info_view_presented)
                        {
                            #if os(macOS)
                            InfoView(info_view_presented: $info_view_presented, document: $document)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                            #else
                            InfoView(info_view_presented: $info_view_presented, document: $document, is_compact: horizontal_size_class == .compact)
                                .frame(maxWidth: 512)
                            #endif
                        }
                        .disabled(base_workspace.add_in_view_disabled)
                    }
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .shadow(radius: 8.0)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding()
                }
                Spacer()
            }
            #if os(iOS)
            .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))
            #endif
        }
    }
}

#if os(macOS)
struct WorkspaceSceneView_macOS: NSViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workspace.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        //Connect scene to class and add placed robots and parts in workspace
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
        {
            base_workspace.connect_scene(viewed_scene)
        }
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(sender:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        base_workspace.scene = viewed_scene
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view, workspace: base_workspace)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate, ObservableObject
    {
        var control: WorkspaceSceneView_macOS
        var workspace: Workspace
        
        init(_ control: WorkspaceSceneView_macOS, _ scn_view: SCNView, workspace: Workspace)
        {
            self.control = control
            
            self.scn_view = scn_view
            self.workspace = workspace
            super.init()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        @objc func handle_tap(sender: NSClickGestureRecognizer)
        {
            if !workspace.is_editing && !workspace.performed
            {
                let tap_location = sender.location(in: scn_view)
                let hit_results = scn_view.hitTest(tap_location, options: [:])
                var result = SCNHitTestResult()
                
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
    }
    
    func scene_check() //Render functions
    {
        if base_workspace.is_selected && base_workspace.performed
        {
            base_workspace.selected_robot.update_robot()
            
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
#else
struct WorkspaceSceneView_iOS: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workspace.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
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

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view, workspace: base_workspace)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate, ObservableObject
    {
        var control: WorkspaceSceneView_iOS
        var workspace: Workspace
        
        init(_ control: WorkspaceSceneView_iOS, _ scn_view: SCNView, workspace: Workspace)
        {
            self.control = control
            
            self.scn_view = scn_view
            self.workspace = workspace
            super.init()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        @objc func handle_tap(sender: UITapGestureRecognizer)
        {
            if !workspace.is_editing && !workspace.performed
            {
                let tap_location = sender.location(in: scn_view)
                let hit_results = scn_view.hitTest(tap_location, options: [:])
                var result = SCNHitTestResult()
                
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
    }
    
    func scene_check() //Render functions
    {
        if base_workspace.is_selected && base_workspace.performed
        {
            base_workspace.selected_robot.update_robot()
            
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
#endif

struct AddInWorkspaceView: View
{
    @State var selected_robot_name = String()
    @State var selected_tool_name = String()
    @State var selected_part_name = String()
    
    @State var tool_attached = false
    @State var attach_robot_name = String()
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var add_in_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @State var is_compact = false
    
    @State var first_select = true //This flag that specifies that the robot was not selected and disables the dismiss() function
    private let add_items: [String] = ["Add Robot", "Add Tool", "Add Part"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Picker("Workspace", selection: $app_state.add_selection)
            {
                ForEach(0..<add_items.count, id: \.self)
                { index in
                    Text(self.add_items[index]).tag(index)
                }
            }
            .onChange(of: app_state.add_selection)
            { _ in
                base_workspace.object_pointer_node?.isHidden = true
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .padding([.horizontal, .top])
            
            //MARK: Object popup menu
            HStack
            {
                switch app_state.add_selection
                {
                case 0:
                    ObjectPickerView(selected_object_name: $selected_robot_name, avaliable_objects_names: .constant(base_workspace.avaliable_robots_names), workspace_object_type: .constant(.robot))
                case 1:
                    ObjectPickerView(selected_object_name: $selected_tool_name, avaliable_objects_names: .constant(base_workspace.avaliable_tools_names), workspace_object_type: .constant(.tool))
                    
                    if base_workspace.avaliable_tools_names.count > 0
                    {
                        Toggle(isOn: $tool_attached)
                        {
                            Image(systemName: "pin.fill")
                        }
                        .toggleStyle(.button)
                    }
                case 2:
                    ObjectPickerView(selected_object_name: $selected_part_name, avaliable_objects_names: .constant(base_workspace.avaliable_parts_names), workspace_object_type: .constant(.part))
                default:
                    Text("None")
                }
            }
            .padding()
            
            Divider()
            
            //MARK: Object position set
            switch app_state.add_selection
            {
            case 0:
                DynamicStack(content: {
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                }, is_compact: $is_compact, spacing: 16)
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
                { _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_robots_names.count == 0)
            case 1:
                ZStack
                {
                    if !tool_attached
                    {
                        DynamicStack(content: {
                            PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                        }, is_compact: $is_compact, spacing: 16)
                        .padding([.horizontal, .top])
                        .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                        { _ in
                            base_workspace.update_object_position()
                        }
                    }
                    else
                    {
                        if base_workspace.attachable_robots_names.count > 0
                        {
                            Picker("Attached to", selection: $attach_robot_name) //Select object name for place in workspace
                            {
                                ForEach(base_workspace.attachable_robots_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            .onAppear
                            {
                                attach_robot_name = base_workspace.attachable_robots_names.first ?? "None"
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            .onDisappear
                            {
                                base_workspace.remove_attachment()
                                tool_attached = false
                            }
                            .onChange(of: attach_robot_name)
                            { _ in
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding([.horizontal, .top])
                            #if os(iOS)
                            .buttonStyle(.bordered)
                            #endif
                        }
                        else
                        {
                            Text("No robots for attach")
                                .padding([.horizontal, .top])
                        }
                    }
                }
                .disabled(base_workspace.avaliable_tools_names.count == 0)
            case 2:
                DynamicStack(content: {
                    PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
                }, is_compact: $is_compact, spacing: 16)
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
                { _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_parts_names.count == 0)
            default:
                Text("None")
            }
            
            #if os(iOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            //MARK: Object place button
            HStack
            {
                Button(action: place_object)
                {
                    Text("Place")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .padding()
                .disabled(base_workspace.selected_object_unavaliable ?? true)
            }
        }
        .onAppear
        {
            base_workspace.add_in_view_dismissed = false
            base_workspace.is_editing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                base_workspace.update_view()
            }
        }
        .onDisappear
        {
            //base_workspace.dismiss_object()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                base_workspace.dismiss_object()
                base_workspace.add_in_view_dismissed = true
                base_workspace.update_view()
            }
        }
    }
    
    private func place_object()
    {
        let type_for_save = base_workspace.selected_object_type
        
        if tool_attached && base_workspace.selected_object_type == .tool
        {
            base_workspace.selected_tool.attached_to = attach_robot_name
            base_workspace.selected_tool.is_attached = true
        }
        
        base_workspace.place_viewed_object()
        
        switch type_for_save
        {
        case .robot:
            document.preset.robots = base_workspace.file_data().robots
        case .tool:
            document.preset.tools = base_workspace.file_data().tools
        case .part:
            document.preset.parts = base_workspace.file_data().parts
        default:
            break
        }
        
        add_in_view_presented.toggle()
    }
}

struct ObjectPickerView: View
{
    @Binding var selected_object_name: String
    @Binding var avaliable_objects_names: [String]
    @Binding var workspace_object_type: WorkspaceObjectType
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        if avaliable_objects_names.count > 0
        {
            #if os(iOS)
            Text("Name")
                .font(.subheadline)
            #endif
            
            Picker("Name", selection: $selected_object_name) //Select object name for place in workspace
            {
                ForEach(avaliable_objects_names, id: \.self)
                { name in
                    Text(name)
                }
            }
            .onAppear
            {
                base_workspace.view_object_node(type: workspace_object_type, name: selected_object_name)
                
                selected_object_name = avaliable_objects_names.first ?? "None"
            }
            .onChange(of: selected_object_name)
            { _ in
                base_workspace.view_object_node(type: workspace_object_type, name: selected_object_name)
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            #if os(iOS)
            .buttonStyle(.bordered)
            #endif
        }
        else
        {
            Text("All elements placed")
                .onAppear
            {
                base_workspace.dismiss_object()
            }
        }
    }
}

struct InfoView: View
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
                Text("\(base_workspace.selected_robot.name ?? "None")")
                    .font(.title3)
                    .padding([.horizontal, .top])
            case .tool:
                HStack(spacing: 0)
                {
                    Text("\(base_workspace.selected_tool.name ?? "None")")
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
                    { new_value in
                        if !new_value
                        {
                            base_workspace.remove_attachment()
                        }
                        document.preset.tools = base_workspace.file_data().tools
                    }
                }
            case .part:
                Text("\(base_workspace.selected_part.name ?? "None")")
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
                        { _ in
                            base_workspace.update_object_position()
                            document.preset.robots = base_workspace.file_data().robots
                        }
                case .tool:
                    if !base_workspace.selected_tool.is_attached
                    {
                        PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                            .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                            { _ in
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
                                { new_value in
                                    base_workspace.attach_tool_to(robot_name: new_value)
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding([.horizontal, .top])
                                #if os(iOS)
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
                                //attach_robot_name = old_attachment ?? avaliable_attachments.first!
                            }
                        }
                    }
                case .part:
                    PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
                        .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
                        { _ in
                            base_workspace.update_object_position()
                            document.preset.parts = base_workspace.file_data().parts
                        }
                default:
                    Text("None")
                }
            }, is_compact: $is_compact, spacing: 12)
            .padding([.horizontal, .top])
            
            #if os(iOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            HStack
            {
                Button(action: remove_object)
                {
                    Text("Remove from workspace")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.red)
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

//MARK: - Workspace cards view
struct WorkspaceCardsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_object_name = String()
    @State private var object_selection: WorkspaceObjectType = .robot
    
    @State private var update_toggle = false
    
    @State private var object_type_changed = false
    
    #if os(iOS)
    @State private var tabview_update_toggle = false
    @State private var is_object_appeared = false
    #endif
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            //Placeholder
            HStack
            {
                Picker(selection: .constant(1), label: Text("Picker"))
                {
                    Text("1").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .hidden()
            }
            .padding([.horizontal, .top])
            //Placeholder
            
            if avaliable_for_place
            {
                #if os(macOS)
                switch object_selection
                {
                case .robot:
                    WorkspaceObjectCard(document: $document, object: base_workspace.robot_by_name(viewed_object_name), remove_completion: { viewed_object_name = base_workspace.placed_robots_names.last ?? "" })
                    
                    HStack
                    {
                        Picker("Object", selection: $viewed_object_name)
                        {
                            ForEach(base_workspace.placed_robots_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .buttonStyle(.borderless)
                    }
                    .padding([.horizontal, .bottom])
                    .onAppear
                    {
                        viewed_object_name = base_workspace.placed_robots_names.first ?? ""
                    }
                case .tool:
                    WorkspaceObjectCard(document: $document, object: base_workspace.tool_by_name(viewed_object_name), remove_completion: { viewed_object_name = base_workspace.placed_tools_names.last ?? "" })
                    
                    HStack
                    {
                        Picker("Object", selection: $viewed_object_name)
                        {
                            ForEach(base_workspace.placed_tools_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .buttonStyle(.borderless)
                    }
                    .padding([.horizontal, .bottom])
                    .onAppear
                    {
                        viewed_object_name = base_workspace.placed_tools_names.first ?? ""
                    }
                case .part:
                    WorkspaceObjectCard(document: $document, object: base_workspace.part_by_name(viewed_object_name), remove_completion: { viewed_object_name = base_workspace.placed_parts_names.last ?? "" })
                    
                    HStack
                    {
                        Picker("Object", selection: $viewed_object_name)
                        {
                            ForEach(base_workspace.placed_parts_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .buttonStyle(.borderless)
                    }
                    .padding([.horizontal, .bottom])
                    .onAppear
                    {
                        viewed_object_name = base_workspace.placed_parts_names.first ?? ""
                    }
                }
                #else
                TabView(selection: $viewed_object_name)
                {
                    switch object_selection
                    {
                    case .robot:
                        ForEach(base_workspace.placed_robots_names, id: \.self)
                        { name in
                            WorkspaceObjectCard(document: $document, object: base_workspace.robot_by_name(name), remove_completion: { viewed_object_name = base_workspace.placed_robots_names.last ?? "" })
                                .tag(name)
                        }
                    case .tool:
                        ForEach(base_workspace.placed_tools_names, id: \.self)
                        { name in
                            WorkspaceObjectCard(document: $document, object: base_workspace.tool_by_name(name), remove_completion: { viewed_object_name = base_workspace.placed_tools_names.last ?? "" })
                                .tag(name)
                        }
                    case .part:
                        ForEach(base_workspace.placed_parts_names, id: \.self)
                        { name in
                            WorkspaceObjectCard(document: $document, object: base_workspace.part_by_name(name), remove_completion: { viewed_object_name = base_workspace.placed_parts_names.last ?? "" }).tag(name)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .automatic))
                .onAppear
                {
                    switch object_selection
                    {
                    case .robot:
                        viewed_object_name = base_workspace.placed_robots_names.first ?? ""
                    case .tool:
                        viewed_object_name = base_workspace.placed_tools_names.first ?? ""
                    case .part:
                        viewed_object_name = base_workspace.placed_parts_names.first ?? ""
                    }
                }
                .modifier(DoubleModifier(update_toggle: $tabview_update_toggle))
                #endif
            }
            else
            {
                Text("No objects placed")
                    .fontWeight(.bold)
                    .font(.system(.title, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 8)
                    .padding()
                    .frame(maxHeight: .infinity)
            }
            
            //MARK: Object edit card
            HStack(spacing: 0)
            {
                if viewed_object_name != "" && avaliable_for_place && base_workspace.selected_object != nil
                {
                    HStack
                    {
                        CardInfoView(document: $document, object: base_workspace.selected_object)
                            .modifier(DoubleModifier(update_toggle: $update_toggle))
                    }
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.trailing)
                    .shadow(radius: 8.0)
                }
                
                HStack
                {
                    switch object_selection
                    {
                    case .robot:
                        ObjectPlaceButton(document: $document, workspace_object_type: .constant(WorkspaceObjectType.robot))
                            .padding(.vertical)
                            .disabled(base_workspace.avaliable_robots_names.count == 0)
                    case .tool:
                        ObjectPlaceButton(document: $document, workspace_object_type: .constant(WorkspaceObjectType.tool))
                            .padding(.vertical)
                            .disabled(base_workspace.avaliable_tools_names.count == 0)
                    case .part:
                        ObjectPlaceButton(document: $document, workspace_object_type: .constant(WorkspaceObjectType.part))
                            .padding(.vertical)
                            .disabled(base_workspace.avaliable_parts_names.count == 0)
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(.gray)
        .overlay(alignment: .top)
        {
            HStack
            {
                Picker("Objects", selection: $object_selection)
                {
                    ForEach(WorkspaceObjectType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue + "s").tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .buttonStyle(.borderless)
                .padding([.horizontal, .top])
                .onChange(of: object_selection)
                { _ in
                    switch object_selection
                    {
                    case .robot:
                        base_workspace.deselect_tool()
                        base_workspace.deselect_part()
                        
                        viewed_object_name = base_workspace.placed_robots_names.first ?? ""
                    case .tool:
                        base_workspace.deselect_robot()
                        base_workspace.deselect_part()
                        
                        viewed_object_name = base_workspace.placed_tools_names.first ?? ""
                    case .part:
                        base_workspace.deselect_robot()
                        base_workspace.deselect_tool()
                        
                        viewed_object_name = base_workspace.placed_parts_names.first ?? ""
                    }
                    
                    new_object_select()
                    object_type_changed = true
                    
                    #if os(iOS)
                    tabview_update_toggle.toggle()
                    #endif
                }
                .onChange(of: viewed_object_name)
                { _ in
                    if !object_type_changed
                    {
                        new_object_select()
                    }
                    else
                    {
                        object_type_changed = false
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #else
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var avaliable_for_place: Bool
    {
        var avaliable_for_place = true
        
        switch object_selection
        {
        case .robot:
            avaliable_for_place = base_workspace.placed_robots_names.count > 0
        case .tool:
            avaliable_for_place = base_workspace.placed_tools_names.count > 0
        case .part:
            avaliable_for_place = base_workspace.placed_parts_names.count > 0
        }
        
        return avaliable_for_place
    }
    
    private func new_object_select()
    {
        //update_toggle.toggle()
        
        switch object_selection
        {
        case .robot:
            base_workspace.deselect_robot()
            base_workspace.select_robot(name: viewed_object_name)
        case .tool:
            base_workspace.deselect_tool()
            base_workspace.select_tool(name: viewed_object_name)
        case .part:
            base_workspace.deselect_part()
            base_workspace.select_part(name: viewed_object_name)
        }
        update_toggle.toggle()
    }
}

struct WorkspaceObjectCard: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
    var object: WorkspaceObject
    var remove_completion: (() -> Void)
    
    var body: some View
    {
        Rectangle()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.thinMaterial)
        .overlay(alignment: .topLeading)
        {
            Rectangle()
                .foregroundColor(.gray)
                .overlay
                {
                    #if os(macOS)
                    ZStack
                    {
                        Image(nsImage: object.image)
                            .resizable()
                            .scaledToFill()
                            .shadow(radius: 8.0)
                    }
                    #else
                    Image(uiImage: object.image)
                        .resizable()
                        .scaledToFill()
                        .shadow(radius: 8.0)
                    #endif
                }
                .overlay(alignment: .topLeading)
                {
                    Text(object.name ?? "None")
                        .fontWeight(.bold)
                        .font(.system(.title, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                }
                .overlay(alignment: .topTrailing)
                {
                    Button(action: remove_object)
                    {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .imageScale(.large)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding()
                //.shadow(radius: 8.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 8.0)
        .padding()
        #if os(iOS)
        .padding(.bottom, 32)
        #endif
    }
    
    private func remove_object()
    {
        object.is_placed = false
        
        switch object
        {
        case is Robot:
            document.preset.robots = base_workspace.file_data().robots
        case is Tool:
            if (object as! Tool).is_attached
            {
                clear_constranints(node: object.node ?? SCNNode())
                (object as! Tool).attached_to = nil
                
                //base_workspace.remove_attachment()
                base_workspace.selected_tool.is_attached = false
            }
            document.preset.tools = base_workspace.file_data().tools
        case is Part:
            document.preset.parts = base_workspace.file_data().parts
        default:
            break
        }
        
        remove_completion()
    }
}

struct CardInfoView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var object: WorkspaceObject?
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var avaliable_attachments = [String]()
    @State private var attach_robot_name = String()
    @State private var old_attachment: String?
    
    @State private var location: [Float] = [0, 0, 0]
    @State private var rotation: [Float] = [0, 0, 0]
    @State private var is_attached = false
    
    @State var is_compact = false
    @State private var appeared = false
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            //Selected object position editor
            DynamicStack(content: {
                switch object
                {
                case is Robot:
                    PositionView(location: $location, rotation: $rotation)
                        .onChange(of: [location, rotation])
                        { values in
                            if appeared
                            {
                                object?.location = values[0]
                                object?.rotation = values[1]
                                
                                document.preset.robots = base_workspace.file_data().robots
                            }
                        }
                case is Tool:
                    if !is_attached
                    {
                        PositionView(location: $location, rotation: $rotation)
                            .onChange(of: [location, rotation])
                            { values in
                                if appeared
                                {
                                    object?.location = values[0]
                                    object?.rotation = values[1]
                                    
                                    document.preset.tools = base_workspace.file_data().tools
                                }
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
                                { new_value in
                                    if appeared
                                    {
                                        (object as! Tool).attached_to = new_value
                                        document.preset.tools = base_workspace.file_data().tools
                                        
                                        clear_constranints(node: object?.node ?? SCNNode())
                                        object?.node?.constraints?.append(SCNReplicatorConstraint(target: base_workspace.robot_by_name(new_value).tool_node))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                                #if os(iOS)
                                .buttonStyle(.bordered)
                                #endif
                            }
                            else
                            {
                                Text("No robots for attach")
                                    .padding([.horizontal, .top])
                            }
                        }
                    }
                case is Part:
                    PositionView(location: $location, rotation: $rotation)
                        .onChange(of: [location, rotation])
                        { values in
                            if appeared
                            {
                                object?.location = values[0]
                                object?.rotation = values[1]
                                
                                document.preset.parts = base_workspace.file_data().parts
                            }
                        }
                default:
                    Text("None")
                }
                
                //Tool pin view
                if object is Tool
                {
                    Toggle(isOn: $is_attached)
                    {
                        Image(systemName: "pin.fill")
                    }
                    .toggleStyle(.button)
                    .onChange(of: is_attached)
                    { new_value in
                        if new_value
                        {
                            if avaliable_attachments.count > 0
                            {
                                if (object as! Tool).attached_to == nil
                                {
                                    attach_robot_name = avaliable_attachments.first ?? ""
                                    
                                    object?.node?.constraints?.append(SCNReplicatorConstraint(target: base_workspace.robot_by_name(attach_robot_name).tool_node))
                                }
                            }
                        }
                        else
                        {
                            (object as! Tool).attached_to = nil
                            clear_constranints(node: object?.node ?? SCNNode())
                        }
                        
                        if appeared
                        {
                            (object as! Tool).is_attached = new_value
                            document.preset.tools = base_workspace.file_data().tools
                        }
                    }
                }
            }, is_compact: $is_compact, spacing: 12)
            .padding()
        }
        .onAppear
        {
            location = object!.location
            rotation = object!.rotation
            
            if object is Tool
            {
                is_attached = (object as! Tool).is_attached
                
                if is_attached
                {
                    (object as! Tool).is_attached = false
                    avaliable_attachments = base_workspace.attachable_robots_names
                    (object as! Tool).is_attached = true
                    
                    attach_robot_name = (object as! Tool).attached_to!
                }
                else
                {
                    avaliable_attachments = base_workspace.attachable_robots_names
                }
                
                old_attachment = (object as! Tool).attached_to
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                appeared = true
            }
        }
    }
}

struct ObjectPlaceButton: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var workspace_object_type: WorkspaceObjectType
    
    @State private var add_in_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            Button(action: { add_in_view_presented.toggle() })
            {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .padding()
                #if os(iOS)
                    .foregroundColor((!base_workspace.add_in_view_disabled || base_workspace.performed) ? Color.secondary : Color.black)
                #endif
            }
            .buttonStyle(.borderless)
            #if os(iOS)
            .foregroundColor(.black)
            #endif
            .popover(isPresented: $add_in_view_presented)
            {
                switch workspace_object_type
                {
                case .robot:
                    AddObjectView(document: $document, add_in_view_presented: $add_in_view_presented, avaliable_objects_names: .constant(base_workspace.avaliable_robots_names), workspace_object_type: $workspace_object_type, selected_object_name: base_workspace.avaliable_robots_names.first ?? "")
                case .tool:
                    AddObjectView(document: $document, add_in_view_presented: $add_in_view_presented, avaliable_objects_names: .constant(base_workspace.avaliable_tools_names), workspace_object_type: $workspace_object_type, selected_object_name: base_workspace.avaliable_tools_names.first ?? "")
                case .part:
                    AddObjectView(document: $document, add_in_view_presented: $add_in_view_presented, avaliable_objects_names: .constant(base_workspace.avaliable_parts_names), workspace_object_type: $workspace_object_type, selected_object_name: base_workspace.avaliable_parts_names.first ?? "")
                }
            }
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
    }
}

struct AddObjectView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var add_in_view_presented: Bool
    @Binding var avaliable_objects_names: [String]
    @Binding var workspace_object_type: WorkspaceObjectType
    
    @State var selected_object_name = String()
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Picker("Name", selection: $selected_object_name) //Select object name for place in workspace
            {
                ForEach(avaliable_objects_names, id: \.self)
                { name in
                    Text(name)
                }
            }
            .labelsHidden()
            .padding(.bottom)
            .frame(maxWidth: .infinity)
            #if os(macOS)
            .pickerStyle(.radioGroup)
            #else
            .pickerStyle(.wheel)
            #endif
            
            HStack
            {
                Button(action: place_object)
                {
                    Text("Place")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
    
    private func place_object()
    {
        switch workspace_object_type
        {
        case .robot:
            base_workspace.robot_by_name(selected_object_name).is_placed = true
            document.preset.robots = base_workspace.file_data().robots
        case .tool:
            base_workspace.tool_by_name(selected_object_name).is_placed = true
            document.preset.tools = base_workspace.file_data().tools
        case .part:
            base_workspace.part_by_name(selected_object_name).is_placed = true
            document.preset.parts = base_workspace.file_data().parts
        }
        
        add_in_view_presented = false
    }
}

//MARK: - Previews
struct WorkspaceView_Previews: PreviewProvider
{
    @EnvironmentObject var base_workspace: Workspace
    
    static var previews: some View
    {
        Group
        {
            #if os(macOS)
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            #else
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), file_name: .constant("None"), file_url: .constant(URL(fileURLWithPath: "")))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            #endif
            WorkspaceCardsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            AddInWorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), add_in_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            InfoView(info_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
        }
        #if os(iOS)
        .previewDevice("iPad mini (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
        #endif
    }
}
