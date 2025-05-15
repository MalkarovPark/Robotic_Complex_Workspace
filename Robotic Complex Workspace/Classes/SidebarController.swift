//
//  SidebarController.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 26.02.2024.
//

import Foundation

//MARK: - Class for sidebar handling
class SidebarController: ObservableObject
{
    #if os(macOS)
    @Published var sidebar_selection: navigation_item? = nil//.WorkspaceView
    #else
    @Published var sidebar_selection: navigation_item? = .WorkspaceView
    #endif
    
    public func flip_workspace_selection()
    {
        sidebar_selection = nil
        perform_workspace_view_reset = true
    }
    
    #if os(macOS)
    @Published var perform_workspace_view_reset = true
    #else
    @Published var perform_workspace_view_reset = false
    #endif
    
    @Published var from_workspace_view = false
    
    #if !os(visionOS)
    @Published public var code_editor_text = String()
    #endif
}
