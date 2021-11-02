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
    @State var file_name = ""
    
    var body: some View
    {
        #if os(macOS)
        SidebarContent(document: $document).frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        #else
        SidebarContent(document: $document).navigationTitle(file_name)
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
            #if os(macOS)
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
            #else
            NavigationLink(destination: WorkspaceView(document: $document))
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationLink(destination: RobotsView())
            {
                Label("Robots", systemImage: "circle")
            }
            #endif
        }
        .listStyle(SidebarListStyle())
        
        .toolbar
        {
            #if os(macOS)
            ToolbarItem
            {
                Button(action: toggle_sidebar)
                {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
            #else
            ToolbarItem(placement: .cancellationAction)
            {
                dismiss_document_button()
            }
            #endif
        }
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
