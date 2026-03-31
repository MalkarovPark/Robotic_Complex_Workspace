//
//  VisualWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import UniformTypeIdentifiers
import RealityKit

import IndustrialKit
import IndustrialKitUI

struct VisualWorkspaceView: View
{
    @State private var add_in_view_presented = false
    @State private var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @AppStorage("ViewMode") private var view_mode: ViewMode = .scene
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    @Binding var is_pan: Bool
    
    @ObservedObject var pendant_controller: PendantController = PendantController()
    
    @State private var scene_content: RealityViewCameraContent?
    @State private var is_spatial = false
    
    @State private var assets_loading = false
    @State private var assets_loaded = false
    
    var body: some View
    {
        ZStack
        {
            RealityView
            { content in
                assets_loading = true
                
                scene_content = content
                #if os(macOS)
                scene_content?.camera = .virtual
                #else
                scene_content?.camera = is_spatial ? .spatialTracking : .virtual
                #endif
                
                base_workspace.place_entity(in: content)
                {
                    pendant_controller.is_opened = true
                    
                    assets_loading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                    {
                        assets_loaded = true
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .all)
            .disabled(assets_loading)
            .realityViewCameraControls(is_pan ? .pan : .orbit)
            .highPriorityGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded
                    { value in
                        base_workspace.process_tap(value: value)
                    }
            )
            .gesture(
                TapGesture()
                    .onEnded
                    {
                        base_workspace.process_empty_tap()
                    }
            )
            .opacity(view_mode == .scene ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: view_mode == .scene)
            #if os(macOS)
            .frame(minWidth: 640, idealWidth: 800, minHeight: 576, idealHeight: 600)
            #endif
            
            HStack(spacing: 0)
            {
                if view_mode != .scene && assets_loaded
                {
                    GalleryWorkspaceView()
                        .frame(maxWidth: .infinity)
                        .opacity(view_mode != .scene ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.95), value: pendant_width)
                }
                
                SpatialPendantView(
                    controller: pendant_controller,
                    workspace: base_workspace,
                    
                    shows_program_indices: true,
                    
                    on_update_workspace: { document_handler.document_update_programs() },
                    on_update_robot: { document_handler.document_update_robots() },
                    on_update_tool: { document_handler.document_update_tools() }
                )
                .frame(maxWidth: pendant_width)
                .animation(.spring(response: 0.35, dampingFraction: 0.95), value: pendant_width)
                .padding([.horizontal, .bottom], 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ZStack
            {
                if assets_loading
                {
                    ProgressView(
                        label:
                            {
                                Text("Loading Assets...")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                    )
                    .progressViewStyle(.circular)
                    .padding()
                    .background
                    {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.thinMaterial)
                    }
                    .offset(y: -32)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: assets_loading)
        }
    }
    
    private var pendant_width: CGFloat
    {
        if (view_mode == .gallery || view_mode == .immersive) && assets_loaded
        {
            if pendant_controller.is_opened && !(base_workspace.selected_object is Part)
            {
                return 216
            }
            else
            {
                return 0
            }
        }
        else
        {
            return .infinity
        }
    }
}

#Preview
{
    VisualWorkspaceView(is_pan: .constant(false))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .environmentObject(DocumentUpdateHandler())
}
