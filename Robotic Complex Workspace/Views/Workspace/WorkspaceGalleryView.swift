//
//  WorkspaceGalleryView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import RealityKit

import IndustrialKit
import IndustrialKitUI

struct WorkspaceGalleryView: View
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
                ProductionObjectCard(object: robot, workspace: base_workspace)
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
                ProductionObjectCard(object: tool, workspace: base_workspace)
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
                ProductionObjectCard(object: part, workspace: base_workspace)
                    .frame(height: card_height)
            }
        }
        .padding()
    }
}

private struct ProductionObjectCard: View
{
    @ObservedObject var object: ProductionObject
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
                    ObjectCardOverlay(object: object)
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
                    ObjectCardOverlay(object: object)
                }
            }
        }
        .opacity(object.is_placed ? 1 : 0.75)
        .animation(.easeInOut(duration: 0.2), value: object.is_placed)
        .animation(.easeInOut(duration: 0.1), value: (object as? Tool)?.attached_to != nil)
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
        .background
        {
            if object_selected
            {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.gray, lineWidth: 2)
                    .opacity(0.5)
            }
        }
    }
    
    private func load_entity()
    {
        switch object
        {
        case is Robot:
            if object.is_internal_module
            {
                preview_entity = Robot.internal_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
            else
            {
                preview_entity = Robot.external_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
        case is Tool:
            if object.is_internal_module
            {
                preview_entity = Tool.internal_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
            else
            {
                preview_entity = Tool.external_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
        case is Part:
            if object.is_internal_module
            {
                preview_entity = Part.internal_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
            else
            {
                preview_entity = Part.external_modules.first { $0.name == object.module_name }?.entity?.clone(recursive: true)
            }
        default:
            break
        }
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
        case is Robot: { document_handler.update_robots() }
        case is Tool: { document_handler.update_tools() }
        case is Part: { document_handler.update_parts() }
        default: {}
        }
    }
}

private struct ObjectCardOverlay: View
{
    @StateObject var object: ProductionObject
    //let object_selected: Bool
    
    var body: some View
    {
        if !object.is_placed
        {
            ZStack(alignment: .topTrailing)
            {
                Image(systemName: "nosign")
                    .font(.system(size: 80))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .opacity(0.1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        /*if object_selected
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
                .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }*/
        
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
                .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    WorkspaceGalleryView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
