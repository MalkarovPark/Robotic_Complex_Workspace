//
//  AddPartView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import IndustrialKit

struct AddPartView: View
{
    @Binding var add_part_view_presented: Bool
    
    @State private var new_part_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            PartPreviewSceneView()
                .overlay(alignment: .top)
                {
                    Text("New Part")
                        .font(.title2)
                        .padding(8)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            
            Divider()
            Spacer()
            
            HStack
            {
                Text("Name")
                    .bold()
                TextField("None", text: $new_part_name)
                #if os(iOS) || os(visionOS)
                    .textFieldStyle(.roundedBorder)
                #endif
            }
            .padding(.top, 8)
            .padding(.horizontal)
            
            HStack(spacing: 0)
            {
                #if os(iOS) || os(visionOS)
                Spacer()
                #endif
                Picker(selection: $app_state.part_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.parts, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8)
                .padding(.leading)
                
                Button("Cancel", action: { add_part_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Add", action: add_part_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onChange(of: app_state.part_name)
        { _, _ in
            app_state.update_part_info()
        }
        .onAppear
        {
            app_state.update_part_info()
        }
    }
    
    func add_part_in_workspace()
    {
        if new_part_name == ""
        {
            new_part_name = "None"
        }
        
        app_state.previewed_object?.name = new_part_name
        base_workspace.add_part(app_state.previewed_object! as! Part)
        document_handler.document_update_parts()
        
        add_part_view_presented.toggle()
    }
}

//MARK: - Previews
#Preview
{
    AddPartView(add_part_view_presented: .constant(true))
        .environmentObject(AppState())
        .environmentObject(Workspace())
}
