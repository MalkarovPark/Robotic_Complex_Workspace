//
//  DetailsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import SwiftUI

struct DetailsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_detail_view_presented = false
    @State private var detail_view_presented = false
    @State private var dragged_detail: Detail?
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.details.count > 0
            {
                
            }
            else
            {
                Text("Press «+» to add new detail")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(Color.white)
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_detail_view_presented.toggle() })
                    {
                        Label("Add Detail", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_detail_view_presented)
                    {
                        AddDetailView(add_detail_view_presented: $add_detail_view_presented, document: $document)
                    }
                }
            }
        }
    }
}

struct AddDetailView:View
{
    @Binding var add_detail_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_detail_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Add Detail")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .foregroundColor(.accentColor)
                .padding(.vertical, 8.0)
                .padding(.horizontal)
            
            Picker(selection: $app_state.detail_name, label: Text("Model")
                    .bold())
            {
                ForEach(app_state.details, id: \.self)
                {
                    Text($0)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 8.0)
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_detail_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: { add_detail_in_workspace() })
                    .keyboardShortcut(.defaultAction)
                    .padding()
            }
        }
        .controlSize(.regular)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
    }
    
    func add_detail_in_workspace()
    {
        
    }
}

struct DetailsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            DetailsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
            AddDetailView(add_detail_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
        }
    }
}
