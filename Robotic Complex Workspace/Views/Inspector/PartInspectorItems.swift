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
    
    @State private var apperance_is_expanded: Bool = false
    
    //@State private var physics_type: PhysicsType
    
    var body: some View
    {
        let physics_type = Binding(
            get: { part.physics_type },
            set:
                { new_value in
                    part.physics_type = new_value
                    
                    on_update()
                }
        )
        
        HStack
        {
            Text("Color")
        }
        .padding(10)
        
        Divider()
        
        HStack
        {
            Picker("Physical Body", selection: physics_type)
            {
                ForEach(PhysicsType.allCases, id: \.self)
                { type in
                    Text(type.rawValue)
                }
            }
            .pickerStyle(.menu)
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
