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
                                SmallCardView(color: part_item.card_info.color, image: part_item.card_info.image, title: part_item.card_info.title)
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
        #if os(macOS) || os(iOS)
        .background(Color.white)
        #endif
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
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
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
    @State private var to_rename = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        SmallCardView(color: part_item.card_info.color, node: part_item.node!, title: part_item.card_info.title, to_rename: $to_rename, edited_name: $part_item.name, on_rename: update_file)
            .shadow(radius: 8)
            .modifier(BorderlessDeleteButtonModifier(workspace: base_workspace, object_item: part_item, objects: base_workspace.parts, on_delete: remove_parts, object_type_name: "part"))
            .modifier(CardMenu(object: part_item, to_rename: $to_rename, clear_preview: part_item.clear_preview, duplicate_object: {
                base_workspace.duplicate_part(name: part_item.name)
            }, update_file: update_file, pass_preferences: {
                
            }, pass_programs: {
                
            }))
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
                #if os(visionOS)
                    .frame(width: 512, height: 512)
                #endif
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
    
    private func update_file()
    {
        document.preset.parts = base_workspace.file_data().parts
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
            PartPreviewSceneView()
                .overlay(alignment: .top)
                {
                    Text("Add Part")
                        .font(.title2)
                        .padding(8)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            
            Divider()
            Spacer()
            
            HStack
            {
                Text("Name")
                    .bold()
                TextField("None", text: $new_part_name)
                #if os(iOS) || os(visionOS)
                    .textFieldStyle(.roundedBorder)
                #endif
            }
            .padding(.top, 8)
            .padding(.horizontal)
            
            HStack(spacing: 0)
            {
                #if os(iOS) || os(visionOS)
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
                .padding(.vertical, 8)
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
        .onChange(of: app_state.part_name)
        { _, _ in
            app_state.update_part_info()
        }
        .onAppear
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
            PartSceneView(part: $part_item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
                #if os(iOS) || os(visionOS)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                #endif
                .padding(.horizontal)
                .onChange(of: new_physics)
                { _, _ in
                    update_data()
                }
                
                ColorPicker("Color", selection: $new_color)
                    .padding(.trailing)
                    .onChange(of: new_color)
                    { _, _ in
                        update_data()
                    }
                #if os(iOS) || os(visionOS)
                    .frame(width: 112)
                #endif
            }
            .padding(.vertical)
        }
        .modifier(ViewCloseButton(is_presented: $part_view_presented))
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
            is_document_updated = true
        }
    }
}

//MARK: - Scene views
struct PartPreviewSceneView: View
{
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, on_render: update_preview_node(scene_view:), on_tap: { _, _ in })
    }
    
    private func update_preview_node(scene_view: SCNView)
    {
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            remove_node?.removeFromParentNode()
            
            app_state.update_part_info()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Node"
            app_state.preview_update_scene = false
        }
    }
}

struct PartSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var app_state: AppState
    
    @Binding var part: Part
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, node: part.node ?? SCNNode(), on_render: update_view_node(scene_view:), on_tap: { _, _ in })
    }
    
    private func update_view_node(scene_view: SCNView)
    {
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            app_state.previewed_object?.image = scene_view.snapshot()
        }
    }
}

//MARK: - Scene Views typealilases
#if os(macOS)
typealias UIViewRepresentable = NSViewRepresentable
typealias UITapGestureRecognizer = NSClickGestureRecognizer
typealias UIColor = NSColor
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
