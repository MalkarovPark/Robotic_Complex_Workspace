//
//  GalleryWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 06.12.2023.
//

import SwiftUI
import IndustrialKit
import SceneKit

struct GalleryWorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_in_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ScrollView(.vertical)
            {
                GroupBox
                {
                    PlacedRobotsGallery(document: $document)
                }
                .padding(.top, 8)
                
                GroupBox
                {
                    PlacedToolsGallery(document: $document)
                }
                
                GroupBox
                {
                    PlacedPartsGallery(document: $document)
                }
                .padding(.bottom, 8)
                
                Spacer(minLength: 64)
            }
            .padding(.horizontal, 8)
        }
        .overlay(alignment: .bottomLeading)
        {
            VStack(spacing: 0)
            {
                Button(action: { add_in_view_presented.toggle() })
                {
                    Image(systemName: "plus")
                        .imageScale(.large)
                        .padding()
                    #if os(iOS)
                        .foregroundColor(base_workspace.performed ? Color.secondary : Color.black)
                    #elseif os(visionOS)
                        .foregroundColor(base_workspace.performed ? Color.secondary : Color.primary)
                    #endif
                }
                .buttonStyle(.borderless)
                #if os(iOS)
                .foregroundColor(.black)
                #endif
                .popover(isPresented: $add_in_view_presented)
                {
                    #if os(macOS)
                    AddInWorkspaceView(document: $document, add_in_view_presented: $add_in_view_presented)
                        .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                    #else
                    AddInWorkspaceView(document: $document, add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                        .frame(maxWidth: 1024)
                    #endif
                }
                .disabled(base_workspace.performed)
            }
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(radius: 8)
            .fixedSize(horizontal: true, vertical: false)
            .padding()
        }
    }
}

struct PlacedRobotsGallery: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
    private let numbers = (0...7).map { $0 }
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_maximum, maximum: object_card_maximum), spacing: 0)]
    
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
                        ObjectCard(document: $document, name: name, color: registers_colors[6], image: base_workspace.robot_by_name(name).card_info.image, node: nil)
                            {
                                base_workspace.select_robot(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                #if os(macOS)
                .padding(.vertical, 16)
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
    }
}

struct PlacedToolsGallery: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_maximum, maximum: object_card_maximum), spacing: 0)]
    
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
                        ObjectCard(document: $document, name: name, color: registers_colors[8], image: nil, node: base_workspace.tool_by_name(name).node)
                            {
                                base_workspace.select_tool(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                #if os(macOS)
                .padding(.vertical, 16)
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
    }
}

struct PlacedPartsGallery: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
    private let numbers = (0...7).map { $0 }
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: object_card_maximum, maximum: object_card_maximum), spacing: 0)]
    
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
                        ObjectCard(document: $document, name: name, color: registers_colors[11], image: nil, node: base_workspace.part_by_name(name).node)
                            {
                                base_workspace.select_part(name: name)
                            }
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                #if os(macOS)
                .padding(.vertical, 16)
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
    }
}

struct ObjectCard: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    let name: String
    let color: Color
    
    let image: UIImage?
    let node: SCNNode?
    
    let on_select: () -> ()
    
    @State private var info_view_presented = false
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundStyle(color)
                .opacity(0.8)
        }
        .overlay(alignment: .topLeading)
        {
            Text(name)
                .foregroundStyle(.white)
                .font(.largeTitle)
                .fontDesign(.rounded)
                .padding()
        }
        .overlay(alignment: .bottomTrailing)
        {
            Rectangle()
                .fill(.clear)
                .overlay
            {
                if image != nil
                {
                    #if os(macOS)
                    Image(nsImage: image!)
                        .resizable()
                        .scaledToFill()
                    #else
                    Image(uiImage: image!)
                        .resizable()
                        .scaledToFill()
                    #endif
                }
                
                if node != nil
                {
                    ObjectSceneView(node: node!)
                        .disabled(true)
                        .padding(8)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .shadow(radius: 2)
            .padding(8)
        }
        .frame(width: object_card_scale, height: object_card_scale / 1.618)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 8)
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
            GalleryInfoView(info_view_presented: $info_view_presented, document: $document)
            #if os(iOS) || os(visionOS)
                .presentationDetents([.height(256)])
            #endif
        }
    }
}

struct GalleryInfoView: View
{
    @Binding var info_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @State private var avaliable_attachments = [String]()
    @State private var attach_robot_name = String()
    @State private var old_attachment: String?
    
    @State var is_compact = false
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            //Selected object position editor
            DynamicStack(content: {
                switch base_workspace.selected_object_type
                {
                case .robot:
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                        .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
                        { _, _ in
                            document.preset.robots = base_workspace.file_data().robots
                        }
                case .tool:
                    if !base_workspace.selected_tool.is_attached
                    {
                        PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                            .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                            { _, _ in
                                document.preset.tools = base_workspace.file_data().tools
                            }
                    }
                    else
                    {
                        HStack(spacing: 0)
                        {
                            if avaliable_attachments.count > 0
                            {
                                Picker("Attach to", selection: $attach_robot_name) //Select object name for place in workspace
                                {
                                    ForEach(avaliable_attachments, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                #if os(iOS) || os(visionOS)
                                .buttonStyle(.bordered)
                                #endif
                                
                                Toggle(isOn: $base_workspace.selected_tool.is_attached)
                                {
                                    Image(systemName: "pin.fill")
                                }
                                .toggleStyle(.button)
                                .onChange(of: base_workspace.selected_tool.is_attached)
                                { _, new_value in
                                    if !new_value
                                    {
                                        base_workspace.selected_tool.attached_to = nil
                                    }
                                    document.preset.tools = base_workspace.file_data().tools
                                }
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
                            if base_workspace.selected_tool.is_attached
                            {
                                old_attachment = base_workspace.selected_tool.attached_to
                                base_workspace.selected_tool.attached_to = nil
                                avaliable_attachments = base_workspace.attachable_robots_names
                                
                                if old_attachment == nil
                                {
                                    attach_robot_name = avaliable_attachments.first!
                                    //base_workspace.attach_tool_to(robot_name: attach_robot_name)
                                }
                                else
                                {
                                    attach_robot_name = old_attachment!
                                }
                            }
                        }
                    }
                case .part:
                    PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
                        .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
                        { _, _ in
                            document.preset.parts = base_workspace.file_data().parts
                        }
                default:
                    Text("None")
                }
            }, is_compact: $is_compact, spacing: 12)
            .padding([.horizontal, .top])
            
            #if os(iOS) || os(visionOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            HStack
            {
                Button(role: .destructive, action: remove_object)
                {
                    Text("Remove from workspace")
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
                        document.preset.tools = base_workspace.file_data().tools
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
    
    private func remove_object()
    {
        let type_for_save = base_workspace.selected_object_type
        base_workspace.remove_selected_object()
        
        switch type_for_save
        {
        case .robot:
            document.preset.robots = base_workspace.file_data().robots
        case .tool:
            if base_workspace.selected_tool.is_attached
            {
                base_workspace.selected_tool.attached_to = nil
                base_workspace.selected_tool.is_attached = false
            }
            document.preset.tools = base_workspace.file_data().tools
        case.part:
            document.preset.parts = base_workspace.file_data().parts
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

let object_card_maximum = object_card_scale + object_card_spacing

#Preview
{
    GalleryWorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}

#Preview
{
    ObjectCard(document: .constant(Robotic_Complex_WorkspaceDocument()), name: "Object", color: .green, image: nil, node: nil, on_select: {})
        .environmentObject(AppState())
}
