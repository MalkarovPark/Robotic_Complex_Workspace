//
//  AddToolView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct AddToolView:View
{
    @Binding var add_tool_view_presented: Bool
    
    @State private var new_tool_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ToolPreviewSceneView()
                .overlay(alignment: .top)
                {
                    Text("New Tool")
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
                TextField("None", text: $new_tool_name)
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
                Picker(selection: $app_state.tool_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.tools, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8)
                .padding(.leading)
                
                Button("Cancel", action: { add_tool_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Add", action: add_tool_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onChange(of: app_state.tool_name)
        { _, _ in
            app_state.update_tool_info()
        }
        .onAppear
        {
            app_state.update_tool_info()
        }
    }
    
    func add_tool_in_workspace()
    {
        if new_tool_name == ""
        {
            new_tool_name = "None"
        }
        
        //app_state.get_scene_image = true
        app_state.previewed_object?.name = new_tool_name
        base_workspace.add_tool(app_state.previewed_object! as! Tool)
        
        document_handler.document_update_tools()
        
        add_tool_view_presented.toggle()
    }
}

struct ToolPreviewSceneView: View
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
            
            app_state.update_tool_info()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Node"
            app_state.preview_update_scene = false
        }
    }
}

//MARK: - Previews
#Preview
{
    AddToolView(add_tool_view_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
