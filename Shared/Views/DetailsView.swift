//
//  DetailsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct DetailsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_detail_view_presented = false
    @State private var detail_view_presented = false
    @State private var dragged_detail: Detail?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.details.count > 0
            {
                //MARK: Scroll view for details
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.details)
                        { detail_item in
                            DetailCardView(document: $document, detail_item: detail_item)
                            .onDrag({
                                self.dragged_detail = detail_item
                                return NSItemProvider(object: detail_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                SmallCardViewPreview(color: detail_item.card_info.color, image: detail_item.card_info.image, title: detail_item.card_info.title)
                            })
                            .onDrop(of: [UTType.text], delegate: DetailDropDelegate(details: $base_workspace.details, dragged_detail: $dragged_detail, document: $document, workspace_details: base_workspace.file_data().details, detail: detail_item))
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .modifier(DoubleModifier(update_toggle: $app_state.view_update_state))
            }
            else
            {
                Text("Press «+» to add new detail")
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
                    Button (action: { add_detail_view_presented.toggle() })
                    {
                        Label("Add Detail", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_detail_view_presented)
                    {
                        AddDetailView(add_detail_view_presented: $add_detail_view_presented, document: $document)
                    }
                }
            }
        }
    }
    
    //MARK: Details manage functions
    func remove_details(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.details.remove(atOffsets: offsets)
            document.preset.details = base_workspace.file_data().details
        }
    }
}

//MARK: - Details card view
struct DetailCardView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var detail_item: Detail
    @State private var detail_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        SmallCardView(color: detail_item.card_info.color, image: detail_item.card_info.image, title: detail_item.card_info.title)
            .modifier(BorderlessDeleteButtonModifier(workspace: base_workspace, object_item: detail_item, objects: base_workspace.details, on_delete: remove_details, object_type_name: "detail"))
            .onTapGesture
            {
                detail_view_presented = true
            }
            .sheet(isPresented: $detail_view_presented)
            {
                DetailView(detail_view_presented: $detail_view_presented, document: $document, detail_item: $detail_item)
                    .onDisappear()
                {
                    detail_view_presented = false
                }
            }
    }
    
    func remove_details(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.details.remove(atOffsets: offsets)
            document.preset.details = base_workspace.file_data().details
        }
    }
}

//MARK: - Drag and Drop delegate
struct DetailDropDelegate : DropDelegate
{
    @Binding var details : [Detail]
    @Binding var dragged_detail : Detail?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_details: [DetailStruct]
    
    let detail: Detail
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.details = workspace_details //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_detail = self.dragged_detail else
        {
            return
        }
        
        if dragged_detail != detail
        {
            let from = details.firstIndex(of: dragged_detail)!
            let to = details.firstIndex(of: detail)!
            withAnimation(.default)
            {
                self.details.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Add detail view
struct AddDetailView: View
{
    @Binding var add_detail_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_detail_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            DetailSceneView_macOS()
                .overlay(alignment: .top)
                {
                    Text("Add Detail")
                        .font(.title2)
                        .padding(8.0)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            #else
            DetailSceneView_iOS()
                .overlay(alignment: .top)
                {
                    Text("Add Detail")
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
                TextField("None", text: $new_detail_name)
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
                Picker(selection: $app_state.detail_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.details, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8.0)
                .padding(.leading)
                
                Button("Cancel", action: { add_detail_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: add_detail_in_workspace)
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
            app_state.update_detail_info()
        }
    }
    
    func add_detail_in_workspace()
    {
        if new_detail_name == ""
        {
            new_detail_name = "None"
        }
        
        app_state.get_scene_image = true
        app_state.previewed_object?.name = new_detail_name
        base_workspace.add_detail(app_state.previewed_object! as! Detail)
        document.preset.details = base_workspace.file_data().details
        
        add_detail_view_presented.toggle()
    }
}

//MARK: - Detail view
struct DetailView: View
{
    @Binding var detail_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var detail_item: Detail
    
    //@State private var new_detail_name = ""
    @State var new_physics: PhysicsType = .ph_none
    @State var new_gripable = false
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
            DetailSceneView_macOS()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            DetailSceneView_iOS()
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
                
                Toggle("Gripable", isOn: $new_gripable)
                    .toggleStyle(SwitchToggleStyle())
                    #if os(iOS)
                    .frame(maxWidth: 128)
                    #endif
                    .padding(.trailing)
                    .onChange(of: new_gripable)
                    { _ in
                        update_data()
                    }
            }
            .padding(.vertical)
        }
        .overlay(alignment: .topLeading)
        {
            Button(action: { detail_view_presented.toggle() })
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
            app_state.previewed_object = detail_item
            app_state.preview_update_scene = true
            
            app_state.reset_previewed_node_position()
            
            let previewed_detail = app_state.previewed_object as? Detail
            previewed_detail?.enable_physics = false
            
            new_physics = detail_item.physics_type
            new_gripable = detail_item.gripable ?? false
            new_color = detail_item.color
            
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
            detail_item.physics_type = new_physics
            detail_item.gripable = new_gripable
            detail_item.color = new_color
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                document.preset.details = base_workspace.file_data().details
            }
            //document.preset.details = base_workspace.file_data().details
            is_document_updated = true
        }
    }
}

//MARK: - Scene views
#if os(macOS)
struct DetailSceneView_macOS: NSViewRepresentable
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
        var control: DetailSceneView_macOS
        
        init(_ control: DetailSceneView_macOS, _ scn_view: SCNView)
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
struct DetailSceneView_iOS: UIViewRepresentable
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
        var control: DetailSceneView_iOS
        
        init(_ control: DetailSceneView_iOS, _ scn_view: SCNView)
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
struct DetailsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            DetailsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
            AddDetailView(add_detail_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            DetailView(detail_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), detail_item: .constant(Detail(name: "None", dictionary: ["String" : "Any"])), new_physics: .ph_none)
                .environmentObject(AppState())
                .environmentObject(Workspace())
        }
    }
}
