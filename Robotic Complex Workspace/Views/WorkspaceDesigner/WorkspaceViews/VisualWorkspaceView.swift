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
    
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    @Binding var is_pan: Bool
    
    @ObservedObject var pendant_controller: PendantController = PendantController()
    
    @State private var scene_content: RealityViewCameraContent?
    @State private var is_spatial = false
    
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
                {
                    pendant_controller.is_opened = true
                }
            }
            /*update:
            { content in
                
            }*/
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
                .modifier(CircleButtonGlassBorderer())
                #if os(macOS) || os(iOS)
                .padding([.horizontal, .top], 10)
                #else
                .padding([.horizontal, .top], 16)
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
        
        document_handler.document_update_programs()
    }
}

#Preview
{
    VisualWorkspaceView(is_pan: .constant(false))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .environmentObject(DocumentUpdateHandler())
}
