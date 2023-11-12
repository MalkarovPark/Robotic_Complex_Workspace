//
//  ContextMenus.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 20.04.2023.
//

import SwiftUI
import IndustrialKit

struct CardMenu: ViewModifier
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @ObservedObject var object: WorkspaceObject //StateObject ???
    
    @Binding var to_rename: Bool
    @State var is_selected = false
    @State var name = String()
    
    let clear_preview: () -> ()
    let duplicate_object: () -> ()
    let update_file: () -> ()
    
    let pass_preferences: () -> ()
    let pass_programs: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            .contextMenu
            {
                Toggle(isOn: $object.is_placed)
                {
                    Label("Placed", systemImage: "target")
                }
                
                Button(action: {
                    clear_preview()
                    update_file()
                })
                {
                    Label("Clear Preview", systemImage: "rectangle.slash")
                }
                
                #if os(macOS)
                Divider()
                #endif
                
                Button(action: {
                    duplicate_object()
                    update_file()
                })
                {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                
                RenameButton()
                    .renameAction
                {
                    withAnimation
                    {
                        to_rename.toggle()
                    }
                }
                
                if object is Robot
                {
                    #if os(macOS)
                    Divider()
                    #endif
                    
                    Menu("Pass")
                    {
                        Button(action: pass_preferences)
                        {
                            Label("Origin Preferences", systemImage: "move.3d")
                        }
                        
                        Button(action: pass_programs)
                        {
                            Label("Positions Program", systemImage: "scroll")
                        }
                    }
                }
            }
            .onChange(of: object.is_placed)
            { _, _ in
                update_file()
            }
            .overlay
            {
                if app_state.preferences_pass_mode || app_state.programs_pass_mode
                {
                    ZStack
                    {
                        Image(systemName: app_state.robot_from.name != name ? "checkmark" : "nosign")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundStyle(is_selected ? .primary : .tertiary)
                    }
                    .frame(width: 64, height: 64)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2))) //.transition(AnyTransition.opacity.animation(.spring))
                    .onTapGesture(perform: update_selection)
                    .onDisappear
                    {
                        is_selected = false
                    }
                }
            }
    }
    
    private func update_selection()
    {
        if app_state.robot_from.name != name
        {
            is_selected.toggle()
            if is_selected
            {
                app_state.robots_to_names.append(name)
            }
            else
            {
                app_state.robots_to_names.remove(at: app_state.robots_to_names.firstIndex(of: name) ?? 0)
            }
        }
    }
}

struct WorkspaceMenu: ViewModifier
{
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var flip = false
    
    public func body(content: Content) -> some View
    {
        ZStack
        {
            if flip
            {
                content
            }
            else
            {
                content
            }
        }
        .contextMenu
        {
            Button(action: flip_scene)
            {
                Label("Reset Scene", systemImage: "arrow.counterclockwise")
            }
        }
    }
    
    private func flip_scene()
    {
        if base_workspace.performed
        {
            base_workspace.reset_performing()
            //base_workspace.update_view()
        }
        flip.toggle()
    }
}
