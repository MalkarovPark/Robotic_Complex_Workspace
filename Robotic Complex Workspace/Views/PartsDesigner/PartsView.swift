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
import IndustrialKitUI

struct PartsView: View
{
    @State private var add_part_view_presented = false
    @State private var part_view_presented = false
    @State private var dragged_part: Part?
    @State private var is_physics_reset = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    @EnvironmentObject var sidebar_controller: SidebarController
    
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
                    // MARK: Scroll view for parts
                    ScrollView(.vertical, showsIndicators: true)
                    {
                        LazyVGrid(columns: columns, spacing: 24)
                        {
                            ForEach(base_workspace.parts)
                            { part_item in
                                PartCardView(part_item: part_item).frame(height: 192)
                                /*.onDrag({
                                    self.dragged_part = part_item
                                    return NSItemProvider(object: part_item.id.uuidString as NSItemProviderWriting)
                                }, preview: {
                                    GlassBoxCard(title: part_item.card_info.title, color: part_item.card_info.color, image: part_item.card_info.image).frame(height: 192)
                                })
                                .onDrop(of: [UTType.text], delegate: PartDropDelegate(parts: $base_workspace.parts, dragged_part: $dragged_part, workspace_parts: base_workspace.file_data().parts, part: part_item, document_handler: document_handler))*/
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
                ContentUnavailableView
                {
                    Label("No parts in preset", systemImage: "shippingbox")
                }
                description:
                {
                    Text("Press «+» to add new part")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) // Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear
        {
            if sidebar_controller.from_workspace_view
            {
                sidebar_controller.from_workspace_view = false
                add_part_view_presented = true
            }
        }
        .toolbar
        {
            // MARK: Toolbar
            ToolbarItem(placement: .automatic)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_part_view_presented.toggle() })
                    {
                        Label("Add Part", systemImage: "plus")
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
        .sheet(isPresented: $add_part_view_presented)
        {
            AddObjectView(is_presented: $add_part_view_presented, previewed_object: app_state.previewed_object, previewed_object_name: $app_state.previewed_part_module_name, internal_modules_list: $app_state.internal_modules_list.part, external_modules_list: $app_state.external_modules_list.part)
            {
                app_state.update_part_info()
            }
            add_object:
            { new_name in
                app_state.previewed_object?.name = new_name

                base_workspace.add_part(app_state.previewed_object! as! Part)
                document_handler.document_update_parts()
            }

            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
    }
    
    // MARK: Parts manage functions
    private func remove_parts(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.parts.remove(atOffsets: offsets)
            document_handler.document_update_parts()
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

// MARK: - Parts card view
struct PartCardView: View
{
    @State var part_item: Part
    @State private var part_view_presented = false
    @State private var to_rename = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        GlassBoxCard(title: part_item.card_info.title, /*color: part_item.card_info.color,*/ node: part_item.node ?? SCNNode(), to_rename: $to_rename, edited_name: $part_item.name, on_rename: update_file)
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
                    .fitted()
                #if os(macOS)
                    .frame(width: 512)
                #elseif os(iOS)
                    .frame(idealWidth: 800, idealHeight: 600)
                #elseif os(visionOS)
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
            document_handler.document_update_parts()
        }
    }
    
    private func update_file()
    {
        document_handler.document_update_parts()
    }
}

// MARK: - Drag and Drop delegate
struct PartDropDelegate : DropDelegate
{
    @Binding var parts : [Part]
    @Binding var dragged_part : Part?
    
    @State var workspace_parts: [Part]
    
    let part: Part
    
    let document_handler: DocumentUpdateHandler
    
    func performDrop(info: DropInfo) -> Bool
    {
        document_handler.document_update_parts()
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

// MARK: - Scene Views typealilases
#if os(macOS)
typealias UIViewRepresentable = NSViewRepresentable
typealias UITapGestureRecognizer = NSClickGestureRecognizer
typealias UIColor = NSColor
#endif

// MARK: - Previews
#Preview
{
    PartsView()
        .environmentObject(Workspace())
}
