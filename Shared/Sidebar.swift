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
    case ToolsView
}

struct Sidebar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var file_name = ""
    
    var body: some View
    {
        NavigationView
        {
            #if os(macOS)
            SidebarContent(document: $document).frame(minWidth: 200, idealWidth: 250)
            #else
            SidebarContent(document: $document).navigationTitle(file_name)
            WorkspaceView(document: $document)
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
            
            NavigationLink(destination: RobotsView(document: $document), tag: navigation_item.RobotsView, selection: $sidebar_selection)
            {
                Label("Robots", systemImage: "r.square") //image: "factory.robot") //systemImage: "circle")
            }
            .tag(navigation_item.RobotsView)
            
            NavigationLink(destination: ToolsView(document: $document), tag: navigation_item.ToolsView, selection: $sidebar_selection)
            {
                Label("Tools", systemImage: "hammer")
            }
            .tag(navigation_item.ToolsView)
            #else
            NavigationLink(destination: WorkspaceView(document: $document))
            {
                Label("Workspace", systemImage: "cube.transparent")
            }
            
            NavigationLink(destination: RobotsView(document: $document))
            {
                Label("Robots", systemImage: "r.square") //image: "factory.robot") //systemImage: "circle")
            }
            
            NavigationLink(destination: ToolsView(document: $document))
            {
                Label("Tools", systemImage: "hammer")
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
