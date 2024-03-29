//
//  PartsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 28.08.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct PartsView: View
{
    @State private var add_part_view_presented = false
    @State private var part_view_presented = false
    @State private var dragged_part: Part?
    @State private var is_physics_reset = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.parts.count > 0
            {
                if is_physics_reset
                {
                    //MARK: Scroll view for parts
                    ScrollView(.vertical, showsIndicators: true)
                    {
                        LazyVGrid(columns: columns, spacing: 24)
                        {
                            ForEach(base_workspace.parts)
                            { part_item in
                                PartCardView(part_item: part_item)
                                .onDrag({
                                    self.dragged_part = part_item
                                    return NSItemProvider(object: part_item.id.uuidString as NSItemProviderWriting)
                                }, preview: {
                                    SmallCardView(color: part_item.card_info.color, image: part_item.card_info.image, title: part_item.card_info.title)
                                })
                                .onDrop(of: [UTType.text], delegate: PartDropDelegate(parts: $base_workspace.parts, dragged_part: $dragged_part, workspace_parts: base_workspace.file_data().parts, part: part_item, app_state: app_state))
                                .transition(AnyTransition.scale)
                            }
                        }
                        .padding(20)
                    }
                    .modifier(DoubleModifier(update_toggle: $app_state.view_update_state))
                }
            }
            else
            {
                Text("Press to add new part ↑")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
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
            ToolbarItem(placement: .automatic)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_part_view_presented.toggle() })
                    {
                        Label("Add Part", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_part_view_presented)
                    {
                        AddPartView(add_part_view_presented: $add_part_view_presented)
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
                    }
                }
            }
        }
        .onAppear
        {
            reset_all_parts_nodes()
            #if os(visionOS)
            pendant_controller.view_dismiss()
            #endif
        }
    }
    
    //MARK: Parts manage functions
    private func remove_parts(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.parts.remove(atOffsets: offsets)
            app_state.document_update_parts()
        }
    }
    
    private func reset_all_parts_nodes()
    {
        for part in base_workspace.parts
        {
            part.node?.remove_all_constraints()
            part.node?.physicsBody = nil
            
            part.node?.position = SCNVector3Zero
            part.node?.rotation = SCNVector4Zero
        }
        
        is_physics_reset = true
    }
}

//MARK: - Parts card view
struct PartCardView: View
{
    @EnvironmentObject var app_state: AppState
    
    @State var part_item: Part
    @State private var part_view_presented = false
    @State private var to_rename = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        SmallCardView(color: part_item.card_info.color, node: part_item.node ?? SCNNode(), title: part_item.card_info.title, to_rename: $to_rename, edited_name: $part_item.name, on_rename: update_file)
        #if !os(visionOS)
            .shadow(radius: 8)
        #endif
            .modifier(CardMenu(object: part_item, to_rename: $to_rename, duplicate_object: {
                base_workspace.duplicate_part(name: part_item.name)
            }, delete_object: delete_part, update_file: update_file))
            .onTapGesture
            {
                part_view_presented = true
            }
            .sheet(isPresented: $part_view_presented)
            {
                PartView(part_view_presented: $part_view_presented, part_item: $part_item)
                    .onDisappear()
                    {
                        part_view_presented = false
                    }
                #if os(visionOS)
                    .frame(width: 512, height: 512)
                #endif
            }
    }
    
    private func delete_part()
    {
        withAnimation
        {
            base_workspace.parts.remove(at: base_workspace.parts.firstIndex(of: part_item) ?? 0)
            base_workspace.elements_check()
            app_state.document_update_parts()
        }
    }
    
    private func update_file()
    {
        app_state.document_update_parts()
    }
}

//MARK: - Drag and Drop delegate
struct PartDropDelegate : DropDelegate
{
    @Binding var parts : [Part]
    @Binding var dragged_part : Part?
    
    @State var workspace_parts: [PartStruct]
    
    let part: Part
    
    let app_state: AppState
    
    func performDrop(info: DropInfo) -> Bool
    {
        app_state.document_update_parts()
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
            let from = parts.firstIndex(of: dragged_part) ?? 0
            let to = parts.firstIndex(of: part) ?? 0
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
                    Text("New Part")
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
                
                Button("Add", action: add_part_in_workspace)
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
        app_state.document_update_parts()
        
        add_part_view_presented.toggle()
    }
}

//MARK: - Part view
struct PartView: View
{
    @Binding var part_view_presented: Bool
    @Binding var part_item: Part
    
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
                app_state.document_update_parts()
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
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn") ?? SCNScene(), on_render: update_preview_node(scene_view:), on_tap: { _, _ in })
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
    @Binding var part: Part
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn") ?? SCNScene(), node: part.node ?? SCNNode())
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
            PartsView()
                .environmentObject(Workspace())
            AddPartView(add_part_view_presented: .constant(true))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            PartView(part_view_presented: .constant(true), part_item: .constant(Part(name: "None", dictionary: ["String" : "Any"])), new_physics: .ph_none)
                .environmentObject(AppState())
                .environmentObject(Workspace())
        }
    }
}
