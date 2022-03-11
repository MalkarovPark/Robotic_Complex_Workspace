//
//  TabBar.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Malkarov Park on 18.11.2021.
//

import SwiftUI

struct TabBar: View
{
    var body: some View
    {
        TabView
        {
            NavigationView
            {
                WorkspaceView()
            }
            .tabItem
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationView
            {
                RobotsView()
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
        TabBar()
    }
}
