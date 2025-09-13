//
//  GalleryWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI
import SceneKit

struct GalleryWorkspaceView: View
{
    @State private var add_in_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
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
                    GroupBox
                    {
                        PlacedRobotsGallery()
                    }
                    
                    GroupBox
                    {
                        PlacedToolsGallery()
                    }
                    
                    GroupBox
                    {
                        PlacedPartsGallery()
                    }
                    
                    Spacer(minLength: 64)
                }
            }
            #if os(visionOS)
            .clipShape(UnevenRoundedRectangle(topTrailingRadius: 40, style: .continuous))
            #endif
            .padding(8)
        }
        #if !os(visionOS)
        .overlay(alignment: .bottomLeading)
        {
            Button(action: { add_in_view_presented.toggle() })
            {
                Image(systemName: "plus")
                    .modifier(CircleButtonImageFramer())
            }
            .modifier(CircleButtonGlassBorderer())
            .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
            {
                #if os(macOS)
                AddInWorkspaceView(add_in_view_presented: $add_in_view_presented)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                AddInWorkspaceView(add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                    .frame(maxWidth: 1024)
                    .background(.ultraThinMaterial)
                #endif
            }
            .disabled(base_workspace.performed)
            .padding()
        }
        #else
        .ornament(attachmentAnchor: .scene(.bottom))
        {
            Button(action: { add_in_view_presented.toggle() })
            {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .padding()
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
            {
                AddInWorkspaceView(add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                    .frame(maxWidth: 1024)
            }
            .disabled(base_workspace.performed)
            .padding()
            .glassBackgroundEffect()
        }
        #endif
    }
}

struct PlacedRobotsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_scale, maximum: .infinity), spacing: object_card_spacing)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.placed_robots_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_robots_names, id: \.self)
                    { name in
                        ObjectCard(name: name, node: base_workspace.robot_by_name(name).node)
                            {
                                base_workspace.select_robot(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
                Text("No robots placed")
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
            if base_workspace.placed_tools_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_tools_names, id: \.self)
                    { name in
                        ObjectCard(name: name, node: base_workspace.tool_by_name(name).node, overlay: {
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
                                            .font(.system(size: 16))
                                            .padding(8)
                                    }
                                    .toggleStyle(.button)
                                    .buttonStyle(.plain)
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
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
                Text("No tools placed")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, object_card_spacing / 1.5)
    }
    
    private func binding_to_attached(for name: String) -> Binding<Bool>
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
    }
}

struct PlacedPartsGallery: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_scale, maximum: .infinity), spacing: object_card_spacing)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.placed_parts_names.count > 0
            {
                LazyVGrid(columns: columns, spacing: object_card_spacing)
                {
                    ForEach(base_workspace.placed_parts_names, id: \.self)
                    { name in
                        ObjectCard(name: name, node: base_workspace.part_by_name(name).node)
                            {
                                base_workspace.select_part(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
                Text("No parts placed")
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
    
    let node: SCNNode?
    
    let on_select: () -> ()
    
    // Overlay
    let overlay_view: Content?
    
    @State private var info_view_presented = false
    
    @EnvironmentObject var app_state: AppState
    
    public init(name: String, node: SCNNode?, @ViewBuilder overlay: () -> Content? = { EmptyView() }, on_select: @escaping () -> Void)
    {
        self.name = name
        
        let card_node = node?.deep_clone()
        card_node?.physicsBody = .static()
        
        self.node = card_node
        self.on_select = on_select
        
        self.overlay_view = overlay()
    }
    
    var body: some View
    {
        GlassBoxCard(title: name, node: node)
        {
            overlay_view
        }
        .frame(minWidth: object_card_scale, minHeight: object_card_scale / 1.618)
        .onTapGesture
        {
            if !app_state.gallery_disabled
            {
                on_select()
                app_state.gallery_disabled = true
                info_view_presented = true
            }
        }
        .popover(isPresented: $info_view_presented)
        {
            #if os(macOS)
            GalleryInfoView(info_view_presented: $info_view_presented)
                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
            #else
            GalleryInfoView(info_view_presented: $info_view_presented, is_compact: horizontal_size_class == .compact)
                .frame(maxWidth: 1024)
                .background(.ultraThinMaterial)
            #endif
        }
    }
}

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
                            if base_workspace.placed_robots_names.count > 0
                            {
                                Picker("Attached to", selection: $attach_robot_name) // Select object name for place in workspace
                                {
                                    ForEach(base_workspace.placed_robots_names, id: \.self)
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
                                attach_robot_name = base_workspace.placed_robots_names.first ?? "??"
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
        base_workspace.unplace_selected_object()
        
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

#Preview
{
    ObjectCard(name: "Object", node: SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)), on_select: {})
        .environmentObject(AppState())
}
