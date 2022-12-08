//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.10.2021.
//

import SwiftUI

enum navigation_item: Int, Hashable, CaseIterable, Identifiable
{
    case WorkspaceView, RobotsView, ToolsView, PartsView //Sidebar items
    
    var id: Int { rawValue }
    var localizedName: LocalizedStringKey //Names of sidebar items
    {
        switch self
        {
        case .WorkspaceView:
            return "Workspace"
        case .RobotsView:
            return "Robots"
        case .ToolsView:
            return "Tools"
        case .PartsView:
            return "Parts"
        }
    }
    
    var image_name: String //Names of sidebar items symbols
    {
        switch self
        {
        case .WorkspaceView:
            return "cube.transparent"
        case .RobotsView:
            return "r.square"
        case .ToolsView:
            return "hammer"
        case .PartsView:
            return "shippingbox"
        }
    }
}

//MARK: - Sidebar view and content
struct Sidebar: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument //Current openet document
    @Binding var first_loaded: Bool //Delayed workspace scene fading out on firs load
    #if os(iOS)
    //Document file info for iOS/iPadOS
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

struct SidebarContent: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var first_loaded: Bool
    #if os(iOS)
    @EnvironmentObject var app_state: AppState
    
    @Binding var file_url: URL
    @Binding var file_name: String
    
    @State var settings_view_presented = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size_class //Horizontal window size handler
    #endif
    
    @State var sidebar_selection: navigation_item? = .WorkspaceView //Selected sidebar item
    
    var body: some View
    {
        NavigationSplitView
        {
            //MARK: Sidebar
            List(navigation_item.allCases, selection: $sidebar_selection)
            { selection in
                NavigationLink(value: selection)
                {
                    switch selection.localizedName
                    {
                    case "Robots":
                        Label(selection.localizedName, systemImage: selection.image_name)
                            .badge(document.preset.robots.count)
                    case "Tools":
                        Label(selection.localizedName, systemImage: selection.image_name)
                            .badge(document.preset.tools.count)
                    case "Parts":
                        Label(selection.localizedName, systemImage: selection.image_name)
                            .badge(document.preset.parts.count)
                    default:
                        Label(selection.localizedName, systemImage: selection.image_name)
                    }
                }
            }
            .navigationTitle("View")
            #if os(iOS)
            .toolbar
            {
                //Settings button for iOS/iPadOS sidebar toolbar
                ToolbarItem(placement: placement_trailing)
                {
                    HStack(alignment: .center)
                    {
                        Button (action: { app_state.settings_view_presented = true })
                        {
                            Label("Settings", systemImage: "slider.horizontal.2.square.on.square")
                        }
                    }
                }
                /*if horizontal_size_class != .compact
                {
                    ToolbarItem(placement: .cancellationAction)
                    {
                        dismiss_document_button()
                    }
                }*/
            }
            .sheet(isPresented: $app_state.settings_view_presented)
            {
                //Show settings view for iOS/iPadOS
                SettingsView(setting_view_presented: $app_state.settings_view_presented)
                    .environmentObject(app_state)
                    .onDisappear
                {
                    app_state.settings_view_presented = false
                }
            }
            #endif
        } detail: {
            ZStack
            {
                //MARK: Content
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
                case .PartsView:
                    PartsView(document: $document)
                default:
                    VStack
                    {
                        //Text("None")
                    }
                    #if os(macOS)
                    .onAppear(perform: { sidebar_selection = .WorkspaceView }) //???
                    #endif
                }
            }
        }
    }
    
    /*#if os(macOS)
    func toggle_sidebar()
    {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
          #selector(NSSplitViewController.toggleSidebar),
          with: nil)
    }
    #endif*/
}

//MARK: - Previews
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
