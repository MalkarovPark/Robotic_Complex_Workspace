//
//  WorkspaceScene.swift
//  RCWorkspace
//
//  Created by Artem on 03.04.2026.
//

import SwiftUI
import RealityKit

import IndustrialKit
import IndustrialKitUI

struct WorkspaceSceneView: View
{
    @ObservedObject var controller: WorkspaceSceneController
    
    let on_update_workspace: () -> ()
    let on_update_robot: () -> ()
    let on_update_tool: () -> ()
    
    @State private var scene_content: RealityViewContent?
    
    @State private var assets_loading = false
    @State private var assets_loaded = false
    
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
        RealityView
        { content in
            assets_loading = true
            
            scene_content = content
            
            controller.workspace.place_entity(in: content)
            {
                //pendant_controller.is_opened = true
                
                assets_loading = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    assets_loaded = true
                }
            }
        }
        placeholder:
        {
            AssetsLoadingPane(assets_loading: assets_loading)
        }
        .highPriorityGesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded
                { value in
                    controller.workspace.process_tap(value: value)
                }
        )
        .gesture(
            TapGesture()
                .onEnded
                {
                    controller.workspace.process_empty_tap()
                }
        )
        .ignoresSafeArea(.container, edges: .all)
        .disabled(assets_loading)
    }
}

public struct WorkspaceScene: SwiftUI.Scene
{
    var space_id: String
    let controller: WorkspaceSceneController
    
    public init(
        window_id: String = WorkspaceSpaceDefaultID,
        controller: WorkspaceSceneController
    )
    {
        self.space_id = window_id
        self.controller = controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        ImmersiveSpace(id: space_id)
        {
            WorkspaceSceneView(controller: controller)
        }
    }
}

///The default window id of Spatial Pendant.
public let WorkspaceSpaceDefaultID = "workspace"

@MainActor public class WorkspaceSceneController: ObservableObject
{
    public init() {}
    
    // MARK: - Workspace management
    @Published public var workspace = Workspace()
    
    public init(workspace: Workspace)
    {
        self.workspace = workspace
    }
    
    // MARK: - Space management
    @Published public var is_opened = false
    {
        didSet
        {
            if is_opened { open() }
            else { dismiss() }
        }
    }
    
    public func on_dismiss() { is_opened = false }
    
    public func set_space_functions(
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
