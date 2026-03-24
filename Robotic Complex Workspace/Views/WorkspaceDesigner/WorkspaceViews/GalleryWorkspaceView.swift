//
//  GalleryWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI
import RealityKit

struct GalleryWorkspaceView: View
{
    @State private var add_in_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 128, maximum: .infinity), spacing: 24)]
    private let card_spacing: CGFloat = 24
    private let card_height: CGFloat = 128
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ScrollView(.vertical)
            {
                VStack(spacing: 8)
                {
                    if base_workspace.robots.count > 0
                    {
                        PlacedRobotsGallery(columns: columns, card_spacing: card_spacing, card_height: card_height)
                    }
                    
                    if base_workspace.tools.count > 0
                    {
                        PlacedToolsGallery(columns: columns, card_spacing: card_spacing, card_height: card_height)
                    }
                    
                    if base_workspace.parts.count > 0
                    {
                        PlacedPartsGallery(columns: columns, card_spacing: card_spacing, card_height: card_height)
                    }
                    
                    //Spacer(minLength: 56)
                }
                .padding(8)
            }
        }
        .onTapGesture
        {
            base_workspace.process_empty_tap()
        }
    }
}

struct PlacedRobotsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    var body: some View
    {
        Text("Robots")
            .font(.headline)
        
        LazyVGrid(columns: columns, spacing: card_spacing)
        {
            ForEach(base_workspace.robots)
            { robot in
                WorkspaceObjectCard(object: robot, workspace: base_workspace)
                    .frame(height: card_height)
            }
        }
        .padding()
    }
}

struct PlacedToolsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    var body: some View
    {
        Text("Tools")
            .font(.headline)
        
        LazyVGrid(columns: columns, spacing: card_spacing)
        {
            ForEach(base_workspace.tools)
            { tool in
                WorkspaceObjectCard(object: tool, workspace: base_workspace)
                    .frame(height: card_height)
            }
        }
        .padding()
    }
}

struct PlacedPartsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    var body: some View
    {
        Text("Parts")
            .font(.headline)
        
        LazyVGrid(columns: columns, spacing: card_spacing)
        {
            ForEach(base_workspace.parts)
            { part in
                WorkspaceObjectCard(object: part, workspace: base_workspace)
                    .frame(height: card_height)
            }
        }
        .padding()
    }
}

private struct WorkspaceObjectCard: View
{
    @ObservedObject var object: WorkspaceObject
    @ObservedObject var workspace: Workspace
    
    @State private var is_renaming = false
    @State private var preview_entity: Entity?
    
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State private var view_id = UUID()
    
    var body: some View
    {
        Button
        {
            tap_object()
        }
        label:
        {
            if preview_entity != nil
            {
                GlassBoxCard(
                    title: object.name,
                    entity: preview_entity,
                    vertical_repostion: true,
                    is_renaming: $is_renaming,
                )
                {
                    if object_selected
                    {
                        ZStack(alignment: .bottomTrailing)
                        {
                            Rectangle()
                                .fill(.clear)
                            
                            ZStack
                            {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.primary)
                            }
                            #if os(macOS)
                            .frame(width: 40, height: 40)
                            #else
                            .frame(width: 48, height: 48)
                            #endif
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            else
            {
                GlassBoxCard(
                    title: object.name,
                    symbol_name: symbol_name,
                    symbol_size: 64,
                    symbol_weight: .regular,
                    is_renaming: $is_renaming,
                )
                {
                    if object_selected
                    {
                        ZStack(alignment: .bottomTrailing)
                        {
                            Rectangle()
                                .fill(.clear)
                            
                            ZStack
                            {
                                Image(systemName: "checkmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 10, height: 10)
                                    .foregroundStyle(.primary)
                            }
                            #if os(macOS)
                            .frame(width: 20, height: 20)
                            #else
                            .frame(width: 24, height: 24)
                            #endif
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    if let tool = object as? Tool,
                       tool.attached_to != nil
                    {
                        ZStack(alignment: .topTrailing)
                        {
                            Rectangle()
                                .fill(.clear)
                            
                            ZStack
                            {
                                Image(systemName: "pin.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 10, height: 10)
                                    .foregroundStyle(.primary)
                            }
                            #if os(macOS)
                            .frame(width: 20, height: 20)
                            #else
                            .frame(width: 24, height: 24)
                            #endif
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .id(view_id)
        .onAppear
        {
            load_entity()
        }
        .onDisappear
        {
            preview_entity = nil
        }
    }
    
    private func load_entity()
    {
        /*if let entity_file_name = module.entity_file_name,
           let entity_file_item = base_stc.entity_items.first(where: { $0.name == entity_file_name })
        {
            preview_entity = entity_file_item.entity.clone(recursive: true)
        }
        else
        {
            preview_entity = nil
        }*/
    }
    
    private func reset_card()
    {
        view_id = UUID()
        load_entity()
    }
    
    private var symbol_name: String
    {
        switch object
        {
        case is Robot: "r.square"
        case is Tool: "hammer"
        case is Part: "shippingbox"
        default: String()
        }
    }
    
    /*private var object_names: [String]
    {
        switch object
        {
        case is Robot: workspace.robot_names
        case is Tool: workspace.tool_names
        case is Part: workspace.part_names
        default: [String]()
        }
    }*/
    
    private func tap_object()
    {
        if !object_selected
        {
            workspace.select_object(object)
        }
        else
        {
            workspace.process_empty_tap()
            //workspace.deselect_object()
        }
    }
    
    private var object_selected: Bool
    {
        switch object
        {
        case is Robot:
            return workspace.selected_object is Robot
            ? object.name == workspace.selected_object?.name
            : false
        case is Tool:
            return workspace.selected_object is Tool
            ? object.name == workspace.selected_object?.name
            : false
        case is Part:
            return workspace.selected_object is Part
            ? object.name == workspace.selected_object?.name
            : false
        default:
            return false
        }
    }
    
    private var document_update_objects: () -> ()
    {
        switch object
        {
        case is Robot: { document_handler.document_update_robots() }
        case is Tool: { document_handler.document_update_tools() }
        case is Part: { document_handler.document_update_parts() }
        default: {}
        }
    }
}

#if os(macOS)
let object_card_scale: CGFloat = 160
let object_card_spacing: CGFloat = 20
#else
let object_card_scale: CGFloat = 192
let object_card_spacing: CGFloat = 32
#endif

#Preview
{
    GalleryWorkspaceView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
