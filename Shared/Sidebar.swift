//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.10.2021.
//

import SwiftUI

enum navigation_item: Int, Hashable, CaseIterable, Identifiable
{
    case WorkspaceView
    case RobotsView
    case ToolsView
    
    var id: Int { rawValue }
    var localizedName: LocalizedStringKey
    {
        switch self
        {
        case .WorkspaceView:
            return "Workspace"
        case .RobotsView:
            return "Robots"
        case .ToolsView:
            return "Tools"
        }
    }
    
    var image_name: String
    {
        switch self
        {
        case .WorkspaceView:
            return "cube.transparent"
        case .RobotsView:
            return "r.square"
        case .ToolsView:
            return "hammer"
        }
    }
}

struct Sidebar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var first_loaded: Bool
    #if os(iOS)
    @Binding var file_url: URL
    @Binding var file_name: String
    #endif
    
    var body: some View
    {
        #if os(macOS)
        SidebarContent(document: $document, first_loaded: $first_loaded).frame(minWidth: 200, idealWidth: 250)
        #else
        SidebarContent(document: $document, first_loaded: $first_loaded, file_url: $file_url, file_name: $file_name).frame(minWidth: 200, idealWidth: 250)
        .navigationBarHidden(true)
        .modifier(DismissModifier())
        #endif
    }
}

struct Sidebar_Previews: PreviewProvider
{
    static var previews: some View
    {
        #if os(macOS)
        Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()), first_loaded: .constant(false))
            .environmentObject(Workspace())
            .environmentObject(AppState())
        #else
        Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()), first_loaded: .constant(false), file_url: .constant(URL(fileURLWithPath: "")), file_name: .constant("None"))
        #endif
    }
}

struct SidebarContent: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var first_loaded: Bool
    #if os(iOS)
    @Binding var file_url: URL
    @Binding var file_name: String
    #endif
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    @State var sidebar_selection: navigation_item? = .WorkspaceView
    
    var body: some View
    {
        NavigationSplitView
        {
            List(navigation_item.allCases, selection: $sidebar_selection)
            { selection in
                NavigationLink(value: selection)
                {
                    switch selection.localizedName
                    {
                    case "Robots":
                        Label(selection.localizedName, systemImage: selection.image_name)
                            .badge(document.preset.robots.count)
                    default:
                        Label(selection.localizedName, systemImage: selection.image_name)
                    }
                }
            }
            .navigationTitle("View")
            .toolbar
            {
                #if os(iOS)
                if horizontal_size_class != .compact
                {
                    ToolbarItem(placement: .cancellationAction)
                    {
                        dismiss_document_button()
                    }
                }
                #endif
            }
        } detail: {
            ZStack
            {
                switch sidebar_selection
                {
                case .WorkspaceView:
                    #if os(macOS)
                    WorkspaceView(document: $document, first_loaded: $first_loaded)
                    #else
                    WorkspaceView(document: $document, first_loaded: $first_loaded, file_name: $file_name, file_url: $file_url)
                    #endif
                case .RobotsView:
                    RobotsView(document: $document)
                case .ToolsView:
                    ToolsView(document: $document)
                default:
                    Text("None")
                }
            }
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
