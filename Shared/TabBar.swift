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
    @Binding var first_loaded: Bool
    
    var body: some View
    {
        TabView
        {
            NavigationView
            {
                WorkspaceView(document: $document, first_loaded: $first_loaded, file_name: .constant("None"), file_url: .constant(URL(fileURLWithPath: "")))
            }
            .tabItem
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationView
            {
                RobotsView(document: $document)
            }
            .tabItem
            {
                Label("Robots", systemImage: "r.square") //image: "factory.robot") //systemImage: "circle")
            }
            .badge(document.preset.robots.count)
            
            NavigationView
            {
                ToolsView(document: $document)
            }
            .tabItem
            {
                Label("Tools", systemImage: "hammer")
            }
        }
    }
}

struct TabBar_Previews: PreviewProvider
{
    static var previews: some View
    {
        TabBar(document: .constant(Robotic_Complex_WorkspaceDocument()), first_loaded: .constant(true))
    }
}
