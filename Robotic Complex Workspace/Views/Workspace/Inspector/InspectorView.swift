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
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @ObservedObject var workspace: Workspace
    
    @State private var new_name: String
    
    private var object: ProductionObject { workspace.selected_object ?? ProductionObject() }
    
    public init(
        document: Binding<Robotic_Complex_WorkspaceDocument>,
        workspace: Workspace
    )
    {
        self._document = document
        self.workspace = workspace
        
        self.new_name = workspace.selected_object?.name ?? String()
    }
    
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
                    TextField("None", text: $new_name)
                        .onSubmit
                        {
                            if object is Robot { update_tool_attachments(old_name: object.name, new_name: new_name) }
                            object.name = new_name
                            
                            update_document(by: object)
                        }
                        .textFieldStyle(.roundedBorder)
                }
                .padding(10)
                .onChange(of: workspace.selected_object ?? ProductionObject())
                { _, new_value in
                    new_name = new_value.name
                }
                
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
                
                if let tool = object as? Tool
                {
                    ToolInspectorItems(tool: tool, workspace: workspace)
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
        #if os(visionOS)
        .frame(width: 300)
        #endif
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
        workspace.delete_object(object)
        workspace.deselect_object()
        update_document(by: stored_object)
    }
    
    private func update_document(by object: ProductionObject)
    {
        let file_data = workspace.file_data()
        
        switch object
        {
        case is Robot:
            document.preset.robots = file_data.robots
        case is Tool:
            document.preset.tools = file_data.tools
        case is Part:
            document.preset.parts = file_data.parts
        default:
            break
        }
    }
    
    private func update_tool_attachments(old_name: String, new_name: String)
    {
        for tool in workspace.tools where tool.attached_to == old_name
        {
            tool.attached_to = nil
            
            workspace.update_tool_attachments()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                tool.attached_to = new_name
                workspace.update_tool_attachments()
                
                document.preset.tools = workspace.file_data().tools
            }
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
        InspectorView(document: .constant(Robotic_Complex_WorkspaceDocument()), workspace: Workspace())
    }
    .frame(width: 400, height: 600)
    .environmentObject(Workspace())
}
