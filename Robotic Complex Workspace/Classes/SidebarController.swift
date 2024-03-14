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
    @Published var sidebar_selection: navigation_item? = .WorkspaceView
    
    public func flip_workspace_selection()
    {
        sidebar_selection = nil
        perform_workspace_view_reset = true
    }
    
    @Published var perform_workspace_view_reset = false
}
