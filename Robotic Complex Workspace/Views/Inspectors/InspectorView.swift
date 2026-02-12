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
    
    @State private var origin_is_expanded: Bool = true // Robot
    
    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 0)
            {
                /*Text(object_type_name)
                    .font(.headline)
                    .padding(10)
                
                Divider()*/
                
                HStack
                {
                    let name_binding = Binding(
                        get: { object.name },
                        set:
                            { new_value in
                                object.name = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    TextField("None", text: name_binding)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(10)
                
                HStack
                {
                    Button(role: .destructive, action: remove_object)
                    {
                        Label("Remove", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonBorderShape(.roundedRectangle)
                    #if os(macOS)
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                    #endif
                    
                    let placement_binding = Binding(
                        get: { object.is_placed },
                        set:
                            { new_value in
                                object.is_placed = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    Toggle(isOn: placement_binding)
                    {
                        Label("Placed", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                    .toggleStyle(.button)
                    #if os(macOS)
                    .buttonStyle(.bordered)
                    #endif
                    .buttonBorderShape(.roundedRectangle)
                }
                .padding([.horizontal, .bottom], 10)
                
                Divider()
                
                DisclosureGroup(isExpanded: $position_is_expanded)
                {
                    let position_binding = Binding(
                        get: { object.position },
                        set:
                            { new_value in
                                object.position = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    #if os(macOS)
                    PositionView(position: position_binding)
                    #else
                    PositionView(position: position_binding, with_steppers: false)
                    #endif
                }
                label:
                {
                    Text("Position")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(10)
                
                Divider()
                
                if let robot = object as? Robot
                {
                    let origin_binding = Binding(
                        get: { robot.origin_position },
                        set:
                            { new_value in
                                robot.origin_position = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    DisclosureGroup(isExpanded: $origin_is_expanded)
                    {
                        #if os(macOS)
                        PositionView(position: origin_binding)
                        #else
                        PositionView(position: origin_binding, with_steppers: false)
                        #endif
                    }
                    label:
                    {
                        Text("Origin")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(10)
                    
                    Divider()
                }
                
                if let tool = object as? Tool
                {
                    let attached_to = Binding(
                        get: { tool.attached_to ?? String() },
                        set:
                            { new_value in
                                tool.attached_to = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    let is_attached = Binding(
                        get: { tool.attached_to != nil },
                        set:
                            { new_value in
                                tool.attached_to = new_value ? base_workspace.placed_robots_names.first : nil
                                
                                update_document(by: object)
                            }
                    )
                    
                    HStack
                    {
                        Picker("Attached to", selection: attached_to)
                        {
                            if base_workspace.placed_robots_names.count > 0
                            {
                                ForEach(base_workspace.placed_robots_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            else
                            {
                                Text("None")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(tool.attached_to == nil)
                        
                        Toggle(isOn: is_attached)
                        {
                            Image(systemName: "pin.fill")
                        }
                        .toggleStyle(.button)
                        #if os(macOS)
                        .buttonStyle(.bordered)
                        #endif
                        .buttonBorderShape(.roundedRectangle)
                    }
                    .padding(10)
                    .disabled(base_workspace.placed_robots_names.count == 0)
                    
                    Divider()
                }
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
        base_workspace.deselect_object()
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
}

#Preview
{
    ZStack
    {
        
    }
    .inspector(isPresented: .constant(true))
    {
        InspectorView(object: Robot(name: "Robot"))
    }
    .frame(width: 400, height: 600)
    .environmentObject(Workspace())
    .environmentObject(DocumentUpdateHandler())
}

#Preview
{
    ZStack
    {
        
    }
    .inspector(isPresented: .constant(true))
    {
        InspectorView(object: Tool(name: "Tool"))
    }
    .frame(width: 400, height: 600)
    .environmentObject(Workspace())
    .environmentObject(DocumentUpdateHandler())
}

#Preview
{
    ZStack
    {
        
    }
    .inspector(isPresented: .constant(true))
    {
        InspectorView(object: Part(name: "Part"))
    }
    .frame(width: 400, height: 600)
    .environmentObject(Workspace())
    .environmentObject(DocumentUpdateHandler())
}
