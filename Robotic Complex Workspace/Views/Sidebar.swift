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
    #if os(iOS) || os(visionOS)
    @EnvironmentObject var app_state: AppState
    
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
            #if os(iOS) || os(visionOS)
            .toolbar
            {
                //Settings button for iOS/iPadOS sidebar toolbar
                ToolbarItem(placement: placement_trailing)
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
                switch sidebar_selection
                {
                case .WorkspaceView:
                    WorkspaceView(document: $document)
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
}

//MARK: - Previews
#Preview
{
    Sidebar(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
