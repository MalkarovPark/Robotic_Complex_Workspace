//
//  Sidebar.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 17.10.2021.
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
struct WorkspaceNavigationView: View
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
        }
        detail:
        {
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
    WorkspaceNavigationView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
