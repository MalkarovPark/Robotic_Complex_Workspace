//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

struct ContentView: View
{
    @State var file_name = ""
    @StateObject private var base_workspace = Workspace()
    @Binding var document: Robotic_Complex_WorkspaceDocument

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif

    @ViewBuilder var body: some View
    {
        #if os(iOS)
        if horizontal_size_class == .compact
        {
            TabBar(document: $document)
                .environmentObject(base_workspace)
                .onAppear
                {
                    get_file_data()
                }
        }
        else
        {
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
    
    func get_file_data()
    {
        base_workspace.file_view(preset: document.preset)
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
