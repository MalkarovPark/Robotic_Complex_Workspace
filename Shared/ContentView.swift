//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

struct ContentView: View
{
    @State var file_name = "" //Visible file name
    @StateObject private var base_workspace = Workspace() //Workspace object in app
    @Binding var document: Robotic_Complex_WorkspaceDocument //Opened document
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    //MARK: Main view
    @ViewBuilder var body: some View
    {
        #if os(iOS)
        if horizontal_size_class == .compact
        {
            //Show tab bar for thin window size
            TabBar(document: $document)
                .environmentObject(base_workspace)
                .onAppear
                {
                    get_file_data()
                }
        }
        else
        {
            //Show sidebar for wide window size
            Sidebar(document: $document, file_name: file_name)
                .environmentObject(base_workspace)
                .onAppear
                {
                    get_file_data()
                }
        }
        #else
        Sidebar(document: $document, file_name: file_name)
            .environmentObject(base_workspace)
            .onAppear
            {
                get_file_data()
            }
        #endif
    }
    
    func get_file_data() //Store preset file data into workspace
    {
        base_workspace.file_view(preset: document.preset)
    }
}

//MARK: - Previews
struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
            .environmentObject(AppState())
    }
}
