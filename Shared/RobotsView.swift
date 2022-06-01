//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

#if os(macOS)
let placement_trailing: ToolbarItemPlacement = .automatic
#else
let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
#endif

struct RobotsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var display_rv = false
    
    var body: some View
    {
        HStack
        {
            if display_rv == false
            {
                //Display robots table view
                RobotsTableView(display_rv: $display_rv, document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .background(Color.white)
            }
            if display_rv == true
            {
                //Display robot view when selected
                RobotView(display_rv: $display_rv, document: $document)
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
    @Binding var display_rv: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_robot_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 160, maximum: .infinity), spacing: 24)]
    
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
                            ZStack
                            {
                                RobotCardView(card_color: robot_item.card_info().color, card_image: robot_item.card_info().image, card_title: robot_item.card_info().title, card_subtitle: robot_item.card_info().subtitle)
                                RobotDeleteButton(robots: $base_workspace.robots, robot_item: robot_item, on_delete: remove_robots)
                            }
                            .onTapGesture
                            {
                                view_robot(robot_index: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
                            }
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(16)
                }
                .animation(.spring(), value: base_workspace.robots)
                .padding([.leading, .trailing], 4)
            }
            else
            {
                Text("Press «+» to add new robot")
                    .foregroundColor(.gray)
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
                        Label("Robots", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_robot_view_presented)
                    {
                        AddRobotView(add_robot_view_presented: $add_robot_view_presented, document: $document)
                    }
                }
            }
        }
    }
    
    //MARK: Robots manage functions
    func view_robot(robot_index: Int)
    {
        base_workspace.select_robot(number: robot_index)
        self.display_rv = true
    }
    
    func remove_robots(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.robots.remove(atOffsets: offsets)
            document.preset.robots = base_workspace.file_data().robots
        }
    }
}

//MARK: - Robots card view
struct RobotCardView: View
{
    @State var card_color: Color
    #if os(macOS)
    @State var card_image: NSImage
    #else
    @State var card_image: UIImage
    #endif
    @State var card_title: String
    @State var card_subtitle: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(card_color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: card_image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: card_image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
                {
                    VStack(alignment: .leading)
                    {
                        Text(card_title)
                            .font(.headline)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                        
                        Text(card_subtitle)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 8)
                    Spacer()
                }
                .background(card_color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 160)
        .shadow(radius: 8.0)
    }
}

struct RobotDeleteButton: View
{
    @Binding var robots: [Robot]
    
    @State private var delete_robot_alert_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    let robot_item: Robot
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Spacer()
                Button(action: { delete_robot_alert_presented = true })
                {
                    Label("Robots", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .padding(4.0)
                }
                    .foregroundColor(.black)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .frame(width: 24.0, height: 24.0)
                    .padding(8.0)
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
            }
            Spacer()
        }
        .alert(isPresented: $delete_robot_alert_presented)
        {
            Alert(
                title: Text("Delete robot?"),
                message: Text("Do you wand to delete this robot – \(robot_item.card_info().title)"),
                primaryButton: .destructive(Text("Yes"), action: delete_robot),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func delete_robot()
    {
        if let index = robots.firstIndex(of: robot_item)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
    }
}

//MARK: - Add robot view
struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var new_robot_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        #if os(macOS)
        let button_padding = 12.0
        
        VStack
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
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding - 8.0)
                
                Button("Save", action: { add_robot_in_workspace() })
                    .keyboardShortcut(.defaultAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding)
            }
        }
        .controlSize(.regular)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #else
        NavigationView
        {
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
            .navigationBarTitle(Text("Add Robot"), displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel", action: { add_robot_view_presented.toggle() }), trailing: Button("Save", action: add_robot_in_workspace)
                                    .keyboardShortcut(.defaultAction))
        }
        #endif
    }
    
    func add_robot_in_workspace()
    {
        base_workspace.add_robot(robot: Robot(name: new_robot_name, manufacturer: app_state.manufacturer_name, model: app_state.model_name, ip_address: "127.0.0.1"))
        document.preset.robots = base_workspace.file_data().robots
        
        base_workspace.elements_check()
        
        add_robot_view_presented.toggle()
    }
}

//MARK: Robot view
struct RobotView: View
{
    @Binding var display_rv: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var origin_move_view_presented = false
    @State var origin_rotate_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    
    //Picker data for thin window size
    @State private var rv_selection = 0
    private let rv_items: [String] = ["View", "Control"]
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            #if os(macOS)
            RobotSceneView(document: $document)
                .onDisappear(perform: close_robot)
            RobotInspectorView(document: $document)
                .disabled(base_workspace.selected_robot.is_moving == true)
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                if rv_selection == 0
                {
                    RobotSceneView(document: $document)
                        .onDisappear(perform: close_robot)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
                else
                {
                    RobotInspectorView(document: $document)
                        .disabled(base_workspace.selected_robot.is_moving == true)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            else
            {
                RobotSceneView(document: $document)
                    .onDisappear(perform: close_robot)
                RobotInspectorView(document: $document)
                    .disabled(base_workspace.selected_robot.is_moving == true)
                    .frame(width: 288)
            }
            #endif
        }
        
        .toolbar
        {
            //MARK: Toolbar items
            ToolbarItem(placement: .navigation)
            {
                Button(action: close_robot)
                {
                    Label("Close", systemImage: "xmark")
                }
            }
            
            #if os(iOS)
            ToolbarItem(placement: .automatic)
            {
                if horizontal_size_class == .compact
                {
                    Picker("Workspace", selection: $rv_selection)
                    {
                        ForEach(0..<rv_items.count, id: \.self)
                        { index in
                            Text(self.rv_items[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
            }
            #endif
            
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: { base_workspace.selected_robot.reset_moving()
                        base_workspace.update_view()
                    })
                    {
                        Label("Stop", systemImage: "stop")
                    }
                    Button(action: { base_workspace.selected_robot.start_pause_moving()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                        {
                            base_workspace.update_view()
                        }
                    })
                    {
                        Label("Play Pause", systemImage: "playpause")
                    }
                }
            }
        }
    }
    
    func close_robot()
    {
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        display_rv = false
    }
}

//MARK: - Cell scene views
struct RobotSceneView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var origin_move_view_presented = false
    @State var origin_rotate_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ZStack
        {
            #if os(macOS)
            CellSceneView_macOS()
            #else
            CellSceneView_iOS()
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
                                base_workspace.selected_robot.update_position()
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
                                base_workspace.selected_robot.update_position()
                                base_workspace.update_view()
                                document.preset.robots = base_workspace.file_data().robots
                                app_state.get_scene_image = true
                            }
                        }
                        .onDisappear
                        {
                            origin_move_view_presented.toggle()
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
struct CellSceneView_macOS: NSViewRepresentable
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
    
    func makeNSView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.robot_workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Connect camera light for follow
        app_state.camera_light_node = viewed_scene.rootNode.childNode(withName: "camera_light", recursively: true)!
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.selected_robot.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.selected_robot.camera_node!.rotation, duration: 0.5)]))
        }
        
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
            //base_workspace.selected_robot.moving_completed = false
        }
        if base_workspace.selected_robot.is_moving == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
            //base_workspace.update_view()
        }
        
        app_state.camera_light_node.runAction(SCNAction.move(to: scene_view.defaultCameraController.pointOfView!.worldPosition, duration: 0.2)) //Follow ligt node the camera
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
        base_workspace.selected_robot.robot_workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Connect camera light for follow
        app_state.camera_light_node = viewed_scene.rootNode.childNode(withName: "camera_light", recursively: true)!
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            scene_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.selected_robot.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.selected_robot.camera_node!.rotation, duration: 0.5)]))
        }
        
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
            //base_workspace.selected_robot.moving_completed = false
        }
        if base_workspace.selected_robot.is_moving == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
            //base_workspace.update_view()
        }
        
        app_state.camera_light_node.runAction(SCNAction.move(to: scene_view.defaultCameraController.pointOfView!.worldPosition, duration: 0.2)) //Follow ligt node the camera
    }
}
#endif

//MARK: Move elements
struct OriginMoveView: View
{
    @Binding var origin_move_view_presented: Bool
    @Binding var origin_view_pos_location: [Float]
    
    var body: some View
    {
        #if os(macOS)
        VStack(spacing: 12)
        {
            Text("Move Origin")
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
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        VStack(spacing: 12)
        {
            Text("Move Origin")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("X:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_location[0], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_location[1], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_location[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_location[2], in: -50...50)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
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
        #if os(macOS)
        VStack(spacing: 12)
        {
            Text("Rotate Origin")
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
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        VStack(spacing: 12)
        {
            Text("Rotate Origin")
                .font(.title3)
            
            HStack(spacing: 8)
            {
                Text("R:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_rotation[0], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("P:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_rotation[1], in: 0...360)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("W:")
                    .frame(width: 20.0)
                TextField("0", value: $origin_view_pos_rotation[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                Stepper("Enter", value: $origin_view_pos_rotation[2], in: -180...180)
                    .labelsHidden()
            }
        }
        .padding()
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #endif
    }
}

//MARK: - Robot inspector view
struct RobotInspectorView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var add_program_view_presented = false
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
        VStack
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
                .padding([.leading, .trailing, .bottom])
                
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
                    
                    VStack
                    {
                        Spacer()
                        HStack
                        {
                            Spacer()
                            Button(action: add_point_to_program)
                            {
                                Label("Add Point", systemImage: "plus")
                                    .labelStyle(.iconOnly)
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
                        }
                    }
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            Spacer()
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[0], parameter_value: $base_workspace.selected_robot.pointer_location[0])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[0], in: 0.0...200.0)
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[1], parameter_value: $base_workspace.selected_robot.pointer_location[1])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[1], in: 0.0...200.0)
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_location[2], parameter_value: $base_workspace.selected_robot.pointer_location[2])
                            }
                            Slider(value: $base_workspace.selected_robot.pointer_location[2], in: 0.0...200.0)
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[0], parameter_value: $base_workspace.selected_robot.pointer_rotation[0])
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[1], parameter_value: $base_workspace.selected_robot.pointer_rotation[1])
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
                                PositionParameterView(position_parameter_view_presented: $ppv_presented_rotation[2], parameter_value: $base_workspace.selected_robot.pointer_rotation[2])
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
            #if os(macOS)
            .padding([.leading, .trailing])
            .padding(.bottom, 12.0)
            #else
            .padding([.leading, .trailing, .bottom])
            #endif
            
            Spacer()
            #if os(macOS)
            Divider()
            #endif
            
            Section
            {
                HStack(spacing: 12.0)
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
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                    #endif
                    
                    Button("-")
                    {
                        delete_position_program()
                    }
                    .disabled(base_workspace.selected_robot.programs_names.count == 0)
                    
                    Button("+")
                    {
                        add_program_view_presented.toggle()
                    }
                    #if os(macOS)
                    .sheet(isPresented: $add_program_view_presented)
                    {
                        AddProgramView(add_program_view_presented: $add_program_view_presented, document: $document, selected_program_index: $base_workspace.selected_robot.selected_program_index)
                            .frame(height: 72.0)
                    }
                    #else
                    .popover(isPresented: $add_program_view_presented)
                    {
                        AddProgramView(add_program_view_presented: $add_program_view_presented, document: $document, selected_program_index: $base_workspace.selected_robot.selected_program_index)
                    }
                    #endif
                }
            }
            .padding(8.0)
            .padding([.leading, .bottom, .trailing], 8.0)
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
    
    func delete_position_program()
    {
        if base_workspace.selected_robot.programs_names.count > 0
        {
            let current_spi = base_workspace.selected_robot.selected_program_index
            base_workspace.selected_robot.delete_program(number: current_spi)
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
        base_workspace.selected_robot.selected_program.add_point(pos_x: base_workspace.selected_robot.pointer_location[0], pos_y: base_workspace.selected_robot.pointer_location[1], pos_z: base_workspace.selected_robot.pointer_location[2], rot_x: base_workspace.selected_robot.pointer_rotation[0], rot_y: base_workspace.selected_robot.pointer_rotation[1], rot_z: base_workspace.selected_robot.pointer_rotation[2])
        
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
    @Binding var parameter_value: Double
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                parameter_value = 0
                position_parameter_view_presented.toggle()
            })
            {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .keyboardShortcut(.defaultAction)
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
            
            Stepper("Enter", value: $parameter_value, in: 0...200)
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
    
    @State var add_text = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack
        {
            Text("New position program")
            #if os(macOS)
                .padding(.top, 12.0)
            #else
                .padding([.leading, .top, .trailing])
                .padding(.bottom, 8.0)
            #endif
            
            HStack(spacing: 12.0)
            {
                TextField("Name", text: $add_text)
                    .frame(minWidth: 128.0, maxWidth: 256.0)
                #if os(iOS)
                    .frame(idealWidth: 256.0)
                    .textFieldStyle(.roundedBorder)
                #endif
                
                #if os(macOS)
                Button("Cancel")
                {
                    add_program_view_presented.toggle()
                }
                .fixedSize()
                .keyboardShortcut(.cancelAction)
                #endif
                
                Button("Add")
                {
                    base_workspace.selected_robot.add_program(prog: PositionsProgram(name: add_text))
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
    @Binding var points: [SCNNode]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var point_item: SCNNode
    @State var position_item_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
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
                Text("X: \(String(format: "%.0f", Double(point_item.position.x))) Y: \(String(format: "%.0f", Double(point_item.position.y))) Z: \(String(format: "%.0f", Double(point_item.position.z)))")
                    .font(.caption)
                
                Text("R: \(String(format: "%.0f", to_deg(in_angle: Double(point_item.rotation.x)))) P: \(String(format: "%.0f", to_deg(in_angle: Double(point_item.rotation.y)))) W: \(String(format: "%.0f", to_deg(in_angle: Double(point_item.rotation.z))))")
                    .font(.caption)
            }
            .onTapGesture
            {
                position_item_view_presented.toggle()
            }
            #if os(macOS)
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .leading)
            {
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [Double(point_item.position.x), Double(point_item.position.y), Double(point_item.position.z)], item_view_pos_rotation: [to_deg(in_angle: Double(point_item.rotation.x)), to_deg(in_angle: Double(point_item.rotation.y)), to_deg(in_angle: Double(point_item.rotation.z))], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
            }
            #else
            .popover(isPresented: $position_item_view_presented)
            {
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [Double(point_item.position.x), Double(point_item.position.y), Double(point_item.position.z)], item_view_pos_rotation: [to_deg(in_angle: Double(point_item.rotation.x)), to_deg(in_angle: Double(point_item.rotation.y)), to_deg(in_angle: Double(point_item.rotation.z))], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
            }
            #endif
            
            Spacer()
            //Image(systemName: "line.3.horizontal")
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
    @Binding var points: [SCNNode]
    @Binding var point_item: SCNNode
    @Binding var position_item_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var item_view_pos_location = [Double]()
    @State var item_view_pos_rotation = [Double]()
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
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
                            TextField("0", value: $item_view_pos_location[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_location[0], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_location[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_location[1], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_location[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_location[2], in: 0...200)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                    .onChange(of: item_view_pos_location)
                    { _ in
                        update_point_location()
                    }
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
                            TextField("0", value: $item_view_pos_rotation[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_rotation[0], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("P:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_rotation[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_rotation[1], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("W:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_rotation[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                            Stepper("Enter", value: $item_view_pos_rotation[2], in: 0...200)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                    .onChange(of: item_view_pos_rotation)
                    { _ in
                        update_point_rotation()
                    }
                }
            }
            .padding([.top, .leading, .trailing])
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
                            TextField("0", value: $item_view_pos_location[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_location[0], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_location[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_location[1], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_location[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_location[2], in: 0...200)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                    .onChange(of: item_view_pos_location)
                    { _ in
                        update_point_location()
                    }
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
                            TextField("0", value: $item_view_pos_rotation[0], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_rotation[0], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("P:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_rotation[1], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_rotation[1], in: 0...200)
                                .labelsHidden()
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("W:")
                                .frame(width: 20.0)
                            TextField("0", value: $item_view_pos_rotation[2], format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Stepper("Enter", value: $item_view_pos_rotation[2], in: 0...200)
                                .labelsHidden()
                        }
                    }
                    .padding(8.0)
                    .onChange(of: item_view_pos_rotation)
                    { _ in
                        update_point_rotation()
                    }
                }
            }
            .padding([.top, .leading, .trailing])
            #endif
            
            HStack
            {
                Button(action: delete_point_from_program)
                {
                    Text("Delete")
                    #if os(macOS)
                        .frame(maxWidth: .infinity)
                    #else
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(.thinMaterial)
                        .foregroundColor(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    #endif
                }
                .padding()
            }
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
        #if os(macOS)
        point_item.position = SCNVector3(x: item_view_pos_location[0], y: item_view_pos_location[1], z: item_view_pos_location[2])
        #else
        point_item.position = SCNVector3(x: Float(item_view_pos_location[0]), y: Float(item_view_pos_location[1]), z: Float(item_view_pos_location[2]))
        #endif
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        #if os(macOS)
        point_item.rotation.x = to_rad(in_angle: item_view_pos_rotation[0])
        point_item.rotation.y = to_rad(in_angle: item_view_pos_rotation[1])
        point_item.rotation.z = to_rad(in_angle: item_view_pos_rotation[2])
        #else
        point_item.rotation.x = Float(to_rad(in_angle: item_view_pos_rotation[0]))
        point_item.rotation.y = Float(to_rad(in_angle: item_view_pos_rotation[1]))
        point_item.rotation.z = Float(to_rad(in_angle: item_view_pos_rotation[2]))
        #endif
        
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
        delete_point()
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
            #if os(macOS)
            RobotCardView(card_color: .green, card_image: NSImage(), card_title: "Robot Name", card_subtitle: "Fanuc")
            #else
            RobotCardView(card_color: .green, card_image: UIImage(), card_title: "Robot Name", card_subtitle: "Fanuc")
            #endif
            //RobotView(display_rv: .constant(false), document: .constant(Robotic_Complex_WorkspaceDocument()))
                //.environmentObject(Workspace())
            PositionParameterView(position_parameter_view_presented: .constant(true), parameter_value: .constant(0))
            //PositionItemListView(points: .constant([SCNNode]()), document: .constant(Robotic_Complex_WorkspaceDocument()), point_item: SCNNode(), on_delete: { IndexSet in print("None") })
                //.environmentObject(Workspace())
        }
    }
}
