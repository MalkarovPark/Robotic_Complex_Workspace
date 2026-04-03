//
//  WorkspaceScene.swift
//  RCWorkspace
//
//  Created by Artem on 03.04.2026.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

struct WorkspaceSceneView: View
{
    @ObservedObject var controller: WorkspaceSceneController
    
    let on_update_workspace: () -> ()
    let on_update_robot: () -> ()
    let on_update_tool: () -> ()
    
    public init(
        controller: WorkspaceSceneController,
        
        on_update_workspace: @escaping () -> () = {},
        on_update_robot: @escaping () -> () = {},
        on_update_tool: @escaping () -> () = {}
    )
    {
        self.controller = controller
        
        self.on_update_workspace = on_update_workspace
        self.on_update_robot = on_update_robot
        self.on_update_tool = on_update_tool
    }
    
    var body: some View
    {
        VStack(spacing: 8)
        {
            Text("Workspace")
            Text("Robots – \(controller.workspace.robots.count)")
            Text("Tools – \(controller.workspace.tools.count)")
            Text("Parts – \(controller.workspace.parts.count)")
        }
        .padding(16)
    }
}

public struct WorkspaceScene: SwiftUI.Scene
{
    var window_id: String
    let controller: WorkspaceSceneController
    
    public init(
        window_id: String = WorkspaceSceneDefaultID,
        controller: WorkspaceSceneController
    )
    {
        self.window_id = window_id
        self.controller = controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        WindowGroup(id: window_id)
        {
            WorkspaceSceneView(controller: controller)
                .padding([.horizontal, .top], 16)
        }
        .windowResizability(.contentSize)
    }
}

///The default widow id of Spatial Pendant.
public let WorkspaceSceneDefaultID = "workspace"

@MainActor public class WorkspaceSceneController: ObservableObject
{
    public init() {}
    
    // MARK: - Workspace management
    @Published public var workspace = Workspace()
    
    public init(workspace: Workspace)
    {
        self.workspace = workspace
    }
    
    // MARK: - Windows management
    @Published public var is_opened = false
    {
        didSet
        {
            if is_opened { open() }
            else { dismiss() }
        }
    }
    
    public func on_dismiss() { is_opened = false }
    
    public func set_windows_functions(
        _ open: @escaping () -> (),
        _ dismiss: @escaping () -> ()
    )
    {
        self.open = open
        self.dismiss = dismiss
    }
    
    private var open = {}
    private var dismiss = {}
}

#Preview
{
    WorkspaceSceneView(controller: WorkspaceSceneController())
}
