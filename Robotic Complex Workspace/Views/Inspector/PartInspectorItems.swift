//
//  PartInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem on 14.02.2026.
//

import SwiftUI
import IndustrialKit

struct PartInspectorItems: View
{
    @ObservedObject var part: Part
    
    //@ObservedObject var workspace: Workspace
    
    public let on_update: () -> ()
    
    @State private var apperance_is_expanded: Bool = true
    @State private var physics_is_expanded: Bool = false
    
    var body: some View
    {
        DisclosureGroup(isExpanded: $apperance_is_expanded)
        {
            let is_custom_color = Binding(
                get: { part.is_custom_color },
                set:
                    { new_value in
                        part.is_custom_color = new_value
                        
                        on_update()
                    }
            )
            
            let part_color = Binding(
                get: { part.color },
                set:
                    { new_value in
                        part.color = new_value
                        
                        on_update()
                    }
            )
            
            VStack(spacing: 20)
            {
                HStack
                {
                    Text("Use Custom Color")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("Use Custom Color", isOn: is_custom_color)
                        .labelsHidden()
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #else
                        .toggleStyle(.switch)
                        .padding(.trailing, 4)
                    #endif
                }
                
                HStack
                {
                    Text("Custom Color")
                        .fontWeight(.light)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    ColorPicker("Color", selection: part_color)
                        .disabled(!part.is_custom_color)
                        .labelsHidden()
                    #if !os(macOS)
                        .opacity(!part.is_custom_color ? 0.5 : 1)
                    #endif
                }
            }
            .padding(.vertical, 10)
        }
        label:
        {
            Text("Apperance")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
        
        DisclosureGroup(isExpanded: $physics_is_expanded)
        {
            VStack(spacing: 20)
            {
                let physics_enabled = Binding(
                    get: { part.physics_enabled },
                    set:
                        { new_value in
                            part.physics_enabled = new_value
                            
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
                
                HStack
                {
                    let physics_mode = Binding(
                        get: { part.physics_body_data.mode },
                        set:
                            { new_value in
                                part.physics_body_data.mode = new_value
                                
                                part.update_model_physics()
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
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                HStack
                {
                    let mass = Binding(
                        get: { part.physics_body_data.mass },
                        set:
                            { new_value in
                                part.physics_body_data.mass = new_value
                                
                                part.update_model_physics()
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
                        get: { part.physics_body_data.affected_by_gravity },
                        set:
                            { new_value in
                                part.physics_body_data.affected_by_gravity = new_value
                                
                                part.update_model_physics()
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
                }
                
                HStack
                {
                    let static_friction = Binding(
                        get: { part.physics_body_data.static_friction },
                        set:
                            { new_value in
                                part.physics_body_data.static_friction = new_value
                                
                                part.update_model_physics()
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
                        get: { part.physics_body_data.dynamic_friction },
                        set:
                            { new_value in
                                part.physics_body_data.dynamic_friction = new_value
                                
                                part.update_model_physics()
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
                        get: { part.physics_body_data.restitution },
                        set:
                            { new_value in
                                part.physics_body_data.restitution = new_value
                                
                                part.update_model_physics()
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
        label:
        {
            Text("Physics")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
    }
    
    private var physics_body_data: PhysicsBodyComponentFileData?
    {
        return part.physics_body_data
    }
}

#Preview
{
    VStack(spacing: 0)
    {
        PartInspectorItems(part: Part(), on_update: {})
    }
}
