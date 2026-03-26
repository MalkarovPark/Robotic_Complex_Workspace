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
                /*Text(object_type_name)
                    .font(.headline)
                    .padding(10)
                
                Divider()*/
                
                HStack
                {
                    let name = Binding(
                        get: { object.name },
                        set:
                            { new_value in
                                object.name = new_value
                                
                                update_document(by: object)
                            }
                    )
                    
                    TextField("None", text: name)
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
                
                /*InspectorItem(label: "Position", is_expanded: false)
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
                    PositionView(position: position_binding, with_steppers: true)
                    #else
                    PositionView(position: position_binding)
                    #endif
                }*/
                
                if let tool = object as? Tool
                {
                    ToolInspectorItems(tool: tool, workspace: base_workspace)
                    {
                        update_document(by: object)
                    }
                }
                else
                {
                    InspectorItem(label: "Position", is_expanded: true)
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
                        PositionView(position: position_binding, with_steppers: true)
                        #else
                        PositionView(position: position_binding)
                        #endif
                    }
                }
                
                if let robot = object as? Robot
                {
                    RobotInspectorItems(robot: robot)
                    {
                        update_document(by: object)
                    }
                }
                
                if let part = object as? Part
                {
                    PartInspectorItems(part: part)
                    {
                        update_document(by: object)
                    }
                }
            }
        }
    }
    
    /*private var object_type_name: String
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
    }*/
    
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

public struct InspectorItem<Content: View>: View
{
    let label: String
    let content: Content
    
    @State var is_expanded: Bool
    
    public init(
        label: String,
        is_expanded: Bool = true,
        
        @ViewBuilder content: () -> Content
    )
    {
        self.is_expanded = is_expanded
        self.label = label
        
        self.content = content()
    }
    
    public var body: some View
    {
        DisclosureGroup(isExpanded: $is_expanded)
        {
            content
        }
        label:
        {
            Text(label)
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
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
