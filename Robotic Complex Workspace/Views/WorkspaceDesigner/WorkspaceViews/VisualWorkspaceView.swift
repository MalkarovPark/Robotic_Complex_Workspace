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
                
                scene_content?.environment
                
                base_workspace.place_entity(to: content)
                
                //robot.model_controller = _6DOF_Controller()
                /*robot.origin_shift.z = 160
                robot.origin_position.x = 200
                
                //robot.place_entity(to: content)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5)
                {
                    robot.toggle_working_area_visibility()
                    robot.toggle_position_pointer_visibility()
                    //robot.toggle_position_program_visibility()
                }*/
            }
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
    
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    private func button_action()
    {
        //base_workspace.toggle_grid_visiblity()
        
        document_handler.document_update_robots()
        document_handler.document_update_tools()
        document_handler.document_update_parts()
    }
}

#Preview
{
    VisualWorkspaceView()
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .environmentObject(DocumentUpdateHandler())
}
