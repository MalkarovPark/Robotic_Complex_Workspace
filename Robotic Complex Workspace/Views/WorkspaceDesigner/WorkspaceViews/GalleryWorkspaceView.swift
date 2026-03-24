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
                    /*on_rename:
                        { new_name in
                            object.name = unique_name(for: new_name, in: object_names)
                            document_update_objects()
                            is_renaming = false
                        }*/
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
                    /*on_rename:
                        { new_name in
                            object.name = unique_name(for: new_name, in: object_names)
                            document_update_objects()
                            is_renaming = false
                        }*/
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
            workspace.deselect_object()
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

/*struct PlacedRobotsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_scale, maximum: .infinity), spacing: object_card_spacing)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.placed_robot_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_robot_names, id: \.self)
                    { name in
                        /*ObjectCard(name: name, entity: base_workspace.robot_by_name(name).entity)
                            {
                                base_workspace.select_robot(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))*/
                    }
                }
                #if os(macOS)
                .padding(.vertical, object_card_spacing / 1.5)
                #else
                .padding(.vertical)
                #endif
            }
            else
            {
                Text("No placed")
                #if os(macOS)
                    .font(.system(size: 16))
                #else
                    .font(.system(size: 24))
                #endif
                    .foregroundStyle(.secondary)
                    .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, object_card_spacing / 1.5)
    }
}

struct PlacedToolsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_scale, maximum: .infinity), spacing: object_card_spacing)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.placed_tool_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_tool_names, id: \.self)
                    { name in
                        /*ObjectCard(name: name, entity: base_workspace.tool_by_name(name).entity, overlay: {
                            VStack
                            {
                                Spacer()
                                
                                HStack
                                {
                                    Spacer()
                                    
                                    Toggle(isOn: binding_to_attached(for: name))
                                    {
                                        Image(systemName: base_workspace.tool_by_name(name).is_attached ? "pin.slash.fill" : "pin.fill")
                                            .foregroundStyle(.black)
                                        #if os(macOS)
                                            .font(.system(size: 12))
                                        #else
                                            .font(.system(size: 16))
                                        #endif
                                            .padding(8)
                                    }
                                    .toggleStyle(.button)
                                    .buttonStyle(.plain)
                                    #if os(macOS)
                                    .frame(width: 32, height: 32)
                                    #else
                                    .frame(width: 36, height: 36)
                                    #endif
                                    #if !os(visionOS)
                                    .background(.bar)
                                    #else
                                    .background(.thinMaterial)
                                    #endif
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .padding(8)
                                }
                            }
                        })
                        {
                            base_workspace.select_tool(name: name)
                        }
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))*/
                    }
                }
                #if os(macOS)
                .padding(.vertical, object_card_spacing / 1.5)
                #else
                .padding(.vertical)
                #endif
            }
            else
            {
                Text("No placed")
                #if os(macOS)
                    .font(.system(size: 16))
                #else
                    .font(.system(size: 24))
                #endif
                    .foregroundStyle(.secondary)
                    .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, object_card_spacing / 1.5)
    }
    
    /*private func binding_to_attached(for name: String) -> Binding<Bool>
    {
        Binding(
            get: {
                base_workspace.tool_by_name(name).is_attached
            },
            set: { newValue in
                document_handler.document_update_tools()
                base_workspace.tool_by_name(name).is_attached = newValue
            }
        )
    }*/
}

struct PlacedPartsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_scale, maximum: .infinity), spacing: object_card_spacing)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.placed_part_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_part_names, id: \.self)
                    { name in
                        /*ObjectCard(name: name, entity: base_workspace.part_by_name(name).entity)
                            {
                                base_workspace.select_part(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))*/
                    }
                }
                #if os(macOS)
                .padding(.vertical, object_card_spacing / 1.5)
                #else
                .padding(.vertical)
                #endif
            }
            else
            {
                Text("No placed")
                #if os(macOS)
                    .font(.system(size: 16))
                #else
                    .font(.system(size: 24))
                #endif
                    .foregroundStyle(.secondary)
                    .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, object_card_spacing / 1.5)
    }
}

struct ObjectCard<Content: View>: View
{
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    let name: String
    
    let entity: Entity?
    
    let on_select: () -> ()
    
    // Overlay
    let overlay_view: Content?
    
    @State private var info_view_presented = false
    
    @EnvironmentObject var app_state: AppState
    
    public init(name: String, entity: Entity?, @ViewBuilder overlay: () -> Content? = { EmptyView() }, on_select: @escaping () -> Void)
    {
        self.name = name
        
        //let card_entity = entity?.deep_clone()
        //card_entity?.physicsBody = .static()
        
        self.entity = entity//card_entity
        self.on_select = on_select
        
        self.overlay_view = overlay()
    }
    
    var body: some View
    {
        GlassBoxCard(title: name, entity: entity)
        {
            overlay_view
        }
        .frame(minWidth: object_card_scale, minHeight: object_card_scale)
        .onTapGesture
        {
            if !app_state.gallery_disabled
            {
                on_select()
                app_state.gallery_disabled = true
                info_view_presented = true
            }
        }
        .popover(isPresented: $info_view_presented, arrowEdge: .trailing)
        {
            #if os(macOS)
            GalleryInfoView(info_view_presented: $info_view_presented)
                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
            #else
            GalleryInfoView(info_view_presented: $info_view_presented, is_compact: horizontal_size_class == .compact)
                .frame(maxWidth: 1024)
            #if !os(visionOS)
                .background(.ultraThinMaterial)
            #endif
            #endif
        }
    }
}*/

struct GalleryInfoView: View
{
    @Binding var info_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State private var attach_robot_name = String()
    @State private var old_attachment: String?
    
    @State var is_compact = false
    
    var body: some View
    {
        EmptyView()
    }
    
    /*var body: some View
    {
        VStack(spacing: 0)
        {
            // Selected object position editor
            DynamicStack(content: {
                switch base_workspace.selected_object_type
                {
                case .robot:
                    PositionView(position: $base_workspace.selected_robot.position)
                        .onChange(of: PositionSnapshot(base_workspace.selected_robot.position))
                        { _, _ in
                            document_handler.document_update_robots()
                        }
                case .tool:
                    if !base_workspace.selected_tool.is_attached
                    {
                        DynamicStack(content: {
                            PositionView(position: $base_workspace.selected_tool.position)
                                .onChange(of: PositionSnapshot(base_workspace.selected_tool.position))
                                { _, _ in
                                    document_handler.document_update_tools()
                                }
                        }, is_compact: $is_compact, spacing: 16)
                    }
                    else
                    {
                        HStack(spacing: 0)
                        {
                            if base_workspace.placed_robot_names.count > 0
                            {
                                Picker("Attached to", selection: $attach_robot_name) // Select object name for place in workspace
                                {
                                    ForEach(base_workspace.placed_robot_names, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                #if os(iOS) || os(visionOS)
                                .buttonStyle(.bordered)
                                #endif
                            }
                            else
                            {
                                Text("No robots for attach")
                                    .padding([.horizontal, .top])
                            }
                        }
                        .frame(minWidth: 224)
                        .onAppear
                        {
                            if base_workspace.selected_tool.attached_to == nil
                            {
                                attach_robot_name = base_workspace.placed_robot_names.first ?? "??"
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            else
                            {
                                attach_robot_name = base_workspace.selected_tool.attached_to!
                            }
                            
                            base_workspace.selected_tool.attached_to = attach_robot_name
                        }
                    }
                case .part:
                    PositionView(position: $base_workspace.selected_part.position)
                        .onChange(of: PositionSnapshot(base_workspace.selected_part.position))
                        { _, _ in
                            document_handler.document_update_parts()
                        }
                default:
                    Text("None")
                }
            }, is_compact: $is_compact, spacing: 16)
            .padding([.horizontal, .top])
            
            #if os(iOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            HStack
            {
                Button(role: .destructive, action: unplace_object)
                {
                    Text("Unplace from workspace")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .onAppear
        {
            base_workspace.in_visual_edit_mode = true
        }
        .onDisappear
        {
            base_workspace.in_visual_edit_mode = false
            
            switch base_workspace.selected_object_type
            {
            case .robot:
                base_workspace.deselect_robot()
            case .tool:
                if base_workspace.selected_tool.is_attached
                {
                    base_workspace.selected_tool.attached_to = attach_robot_name
                    
                    if old_attachment != attach_robot_name
                    {
                        document_handler.document_update_tools()
                    }
                }
                else
                {
                    base_workspace.selected_tool.attached_to = nil
                }
                
                base_workspace.deselect_tool()
            case .part:
                base_workspace.deselect_part()
            default:
                break
            }
            
            app_state.gallery_disabled = false
        }
    }
    
    private func unplace_object()
    {
        let type_for_save = base_workspace.selected_object_type
        //base_workspace.unplace_selected_object()
        
        switch type_for_save
        {
        case .robot:
            document_handler.document_update_robots()
        case .tool:
            if base_workspace.selected_tool.is_attached
            {
                base_workspace.selected_tool.attached_to = nil
                base_workspace.selected_tool.is_attached = false
            }
            document_handler.document_update_tools()
        case.part:
            document_handler.document_update_parts()
        default:
            break
        }
        
        info_view_presented.toggle()
    }*/
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

/*#Preview
{
    ObjectCard(name: "Object", entity: ModelEntity(mesh: .generateBox(size: 1.0, cornerRadius: 0.1), materials: [SimpleMaterial(color: .white, isMetallic: false)]), on_select: {})
        .environmentObject(AppState())
}*/
