//
//  InspectorView.swift
//  RCWorkspace
//
//  Created by Artem on 21.01.2026.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

struct InspectorView: View
{
    @ObservedObject var object: WorkspaceObject
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State private var last_object: WorkspaceObject?
    @State private var position_is_expanded: Bool = true
    
    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 0)
            {
                Text(object_type_name)
                    .font(.headline)
                    .padding(10)
                
                Divider()
                
                HStack
                {
                    TextField("None", text: $object.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(10)
                .onChange(of: object.name)
                { _, _ in
                    update_document(by: object)
                }
                
                Divider()
                
                DisclosureGroup("Position", isExpanded: $position_is_expanded)
                {
                    #if os(macOS)
                    HStack
                    {
                        PositionView(position: $object.position)
                            .onChange(of: position_change_key)
                            { _, _ in
                                guard last_object === object else
                                {
                                    last_object = object
                                    return
                                }
                                
                                object.update_model_position()
                                update_document(by: object)
                            }
                    }
                    #else
                    VStack
                    {
                        PositionView(position: $object.position)
                            .onChange(of: position_change_key)
                            { _, _ in
                                guard last_object === object else
                                {
                                    last_object = object
                                    return
                                }
                                
                                object.update_model_position()
                                update_document(by: object)
                            }
                    }
                    #endif
                }
                .padding(10)
                
                Divider()
                
                HStack
                {
                    Button(role: .destructive, action: remove_object)
                    {
                        Label("Remove", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    #if os(macOS)
                    .foregroundStyle(.red)
                    #endif
                    
                    Toggle(isOn: $object.is_placed)
                    {
                        Label("Placed", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                    .toggleStyle(.button)
                    .onChange(of: object.is_placed)
                    { _, _ in
                        update_document(by: object)
                    }
                }
                .padding(10)
            }
        }
    }
    
    private var object_type_name: String
    {
        switch object
        {
        case is Robot:
            return "Robot"
        case is Tool:
            return "Tool"
        case is Part:
            return "Part"
        default:
            return "None"
        }
    }
    
    private func remove_object()
    {
        let stored_object = object
        base_workspace.delete_object(object)
        update_document(by: stored_object)
    }
    
    private func update_document(by object: WorkspaceObject)
    {
        switch object
        {
        case is Robot:
            document_handler.document_update_robots()
        case is Tool:
            document_handler.document_update_tools()
        case is Part:
            document_handler.document_update_parts()
        default:
            break
        }
    }
    
    private var position_change_key: [Float]
    {
        let p = object.position
        return [p.x, p.y, p.z, p.r, p.p, p.w]
    }
}

#Preview
{
    InspectorView(object: Robot(name: "Name"))
        .frame(width: 256, height: 600)
}
