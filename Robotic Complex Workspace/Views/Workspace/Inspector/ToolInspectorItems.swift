//
//  ToolInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem on 14.02.2026.
//

import SwiftUI

import IndustrialKit
import IndustrialKitUI

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
        
        InspectorItem(label: tool.attached_to == nil ? "Position" : "Position (Local)", is_expanded: true)
        {
            let position_binding = Binding(
                get: { tool.position },
                set:
                    { new_value in
                        tool.position = new_value
                        
                        on_update()
                    }
            )
            
            let local_position_binding = Binding(
                get: { tool.local_position },
                set:
                    { new_value in
                        tool.local_position = new_value
                        
                        on_update()
                    }
            )
            
            #if os(macOS)
            PositionView(position: tool.attached_to == nil ? position_binding : local_position_binding, with_steppers: true)
            #else
            PositionView(position: tool.attached_to != nil ? position_binding : local_position_binding)
            #endif
        }
        
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
        
        InspectorItem(label: "Physics", is_expanded: false)
        {
            VStack(spacing: 20)
            {
                let physics_enabled = Binding(
                    get: { tool.physics_enabled },
                    set:
                        { new_value in
                            tool.physics_enabled = new_value
                            
                            on_update()
                        }
                )
                
                HStack
                {
                    Text("Physics Enabled")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("Physics Enabled", isOn: physics_enabled)
                        .labelsHidden()
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #else
                        .toggleStyle(.switch)
                        .padding(.trailing, 4)
                    #endif
                }
                
                /*HStack
                {
                    let physics_mode = Binding(
                        get: { tool.physics_body_data.mode },
                        set:
                            { new_value in
                                tool.physics_body_data.mode = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Mode")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Picker("Mode", selection: physics_mode)
                    {
                        ForEach(PhysicsBodyModeFileData.allCases, id: \.self)
                        { type in
                            
                            if type != ._dynamic
                            {
                                Text(type.rawValue)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }*/
                
                /*HStack
                {
                    let mass = Binding(
                        get: { tool.physics_body_data.mass },
                        set:
                            { new_value in
                                tool.physics_body_data.mass = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Mass (kg)")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    TextField("Mass", value: mass, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .labelsHidden()
                    
                    Stepper("Enter", value: mass, in: 0...1000000)
                        .labelsHidden()
                    #if !os(macOS)
                        .padding(.trailing, 4)
                    #endif
                }
                
                HStack
                {
                    let affected_by_gravity = Binding(
                        get: { tool.physics_body_data.affected_by_gravity },
                        set:
                            { new_value in
                                tool.physics_body_data.affected_by_gravity = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Affected by Gravity")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("Affected by Gravity", isOn: affected_by_gravity)
                        .labelsHidden()
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #else
                        .toggleStyle(.switch)
                        .padding(.trailing, 4)
                    #endif
                }*/
                
                HStack
                {
                    let static_friction = Binding(
                        get: { tool.physics_body_data.static_friction },
                        set:
                            { new_value in
                                tool.physics_body_data.static_friction = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Static Friction")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    TextField("Static Friction", value: static_friction, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .labelsHidden()
                }
                
                HStack
                {
                    let dynamic_friction = Binding(
                        get: { tool.physics_body_data.dynamic_friction },
                        set:
                            { new_value in
                                tool.physics_body_data.dynamic_friction = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Dynamic Friction")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    TextField("Dynamic Friction", value: dynamic_friction, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .labelsHidden()
                }
                
                HStack
                {
                    let restitution = Binding(
                        get: { tool.physics_body_data.restitution },
                        set:
                            { new_value in
                                tool.physics_body_data.restitution = new_value
                                
                                tool.update_model_physics()
                                on_update()
                            }
                    )
                    
                    Text("Restitution")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    TextField("Restitution", value: restitution, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .labelsHidden()
                }
            }
            .padding(.vertical, 10)
        }
    }
}

#Preview
{
    VStack(spacing: 0)
    {
        ToolInspectorItems(tool: Tool(), workspace: Workspace(), on_update: {})
    }
}
