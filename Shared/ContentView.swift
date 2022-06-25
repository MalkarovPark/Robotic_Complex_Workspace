//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

struct ContentView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument //Opened document
    
    #if os(iOS)
    @State var file_name = "" //Visible file name
    @State var file_url: URL
    #endif
    @State var first_loaded = true
    
    @StateObject private var base_workspace = Workspace() //Workspace object in app
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    //MARK: Main view
    @ViewBuilder var body: some View
    {
        #if os(iOS)
        Sidebar(document: $document, first_loaded: $first_loaded, file_url: $file_url, file_name: $file_name)
            .environmentObject(base_workspace)
            .onAppear
            {
                get_file_data()
            }
        #else
        Sidebar(document: $document, first_loaded: $first_loaded)
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
        #if os(macOS)
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
            .environmentObject(AppState())
            .frame(width: 800, height: 600)
        #else
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()), file_url: URL(fileURLWithPath: ""))
            .environmentObject(AppState())
            .frame(width: 800, height: 600)
        #endif
    }
}
