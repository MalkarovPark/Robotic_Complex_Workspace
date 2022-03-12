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
    
    var body: some View
    {
        TabView
        {
            NavigationView
            {
                WorkspaceView(document: $document)
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
                Label("Robots", image: "factory.robot") //systemImage: "circle")
            }
        }
    }
}

struct TabBar_Previews: PreviewProvider
{
    static var previews: some View
    {
        TabBar(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
