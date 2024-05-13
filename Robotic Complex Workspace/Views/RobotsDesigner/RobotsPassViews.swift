//
//  RobotsPassViews.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import IndustrialKit

struct PassPreferencesView: View
{
    @Binding var is_presented: Bool
    
    @State private var origin_location = false
    @State private var origin_rotation = false
    @State private var space_scale = false
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Pass Preferences")
                .font(.title2)
                .padding(.bottom)
            
            List
            {
                Toggle(isOn: $origin_location)
                {
                    Text("Location")
                }
                
                Toggle(isOn: $origin_rotation)
                {
                    Text("Rotation")
                }
                
                Toggle(isOn: $space_scale)
                {
                    Text("Scale")
                }
            }
            .modifier(ListBorderer())
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding(.trailing)
                
                Button(action: {
                    pass_perform()
                    is_presented.toggle()
                })
                {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!origin_location && !origin_rotation && !space_scale)
            }
        }
        .padding()
    }
    
    private func pass_perform()
    {
        app_state.preferences_pass_mode = true
        
        app_state.origin_location_flag = origin_location
        app_state.origin_rotation_flag = origin_rotation
        app_state.space_scale_flag = space_scale
    }
}

//MARK: Pass programs view
struct PassProgramsView: View
{
    @Binding var is_presented: Bool
    
    @State private var selected_programs = Set<String>()
    @State var items: [String]
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Pass Programs")
                .font(.title2)
                .padding(.bottom)
            
            List(items, id: \.self)
            { item in
                Toggle(isOn: Binding(get: {
                    self.selected_programs.contains(item)
                }, set: { new_value in
                    if new_value
                    {
                        self.selected_programs.insert(item)
                    }
                    else
                    {
                        self.selected_programs.remove(item)
                    }
                }))
                {
                    Text(item)
                }
            }
            .modifier(ListBorderer())
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding(.trailing)
                
                Button(action: {
                    pass_perform()
                    is_presented.toggle()
                })
                {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selected_programs.count == 0)
            }
        }
        .padding()
    }
    
    private func pass_perform()
    {
        app_state.programs_pass_mode = true
        app_state.passed_programs_names_list = Array(selected_programs).sorted()
    }
}

//MARK: - Previews
#Preview
{
    PassPreferencesView(is_presented: .constant(true))
        .environmentObject(AppState())
}

#Preview
{
    PassProgramsView(is_presented: .constant(true), items: [String]())
}
