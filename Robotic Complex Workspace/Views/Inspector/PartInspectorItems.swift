//
//  PartInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem Malkarov on 14.02.2026.
//

import SwiftUI
import IndustrialKit

struct PartInspectorItems: View
{
    @ObservedObject var part: Part
    
    //@ObservedObject var workspace: Workspace
    
    public let on_update: () -> ()
    
    @State private var apperance_is_expanded: Bool = true
    @State private var physics_is_expanded: Bool = true
    
    //@State private var physics_type: PhysicsType
    
    var body: some View
    {
        DisclosureGroup(isExpanded: $apperance_is_expanded)
        {
            let part_color = Binding(
                get: { part.color ?? .indigo },
                set:
                    { new_value in
                        part.color = new_value
                        
                        on_update()
                    }
            )
            
            let use_custom_color = Binding(
                get: { part.color != nil },
                set:
                    { new_value in
                        part.color = new_value ? .indigo : nil
                        
                        on_update()
                    }
            )
            
            VStack(spacing: 10)
            {
                HStack
                {
                    Text("Use Custom Color")
                    
                    Spacer()
                    
                    Toggle("", isOn: use_custom_color)
                        .labelsHidden()
                    #if os(macOS)
                        .toggleStyle(.checkbox)
                    #else
                        .toggleStyle(.switch)
                    #endif
                }
                
                HStack
                {
                    Text("Color")
                    
                    Spacer()
                    
                    ColorPicker("Color", selection: part_color)
                        .disabled(part.color == nil)
                        .labelsHidden()
                }
            }
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
            VStack(spacing: 10)
            {
                HStack
                {
                    let physics_type = Binding(
                        get: { part.physics_type },
                        set:
                            { new_value in
                                part.physics_type = new_value
                                
                                on_update()
                            }
                    )
                    
                    Text("Mode")
                    
                    Spacer()
                    
                    Picker("Mode", selection: physics_type)
                    {
                        ForEach(PhysicsType.allCases, id: \.self)
                        { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        label:
        {
            Text("Physics")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
    }
}

#Preview
{
    VStack(spacing: 0)
    {
        PartInspectorItems(part: Part(), on_update: {})
    }
}
