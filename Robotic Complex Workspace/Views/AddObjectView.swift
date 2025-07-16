//
//  AddObjectView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.09.2024.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI
import SceneKit

struct AddObjectView: View
{
    @Binding var is_presented: Bool
    
    @State private var new_object_name = ""
    
    let previewed_object: WorkspaceObject?
    
    @Binding var previewed_object_name: String
    @Binding var internal_modules_list: [String]
    @Binding var external_modules_list: [String]
    
    private var update_object_info: () -> Void
    private var add_object: (String) -> Void
    
    public init(is_presented: Binding<Bool>,
                previewed_object: WorkspaceObject?,
                previewed_object_name: Binding<String>,
                internal_modules_list: Binding<[String]>,
                external_modules_list: Binding<[String]>,
                update_object_info: @escaping () -> Void,
                add_object: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        
        self.previewed_object = previewed_object
        
        self._previewed_object_name = previewed_object_name
        self._internal_modules_list = internal_modules_list
        self._external_modules_list = external_modules_list
        
        self.update_object_info = update_object_info
        self.add_object = add_object
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ObjectPreviewSceneView()
                .overlay(alignment: .top)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: { is_presented = false })
                        {
                            Image(systemName: "xmark")
                                .imageScale(.large)
                                .frame(width: 16, height: 16)
                        }
                        .keyboardShortcut(.cancelAction)
                        #if !os(visionOS)
                        .controlSize(.extraLarge)
                        #endif
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glass)
                        
                        Spacer()
                        
                        Button(action: add_object_in_workspace)
                        {
                            Image(systemName: "checkmark")
                                .imageScale(.large)
                                .frame(width: 16, height: 16)
                        }
                        .keyboardShortcut(.defaultAction)
                        #if !os(visionOS)
                        .controlSize(.extraLarge)
                        #endif
                        .buttonBorderShape(.circle)
                        .buttonStyle(.glassProminent)
                        
                    }
                    .padding(8)
                    #if !os(macOS)
                    .padding(.top, 4)
                    #endif
                }
                .overlay(alignment: .bottom)
                {
                    HStack(spacing: 0)
                    {
                        TextField("Name", text: $new_object_name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                        
                        Picker(selection: $previewed_object_name, label: Text("Model")
                                .bold())
                        {
                            if internal_modules_list.count > 0
                            {
                                Section(header: Text("Internal"))
                                {
                                    ForEach(internal_modules_list, id: \.self)
                                    {
                                        Text($0).tag($0)
                                    }
                                }
                            }
                            
                            if external_modules_list.count > 0
                            {
                                Section(header: Text("External"))
                                {
                                    ForEach(external_modules_list, id: \.self)
                                    {
                                        Text($0).tag(".\($0)")
                                    }
                                }
                            }
                        }
                        #if os(macOS)
                        .buttonStyle(.bordered)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                    .padding(10)
                    .glassEffect(in: .rect(cornerRadius: 16.0))
                    .padding()
                }
        }
        .controlSize(.regular)
        #if os(macOS)
        .fitted()
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #elseif os(visionOS)
        .frame(width: 512, height: 512)
        #endif
        .onAppear
        {
            update_object_info()
        }
    }
    
    private func add_object_in_workspace()
    {
        if new_object_name == ""
        {
            new_object_name = "None"
        }
        
        add_object(new_object_name)
        
        is_presented.toggle()
    }
}

struct ObjectPreviewSceneView: View
{
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn") ?? SCNScene(), on_render: update_preview_node(scene_view:))
    }
    
    private func update_preview_node(scene_view: SCNView)
    {
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Node"
            app_state.preview_update_scene = false
        }
    }
}

#Preview
{
    AddObjectView(is_presented: .constant(true), previewed_object: nil, previewed_object_name: .constant("Name"), internal_modules_list: .constant([String]()), external_modules_list: .constant([String]()), update_object_info: {}, add_object: {_ in})
}
