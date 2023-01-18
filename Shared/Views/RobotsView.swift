//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import Charts
import UniformTypeIdentifiers
import IndustrialKit

struct RobotsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var robot_view_presented = false
    
    var body: some View
    {
        HStack
        {
            if robot_view_presented == false
            {
                //Display robots table view
                RobotsTableView(robot_view_presented: $robot_view_presented, document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .background(Color.white)
            }
            else
            {
                //Display robot view when selected
                RobotView(robot_view_presented: $robot_view_presented, document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #endif
    }
}

struct RobotsTableView: View
{
    @Binding var robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_robot_view_presented = false
    @State private var dragged_robot: Robot?
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.robots.count > 0
            {
                //MARK: Scroll view for robots
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.robots)
                        { robot_item in
                            LargeCardView(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle)
                                .modifier(CircleDeleteButtonModifier(workspace: base_workspace, object_item: robot_item, objects: base_workspace.robots, on_delete: delete_robots, object_type_name: "robot"))
                            .onTapGesture
                            {
                                view_robot(robot_index: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
                            }
                            .onDrag({
                                self.dragged_robot = robot_item
                                return NSItemProvider(object: robot_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                LargeCardViewPreview(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle)
                            })
                            .onDrop(of: [UTType.text], delegate: RobotDropDelegate(robots: $base_workspace.robots, dragged_robot: $dragged_robot, document: $document, workspace_robots: base_workspace.file_data().robots, robot: robot_item))
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.robots)
            }
            else
            {
                Text("Press «+» to add new robot")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_robot_view_presented.toggle() })
                    {
                        Label("Add Robot", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_robot_view_presented)
                    {
                        AddRobotView(add_robot_view_presented: $add_robot_view_presented, document: $document)
                        #if os(iOS)
                            .presentationDetents([.height(512), .large])
                        #endif
                    }
                }
            }
        }
    }
    
    //MARK: Robots manage functions
    func view_robot(robot_index: Int)
    {
        base_workspace.select_robot(index: robot_index)
        self.robot_view_presented = true
    }
    
    func delete_robots(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.robots.remove(atOffsets: offsets)
            document.preset.robots = base_workspace.file_data().robots
        }
    }
}

//MARK: - Drag and Drop delegate
struct RobotDropDelegate : DropDelegate
{
    @Binding var robots : [Robot]
    @Binding var dragged_robot : Robot?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_robots: [RobotStruct]
    
    let robot: Robot
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.robots = workspace_robots //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_robot = self.dragged_robot else
        {
            return
        }
        
        if dragged_robot != robot
        {
            let from = robots.firstIndex(of: dragged_robot)!
            let to = robots.firstIndex(of: robot)!
            withAnimation(.default)
            {
                self.robots.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Add robot view
struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_robot_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        #if os(macOS)
        VStack(spacing: 0)
        {
            Text("Add Robot")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            //MARK: Robot model selection
            VStack
            {
                HStack
                {
                    Text("Name")
                        .bold()
                    TextField("None", text: $new_robot_name)
                }
                
                Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                        .bold())
                {
                    ForEach(app_state.manufacturers, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker(selection: $app_state.series_name, label: Text("Series")
                        .bold())
                {
                    ForEach(app_state.series, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
                
                Picker(selection: $app_state.model_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.models, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                
                Button("Save", action: add_robot_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        .controlSize(.regular)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #else
        VStack(spacing: 0)
        {
            Text("Add Robot")
                .font(.title2)
                .padding()
            
            Divider()
            
            //MARK: Robot model selection
            Form
            {
                Section(header: Text("Name"))
                {
                    TextField(text: $new_robot_name, prompt: Text("None"))
                    {
                        Text("Name")
                    }
                }
                
                Section(header: Text("Parameters"))
                {
                    Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                            .bold())
                    {
                        ForEach(app_state.manufacturers, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.series_name, label: Text("Series")
                            .bold())
                    {
                        ForEach(app_state.series, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.model_name, label: Text("Model")
                            .bold())
                    {
                        ForEach(app_state.models, id: \.self)
                        {
                            Text($0)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .buttonStyle(.bordered)
                Button("Save", action: add_robot_in_workspace)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        #endif
    }
    
    func add_robot_in_workspace()
    {
        if new_robot_name == ""
        {
            new_robot_name = "None"
        }
        
        base_workspace.add_robot(Robot(name: new_robot_name, manufacturer: app_state.manufacturer_name, dictionary: app_state.robot_dictionary))
        document.preset.robots = base_workspace.file_data().robots
        
        base_workspace.elements_check()
        
        add_robot_view_presented.toggle()
    }
}

//MARK: Robot view
struct RobotView: View
{
    @Binding var robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    
    //Picker data for thin window size
    @State private var program_view_presented = false
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            #if os(macOS)
            RobotSceneView(document: $document)
                .onDisappear(perform: close_robot)
            
            Divider()
            
            RobotInspectorView(document: $document)
                .disabled(base_workspace.selected_robot.performed == true)
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    RobotSceneView(document: $document)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    
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
                                RobotInspectorView(document: $document)
                                    .disabled(base_workspace.selected_robot.performed == true)
                                    .presentationDetents([.medium, .large])
                            }
                            .onDisappear()
                            {
                                program_view_presented = false
                            }
                        }
                    }
                }
                .onDisappear(perform: close_robot)
            }
            else
            {
                RobotSceneView(document: $document)
                    .onDisappear(perform: close_robot)
                RobotInspectorView(document: $document)
                    .disabled(base_workspace.selected_robot.performed == true)
                    .frame(width: 288)
            }
            #endif
        }
        .onAppear()
        {
            base_workspace.selected_robot.clear_finish_handler()
            if base_workspace.selected_robot.programs_count > 0
            {
                base_workspace.selected_robot.select_program(index: 0)
            }
        }
        
        .toolbar
        {
            //MARK: Toolbar items
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: close_robot)
                    {
                        Image(systemName: "rectangle.grid.2x2")
                    }
                    Divider()
                    
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
                        ConnectorView(is_presented: $connector_view_presented, document: $document, demo: $base_workspace.selected_robot.demo, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document.preset.robots = base_workspace.file_data().robots })
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, document: $document, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document.preset.robots = base_workspace.file_data().robots })
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
                }
            }
        }
    }
    
    func close_robot()
    {
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
    }
}

//MARK: - Cell scene views
struct RobotSceneView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var origin_move_view_presented = false
    @State private var origin_rotate_view_presented = false
    @State private var space_scale_view_presented = false
    
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
            CellSceneView_macOS()
            #else
            if !(horizontal_size_class == .compact)
            {
                CellSceneView_iOS()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))
                    .navigationBarTitleDisplayMode(.inline)
            }
            else
            {
                CellSceneView_iOS()
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
                            { _ in
                                base_workspace.selected_robot.robot_location_place()
                                base_workspace.update_view()
                                document.preset.robots = base_workspace.file_data().robots
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
                            { _ in
                                base_workspace.selected_robot.robot_location_place()
                                base_workspace.update_view()
                                document.preset.robots = base_workspace.file_data().robots
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
                            { _ in
                                base_workspace.selected_robot.update_space_scale()
                                base_workspace.update_view()
                                document.preset.robots = base_workspace.file_data().robots
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
struct CellSceneView_macOS: NSViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    
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
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: CellSceneView_macOS
        
        init(_ control: CellSceneView_macOS, _ scn_view: SCNView)
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
                print("🍮 tapped – \(result.node.name!)")
            }
        }
    }
    
    func scene_check() //Render functions
    {
        base_workspace.selected_robot.update_robot()
        if base_workspace.selected_robot.moving_completed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        if base_workspace.selected_robot.performed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}
#else
struct CellSceneView_iOS: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: CellSceneView_iOS
        
        init(_ control: CellSceneView_iOS, _ scn_view: SCNView)
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
    
    func scene_check()
    {
        base_workspace.selected_robot.update_robot()
        if base_workspace.selected_robot.moving_completed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        if base_workspace.selected_robot.performed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}
#endif

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
                    .frame(width: 20.0)
                TextField("0", value: $space_scale[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $space_scale[0], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20.0)
                TextField("0", value: $space_scale[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $space_scale[1], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20.0)
                TextField("0", value: $space_scale[2], format: .number)
                    .textFieldStyle(.roundedBorder)
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
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_location[0], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_location[1], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_location[2], in: -50...50)
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
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[0], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("P:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[1], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("W:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[2], in: -180...180)
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

//MARK: - Robot inspector view
struct RobotInspectorView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_program_view_presented = false
    @State var ppv_presented_location = [false, false, false]
    @State var ppv_presented_rotation = [false, false, false]
    @State private var teach_selection = 0
    @State var dragged_point: SCNNode?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let button_padding = 12.0
    private let teach_items: [String] = ["Location", "Rotation"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Points")
                .padding(.top)
            
            ZStack
            {
                List
                {
                    if base_workspace.selected_robot.programs_count > 0
                    {
                        if base_workspace.selected_robot.selected_program.points_count > 0
                        {
                            ForEach(base_workspace.selected_robot.selected_program.points, id: \.self)
                            { point in
                                PositionItemListView(points: $base_workspace.selected_robot.selected_program.points, document: $document, point_item: point, on_delete: remove_points)
                                    .onDrag
                                {
                                    return NSItemProvider()
                                }
                            }
                            .onMove(perform: point_item_move)
                            .onChange(of: base_workspace.robots)
                            { _ in
                                document.preset.robots = base_workspace.file_data().robots
                                app_state.get_scene_image = true
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
                .padding()
                
                if base_workspace.selected_robot.programs_count == 0
                {
                    Text("No program selected")
                        .foregroundColor(.gray)
                }
                else
                {
                    if base_workspace.selected_robot.selected_program.points_count == 0
                    {
                        Text("Empty Program")
                            .foregroundColor(.gray)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing)
            {
                if base_workspace.selected_robot.programs_count > 0
                {
                    Spacer()
                    Button(action: add_point_to_program)
                    {
                        Image(systemName: "plus")
                            .padding(8.0)
                    }
                    .disabled(base_workspace.selected_robot.programs_count == 0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .frame(width: 24.0, height: 24.0)
                    .shadow(radius: 4.0)
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                    .padding(32.0)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            //Spacer()
            GroupBox
            {
                VStack
                {
                    Picker("LR", selection: $teach_selection)
                    {
                        ForEach(0..<teach_items.count, id: \.self)
                        { index in
                            Text(self.teach_items[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    #if os(macOS)
                    .padding(8.0)
                    #else
                    .padding(.bottom, 8.0)
                    #endif
                    
                    if teach_selection == 0
                    {
                        HStack
                        {
                            Button(action: { ppv_presented_location[0].toggle() })
                            {
                                Label("X: " + String(format: "%.0f", base_workspace.selected_robot.pointer_location[0]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_location[0])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[0], parameter_value: $base_workspace.selected_robot.pointer_location[0], limit_min: .constant(0), limit_max: $base_workspace.selected_robot.space_scale[0])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[0], in: 0.0...base_workspace.selected_robot.space_scale[0])
                                .padding(.trailing)
                        }
                        
                        HStack
                        {
                            Button(action: { ppv_presented_location[1].toggle() })
                            {
                                Label("Y: " + String(format: "%.0f", base_workspace.selected_robot.pointer_location[1]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_location[1])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[1], parameter_value: $base_workspace.selected_robot.pointer_location[1], limit_min: .constant(0), limit_max: $base_workspace.selected_robot.space_scale[1])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[1], in: 0.0...base_workspace.selected_robot.space_scale[1])
                                .padding(.trailing)
                        }
                        
                        HStack
                        {
                            Button(action: { ppv_presented_location[2].toggle() })
                            {
                                Label("Z: " + String(format: "%.0f", base_workspace.selected_robot.pointer_location[2]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_location[2])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[2], parameter_value: $base_workspace.selected_robot.pointer_location[2], limit_min: .constant(0), limit_max: $base_workspace.selected_robot.space_scale[2])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[2], in: 0.0...base_workspace.selected_robot.space_scale[2])
                                .padding(.trailing)
                        }
                        #if os(macOS)
                        .padding(.bottom, 8.0)
                        #else
                        .padding(.bottom, 4.0)
                        #endif
                    }
                    else
                    {
                        HStack
                        {
                            Button(action: { ppv_presented_rotation[0].toggle() })
                            {
                                Label("R: " + String(format: "%.0f", base_workspace.selected_robot.pointer_rotation[0]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_rotation[0])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[0], parameter_value: $base_workspace.selected_robot.pointer_rotation[0], limit_min: .constant(-180), limit_max: .constant(180))
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_rotation[0], in: -180.0...180.0)
                                .padding(.trailing)
                        }
                        
                        HStack
                        {
                            Button(action: { ppv_presented_rotation[1].toggle() })
                            {
                                Label("P: " + String(format: "%.0f", base_workspace.selected_robot.pointer_rotation[1]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_rotation[1])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[1], parameter_value: $base_workspace.selected_robot.pointer_rotation[1], limit_min: .constant(-180), limit_max: .constant(180))
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_rotation[1], in: -180.0...180.0)
                                .padding(.trailing)
                        }
                        
                        HStack
                        {
                            Button(action: { ppv_presented_rotation[2].toggle() })
                            {
                                Label("W: " + String(format: "%.0f", base_workspace.selected_robot.pointer_rotation[2]), systemImage: "square")
                                    .labelStyle(.titleOnly)
                                    .foregroundColor(Color.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .frame(width: 64.0)
                            .popover(isPresented: $ppv_presented_rotation[2])
                            {
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[2], parameter_value: $base_workspace.selected_robot.pointer_rotation[2], limit_min: .constant(-180), limit_max: .constant(180))
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_rotation[2], in: -180.0...180.0)
                                .padding(.trailing)
                        }
                        #if os(macOS)
                        .padding(.bottom, 8.0)
                        #else
                        .padding(.bottom, 4.0)
                        #endif
                    }
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) //(spacing: 12.0)
            {
                #if os(iOS)
                Text("Program")
                    .font(.subheadline)
                #endif
                
                Picker("Program", selection: $base_workspace.selected_robot.selected_program_index)
                {
                    if base_workspace.selected_robot.programs_names.count > 0
                    {
                        ForEach(0 ..< base_workspace.selected_robot.programs_names.count, id: \.self)
                        {
                            Text(base_workspace.selected_robot.programs_names[$0])
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .pickerStyle(.menu)
                .disabled(base_workspace.selected_robot.programs_names.count == 0)
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .buttonStyle(.borderedProminent)
                #endif
                
                Button("-")
                {
                    delete_positions_program()
                }
                .disabled(base_workspace.selected_robot.programs_names.count == 0)
                .padding(.horizontal)
                
                Button("+")
                {
                    add_program_view_presented.toggle()
                }
                .popover(isPresented: $add_program_view_presented)
                {
                    AddProgramView(add_program_view_presented: $add_program_view_presented, document: $document, selected_program_index: $base_workspace.selected_robot.selected_program_index)
                    #if os(macOS)
                        .frame(height: 72.0)
                    #else
                        .presentationDetents([.height(96.0)])
                    #endif
                }
            }
            .padding()
        }
    }
    
    func point_item_move(from source: IndexSet, to destination: Int)
    {
        base_workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        base_workspace.selected_robot.selected_program.visual_build()
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            base_workspace.selected_robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func delete_positions_program()
    {
        if base_workspace.selected_robot.programs_names.count > 0
        {
            let current_spi = base_workspace.selected_robot.selected_program_index
            base_workspace.selected_robot.delete_program(index: current_spi)
            if base_workspace.selected_robot.programs_names.count > 1 && current_spi > 0
            {
                base_workspace.selected_robot.selected_program_index = current_spi - 1
            }
            else
            {
                base_workspace.selected_robot.selected_program_index = 0
            }
            
            document.preset.robots = base_workspace.file_data().robots
            app_state.get_scene_image = true
            base_workspace.update_view()
        }
    }
    
    func add_point_to_program()
    {
        base_workspace.selected_robot.selected_program.add_point(PositionPoint(x: base_workspace.selected_robot.pointer_location[0], y: base_workspace.selected_robot.pointer_location[1], z: base_workspace.selected_robot.pointer_location[2], r: base_workspace.selected_robot.pointer_rotation[0], p: base_workspace.selected_robot.pointer_rotation[1], w: base_workspace.selected_robot.pointer_rotation[2], move_type: .linear))
        
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
        base_workspace.update_view()
    }
}

struct PositionDropDelegate: DropDelegate
{
    @Binding var points: [SCNNode]
    @Binding var dragged_point: SCNNode?
    
    let point: SCNNode
    
    func performDrop(info: DropInfo) -> Bool
    {
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_point = self.dragged_point else
        {
            return
        }
        
        if dragged_point != point
        {
            let from = points.firstIndex(of: dragged_point)!
            let to = points.firstIndex(of: point)!
            withAnimation(.default)
            {
                self.points.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: Position parameter view
struct PositionParameterView: View
{
    @Binding var position_parameter_view_presented: Bool
    @Binding var parameter_value: Float
    @Binding var limit_min: Float
    @Binding var limit_max: Float
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    parameter_value = 0
                }
                //parameter_value = 0
                position_parameter_view_presented.toggle()
            })
            {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderedProminent)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 8.0)
            #endif
            
            TextField("0", value: $parameter_value, format: .number)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .frame(width: 64.0)
            #else
                .frame(width: 128.0)
            #endif
            
            Stepper("Enter", value: $parameter_value, in: Float(limit_min)...Float(limit_max))
                .labelsHidden()
            #if os(iOS)
                .padding(.trailing, 8.0)
            #endif
        }
        .padding(8.0)
    }
}

//MARK: Add program view
struct AddProgramView: View
{
    @Binding var add_program_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack
        {
            Text("New position program")
                .font(.title3)
            #if os(macOS)
                .padding(.top, 12.0)
            #else
                .padding([.leading, .top, .trailing])
                .padding(.bottom, 8.0)
            #endif
            
            HStack(spacing: 12.0)
            {
                TextField("None", text: $new_program_name)
                    .frame(minWidth: 128.0, maxWidth: 256.0)
                #if os(iOS)
                    .frame(idealWidth: 256.0)
                    .textFieldStyle(.roundedBorder)
                #endif
                
                Button("Add")
                {
                    if new_program_name == ""
                    {
                        new_program_name = "None"
                    }
                    
                    base_workspace.selected_robot.add_program(PositionsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_robot.programs_names.count - 1
                    
                    document.preset.robots = base_workspace.file_data().robots
                    app_state.get_scene_image = true
                    add_program_view_presented.toggle()
                }
                .fixedSize()
                .keyboardShortcut(.defaultAction)
            }
            .padding([.leading, .bottom, .trailing], 12.0)
        }
    }
}

//MARK: - Position item view for list
struct PositionItemListView: View
{
    @Binding var points: [PositionPoint]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var point_item: PositionPoint
    @State var position_item_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(base_workspace.selected_robot.inspector_point_color(point: point_item)) //.gray)
            
            Spacer()
            
            VStack
            {
                Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                    .font(.caption)
                
                Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                    .font(.caption)
            }
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .leading)
            {
                #if os(macOS)
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], is_compact: horizontal_size_class == .compact, on_delete: on_delete)
                    .presentationDetents([.height(500)])
                #endif
            }
            
            Spacer()
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
}

//MARK: - Position item edit view
struct PositionItemView: View
{
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    @State var is_compact = false
    #endif
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            HStack(spacing: 0)
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
                                        TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                        Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                            .labelsHidden()
                                    }
                                }
                                .onChange(of: item_view_pos_location)
                                { _ in
                                    update_point_location()
                                }
                            case .rotation:
                                ForEach(RotationComponents.allCases, id: \.self)
                                { rotation_component in
                                    HStack(spacing: 8)
                                    {
                                        Text(rotation_component.info.text)
                                            .frame(width: 20.0)
                                        TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                        Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                            .labelsHidden()
                                    }
                                    .onChange(of: item_view_pos_rotation)
                                    { _ in
                                        update_point_rotation()
                                    }
                                }
                            }
                        }
                    }
                    .padding([.top, .trailing])
                }
            }
            .padding(.leading)
            #else
            if !is_compact
            {
                HStack(spacing: 0)
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
                                            TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                                .labelsHidden()
                                        }
                                    }
                                    .onChange(of: item_view_pos_location)
                                    { _ in
                                        update_point_location()
                                    }
                                case .rotation:
                                    ForEach(RotationComponents.allCases, id: \.self)
                                    { rotation_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(rotation_component.info.text)
                                                .frame(width: 20.0)
                                            TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                                .labelsHidden()
                                        }
                                        .onChange(of: item_view_pos_rotation)
                                        { _ in
                                            update_point_rotation()
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.top, .trailing])
                    }
                }
                .padding(.leading)
            }
            else
            {
                VStack(spacing: 0)
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
                                            TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                                .labelsHidden()
                                        }
                                    }
                                    .onChange(of: item_view_pos_location)
                                    { _ in
                                        update_point_location()
                                    }
                                case .rotation:
                                    ForEach(RotationComponents.allCases, id: \.self)
                                    { rotation_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(rotation_component.info.text)
                                                .frame(width: 20.0)
                                            TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                                .labelsHidden()
                                        }
                                        .onChange(of: item_view_pos_rotation)
                                        { _ in
                                            update_point_rotation()
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.horizontal, .top])
                    }
                }
                
                Spacer()
            }
            #endif
            
            Button(action: delete_point_from_program)
            {
                Text("Delete")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color.red)
            }
            .padding()
            #if os(iOS)
            .buttonStyle(.bordered)
            #endif
        }
        .onAppear()
        {
            base_workspace.selected_robot.selected_program.selected_point_index = base_workspace.selected_robot.selected_program.points.firstIndex(of: point_item) ?? -1
        }
        .onDisappear()
        {
            base_workspace.selected_robot.selected_program.selected_point_index = -1
        }
    }
    
    //MARK: Point manage functions
    func update_point_location()
    {
        point_item.x = item_view_pos_location[0]
        point_item.y = item_view_pos_location[1]
        point_item.z = item_view_pos_location[2]
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        point_item.r = item_view_pos_rotation[0]
        point_item.p = item_view_pos_rotation[1]
        point_item.w = item_view_pos_rotation[2]
        
        update_workspace_data()
    }
    
    func update_workspace_data()
    {
        base_workspace.update_view()
        base_workspace.selected_robot.selected_program.visual_build()
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func delete_point_from_program()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
        {
            delete_point()
        }
        //delete_point()
        
        base_workspace.update_view()
        position_item_view_presented.toggle()
        
        base_workspace.selected_robot.selected_program.selected_point_index = -1
    }
    
    func delete_point()
    {
        if let index = base_workspace.selected_robot.selected_program.points.firstIndex(of: point_item)
        {
            self.on_delete(IndexSet(integer: index))
        }
    }
}

//MARK: - Previews
struct RobotsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            RobotsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            AddRobotView(add_robot_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
            
            RobotView(robot_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            
            OriginRotateView(origin_rotate_view_presented: .constant(true), origin_view_pos_rotation: .constant([0.0, 0.0, 0.0]))
            OriginMoveView(origin_move_view_presented: .constant(true), origin_view_pos_location: .constant([0.0, 0.0, 0.0]))
            SpaceScaleView(space_scale_view_presented: .constant(true), space_scale: .constant([2.0, 2.0, 2.0]))
            
            PositionParameterView(position_parameter_view_presented: .constant(true), parameter_value: .constant(0), limit_min: .constant(0), limit_max: .constant(200))
            PositionItemListView(points: .constant([PositionPoint()]), document: .constant(Robotic_Complex_WorkspaceDocument()), point_item: PositionPoint()) { IndexSet in }
                .environmentObject(Workspace())
        }
    }
}
