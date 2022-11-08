//
//  ToolsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.03.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct ToolsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_tool_view_presented = false
    @State private var tool_view_presented = false
    @State private var dragged_tool: Tool?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.tools.count > 0
            {
                //MARK: Scroll view for robots
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.tools)
                        { tool_item in
                            ToolCardView(document: $document, tool_item: tool_item)
                            .onDrag({
                                self.dragged_tool = tool_item
                                return NSItemProvider(object: tool_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                LargeCardViewPreview(color: tool_item.card_info.color, image: tool_item.card_info.image, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
                            })
                            .onDrop(of: [UTType.text], delegate: ToolDropDelegate(tools: $base_workspace.tools, dragged_tool: $dragged_tool, document: $document, workspace_tools: base_workspace.file_data().tools, tool: tool_item))
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.tools)
                .modifier(DoubleModifier(update_toggle: $app_state.view_update_state))
            }
            else
            {
                Text("Press «+» to add new tool")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(Color.white)
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_tool_view_presented.toggle() })
                    {
                        Label("Add Tool", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_tool_view_presented)
                    {
                        AddToolView(add_tool_view_presented: $add_tool_view_presented, document: $document)
                    }
                }
            }
        }
    }
}

//MARK: - Tools card view
struct ToolCardView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var tool_item: Tool
    @State private var tool_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        LargeCardView(color: tool_item.card_info.color, image: tool_item.card_info.image, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
            .modifier(CircleDeleteButtonModifier(workspace: base_workspace, object_item: tool_item, objects: base_workspace.tools, on_delete: remove_tools, object_type_name: "tool"))
            .onTapGesture
            {
                base_workspace.select_tool(name: tool_item.name!)
                tool_view_presented = true
            }
            .sheet(isPresented: $tool_view_presented)
            {
                ToolView(tool_view_presented: $tool_view_presented, document: $document)
                    .onDisappear()
                {
                    tool_view_presented = false
                }
            }
    }
    
    func remove_tools(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.tools.remove(atOffsets: offsets)
            document.preset.tools = base_workspace.file_data().tools
        }
    }
}

//MARK: - Drag and Drop delegate
struct ToolDropDelegate : DropDelegate
{
    @Binding var tools : [Tool]
    @Binding var dragged_tool : Tool?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_tools: [ToolStruct]
    
    let tool: Tool
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.tools = workspace_tools //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_tool = self.dragged_tool else
        {
            return
        }
        
        if dragged_tool != tool
        {
            let from = tools.firstIndex(of: dragged_tool)!
            let to = tools.firstIndex(of: tool)!
            withAnimation(.default)
            {
                self.tools.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Add tool view
struct AddToolView:View
{
    @Binding var add_tool_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_tool_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            ToolSceneView_macOS()
                .overlay(alignment: .top)
                {
                    Text("Add Tool")
                        .font(.title2)
                        .padding(8.0)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding([.top, .leading, .trailing])
                }
            #else
            ToolSceneView_iOS()
                .overlay(alignment: .top)
                {
                    Text("Add Tool")
                        .font(.title2)
                        .padding(8.0)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            #endif
            
            Divider()
            Spacer()
            
            HStack
            {
                Text("Name")
                    .bold()
                TextField("None", text: $new_tool_name)
                #if os(iOS)
                    .textFieldStyle(.roundedBorder)
                #endif
            }
            .padding(.top, 8.0)
            .padding(.horizontal)
            
            HStack(spacing: 0)
            {
                #if os(iOS)
                Spacer()
                #endif
                Picker(selection: $app_state.tool_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.tools, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8.0)
                .padding(.leading)
                
                Button("Cancel", action: { add_tool_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: add_tool_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onAppear()
        {
            app_state.update_tool_info()
        }
    }
    
    func add_tool_in_workspace()
    {
        if new_tool_name == ""
        {
            new_tool_name = "None"
        }
        
        app_state.get_scene_image = true
        app_state.previewed_object?.name = new_tool_name
        base_workspace.add_tool(app_state.previewed_object! as! Tool)
        
        document.preset.tools = base_workspace.file_data().tools
        
        add_tool_view_presented.toggle()
    }
}

//MARK: - Tool view
struct ToolView: View
{
    @Binding var tool_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    //@Binding var tool_item: Tool
    
    //@State var new_physics: PhysicsType = .ph_none
    @State private var add_program_view_presented = false
    @State private var add_operation_view_presented = false
    @State private var new_operation_code = 0
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            #if os(macOS)
            ToolSceneView_macOS()
            #else
            ToolSceneView_iOS()
            #endif
            
            Divider()
            
            VStack(spacing: 0)
            {
                Text("Operations")
                    .padding(.top)
                
                ZStack
                {
                    List
                    {
                        if base_workspace.selected_tool.programs_count > 0
                        {
                            if base_workspace.selected_tool.selected_program.codes_count > 0
                            {
                                ForEach(base_workspace.selected_tool.selected_program.codes, id: \.self)
                                { code in
                                    OperationItemListView(codes: $base_workspace.selected_tool.selected_program.codes, document: $document, code_item: code, on_delete: remove_codes)
                                        .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                                }
                                .onMove(perform: code_item_move)
                                .onChange(of: base_workspace.tools)
                                { _ in
                                    document.preset.tools = base_workspace.file_data().tools
                                    app_state.get_scene_image = true
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
                    .padding()
                    
                    if base_workspace.selected_tool.programs_count == 0
                    {
                        Text("No program selected")
                            .foregroundColor(.gray)
                    }
                    else
                    {
                        if base_workspace.selected_tool.selected_program.codes_count == 0
                        {
                            Text("Empty Program")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing)
                {
                    ZStack(alignment: .trailing)
                    {
                        Button(action: add_operation_to_program) //Add element button
                        {
                            HStack
                            {
                                Image(systemName: "plus")
                            }
                            .padding()
                        }
                        #if os(macOS)
                        .frame(maxWidth: 80.0, alignment: .leading)
                        #else
                        .frame(maxWidth: 86.0, alignment: .leading)
                        #endif
                        .background(.thinMaterial)
                        .cornerRadius(32)
                        .shadow(radius: 4.0)
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding()
                        
                        Button(action: { add_operation_view_presented = true }) //Configure new element button
                        {
                            Circle()
                                .foregroundColor(.accentColor)
                                .overlay(
                                    base_workspace.selected_tool.code_info(new_operation_code).image
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: base_workspace.selected_tool.code_info(new_operation_code).image)
                                )
                                .frame(width: 32, height: 32)
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding(.trailing, 24)
                        .popover(isPresented: $add_operation_view_presented)
                        {
                            #if os(macOS)
                            HStack
                            {
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes_count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(base_workspace.selected_tool.code_info(code).label)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .padding()
                                .disabled(base_workspace.selected_tool.codes_count == 0)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.menu)
                            }
                            #else
                            VStack
                            {
                                Text("Code")
                                    .font(.subheadline)
                                    .padding()
                                    //.padding(.top)
                                
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes_count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(base_workspace.selected_tool.code_info(code).label)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(base_workspace.selected_tool.codes_count == 0)
                                .pickerStyle(.wheel)
                                .frame(maxWidth: 192)
                                .buttonStyle(.borderedProminent)
                            }
                            #endif
                        }
                    }
                    .padding(16)
                }
                
                Divider()
                
                HStack(spacing: 0)
                {
                    #if os(iOS)
                    Text("Program")
                        .font(.subheadline)
                    #endif
                    
                    Picker("Program", selection: $base_workspace.selected_tool.selected_program_index)
                    {
                        if base_workspace.selected_tool.programs_names.count > 0
                        {
                            ForEach(0 ..< base_workspace.selected_tool.programs_names.count, id: \.self)
                            {
                                Text(base_workspace.selected_tool.programs_names[$0])
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(base_workspace.selected_tool.programs_names.count == 0)
                    .frame(maxWidth: .infinity)
                    #if os(iOS)
                    .buttonStyle(.borderedProminent)
                    #endif
                    
                    Button("-")
                    {
                        delete_operations_program()
                    }
                    .disabled(base_workspace.selected_tool.programs_names.count == 0)
                    .padding(.horizontal)
                    
                    Button("+")
                    {
                        add_program_view_presented.toggle()
                    }
                    .popover(isPresented: $add_program_view_presented)
                    {
                        AddOperationProgramView(add_program_view_presented: $add_program_view_presented, document: $document, selected_program_index: $base_workspace.selected_tool.selected_program_index)
                        #if os(macOS)
                            .frame(height: 72.0)
                        #else
                            .presentationDetents([.height(96.0)])
                        #endif
                    }
                }
                .padding()
            }
            .frame(width: 256)
        }
        .overlay(alignment: .topLeading)
        {
            Button(action: { tool_view_presented.toggle() })
            {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
            .padding()
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 640, maxWidth: 800, minHeight: 400, idealHeight: 480, maxHeight: 600)
        #endif
        .onAppear
        {
            app_state.previewed_object?.node = base_workspace.selected_tool.node
            app_state.preview_update_scene = true
        }
        .onDisappear
        {
            if is_document_updated
            {
                app_state.view_update_state.toggle()
            }
        }
    }
    
    func update_data()
    {
        if ready_for_save
        {
            app_state.get_scene_image = true
            //tool_item.physics_type = new_physics
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                document.preset.tools = base_workspace.file_data().tools
            }
            is_document_updated = true
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        base_workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        base_workspace.selected_robot.selected_program.visual_build()
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            base_workspace.selected_tool.selected_program.codes.remove(atOffsets: offsets)
        }
        
        document.preset.tools = base_workspace.file_data().tools
        app_state.get_scene_image = true
    }
    
    func delete_operations_program()
    {
        if base_workspace.selected_tool.programs_names.count > 0
        {
            let current_spi = base_workspace.selected_tool.selected_program_index
            base_workspace.selected_tool.delete_program(number: current_spi)
            if base_workspace.selected_tool.programs_names.count > 1 && current_spi > 0
            {
                base_workspace.selected_tool.selected_program_index = current_spi - 1
            }
            else
            {
                base_workspace.selected_tool.selected_program_index = 0
            }
            
            document.preset.tools = base_workspace.file_data().tools
            app_state.get_scene_image = true
            base_workspace.update_view()
        }
    }
    
    func add_operation_to_program()
    {
        base_workspace.selected_robot.selected_program.add_point(PositionPoint(x: base_workspace.selected_robot.pointer_location[0], y: base_workspace.selected_robot.pointer_location[1], z: base_workspace.selected_robot.pointer_location[2], r: base_workspace.selected_robot.pointer_rotation[0], p: base_workspace.selected_robot.pointer_rotation[1], w: base_workspace.selected_robot.pointer_rotation[2], move_type: .linear))
        
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
        base_workspace.update_view()
    }
}

struct OperationDropDelegate: DropDelegate
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
struct OperationParameterView: View
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
struct AddOperationProgramView: View
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
            Text("New operations program")
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
                    
                    base_workspace.selected_tool.add_program(OperationsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_tool.programs_names.count - 1
                    
                    document.preset.tools = base_workspace.file_data().tools
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
struct OperationItemListView: View
{
    @Binding var codes: [Int]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var code_item: Int
    //@State var position_item_view_presented = false
    
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
                .foregroundColor(base_workspace.selected_tool.inspector_code_color(code: code_item))
            Spacer()
            VStack
            {
                Text("Code name")
                    .font(.caption)
            }
            .onTapGesture
            {
                print("None")
                //position_item_view_presented.toggle()
            }
            Spacer()
        }
        /*.onTapGesture
        {
            print("None")
            //position_item_view_presented.toggle()
        }*/
    }
}

//MARK: - Scene views
#if os(macOS)
struct ToolSceneView_macOS: NSViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/View.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = NSColor.clear
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = NSColor.clear
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            app_state.previewed_object?.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_macOS
        
        init(_ control: ToolSceneView_macOS, _ scn_view: SCNView)
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
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Tool", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Tool"
            app_state.preview_update_scene = false
        }
    }
}
#else
struct ToolSceneView_iOS: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/View.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = UIColor.clear
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            app_state.previewed_object?.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_iOS
        
        init(_ control: ToolSceneView_iOS, _ scn_view: SCNView)
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
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Tool", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Tool"
            app_state.preview_update_scene = false
        }
    }
}
#endif

//MARK: - Previews
struct ToolsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ToolsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            AddToolView(add_tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            ToolView(tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
        }
    }
}
