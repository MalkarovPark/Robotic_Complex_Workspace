//
//  TabBar.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Malkarov Park on 18.11.2021.
//

import SwiftUI

struct TabBar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var base_workspace: Workspace
    
    var body: some View
    {
        TabView
        {
            NavigationView
            {
                WorkspaceView(document: $document, base_workspace: $base_workspace)
            }
            .tabItem
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationView
            {
                RobotsView(base_workspace: $base_workspace)
            }
            .tabItem
            {
                Label("Robots", systemImage: "circle")
            }
        }
    }
}

struct TabBar_Previews: PreviewProvider
{
    static var previews: some View
    {
        TabBar(document: .constant(Robotic_Complex_WorkspaceDocument()), base_workspace: .constant(Workspace()))
    }
}
