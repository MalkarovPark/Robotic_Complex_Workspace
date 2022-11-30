//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct WorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var first_loaded: Bool
    #if os(iOS)
    @Binding var file_name: String
    @Binding var file_url: URL
    
    @EnvironmentObject var app_state: AppState
    #endif
    
    @State var worked = false
    
    @EnvironmentObject var base_workspace: Workspace
    
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
            if !first_loaded
            {
                ComplexWorkspaceView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .onDisappear(perform: stop_perform)
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
                    if !first_loaded
                    {
                        ComplexWorkspaceView(document: $document)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                            .onDisappear(perform: stop_perform)
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
                if !first_loaded
                {
                    ComplexWorkspaceView(document: $document)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                        .onDisappear(perform: stop_perform)
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
            .onAppear()
        {
            if first_loaded
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    first_loaded = false
                }
            }
        }
        
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
                                .frame(width: 512)
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
                                .frame(width: 512)
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
        .onDisappear
        { 
            base_workspace.deselect_object()
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
        //Connect scene to class and add placed robots and details in workspace
        base_workspace.connect_scene(viewed_scene)
        
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
        //Connect scene to class and add placed robots and details in workspace
        base_workspace.connect_scene(viewed_scene)
        
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
    @State var selected_detail_name = String()
    
    @State var tool_attached = false
    @State var attach_robot_name = String()
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var add_in_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    @State var is_compact = false
    #endif
    
    @State var first_select = true //This flag that specifies that the robot was not selected and disables the dismiss() function
    private let add_items: [String] = ["Add Robot", "Add Tool", "Add Detail"]
    
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
                #if os(iOS)
                Text("Name")
                    .font(.subheadline)
                #endif
                
                switch app_state.add_selection
                {
                case 0:
                    ObjectPickerView(selected_object_name: $selected_robot_name, avaliable_objects_names: .constant(base_workspace.avaliable_robots_names), workspace_object_type: .constant(.robot))
                case 1:
                    ObjectPickerView(selected_object_name: $selected_tool_name, avaliable_objects_names: .constant(base_workspace.avaliable_tools_names), workspace_object_type: .constant(.tool))
                    
                    Toggle(isOn: $tool_attached)
                    {
                        Image(systemName: "pin.fill")
                    }
                    .toggleStyle(.button)
                case 2:
                    ObjectPickerView(selected_object_name: $selected_detail_name, avaliable_objects_names: .constant(base_workspace.avaliable_details_names), workspace_object_type: .constant(.detail))
                default:
                    Text("None")
                }
            }
            .padding()
            
            Divider()
            
            //MARK: Object position set
            #if os(macOS)
            switch app_state.add_selection
            {
            case 0:
                HStack(spacing: 16)
                {
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                }
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
                        HStack(spacing: 16)
                        {
                            PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                        }
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
                            Picker("Attach to", selection: $attach_robot_name) //Select object name for place in workspace
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
                HStack(spacing: 16)
                {
                    PositionView(location: $base_workspace.selected_detail.location, rotation: $base_workspace.selected_detail.rotation)
                }
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_detail.location, base_workspace.selected_detail.rotation])
                { _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_details_names.count == 0)
            default:
                Text("None")
            }
            #else
            switch app_state.add_selection
            {
            case 0:
                DynamicStack(content: {
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                }, is_compact: $is_compact, spacing: 12)
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
                            Picker("Attach to", selection: $attach_robot_name) //Select object name for place in workspace
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
                    PositionView(location: $base_workspace.selected_detail.location, rotation: $base_workspace.selected_detail.rotation)
                }, is_compact: $is_compact, spacing: 12)
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_detail.location, base_workspace.selected_detail.rotation])
                { _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_details_names.count == 0)
            default:
                Text("None")
            }
            
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
    
    func place_object()
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
        case.detail:
            document.preset.details = base_workspace.file_data().details
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
    
    @State var avaliable_attachments = [String]()
    @State var attach_robot_name = String()
    @State private var old_attachment: String?
    
    #if os(iOS)
    @State var is_compact = false
    #endif
    
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
                    Text("\(base_workspace.selected_robot.name ?? "None")")
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
            case .detail:
                Text("\(base_workspace.selected_detail.name ?? "None")")
                    .font(.title3)
                    .padding([.horizontal, .top])
            default:
                Text("None")
            }
            
            //Selected object position editor
            #if os(macOS)
            HStack(spacing: 16)
            {
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
                                .padding(.horizontal)
                                #if os(iOS)
                                .buttonStyle(.bordered)
                                #endif
                            }
                            else
                            {
                                Text("No robots for attach")
                                    .padding(.horizontal)
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
                case .detail:
                    PositionView(location: $base_workspace.selected_detail.location, rotation: $base_workspace.selected_detail.rotation)
                        .onChange(of: [base_workspace.selected_detail.location, base_workspace.selected_detail.rotation])
                        { _ in
                            base_workspace.update_object_position()
                            document.preset.details = base_workspace.file_data().details
                        }
                default:
                    Text("None")
                }
            }
            .padding([.horizontal, .top])
            #else
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
                case .detail:
                    PositionView(location: $base_workspace.selected_detail.location, rotation: $base_workspace.selected_detail.rotation)
                        .onChange(of: [base_workspace.selected_detail.location, base_workspace.selected_detail.rotation])
                        { _ in
                            base_workspace.update_object_position()
                            document.preset.details = base_workspace.file_data().details
                        }
                default:
                    Text("None")
                }
            }, is_compact: $is_compact, spacing: 12)
            .padding([.horizontal, .top])
            
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
    
    func remove_object()
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
        case.detail:
            document.preset.details = base_workspace.file_data().details
        default:
            break
        }
        
        info_view_presented.toggle()
    }
}

struct PositionView: View
{
    @Binding var location: [Float]
    @Binding var rotation: [Float]
    
    var body: some View
    {
        ForEach(PositionComponents.allCases, id: \.self)
        { position_component in
            GroupBox(label: Text(position_component.rawValue)
                .font(.headline))
            {
                VStack(spacing: 12)
                {
                    switch position_component
                    {
                    case .location:
                        ForEach(LocationComponents.allCases, id: \.self)
                        { location_component in
                            HStack(spacing: 8)
                            {
                                Text(location_component.info.text)
                                    .frame(width: 20.0)
                                TextField("0", value: $location[location_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
                                Stepper("Enter", value: $location[location_component.info.index], in: -1000...1000)
                                    .labelsHidden()
                            }
                        }
                    case .rotation:
                        ForEach(RotationComponents.allCases, id: \.self)
                        { rotation_component in
                            HStack(spacing: 8)
                            {
                                Text(rotation_component.info.text)
                                    .frame(width: 20.0)
                                TextField("0", value: $rotation[rotation_component.info.index], format: .number)
                                    .textFieldStyle(.roundedBorder)
                                Stepper("Enter", value: $rotation[rotation_component.info.index], in: -180...180)
                                    .labelsHidden()
                            }
                        }
                    }
                }
                .padding(8.0)
            }
        }
    }
}

//MARK: - Control program view
struct ControlProgramView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var program_columns = Array(repeating: GridItem(.flexible()), count: 1)
    @State var dragged_element: WorkspaceProgramElement?
    @State var add_element_view_presented = false
    @State var add_new_element_data = workspace_program_element_struct()
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
            //MARK: Scroll view for program elements
            ScrollView
            {
                LazyVGrid(columns: program_columns)
                {
                    ForEach(base_workspace.elements)
                    { element in
                        ElementCardView(elements: $base_workspace.elements, document: $document, element_item: element, on_delete: remove_elements)
                        .onDrag({
                            self.dragged_element = element
                            return NSItemProvider(object: element.id.uuidString as NSItemProviderWriting)
                        }, preview: {
                            ElementCardViewPreview(element_item: element)
                        })
                        .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $base_workspace.elements, dragged_element: $dragged_element, document: $document, workspace_elements: base_workspace.file_data().elements, element: element))
                    }
                    .padding(4)
                }
                .padding()
                .disabled(base_workspace.performed)
            }
            .animation(.spring(), value: base_workspace.elements)
            
            //MARK: New program element button
            VStack
            {
                Spacer()
                HStack
                {
                    Spacer()
                    ZStack(alignment: .trailing)
                    {
                        Button(action: add_new_program_element) //Add element button
                        {
                            HStack
                            {
                                Text("Add Element")
                                Spacer()
                            }
                            .padding()
                        }
                        #if os(macOS)
                        .frame(maxWidth: 144.0, alignment: .leading)
                        #else
                        .frame(maxWidth: 176.0, alignment: .leading)
                        #endif
                        .background(.thinMaterial)
                        .cornerRadius(32)
                        .shadow(radius: 4.0)
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding()
                        
                        Button(action: { add_element_view_presented.toggle() }) //Configure new element button
                        {
                            Circle()
                                .foregroundColor(add_button_color())
                                .overlay(
                                    add_button_image()
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: add_button_image())
                                )
                                .frame(width: 32, height: 32)
                                .animation(.easeInOut(duration: 0.2), value: add_button_color())
                        }
                        .popover(isPresented: $add_element_view_presented)
                        {
                            AddElementView(add_element_view_presented: $add_element_view_presented, add_new_element_data: $add_new_element_data)
                            #if os(iOS)
                                .presentationDetents([.height(128.0)])
                            #endif
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding(.trailing, 24)
                    }
                }
            }
        }
    }
    
    func add_new_program_element()
    {
        base_workspace.update_view()
        //let new_program_element = WorkspaceProgramElement(element_type: add_new_element_data.element_type, performer_type: add_new_element_data.performer_type, modificator_type: add_new_element_data.modificator_type, logic_type: add_new_element_data.logic_type)
        let new_program_element = WorkspaceProgramElement(element_struct: add_new_element_data)
        
        //Checking for existing workspace components for element selection
        switch new_program_element.element_data.element_type
        {
        case .perofrmer:
            switch new_program_element.element_data.performer_type
            {
            case .robot:
                if base_workspace.placed_robots_names.count > 0
                {
                    new_program_element.element_data.robot_name = base_workspace.placed_robots_names.first!
                    base_workspace.select_robot(name: new_program_element.element_data.robot_name)
                    
                    if base_workspace.selected_robot.programs_count > 0
                    {
                        new_program_element.element_data.program_name = base_workspace.selected_robot.programs_names.first!
                    }
                    base_workspace.deselect_robot()
                }
            case .tool:
                break
            }
        case .modificator:
            break
        case .logic:
            break
        }
        
        //Add new program element and save to file
        base_workspace.elements.append(new_program_element)
        document.preset.elements = base_workspace.file_data().elements
    }
    
    //MARK: Button image by element subtype
    func add_button_image() -> Image
    {
        var badge_image: Image
        
        switch add_new_element_data.element_type
        {
        case .perofrmer:
            switch add_new_element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modificator:
            switch add_new_element_data.modificator_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch add_new_element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    //MARK: Button color by element type
    func add_button_color() -> Color
    {
        var badge_color: Color
        
        switch add_new_element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modificator:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
    
    func remove_elements(at offsets: IndexSet) //Remove program element function
    {
        withAnimation
        {
            base_workspace.elements.remove(atOffsets: offsets)
        }
        
        document.preset.elements = base_workspace.file_data().elements
    }
}

//MARK: - Drag and Drop delegate
struct WorkspaceDropDelegate : DropDelegate
{
    @Binding var elements : [WorkspaceProgramElement]
    @Binding var dragged_element : WorkspaceProgramElement?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_elements: [workspace_program_element_struct]
    
    let element: WorkspaceProgramElement
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.elements = workspace_elements //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_element = self.dragged_element else
        {
            return
        }
        
        if dragged_element != element
        {
            let from = elements.firstIndex(of: dragged_element)!
            let to = elements.firstIndex(of: element)!
            withAnimation(.default)
            {
                self.elements.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Workspace program element card view
struct ElementCardView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var element_item: WorkspaceProgramElement
    @State var element_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        badge_image()
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: badge_image())
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: badge_color())
                    
                    VStack(alignment: .leading)
                    {
                        Text(element_item.subtype)
                            .font(.title3)
                            .animation(.easeInOut(duration: 0.2), value: element_item.element_data.element_type.rawValue)
                        Text(element_item.info)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: element_item.info)
                    }
                    .padding([.trailing], 32.0)
                }
            }
        }
        .frame(height: 80)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
        .onTapGesture
        {
            element_view_presented.toggle()
        }
        .popover(isPresented: $element_view_presented,
                 arrowEdge: .trailing)
        {
            ElementView(elements: $elements, element_item: $element_item, element_view_presented: $element_view_presented, document: $document, new_element_item_data: element_item.element_data, on_delete: on_delete)
        }
        .overlay(alignment: .topTrailing)
        {
            if base_workspace.is_current_element(element: element_item)
            {
                Circle()
                    .foregroundColor(Color.yellow)
                    .frame(width: 16, height: 16)
                    .padding()
                    .shadow(radius: 8.0)
                    .transition(AnyTransition.scale)
            }
        }
    }
    
    //MARK: Badge image by element subtype
    func badge_image() -> Image
    {
        var badge_image: Image
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            switch element_item.element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modificator:
            switch element_item.element_data.modificator_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch element_item.element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    //MARK: Badge color by element type
    func badge_color() -> Color
    {
        var badge_color: Color
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modificator:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
}

//MARK: - Workspace program element card preview for drag
struct ElementCardViewPreview: View
{
    @State var element_item: WorkspaceProgramElement
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        badge_image()
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: badge_image())
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(16)
                    
                    VStack(alignment: .leading)
                    {
                        Text(element_item.subtype)
                            .font(.title3)
                        Text(element_item.info)
                            .foregroundColor(.secondary)
                    }
                    .padding([.trailing], 32.0)
                }
            }
        }
        .frame(height: 80)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    }
    
    func badge_image() -> Image
    {
        var badge_image: Image
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            switch element_item.element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modificator:
            switch element_item.element_data.modificator_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch element_item.element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    func badge_color() -> Color
    {
        var badge_color: Color
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modificator:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
}

//MARK: - Add element view
struct AddElementView: View
{
    @Binding var add_element_view_presented: Bool
    @Binding var add_new_element_data: workspace_program_element_struct
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                //MARK: Type picker
                Picker("Type", selection: $add_new_element_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.bottom, 8.0)
                
                //MARK: Subtype pickers cases
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch add_new_element_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $add_new_element_data.performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    case .modificator:
                        Picker("Type", selection: $add_new_element_data.modificator_type)
                        {
                            ForEach(ModificatorType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    case .logic:
                        Picker("Type", selection: $add_new_element_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
    }
}

struct ElementView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var element_item: WorkspaceProgramElement
    @Binding var element_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var new_element_item_data: workspace_program_element_struct
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                //MARK: Type picker
                Picker("Type", selection: $new_element_item_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.bottom, 8.0)
                
                //MARK: Subtype pickers cases
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch new_element_item_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $new_element_item_data.performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    case .modificator:
                        Picker("Type", selection: $new_element_item_data.modificator_type)
                        {
                            ForEach(ModificatorType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    case .logic:
                        Picker("Type", selection: $new_element_item_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    }
                }
            }
            .padding()
            Divider()
            
            Spacer()
            
            //MARK: Type views cases
            VStack
            {
                switch new_element_item_data.element_type
                {
                case .perofrmer:
                    PerformerElementView(performer_type: $new_element_item_data.performer_type, robot_name: $new_element_item_data.robot_name, program_name: $new_element_item_data.program_name, tool_name: $new_element_item_data.tool_name)
                case .modificator:
                    ModificatorElementView(modificator_type: $new_element_item_data.modificator_type)
                case .logic:
                    LogicElementView(logic_type: $new_element_item_data.logic_type, mark_name: $new_element_item_data.mark_name, target_mark_name: $new_element_item_data.target_mark_name)
                }
            }
            .padding()
            
            Spacer()
            
            //MARK: Delete and save buttons
            Divider()
            HStack
            {
                Button("Delete", action: delete_program_element)
                    .padding()
                
                Spacer()
                
                Button("Update", action: update_program_element)
                    .keyboardShortcut(.defaultAction)
                    .padding()
                #if os(macOS)
                    .foregroundColor(Color.white)
                #endif
            }
        }
    }
    
    //MARK: Program elements manage functions
    func update_program_element()
    {
        element_item.element_data = new_element_item_data
        base_workspace.elements_check()
        
        document.preset.elements = base_workspace.file_data().elements
        
        element_view_presented.toggle()
    }
    
    func delete_program_element()
    {
        delete_element()
        base_workspace.update_view()
        
        element_view_presented.toggle()
    }
    
    func delete_element()
    {
        if let index = elements.firstIndex(of: element_item)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
    }
}

//MARK: - Performer element view
struct PerformerElementView: View
{
    @Binding var performer_type: PerformerType
    @Binding var robot_name: String
    @Binding var program_name: String
    @Binding var tool_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_robot: Robot?
    @State private var viewed_tool: Tool?
    
    var body: some View
    {
        VStack
        {
            switch performer_type
            {
            case .robot:
                //MARK: Robot subview
                if base_workspace.placed_robots_names.count > 0
                {
                    //MARK: Robot subview
                    #if os(macOS)
                    Picker("Name", selection: $robot_name) //Robot picker
                    {
                        ForEach(base_workspace.placed_robots_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: robot_name)
                    { _ in
                        viewed_robot = base_workspace.robot_by_name(robot_name)
                        if viewed_robot?.programs_names.count ?? 0 > 0
                        {
                            program_name = viewed_robot?.programs_names.first ?? ""
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if robot_name == ""
                        {
                            robot_name = base_workspace.placed_robots_names.first!
                        }
                        else
                        {
                            viewed_robot = base_workspace.robot_by_name(robot_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.placed_robots_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $program_name) //Robot program picker
                    {
                        if viewed_robot?.programs_names.count ?? 0 > 0
                        {
                            ForEach(viewed_robot!.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(viewed_robot?.programs_names.count == 0)
                    #else
                    VStack
                    {
                        GeometryReader
                        { geometry in
                            HStack(spacing: 0)
                            {
                                Picker("Name", selection: $robot_name) //Robot picker
                                {
                                    if base_workspace.placed_robots_names.count > 0
                                    {
                                        ForEach(base_workspace.placed_robots_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .onChange(of: robot_name)
                                { _ in
                                    viewed_robot = base_workspace.robot_by_name(robot_name)
                                    if viewed_robot?.programs_names.count ?? 0 > 0
                                    {
                                        program_name = viewed_robot?.programs_names.first ?? ""
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if robot_name == ""
                                    {
                                        robot_name = base_workspace.placed_robots_names[0]
                                    }
                                    else
                                    {
                                        viewed_robot = base_workspace.robot_by_name(robot_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.placed_robots_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                                
                                Picker("Program", selection: $program_name) //Robot program picker
                                {
                                    if viewed_robot?.programs_names.count ?? 0 > 0
                                    {
                                        ForEach(viewed_robot!.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(viewed_robot?.programs_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                            }
                        }
                    }
                    .frame(height: 128)
                    #endif
                }
                else
                {
                    Text("No robots placed in this workspace")
                }
            case .tool:
                //MARK: Tool subview
                if base_workspace.placed_tools_names.count > 0
                {
                    //MARK: tool subview
                    #if os(macOS)
                    Picker("Name", selection: $tool_name) //tool picker
                    {
                        ForEach(base_workspace.placed_tools_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: tool_name)
                    { _ in
                        viewed_tool = base_workspace.tool_by_name(tool_name)
                        if viewed_tool?.programs_names.count ?? 0 > 0
                        {
                            program_name = viewed_tool?.programs_names.first ?? ""
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if tool_name == ""
                        {
                            tool_name = base_workspace.placed_tools_names.first!
                        }
                        else
                        {
                            viewed_tool = base_workspace.tool_by_name(tool_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.placed_tools_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $program_name) //tool program picker
                    {
                        if viewed_tool?.programs_names.count ?? 0 > 0
                        {
                            ForEach(viewed_tool!.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(viewed_tool?.programs_names.count == 0)
                    #else
                    VStack
                    {
                        GeometryReader
                        { geometry in
                            HStack(spacing: 0)
                            {
                                Picker("Name", selection: $tool_name) //tool picker
                                {
                                    if base_workspace.placed_tools_names.count > 0
                                    {
                                        ForEach(base_workspace.placed_tools_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .onChange(of: tool_name)
                                { _ in
                                    viewed_tool = base_workspace.tool_by_name(tool_name)
                                    if viewed_tool?.programs_names.count ?? 0 > 0
                                    {
                                        program_name = viewed_tool?.programs_names.first ?? ""
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if tool_name == ""
                                    {
                                        tool_name = base_workspace.placed_tools_names[0]
                                    }
                                    else
                                    {
                                        viewed_tool = base_workspace.tool_by_name(tool_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.placed_tools_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                                
                                Picker("Program", selection: $program_name) //tool program picker
                                {
                                    if viewed_tool?.programs_names.count ?? 0 > 0
                                    {
                                        ForEach(viewed_tool!.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(viewed_tool?.programs_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                            }
                        }
                    }
                    .frame(height: 128)
                    #endif
                }
                else
                {
                    Text("No tools placed in this workspace")
                }
            }
        }
    }
}

//MARK: - Modificator element view
struct ModificatorElementView: View
{
    @Binding var modificator_type: ModificatorType
    var body: some View
    {
        Text("Modificator")
        switch modificator_type
        {
        case .observer:
            //MARK: Observer subview
            Text("Observer")
        case .changer:
            //MARK: Changer subview
            Text("Changer")
        }
    }
}

//MARK: - Logic element view
struct LogicElementView: View
{
    @Binding var logic_type: LogicType
    @Binding var mark_name: String
    @Binding var target_mark_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            switch logic_type
            {
            case .jump:
                //MARK: Jump subview
                #if os(macOS)
                HStack
                {
                    Picker("To Mark:", selection: $target_mark_name) //Target mark picker
                    {
                        if base_workspace.marks_names.count > 0
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .onAppear
                    {
                        if base_workspace.marks_names.count > 0 && target_mark_name == ""
                        {
                            target_mark_name = base_workspace.marks_names[0]
                        }
                    }
                    .disabled(base_workspace.marks_names.count == 0)
                }
                #else
                VStack
                {
                    if base_workspace.marks_names.count > 0
                    {
                        Text("To mark:")
                        Picker("To Mark:", selection: $target_mark_name) //Target mark picker
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .onAppear
                        {
                            if base_workspace.marks_names.count > 0 && target_mark_name == ""
                            {
                                target_mark_name = base_workspace.marks_names[0]
                            }
                        }
                        .disabled(base_workspace.marks_names.count == 0)
                        .pickerStyle(.wheel)
                    }
                    else
                    {
                        Text("No marks")
                    }
                }
                #endif
            case .mark:
                //MARK: Mark subview
                HStack
                {
                    Text("Name")
                    TextField("None", text: $mark_name) //Mark name field
                        .textFieldStyle(.roundedBorder)
                }
            case .equal:
                //MARK: Equal subview
                Text("Equal")
            case .unequal:
                //MARK: Unequal subview
                Text("Unequal")
            }
        }
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
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), first_loaded: .constant(false))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            #else
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), first_loaded: .constant(false), file_name: .constant("None"), file_url: .constant(URL(fileURLWithPath: "")))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            #endif
            AddInWorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), add_in_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            InfoView(info_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            ElementCardView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), document: .constant(Robotic_Complex_WorkspaceDocument()), element_item: WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            ElementView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), element_item: .constant(WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)), element_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), new_element_item_data: workspace_program_element_struct(element_type: .logic, performer_type: .robot, modificator_type: .changer, logic_type: .jump), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            LogicElementView(logic_type: .constant(.mark), mark_name: .constant("Mark Name"), target_mark_name: .constant("Target Mark Name"))
        }
    }
}