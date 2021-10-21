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
        #if os(macOS)
        SidebarContent(document: $document).frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        #else
        SidebarContent(document: $document)//.navigationTitle("Code")
        #endif
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
    @State var sidebar_selection: navigation_item? = .WorkspaceView
    
    var body: some View
    {
        List(selection: $sidebar_selection)
        {
            NavigationLink(destination: WorkspaceView(document: $document), tag: navigation_item.WorkspaceView, selection: $sidebar_selection)
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            .tag(navigation_item.WorkspaceView)
            
            NavigationLink(destination: RobotsView(), tag: navigation_item.RobotsView, selection: $sidebar_selection)
            {
                Label("Robots", systemImage: "circle")
            }
            .tag(navigation_item.RobotsView)
        }
        .listStyle(SidebarListStyle())
        
        #if os(macOS)
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
        #endif
    }
    
    #if os(macOS)
    func toggle_sidebar()
    {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
          #selector(NSSplitViewController.toggleSidebar),
          with: nil)
    }
    #endif
}
