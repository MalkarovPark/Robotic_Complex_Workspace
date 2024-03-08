//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.10.2021.
//

import SwiftUI
import IndustrialKit

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
    
    var body: some View
    {
        SidebarContent(document: $document).frame(minWidth: 200, idealWidth: 250)
        #if os(iOS) || os(visionOS)
            .navigationBarHidden(true)
        #endif
    }
}

struct SidebarContent: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @State var settings_view_presented = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size_class //Horizontal window size handler
    #endif
    
    //@State var sidebar_selection: navigation_item? = .WorkspaceView //Selected sidebar item
    #if os(visionOS)
    @EnvironmentObject var sidebar_controller: SidebarController
    #else
    @StateObject var sidebar_controller = SidebarController()
    #endif
    
    var body: some View
    {
        NavigationSplitView
        {
            //MARK: Sidebar
            List(navigation_item.allCases, selection: $sidebar_controller.sidebar_selection)
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
            #if !os(macOS)
            .toolbar
            {
                //Settings button for iOS/iPadOS sidebar toolbar
                ToolbarItem(placement: toolbar_item_placement_trailing)
                {
                    HStack(alignment: .center)
                    {
                        Button (action: { app_state.settings_view_presented = true })
                        {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
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
                #if os(visionOS)
                .frame(width: 512, height: 512)
                #endif
            }
            #endif
        } detail: {
            ZStack
            {
                //MARK: Content
                switch sidebar_controller.sidebar_selection
                {
                case .WorkspaceView:
                    WorkspaceView()
                    #if os(visionOS)
                        .modifier(ViewPendantButton())
                    #else
                        .environmentObject(sidebar_controller)
                    #endif
                case .RobotsView:
                    RobotsView()
                    #if os(visionOS)
                        .modifier(ViewPendantButton())
                    #endif
                case .ToolsView:
                    ToolsView()
                    #if os(visionOS)
                        .modifier(ViewPendantButton())
                    #endif
                case .PartsView:
                    PartsView()
                    #if os(visionOS)
                        .modifier(ViewPendantButton())
                    #endif
                default:
                    Rectangle()
                    #if os(macOS)
                        .fill(.gray)
                    #else
                        .fill(.clear)
                    #endif
                        .onAppear
                    {
                        if sidebar_controller.perform_workspace_view_reset
                        {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)
                            {
                                sidebar_controller.sidebar_selection = .WorkspaceView
                                sidebar_controller.perform_workspace_view_reset = false
                            }
                        }
                    }
                }
            }
        }
    }
}

//MARK: - Previews
#Preview
{
    Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
