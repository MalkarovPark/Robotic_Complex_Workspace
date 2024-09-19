//
//  PartView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct PartView: View
{
    @Binding var part_view_presented: Bool
    @Binding var part_item: Part
    
    @State var new_physics: PhysicsType = .ph_none
    @State var new_color: Color = .accentColor
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            PartSceneView(part: $part_item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            HStack(spacing: 0)
            {
                Picker("Physics", selection: $new_physics)
                {
                    ForEach(PhysicsType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(iOS) || os(visionOS)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                #endif
                .padding(.horizontal)
                .onChange(of: new_physics)
                { _, _ in
                    update_data()
                }
                
                ColorPicker("Color", selection: $new_color)
                    .padding(.trailing)
                    .onChange(of: new_color)
                    { _, _ in
                        update_data()
                    }
                #if os(iOS) || os(visionOS)
                    .frame(width: 112)
                #endif
            }
            .padding(.vertical)
        }
        .modifier(ViewCloseButton(is_presented: $part_view_presented))
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onAppear()
        {
            app_state.previewed_object = part_item
            app_state.preview_update_scene = true
            
            let previewed_part = app_state.previewed_object as? Part
            previewed_part?.enable_physics = false
            
            new_physics = part_item.physics_type
            new_color = part_item.color
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                ready_for_save = true
            }
        }
        .onDisappear()
        {
            if is_document_updated
            {
                app_state.view_update_state.toggle()
            }
        }
    }
    
    func update_data()
    {
        if ready_for_save
        {
            app_state.get_scene_image = true
            part_item.physics_type = new_physics
            part_item.color = new_color
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                document_handler.document_update_parts()
            }
            is_document_updated = true
        }
    }
}

struct PartSceneView: View
{
    @Binding var part: Part
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn") ?? SCNScene(), node: part.node ?? SCNNode())
    }
}

#Preview
{
    PartView(part_view_presented: .constant(true), part_item: .constant(Part(name: "None", dictionary: ["String" : "Any"])), new_physics: .ph_none)
        .environmentObject(AppState())
        .environmentObject(Workspace())
}
