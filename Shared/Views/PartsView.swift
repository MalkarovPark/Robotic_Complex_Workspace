//
//  PartsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct PartsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_part_view_presented = false
    @State private var part_view_presented = false
    @State private var dragged_part: Part?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.parts.count > 0
            {
                //MARK: Scroll view for parts
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.parts)
                        { part_item in
                            PartCardView(document: $document, part_item: part_item)
                            .onDrag({
                                self.dragged_part = part_item
                                return NSItemProvider(object: part_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                SmallCardViewPreview(color: part_item.card_info.color, image: part_item.card_info.image, title: part_item.card_info.title)
                            })
                            .onDrop(of: [UTType.text], delegate: PartDropDelegate(parts: $base_workspace.parts, dragged_part: $dragged_part, document: $document, workspace_parts: base_workspace.file_data().parts, part: part_item))
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .modifier(DoubleModifier(update_toggle: $app_state.view_update_state))
            }
            else
            {
                Text("Press «+» to add new part")
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
                    Button (action: { add_part_view_presented.toggle() })
                    {
                        Label("Add Part", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_part_view_presented)
                    {
                        AddPartView(add_part_view_presented: $add_part_view_presented, document: $document)
                    }
                }
            }
        }
    }
    
    //MARK: Parts manage functions
    func remove_parts(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.parts.remove(atOffsets: offsets)
            document.preset.parts = base_workspace.file_data().parts
        }
    }
}

//MARK: - Parts card view
struct PartCardView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var part_item: Part
    @State private var part_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        SmallCardView(color: part_item.card_info.color, image: part_item.card_info.image, title: part_item.card_info.title)
            .modifier(BorderlessDeleteButtonModifier(workspace: base_workspace, object_item: part_item, objects: base_workspace.parts, on_delete: remove_parts, object_type_name: "part"))
            .onTapGesture
            {
                part_view_presented = true
            }
            .sheet(isPresented: $part_view_presented)
            {
                PartView(part_view_presented: $part_view_presented, document: $document, part_item: $part_item)
                    .onDisappear()
                {
                    part_view_presented = false
                }
            }
    }
    
    func remove_parts(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.parts.remove(atOffsets: offsets)
            document.preset.parts = base_workspace.file_data().parts
        }
    }
}

//MARK: - Drag and Drop delegate
struct PartDropDelegate : DropDelegate
{
    @Binding var parts : [Part]
    @Binding var dragged_part : Part?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_parts: [PartStruct]
    
    let part: Part
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.parts = workspace_parts //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_part = self.dragged_part else
        {
            return
        }
        
        if dragged_part != part
        {
            let from = parts.firstIndex(of: dragged_part)!
            let to = parts.firstIndex(of: part)!
            withAnimation(.default)
            {
                self.parts.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Add part view
struct AddPartView: View
{
    @Binding var add_part_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_part_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            PartSceneView_macOS()
                .overlay(alignment: .top)
                {
                    Text("Add Part")
                        .font(.title2)
                        .padding(8.0)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            #else
            PartSceneView_iOS()
                .overlay(alignment: .top)
                {
                    Text("Add Part")
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
                TextField("None", text: $new_part_name)
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
                Picker(selection: $app_state.part_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.parts, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8.0)
                .padding(.leading)
                
                Button("Cancel", action: { add_part_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: add_part_in_workspace)
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
            app_state.update_part_info()
        }
    }
    
    func add_part_in_workspace()
    {
        if new_part_name == ""
        {
            new_part_name = "None"
        }
        
        app_state.get_scene_image = true
        app_state.previewed_object?.name = new_part_name
        base_workspace.add_part(app_state.previewed_object! as! Part)
        document.preset.parts = base_workspace.file_data().parts
        
        add_part_view_presented.toggle()
    }
}

//MARK: - Part view
struct PartView: View
{
    @Binding var part_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var part_item: Part
    
    //@State private var new_part_name = ""
    @State var new_physics: PhysicsType = .ph_none
    @State var new_color: Color = .accentColor
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            PartSceneView_macOS()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            PartSceneView_iOS()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif
            
            Divider()
            
            HStack(spacing: 0)
            {
                Picker("Physics", selection: $new_physics)
                {
                    ForEach(PhysicsType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(iOS)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                #endif
                .padding(.horizontal)
                .onChange(of: new_physics)
                { _ in
                    update_data()
                }
                
                ColorPicker("Color", selection: $new_color)
                    .padding(.trailing)
                    .onChange(of: new_color)
                    { _ in
                        update_data()
                    }
                #if os(iOS)
                    .frame(width: 112)
                #endif
            }
            .padding(.vertical)
        }
        .overlay(alignment: .topLeading)
        {
            Button(action: { part_view_presented.toggle() })
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
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onAppear()
        {
            app_state.previewed_object = part_item
            app_state.preview_update_scene = true
            
            app_state.reset_previewed_node_position()
            
            let previewed_part = app_state.previewed_object as? Part
            previewed_part?.enable_physics = false
            
            new_physics = part_item.physics_type
            new_color = part_item.color
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                ready_for_save = true
            }
        }
        .onDisappear()
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
            part_item.physics_type = new_physics
            part_item.color = new_color
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                document.preset.parts = base_workspace.file_data().parts
            }
            //document.preset.parts = base_workspace.file_data().parts
            is_document_updated = true
        }
    }
}

//MARK: - Scene views
#if os(macOS)
struct PartSceneView_macOS: NSViewRepresentable
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
        //Update commands
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
        var control: PartSceneView_macOS
        
        init(_ control: PartSceneView_macOS, _ scn_view: SCNView)
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
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Figure", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Figure"
            app_state.preview_update_scene = false
        }
    }
}
#else
struct PartSceneView_iOS: UIViewRepresentable
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
        //Update commands
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
        var control: PartSceneView_iOS
        
        init(_ control: PartSceneView_iOS, _ scn_view: SCNView)
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
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Figure", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Figure"
            app_state.preview_update_scene = false
        }
    }
}
#endif

//MARK: - Previews
struct PartsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            PartsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
            AddPartView(add_part_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            PartView(part_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), part_item: .constant(Part(name: "None", dictionary: ["String" : "Any"])), new_physics: .ph_none)
                .environmentObject(AppState())
                .environmentObject(Workspace())
        }
    }
}
