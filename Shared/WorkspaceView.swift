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
    @State var cycle = false
    @State var worked = false
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    
    //Picker data for thin window size
    @State private var wv_selection = 0
    private let wv_items: [String] = ["View", "Control"]
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
            ComplexWorkspaceView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            ControlProgramView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                if wv_selection == 0
                {
                    ComplexWorkspaceView(document: $document)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
                else
                {
                    ControlProgramView(document: $document)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            else
            {
                ComplexWorkspaceView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction)
            {
                if horizontal_size_class == .compact
                {
                    Picker("Workspace", selection: $wv_selection)
                    {
                        ForEach(0..<wv_items.count, id: \.self)
                        { index in
                            Text(self.wv_items[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
            }
            #endif
            ToolbarItem(placement: placement_trailing)
            {
                //MARK: Workspace performing elements
                HStack(alignment: .center)
                {
                    Button(action: change_cycle)
                    {
                        if cycle == false
                        {
                            Label("One", systemImage: "repeat.1")
                        }
                        else
                        {
                            Label("Repeat", systemImage: "repeat")
                        }
                    }
                    Button(action: add_robot)
                    {
                        Label("Reset", systemImage: "stop")
                    }
                    Button(action: change_work)
                    {
                        Label("PlayPause", systemImage: "playpause")
                    }
                }
            }
        }
    }
    
    func add_robot()
    {
        print("🪄")
    }
    
    func change_work()
    {
        print("🪄")
    }
    
    func change_cycle()
    {
        cycle.toggle()
    }
}

//MARK: - Workspace scene views
struct ComplexWorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var add_robot_in_workspace_view_presented = false
    @State var robot_info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ZStack
        {
            #if os(macOS)
            WorkspaceSceneView_macOS()
            #else
            WorkspaceSceneView_iOS()
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))
                .navigationBarTitleDisplayMode(.inline)
            #endif
            
            HStack
            {
                VStack
                {
                    Spacer()
                    VStack(spacing: 0)
                    {
                        Button(action: { add_robot_in_workspace_view_presented.toggle() })
                        {
                            Image(systemName: "plus")
                                .imageScale(.large)
                                .padding()
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $add_robot_in_workspace_view_presented)
                        {
                            AddRobotInWorkspaceView(document: $document, add_robot_in_workspace_view_presented: $add_robot_in_workspace_view_presented)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                        }
                        /*.onDisappear
                        {
                            add_robot_in_workspace_view_presented.toggle()
                        }*/
                        .disabled(base_workspace.avaliable_robots_names.count == 0)
                        
                        Divider()
                        
                        Button(action: { robot_info_view_presented.toggle() })
                        {
                            Image(systemName: "info.circle")
                                .imageScale(.large)
                                .padding()
                        }
                        .buttonStyle(.borderless)
                        #if os(iOS)
                        .foregroundColor(.black)
                        #endif
                        .popover(isPresented: $robot_info_view_presented)
                        {
                            RobotInfoView(robot_info_view_presented: $robot_info_view_presented)
                        }
                        .onDisappear
                        {
                            robot_info_view_presented.toggle()
                        }
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
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        //Begin commands
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        base_workspace.workcells_node = viewed_scene.rootNode.childNode(withName: "workcells", recursively: true)
        
        //Add placed robots in workspace
        base_workspace.place_robots(scene: viewed_scene)
        
        //Connect camera light for follow
        app_state.camera_light_node = viewed_scene.rootNode.childNode(withName: "camera_light", recursively: true)!
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        app_state.workspace_scene = viewed_scene
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        //Update commands
        
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.camera_node!.rotation, duration: 0.5)]))
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: WorkspaceSceneView_macOS
        
        init(_ control: WorkspaceSceneView_macOS, _ scn_view: SCNView)
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
        @objc func handle_tap(_ gesture_recognize: NSGestureRecognizer)
        {
            let tap_location = gesture_recognize.location(in: scn_view)
            let hit_results = scn_view.hitTest(tap_location, options: [:])
            var result = SCNHitTestResult()
            
            if hit_results.count > 0
            {
                result = hit_results[0]
                
                print(result.localCoordinates)
                print("\(result.node.parent?.parent?.name)")
                print("🍮 tapped – \(result.node.name!)")
            }
        }
    }
    
    func scene_check() //Render functions
    {
        app_state.camera_light_node.runAction(SCNAction.move(to: scene_view.defaultCameraController.pointOfView!.worldPosition, duration: 0.2)) //Follow ligt node the camera
        //app_state.camera_light_node.worldPosition = scene_view.defaultCameraController.pointOfView?.worldPosition ?? SCNVector3(0, 0, 0)
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
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        //Begin commands
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        base_workspace.workcells_node = viewed_scene.rootNode.childNode(withName: "workcells", recursively: true)
        
        //Add placed robots in workspace
        base_workspace.place_robots(scene: viewed_scene)
        
        //Connect camera light for follow
        app_state.camera_light_node = viewed_scene.rootNode.childNode(withName: "camera_light", recursively: true)!
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        app_state.workspace_scene = viewed_scene
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        //Update commands
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.camera_node!.rotation, duration: 0.5)]))
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: WorkspaceSceneView_iOS
        
        init(_ control: WorkspaceSceneView_iOS, _ scn_view: SCNView)
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
        @objc func handle_tap(_ gesture_recognize: UIGestureRecognizer)
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
        }
    }
    
    func scene_check() //Render functions
    {
        app_state.camera_light_node.runAction(SCNAction.move(to: scene_view.defaultCameraController.pointOfView!.worldPosition, duration: 0.2)) //Follow ligt node the camera
    }
}
#endif

struct AddRobotInWorkspaceView: View
{
    @State var selected_robot_name = String()
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var add_robot_in_workspace_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Add robot in workspace")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack
            {
                #if os(iOS)
                Text("Robot")
                    .font(.subheadline)
                #endif
                
                Picker("Robot", selection: $selected_robot_name) //Select robot for place in workspace
                {
                    ForEach(base_workspace.avaliable_robots_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onAppear
                {
                    selected_robot_name = base_workspace.avaliable_robots_names.first ?? "None"
                    view_robot()
                    //base_workspace.unit_point_node?.isHidden = false
                }
                .onChange(of: selected_robot_name)
                { _ in
                    change_selected_robot()
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                #endif
            }
            .padding()
            
            Divider()
            
            #if os(macOS)
            HStack(spacing: 16)
            {
                GroupBox(label: Text("Location")
                    .font(.headline))
                {
                    VStack(spacing: 12)
                    {
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[0], in: -1000...1000)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[1], in: -1000...1000)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[2], in: -1000...1000)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                }
    
                GroupBox(label: Text("Rotation")
                    .font(.headline))
                {
                    VStack(spacing: 12)
                    {
                        HStack(spacing: 8)
                        {
                            Text("R:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[0], in: -180...180)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("P:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[1], in: -180...180)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("W:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[2], in: -180...180)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                }
            }
            .padding()
            .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
            { _ in
                update_unit_origin_position()
            }
            #else
            VStack(spacing: 12)
            {
                GroupBox(label: Text("Location")
                    .font(.headline))
                {
                    VStack(spacing: 12)
                    {
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[0], in: -1000...1000)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[1], in: -1000...1000)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.location[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.location[2], in: -1000...1000)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                }
    
                GroupBox(label: Text("Rotation")
                    .font(.headline))
                {
                    VStack(spacing: 12)
                    {
                        HStack(spacing: 8)
                        {
                            Text("R:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[0], in: -180...180)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("P:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[1], in: -180...180)
                                .labelsHidden()
                        }
            
                        HStack(spacing: 8)
                        {
                            Text("W:")
                                .frame(width: 20.0)
                            TextField("0", value: $base_workspace.selected_robot.rotation[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $base_workspace.selected_robot.rotation[2], in: -180...180)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                }
            }
            .padding([.top, .leading, .trailing])
            .padding(.bottom, 8.0)
            .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
            { _ in
                update_unit_origin_position()
            }

            Spacer()
            #endif
            
            //MARK: Place and cancel buttons
            Divider()
            HStack
            {
                Button("Cancel", action: { add_robot_in_workspace_view_presented.toggle()
                    dismiss_view() })
                    .padding()
                
                Spacer()
                
                Button("Place", action: place_robot)
                    .keyboardShortcut(.defaultAction)
                    .padding()
                #if os(macOS)
                    .foregroundColor(Color.white)
                #endif
            }
        }
        .onDisappear
        {
            dismiss_view()
        }
    }
    
    func view_robot() //Get robot and update position
    {
        base_workspace.select_robot(name: selected_robot_name)
        
        base_workspace.workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!) //Get workcell from Workcell.scn and add it to Workspace.scn
        base_workspace.unit_node = base_workspace.workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
        
        base_workspace.unit_node?.name = selected_robot_name
        base_workspace.selected_robot.robot_workcell_connect(scene: app_state.workspace_scene, name: selected_robot_name)
        base_workspace.selected_robot.update_robot()
        
        base_workspace.selected_robot.unit_origin_node?.isHidden = false
    }
    
    func change_selected_robot()
    {
        dismiss_view()
        base_workspace.select_robot(name: selected_robot_name)
        view_robot()
    }
    
    func update_unit_origin_position()
    {
        #if os(macOS)
        base_workspace.unit_node?.worldPosition = SCNVector3(x: CGFloat(base_workspace.selected_robot.location[0]), y: CGFloat(base_workspace.selected_robot.location[2]), z: CGFloat(base_workspace.selected_robot.location[1]))
        
        base_workspace.unit_node?.eulerAngles.x = to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[1]))
        base_workspace.unit_node?.eulerAngles.y = to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[2]))
        base_workspace.unit_node?.eulerAngles.z = to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[0]))
        #else
        base_workspace.unit_node?.worldPosition = SCNVector3(x: base_workspace.selected_robot.location[0], y: base_workspace.selected_robot.location[2], z: base_workspace.selected_robot.location[1])
        
        base_workspace.unit_node?.eulerAngles.x = Float(to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[1])))
        base_workspace.unit_node?.eulerAngles.y = Float(to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[2])))
        base_workspace.unit_node?.eulerAngles.z = Float(to_rad(in_angle: CGFloat(base_workspace.selected_robot.rotation[0])))
        #endif
    }
    
    func dismiss_view()
    {
        if base_workspace.selected_robot.is_placed == false
        {
            base_workspace.selected_robot.location = [0, 0, 0]
            base_workspace.selected_robot.rotation = [0, 0, 0]
            
            base_workspace.unit_node?.removeFromParentNode()
        }
    }
    
    func place_robot()
    {
        base_workspace.selected_robot.is_placed = true
        
        base_workspace.selected_robot.unit_origin_node?.isHidden = true
        base_workspace.workcells_node?.addChildNode(base_workspace.unit_node!)
        
        document.preset.robots = base_workspace.file_data().robots
        
        add_robot_in_workspace_view_presented.toggle()
    }
}

struct RobotInfoView: View
{
    @Binding var robot_info_view_presented: Bool
    
    var body: some View
    {
        Text("Robot Info View")
            .padding()
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
                        .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $base_workspace.elements, dragged_element: $dragged_element, element: element))
                    }
                    .padding(4)
                }
                .padding()
                .onChange(of: base_workspace.elements)
                { _ in
                    //Update file after elements reordering
                    document.preset.elements = base_workspace.file_data().elements
                }
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
        var new_program_element = WorkspaceProgramElement(element_type: add_new_element_data.element_type, performer_type: add_new_element_data.performer_type, modificator_type: add_new_element_data.modificator_type, logic_type: add_new_element_data.logic_type)
        
        //Checking for existing workspace components for element selection
        switch new_program_element.element_data.element_type
        {
        case .perofrmer:
            switch new_program_element.element_data.performer_type
            {
            case .robot:
                if base_workspace.robots.count > 0
                {
                    new_program_element.element_data.robot_name = base_workspace.robots[0].name!
                    if base_workspace.robots[0].programs_count > 0
                    {
                        new_program_element.element_data.robot_program_name = base_workspace.robots[0].programs_names[0]
                    }
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
    
    let element: WorkspaceProgramElement
    
    func performDrop(info: DropInfo) -> Bool
    {
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
                        //.font(.system(size: 32))
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
                        Text(type.localizedName).tag(type)
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
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .modificator:
                        Picker("Type", selection: $add_new_element_data.modificator_type)
                        {
                            ForEach(ModificatorType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .logic:
                        Picker("Type", selection: $add_new_element_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
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
                        Text(type.localizedName).tag(type)
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
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .modificator:
                        Picker("Type", selection: $new_element_item_data.modificator_type)
                        {
                            ForEach(ModificatorType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .logic:
                        Picker("Type", selection: $new_element_item_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
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
                    PerformerElementView(performer_type: $new_element_item_data.performer_type, robot_name: $new_element_item_data.robot_name, robot_program_name: $new_element_item_data.robot_program_name, tool_name: $new_element_item_data.tool_name)
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
                
                Button("Save", action: update_program_element)
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
    @Binding var robot_program_name: String
    @Binding var tool_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            switch performer_type
            {
            case .robot:
                if base_workspace.robots.count > 0
                {
                    //MARK: Robot subview
                    #if os(macOS)
                    Picker("Name", selection: $robot_name) //Robot picker
                    {
                        if base_workspace.robots_names.count > 0
                        {
                            ForEach(base_workspace.robots_names, id: \.self)
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
                        base_workspace.select_robot(name: robot_name)
                        if base_workspace.selected_robot.programs_names.count > 0
                        {
                            robot_program_name = base_workspace.selected_robot.programs_names[0]
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if robot_name == ""
                        {
                            robot_name = base_workspace.robots_names[0]
                        }
                        else
                        {
                            base_workspace.select_robot(name: robot_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.robots_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $robot_program_name) //Robot program picker
                    {
                        if base_workspace.selected_robot.programs_names.count > 0
                        {
                            ForEach(base_workspace.selected_robot.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(base_workspace.selected_robot.programs_names.count == 0)
                    #else
                    VStack
                    {
                        GeometryReader
                        { geometry in
                            HStack(spacing: 0)
                            {
                                Picker("Name", selection: $robot_name) //Robot picker
                                {
                                    if base_workspace.robots_names.count > 0
                                    {
                                        ForEach(base_workspace.robots_names, id: \.self)
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
                                    base_workspace.select_robot(name: robot_name)
                                    if base_workspace.selected_robot.programs_names.count > 0
                                    {
                                        robot_program_name = base_workspace.selected_robot.programs_names[0]
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if robot_name == ""
                                    {
                                        robot_name = base_workspace.robots_names[0]
                                    }
                                    else
                                    {
                                        base_workspace.select_robot(name: robot_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.robots_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                                
                                Picker("Program", selection: $robot_program_name) //Robot program picker
                                {
                                    if base_workspace.selected_robot.programs_names.count > 0
                                    {
                                        ForEach(base_workspace.selected_robot.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(base_workspace.selected_robot.programs_names.count == 0)
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
                    Text("No robots in this workspace")
                }
            case .tool:
                //MARK: Tool subview
                Text("Tool")
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
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            ElementCardView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), document: .constant(Robotic_Complex_WorkspaceDocument()), element_item: WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot), on_delete: { IndexSet in print("None") })
            ElementView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), element_item: .constant(WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)), element_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), new_element_item_data: workspace_program_element_struct(element_type: .logic, performer_type: .robot, modificator_type: .changer, logic_type: .jump), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            //PerformerElementView(performer_type: .constant(.robot), robot_name: .constant("Robot"), robot_program_name: .constant("Robot Program"), tool_name: .constant("Tool"))
                //.environmentObject(Workspace())
            LogicElementView(logic_type: .constant(.mark), mark_name: .constant("Mark Name"), target_mark_name: .constant("Target Mark Name"))
        }
    }
}
