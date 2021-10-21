//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.10.2021.
//

import SwiftUI

struct Sidebar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    var body: some View
    {
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        SidebarContent(document: $document).frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
}

struct Sidebar_Previews: PreviewProvider
{
    static var previews: some View
    {
        Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}

struct SidebarContent: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    var body: some View
    {
        List
        {
            Label("Workspace", systemImage: "cube.transparent")
            Label("Robots", systemImage: "circle")
        }
        .listStyle(SidebarListStyle())
        
        .toolbar
        {
            ToolbarItem
            {
                Button(action: toggle_sidebar)
                {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
        }
    }
    
    func toggle_sidebar()
    {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
          #selector(NSSplitViewController.toggleSidebar),
          with: nil)
    }
}
