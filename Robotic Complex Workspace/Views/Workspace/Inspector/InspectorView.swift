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
                #if !os(visionOS)
                .padding(10)
                #else
                .padding([.horizontal, .bottom], 10)
                #endif
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
                    #if !os(visionOS)
                    .buttonBorderShape(.roundedRectangle)
                    #else
                    .buttonBorderShape(.capsule)
                    #endif
                    #if os(macOS) || os(iOS)
                    .buttonStyle(.bordered)
                    .tint(.red)
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
                    #if !os(visionOS)
                    .buttonBorderShape(.roundedRectangle)
                    #else
                    .buttonBorderShape(.capsule)
                    #endif
                }
                .padding([.horizontal, .bottom], 10)
                
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
                                    
                                    #if !os(visionOS)
                                    workspace.focus(on: object.model_entity, animated: false)
                                    #endif
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
        .frame(width: 400)
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
        #if os(macOS) || os(iOS)
        GroupBox
        {
            DisclosureGroup(isExpanded: $is_expanded)
            {
                content
                #if os(macOS)
                    .padding(5)
                #elseif os(iOS)
                    .padding(.top, 10)
                #endif
            }
            label:
            {
                Text(label)
                #if os(macOS)
                    .font(.system(size: 14))
                #elseif os(iOS)
                    .font(.system(size: 18))
                    .tint(.black)
                #endif
            }
        }
        .padding([.horizontal, .bottom], 10)
        #else
        VStack(spacing: 0)
        {
            DisclosureGroup(isExpanded: $is_expanded)
            {
                content
                    .padding([.horizontal, .bottom], 16)
            }
            label:
            {
                Text(label)
                    .font(.system(size: 18))
            }
        }
        .background
        {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        }
        .padding([.horizontal, .bottom], 10)
        #endif
    }
}

#Preview
{
    #if !os(visionOS)
    ZStack
    {
        
    }
    .inspector(isPresented: .constant(true))
    {
        InspectorView(document: .constant(Robotic_Complex_WorkspaceDocument()), workspace: Workspace())
    }
    .frame(width: 420, height: 600)
    .environmentObject(Workspace())
    #else
    InspectorView(document: .constant(Robotic_Complex_WorkspaceDocument()), workspace: Workspace())
        .glassBackgroundEffect()
        .frame(width: 400, height: 600)
        .environmentObject(Workspace())
    #endif
}
