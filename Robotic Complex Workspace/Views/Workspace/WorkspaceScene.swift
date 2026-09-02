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

import ARKit

struct WorkspaceSceneView: View
{
    @ObservedObject var controller: WorkspaceSceneController
    @ObservedObject var inspector_controller: ObjectInspectorController
    
    @State private var scene_content: RealityViewContent?
    
    @State private var assets_loading = false
    @State private var assets_loaded = false
    
    @State private var world_tracking_provider = WorldTrackingProvider()
    @State private var arkit_session = ARKitSession()
    
    @State private var device_camera_position: simd_float3 = .zero
    
    public init(
        controller: WorkspaceSceneController,
        inspector_controller: ObjectInspectorController,
        
        on_update_workspace: @escaping () -> () = {},
        on_update_robot: @escaping () -> () = {},
        on_update_tool: @escaping () -> () = {},
        on_update_part: @escaping () -> () = {}
    )
    {
        self.controller = controller
        self.inspector_controller = inspector_controller
        
        self.controller.set_document_functions(on_update_workspace, on_update_robot, on_update_tool, on_update_part)
    }
    
    var body: some View
    {
        RealityView
        { content in
            assets_loading = true
            
            scene_content = content
            
            controller.workspace.place_entity(in: content)
            {
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
        .task
        {
            do
            {
                try await arkit_session.run([world_tracking_provider])
            }
            catch
            {
                print("\(error)")
                return
            }
            
            while true
            {
                let device_anchor = world_tracking_provider.queryDeviceAnchor(
                    atTimestamp: CACurrentMediaTime()
                )
                
                if let device_anchor = device_anchor
                {
                    controller.workspace.device_camera_position = Transform(matrix: device_anchor.originFromAnchorTransform).translation
                }
                
                try? await Task.sleep(nanoseconds: 16_666_667) // ~60 FPS
            }
        }
    }
}

public struct WorkspaceScene: SwiftUI.Scene
{
    var space_id: String
    
    let controller: WorkspaceSceneController
    let inspector_controller: ObjectInspectorController
    
    public init(
        space_id: String = WorkspaceSpaceDefaultID,
        
        controller: WorkspaceSceneController,
        inspector_controller: ObjectInspectorController
    )
    {
        self.space_id = space_id
        self.controller = controller
        self.inspector_controller = inspector_controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        ImmersiveSpace(id: space_id)
        {
            WorkspaceSceneView(controller: controller, inspector_controller: inspector_controller)
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
    
    // MARK: - Document management
    public var on_update_workspace = {}
    
    public var on_update_robot = {}
    public var on_update_tool = {}
    public var on_update_part = {}
    
    public func set_document_functions(
        _ on_update_workspace: @escaping () -> (),
        
        _ on_update_robot: @escaping () -> (),
        _ on_update_tool: @escaping () -> (),
        _ on_update_part: @escaping () -> ()
    )
    {
        self.on_update_workspace = on_update_workspace
        
        self.on_update_robot = on_update_robot
        self.on_update_tool = on_update_tool
        self.on_update_part = on_update_part
    }
}

#Preview
{
    WorkspaceSceneView(controller: WorkspaceSceneController(), inspector_controller: ObjectInspectorController(workspace: Workspace(), document: .constant(Robotic_Complex_WorkspaceDocument())))
}
