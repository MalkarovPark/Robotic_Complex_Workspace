//
//  WorkspaceSpatialView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import UniformTypeIdentifiers
import RealityKit

import IndustrialKit
import IndustrialKitUI

struct WorkspaceSpatialView: View
{
    @State private var add_in_view_presented = false
    @State private var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    //#if os(macOS) || os(iOS)
    @AppStorage("ViewMode") private var view_mode: ViewMode = .scene
    //#endif
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    @Binding var is_pan: Bool
    
    @ObservedObject var pendant_controller: PendantController
    
    #if os(macOS) || os(iOS)
    @State private var scene_content: RealityViewCameraContent?
    #else
    @State private var scene_content: RealityViewContent?
    @EnvironmentObject var workspace_controller: WorkspaceSceneController
    #endif
    @State private var is_spatial = false
    
    @State private var assets_loading = false
    @State private var assets_loaded = false
    
    var body: some View
    {
        ZStack
        {
            #if os(visionOS)
            if assets_loaded
            {
                WorkspaceGalleryView(document: $document)
                    .frame(maxWidth: .infinity)
            }
            else
            {
                RealityView
                { content in
                    assets_loading = true
                    
                    scene_content = content
                    
                    base_workspace.place_entity(in: content)
                    {
                        //pendant_controller.is_opened = true
                        
                        assets_loading = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                        {
                            assets_loaded = true
                            workspace_controller.set_view_mode(view_mode)
                        }
                    }
                }
                .frame(depth: 0)
                .hidden()
            }
            
            AssetsLoadingPane(assets_loading: assets_loading)
            #endif
            
            #if os(macOS) || os(iOS)
            RealityView
            { content in
                assets_loading = true
                
                scene_content = content
                #if os(macOS)
                scene_content?.camera = .virtual
                #elseif os(iOS)
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
                    WorkspaceGalleryView(document: $document)
                        .frame(maxWidth: .infinity)
                        .opacity(view_mode != .scene ? 1 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.95), value: pendant_width)
                }
                
                SpatialPendant(
                    controller: pendant_controller,
                    
                    shows_program_indices: true,
                    
                    on_update_workspace:
                        {
                            document.preset.programs = base_workspace.file_data().programs
                            document.preset.registers = base_workspace.file_data().registers
                        },
                    on_update_robot:
                        {
                            document.preset.robots = base_workspace.file_data().robots
                        },
                    on_update_tool:
                        {
                            document.preset.tools = base_workspace.file_data().tools
                        }
                )
                .frame(maxWidth: pendant_width)
                .animation(.spring(response: 0.35, dampingFraction: 0.95), value: pendant_width)
                .padding([.horizontal, .bottom], 7.8)
                #if os(macOS) || os(visionOS)
                .ignoresSafeArea(edges: .bottom)
                #else
                .ignoresSafeArea(edges: horizontal_size_class == .compact ? .init() : .bottom)
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            AssetsLoadingPane(assets_loading: assets_loading)
            #endif
        }
    }
    
    #if os(macOS) || os(iOS)
    private var pendant_width: CGFloat
    {
        if view_mode != .scene && assets_loaded
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
    #endif
}

struct AssetsLoadingPane: View
{
    let assets_loading: Bool
    var body: some View
    {
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
                #if os(macOS) || os(iOS)
                .background
                {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.thinMaterial)
                }
                #else
                .scaleEffect(1.05)
                #endif
                #if os(iOS)
                .scaleEffect(1.25)
                #endif
                .offset(y: -32)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: assets_loading)
    }
}

#Preview
{
    WorkspaceSpatialView(
        document: .constant(Robotic_Complex_WorkspaceDocument()),
        is_pan: .constant(false),
        pendant_controller: PendantController()
    )
    .environmentObject(Workspace())
    .environmentObject(AppState())
}
