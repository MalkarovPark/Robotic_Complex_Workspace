//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.10.2021.
//

import SwiftUI

enum navigation_item
{
    case WorkspaceView
    case RobotsView
}

struct Sidebar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var base_workspace: Workspace
    @State var file_name = ""
    
    var body: some View
    {
        NavigationView
        {
            #if os(macOS)
            SidebarContent(document: $document, base_workspace: $base_workspace).frame(minWidth: 200, idealWidth: 250)
            #else
            SidebarContent(document: $document, base_workspace: $base_workspace).navigationTitle(file_name)
            WorkspaceView(document: $document, base_workspace: $base_workspace)
            #endif
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        #if os(iOS)
        .navigationBarHidden(true)
        .modifier(DismissModifier())
        #endif
    }
}

struct Sidebar_Previews: PreviewProvider
{
    static var previews: some View
    {
        Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()), base_workspace: .constant(Workspace()))
    }
}

struct SidebarContent: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var sidebar_selection: navigation_item? = .WorkspaceView
    @Binding var base_workspace: Workspace
    
    var body: some View
    {
        List(selection: $sidebar_selection)
        {
            #if os(macOS)
            NavigationLink(destination: WorkspaceView(document: $document, base_workspace: $base_workspace), tag: navigation_item.WorkspaceView, selection: $sidebar_selection)
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            .tag(navigation_item.WorkspaceView)
            
            NavigationLink(destination: RobotsView(base_workspace: $base_workspace), tag: navigation_item.RobotsView, selection: $sidebar_selection)
            {
                Label("Robots", systemImage: "circle")
            }
            .tag(navigation_item.RobotsView)
            #else
            NavigationLink(destination: WorkspaceView(document: $document, base_workspace: $base_workspace))
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationLink(destination: RobotsView(base_workspace: $base_workspace))
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
