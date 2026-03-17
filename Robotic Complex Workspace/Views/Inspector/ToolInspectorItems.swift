//
//  ToolInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem on 14.02.2026.
//

import SwiftUI
import IndustrialKit

struct ToolInspectorItems: View
{
    @ObservedObject var tool: Tool
    
    @ObservedObject var workspace: Workspace
    
    public let on_update: () -> ()
    
    @State private var origin_is_expanded: Bool = false
    @State private var space_is_expanded: Bool = false
    
    var body: some View
    {
        let attached_to = Binding(
            get: { tool.attached_to ?? String() },
            set:
                { new_value in
                    tool.attached_to = new_value
                    
                    workspace.update_tool_attachments()
                    
                    on_update()
                }
        )
        
        let is_attached = Binding(
            get: { tool.attached_to != nil },
            set:
                { new_value in
                    tool.attached_to = new_value ? workspace.attachment_supporting_robot_names.first : nil
                    
                    workspace.update_tool_attachments()
                    
                    on_update()
                }
        )
        
        HStack
        {
            Picker("Attached to", selection: attached_to)
            {
                if workspace.placed_robot_names.count > 0
                {
                    ForEach(workspace.attachment_supporting_robot_names, id: \.self)
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
        .disabled(workspace.attachment_supporting_robot_names.count == 0)
        
        Divider()
    }
}

#Preview
{
    VStack(spacing: 0)
    {
        ToolInspectorItems(tool: Tool(), workspace: Workspace(), on_update: {})
    }
}
