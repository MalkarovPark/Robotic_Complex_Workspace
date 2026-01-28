//
//  VisualWorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2023.
//

import SwiftUI
import UniformTypeIdentifiers
import IndustrialKit
import IndustrialKitUI
import RealityKit

struct VisualWorkspaceView: View
{
    @State private var add_in_view_presented = false
    @State private var info_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    //@EnvironmentObject var sidebar_controller: SidebarController
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    @State private var is_spatial = false
    @State var is_pan = false
    
    @State private var scene_content: RealityViewCameraContent?
    
    @StateObject var robot = Robot(name: "6DOF Robot", entity_name: "6DOF.robot.Scene.usdz", model_controller: _6DOF_Controller())
    
    var body: some View
    {
        ZStack
        {
            RealityView
            { content in
                scene_content = content
                #if os(macOS)
                scene_content?.camera = .virtual
                #else
                scene_content?.camera = is_spatial ? .spatialTracking : .virtual
                #endif
                
                base_workspace.place_entity(to: content)
                
                robot.model_controller = _6DOF_Controller()
                robot.origin_shift.z = 160
                robot.origin_position.x = 200
                //robot.place_entity(to: content)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5)
                {
                    robot.toggle_working_area_visibility()
                    robot.toggle_position_pointer_visibility()
                    //robot.toggle_position_program_visibility()
                }
            }
            .realityViewCameraControls(is_pan ? .pan : .orbit)
            /*.gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded
                    { value in
                        base_workspace.process_tap(value: value)
                    }
            )*/
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
            //.backgroundStyle(.gray.opacity(0.25))
            .ignoresSafeArea(.container, edges: [.top, .bottom])
            
            FloatingView(alignment: .trailing)
            {
                RobotControlView(robot: robot)
                    .padding(8)
            }
            .padding(10)
        }
        .overlay(alignment: .bottomLeading)
        {
            HStack(spacing: 0)
            {
                Button(action: { is_pan.toggle() })
                {
                    Image(systemName: is_pan ? "move.3d" : "rotate.3d")
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                        .animation(.easeInOut(duration: 0.3), value: is_pan)
                        .modifier(CircleButtonImageFramer())
                }
                .keyboardShortcut(.cancelAction)
                .modifier(CircleButtonGlassBorderer())
                .keyboardShortcut(.cancelAction)
                #if os(macOS) || os(iOS)
                .padding(10)
                #else
                .padding(16)
                #endif
            }
        }
        .overlay(alignment: .topLeading)
        {
            HStack(spacing: 0)
            {
                Button(action: button_action)
                {
                    Image(systemName: "checkmark")
                        .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                        .animation(.easeInOut(duration: 0.3), value: is_pan)
                        .modifier(CircleButtonImageFramer())
                }
                .keyboardShortcut(.cancelAction)
                .modifier(CircleButtonGlassBorderer())
                .keyboardShortcut(.cancelAction)
                #if os(macOS) || os(iOS)
                .padding(10)
                #else
                .padding(16)
                #endif
            }
        }
    }
    
    private func button_action()
    {
        base_workspace.toggle_grid_visiblity()
    }
    
    /*var body: some View
    {
        EmptyView()
        //WorkspaceSceneView()
            //.modifier(BackgroundExtensionModifier(color: Color(red: 142/255, green: 142/255, blue: 147/255)))
            /*.modifier(WorkspaceMenu(flip_func: sidebar_controller.flip_workspace_selection))
        #if os(macOS)
            .modifier(BackgroundExtensionModifier(color: Color(red: 142/255, green: 142/255, blue: 147/255)))
        #elseif os(iOS)
            .modifier(BackgroundExtensionModifier(color: Color(red: 124/255, green: 123/255, blue: 129/255)))
        #else
            .modifier(BackgroundExtensionModifierL())
            .ignoresSafeArea(.container, edges: [.top, .bottom])
        #endif
            .disabled(add_in_view_presented)
        #if os(iOS) || os(visionOS)
            .onDisappear
            {
                app_state.locked = false
            }
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if !os(visionOS)
            .overlay(alignment: .bottomLeading)
            {
                GlassEffectContainer
                {
                    VStack(spacing: 0)
                    {
                        Button(action: { add_in_view_presented.toggle() })
                        {
                            Image(systemName: "plus")
                                .modifier(CircleButtonImageFramer())
                            #if !os(macOS)
                                .opacity(!add_in_view_disabled || base_workspace.performed ? 1 : 0.5)
                            #endif
                        }
                        .disabled(add_in_view_disabled || base_workspace.performed)
                        .modifier(CircleButtonGlassBorderer())
                        .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
                        {
                            #if os(macOS)
                            AddInWorkspaceView(add_in_view_presented: $add_in_view_presented)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                            #else
                            AddInWorkspaceView(add_in_view_presented: $add_in_view_presented, is_compact: horizontal_size_class == .compact)
                                .frame(maxWidth: 1024)
                            #endif
                        }
                        .padding(.bottom)
                        
                        Button(action: { info_view_presented.toggle() })
                        {
                            Image(systemName: "pencil")
                                .modifier(CircleButtonImageFramer())
                            #if !os(macOS)
                                .opacity(add_in_view_disabled && !base_workspace.performed ? 1 : 0.5)
                            #endif
                        }
                        .modifier(CircleButtonGlassBorderer())
                        .disabled(!add_in_view_disabled || base_workspace.performed)
                        .popover(isPresented: $info_view_presented, arrowEdge: default_popover_edge)
                        {
                            #if os(macOS)
                            VisualInfoView(info_view_presented: $info_view_presented)
                                .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                            #else
                            VisualInfoView(info_view_presented: $info_view_presented, is_compact: horizontal_size_class == .compact)
                                .frame(maxWidth: 1024)
                            #endif
                        }
                    }
                }
                .padding()
            }
        #else
            .ornament(attachmentAnchor: .scene(.bottom))
            {
                HStack(spacing: 0)
                {
                    Button(action: { add_in_view_presented.toggle() })
                    {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $add_in_view_presented, arrowEdge: default_popover_edge)
                    {
                        AddInWorkspaceView(add_in_view_presented: $add_in_view_presented)
                            .frame(maxWidth: 1024)
                    }
                    .disabled(add_in_view_disabled || base_workspace.performed)
                    .padding(.trailing, 8)
                    
                    Button(action: { info_view_presented.toggle() })
                    {
                        Image(systemName: "pencil")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $info_view_presented, arrowEdge: default_popover_edge)
                    {
                        VisualInfoView(info_view_presented: $info_view_presented)
                            .frame(maxWidth: 1024)
                    }
                    .disabled(!add_in_view_disabled)
                }
                .padding(8)
                .labelStyle(.iconOnly)
                .glassBackgroundEffect()
            }
        #endif
            .onDisappear
            {
                base_workspace.deselect_object()
            }
            .onAppear
            {
                base_workspace.deselect_object()
                base_workspace.update_view()
            }*/
    }*/
    
    private var add_in_view_disabled: Bool
    {
        if base_workspace.any_object_selected && app_state.add_in_view_dismissed && !base_workspace.performed
        {
            return true
        }
        else
        {
            return false
        }
    }
}

#Preview
{
    VisualWorkspaceView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
        //.environmentObject(SidebarController())
        .environmentObject(DocumentUpdateHandler())
}
