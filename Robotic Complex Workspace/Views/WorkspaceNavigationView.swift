//
//  WorkspaceNavigationView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 17.10.2021.
//

import SwiftUI
import IndustrialKit
import SceneKit

enum navigation_item: Int, Hashable, CaseIterable, Identifiable
{
    case WorkspaceView, RobotsView, ToolsView, PartsView // Sidebar items
    
    var id: Int { rawValue }
    var localizedName: LocalizedStringKey // Names of sidebar items
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
    
    var image_name: String // Names of sidebar items symbols
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

// MARK: - Sidebar view and content
struct WorkspaceNavigationView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if !os(macOS)
    @State var settings_view_presented = false
    
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    
    @Environment(\.dismiss) private var dismiss
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var sidebar_controller: SidebarController
    #else
    @StateObject var sidebar_controller = SidebarController()
    #endif
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                // MARK: Content
                WorkspaceView()
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar
            {
                ToolbarItem(placement: .cancellationAction)
                {
                    HStack(alignment: .center)
                    {
                        /*Button(action: { dismiss() })
                        {
                            Label("Dismiss", systemImage: "folder")
                        }
                        #if os(visionOS)
                        .buttonBorderShape(.circle)
                        .padding(.trailing)
                        #endif*/
                        
                        Button (action: { app_state.settings_view_presented = true })
                        {
                            Label("Settings", systemImage: "gear")
                        }
                        #if os(visionOS)
                        .buttonBorderShape(.circle)
                        #endif
                    }
                }
            }
            .sheet(isPresented: $app_state.settings_view_presented)
            {
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
        }
    }
}

// MARK: - Previews
#Preview
{
    WorkspaceNavigationView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
