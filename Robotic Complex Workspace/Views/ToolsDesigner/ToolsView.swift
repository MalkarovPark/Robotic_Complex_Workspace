//
//  ToolsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 17.03.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct ToolsView: View
{
    @State private var add_tool_view_presented = false
    @State private var tool_view_presented = false
    @State private var dragged_tool: Tool?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    @EnvironmentObject var sidebar_controller: SidebarController
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        NavigationStack
        {
            if base_workspace.tools.count > 0
            {
                //MARK: Scroll view for tools
                ScrollView(.vertical)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.tools)
                        { tool_item in
                            ToolCardView(tool_item: tool_item)
                                .onDrag({
                                    self.dragged_tool = tool_item
                                    return NSItemProvider(object: tool_item.id.uuidString as NSItemProviderWriting)
                                }, preview: {
                                    LargeCardView(color: tool_item.card_info.color, node: tool_item.node, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
                                })
                                .onDrop(of: [UTType.text], delegate: ToolDropDelegate(tools: $base_workspace.tools, dragged_tool: $dragged_tool, workspace_tools: base_workspace.file_data().tools, tool: tool_item, document_handler: document_handler))
                                .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.tools)
            }
            else
            {
                ContentUnavailableView
                {
                    Label("No tools in preset", systemImage: "hammer")
                }
                description:
                {
                    Text("Press «+» to add new tool")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(macOS) || os(iOS)
        .background(.white)
        #endif
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear
        {
            if sidebar_controller.from_workspace_view
            {
                sidebar_controller.from_workspace_view = false
                add_tool_view_presented = true
            }
        }
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: .automatic)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_tool_view_presented.toggle() })
                    {
                        Label("Add Tool", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_tool_view_presented)
                    {
                        AddObjectView(is_presented: $add_tool_view_presented, title: "Tool", previewed_object: app_state.previewed_object, previewed_object_name: $app_state.previewed_tool_module_name, internal_modules_list: $app_state.internal_modules_list.tool, external_modules_list: $app_state.external_modules_list.tool)
                        {
                            app_state.update_tool_info()
                        }
                        add_object:
                        { new_name in
                            app_state.previewed_object?.name = new_name

                            base_workspace.add_tool(app_state.previewed_object! as! Tool)
                            document_handler.document_update_tools()
                        }
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
                    }
                }
            }
        }
    }
}

//MARK: - Tools card view
struct ToolCardView: View
{
    @State var tool_item: Tool
    @State private var tool_view_presented = false
    @State private var to_rename = false
    
    @State private var update_toggle = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        LargeCardView(color: tool_item.card_info.color, node: removed_constraints(node: tool_item.node ?? SCNNode()), title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle, to_rename: $to_rename, edited_name: $tool_item.name, on_rename: update_file)
        #if !os(visionOS)
            .shadow(radius: 8)
        /*#else
            .frame(depth: 24)*/
        #endif
            .overlay
            {
                NavigationLink(destination: ToolView(tool: $tool_item).onAppear(perform: remove_tool_constraints))
                {
                    Rectangle()
                        .fill(.clear)
                }
                .buttonStyle(.borderless)
                .modifier(CardMenu(object: tool_item, to_rename: $to_rename, duplicate_object: {
                    base_workspace.duplicate_tool(name: tool_item.name)
                }, delete_object: delete_tool, update_file: update_file))
                .modifier(DoubleModifier(update_toggle: $update_toggle))
            }
            .overlay(alignment: .bottomTrailing)
            {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .frame(width: 32, height: 32)
                    .padding(8)
                    .background(.clear)
            }
    }
    
    private func remove_tool_constraints()
    {
        /*if tool_item.node?.constraints?.count ?? 0 > 0 //tool_item.is_attached
        {
            tool_item.node?.remove_all_constraints()
            tool_item.node?.position = SCNVector3Zero
            tool_item.node?.rotation = SCNVector4Zero
            
            update_toggle.toggle()
        }*/
    }
    
    private func removed_constraints(node: SCNNode) -> SCNNode
    {
        node.remove_all_constraints()
        
        return node
    }
    
    private func delete_tool()
    {
        withAnimation
        {
            base_workspace.tools.remove(at: base_workspace.tools.firstIndex(of: tool_item) ?? 0)
            base_workspace.elements_check()
            document_handler.document_update_tools()
        }
    }
    
    private func update_file()
    {
        document_handler.document_update_tools()
    }
}

//MARK: - Drag and Drop delegate
struct ToolDropDelegate : DropDelegate
{
    @Binding var tools : [Tool]
    @Binding var dragged_tool : Tool?
    
    @State var workspace_tools: [Tool]
    
    let tool: Tool
    let document_handler: DocumentUpdateHandler
    
    func performDrop(info: DropInfo) -> Bool
    {
        document_handler.document_update_tools() //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_tool = self.dragged_tool else
        {
            return
        }
        
        if dragged_tool != tool
        {
            let from = tools.firstIndex(of: dragged_tool)!
            let to = tools.firstIndex(of: tool)!
            withAnimation(.default)
            {
                self.tools.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Previews
#Preview
{
    ToolsView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
