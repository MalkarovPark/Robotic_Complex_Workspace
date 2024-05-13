//
//  AddRobotView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import IndustrialKit

struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    
    @State private var new_robot_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        #if os(macOS)
        VStack(spacing: 0)
        {
            Text("New Robot")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            //MARK: Robot model selection
            VStack
            {
                HStack
                {
                    Text("Name")
                        .bold()
                    TextField("None", text: $new_robot_name)
                }
                
                Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                        .bold())
                {
                    ForEach(app_state.manufacturers, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker(selection: $app_state.series_name, label: Text("Series")
                        .bold())
                {
                    ForEach(app_state.series, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4)
                
                Picker(selection: $app_state.model_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.models, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                
                Button("Save", action: add_robot_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        .controlSize(.regular)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #else
        VStack(spacing: 0)
        {
            Text("New Robot")
                .font(.title2)
                .padding()
            
            #if os(iOS)
            Divider()
            #endif
            
            //MARK: Robot model selection
            Form
            {
                Section(header: Text("Name"))
                {
                    TextField(text: $new_robot_name, prompt: Text("None"))
                    {
                        Text("Name")
                    }
                }
                
                Section(header: Text("Parameters"))
                {
                    Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                            .bold())
                    {
                        ForEach(app_state.manufacturers, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.series_name, label: Text("Series")
                            .bold())
                    {
                        ForEach(app_state.series, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.model_name, label: Text("Model")
                            .bold())
                    {
                        ForEach(app_state.models, id: \.self)
                        {
                            Text($0)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .buttonStyle(.bordered)
                Button("Add", action: add_robot_in_workspace)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        #endif
    }
    
    func add_robot_in_workspace()
    {
        if new_robot_name == ""
        {
            new_robot_name = "None"
        }
        
        base_workspace.add_robot(Robot(name: new_robot_name, manufacturer: app_state.manufacturer_name, dictionary: app_state.robot_dictionary))
        document_handler.document_update_robots()
        
        add_robot_view_presented.toggle()
    }
}

//MARK: - Previews
#Preview
{
    AddRobotView(add_robot_view_presented: .constant(false))
        .environmentObject(AppState())
        .environmentObject(Workspace())
}
