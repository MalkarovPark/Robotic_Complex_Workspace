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

public struct WorkspaceImmersiveSpace: SwiftUI.Scene
{
    var space_id: String
    
    let controller: WorkspaceSceneController
    let inspector_controller: ObjectInspectorController
    
    public init(
        space_id: String = WorkspaceImmersiveSpaceDefaultID,
        
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

public let WorkspaceImmersiveSpaceDefaultID = "workspace_immersive"

public struct WorkspaceVolumetricWindow: SwiftUI.Scene
{
    var window_id: String
    
    let controller: WorkspaceSceneController
    let inspector_controller: ObjectInspectorController
    
    public init(
        window_id: String = WorkspaceVolumetricWindowDefaultID,
        
        controller: WorkspaceSceneController,
        inspector_controller: ObjectInspectorController
    )
    {
        self.window_id = window_id
        self.controller = controller
        self.inspector_controller = inspector_controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        WindowGroup(id: window_id)
        {
            WorkspaceSceneView(controller: controller, inspector_controller: inspector_controller)
        }
        .windowStyle(.volumetric)
        .windowResizability(.contentSize)
    }
}

public let WorkspaceVolumetricWindowDefaultID = "workspace_volumetric"

@MainActor public class WorkspaceSceneController: ObservableObject
{
    public init() {}
    
    // MARK: - Workspace management
    @Published public var workspace = Workspace()
    
    public init(workspace: Workspace)
    {
        self.workspace = workspace
    }
    
    public func set_view_mode(_ mode: ViewMode)
    {
        switch mode
        {
        case .scene:
            dismiss_space()
            open_window()
        case .gallery:
            dismiss_window()
            dismiss_space()
        case .immersive:
            dismiss_window()
            open_space()
        }
        
        view_mode = mode
    }
    
    private var view_mode: ViewMode = .scene
    
    public func dismiss_view()
    {
        if view_mode == .scene { dismiss_window() }
        else if view_mode == .immersive { dismiss_space() }
    }
    
    // MARK: - Space management
    public func set_space_functions(
        _ open: @escaping () -> (),
        _ dismiss: @escaping () -> ()
    )
    {
        self.open_space = open
        self.dismiss_space = dismiss
    }
    
    public func reset_immersive_space()
    {
        dismiss_space()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1)
        {
            if self.view_mode != .immersive { return }
            self.open_space()
        }
    }
    
    private var open_space = {}
    private var dismiss_space = {}
    
    // MARK: - Window management
    public func set_window_functions(
        _ open: @escaping () -> (),
        _ dismiss: @escaping () -> ()
    )
    {
        self.open_window = open
        self.dismiss_window = dismiss
    }
    
    private var open_window = {}
    private var dismiss_window = {}
    
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
