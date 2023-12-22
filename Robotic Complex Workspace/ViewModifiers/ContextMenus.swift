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
    @State private var delete_alert_presented = false
    
    let clear_preview: () -> ()
    let duplicate_object: () -> ()
    let delete_object: () -> ()
    let update_file: () -> ()
    
    let pass_preferences: () -> ()
    let pass_programs: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
            .alert(isPresented: $delete_alert_presented)
            {
                Alert(
                    title: Text("Delete \(object_type_name())?"),
                    message: Text("Do you want to delete this \(object_type_name()) – \(object.name)"),
                    primaryButton: .destructive(Text("Delete"), action: {
                        delete_object()
                        update_file()
                    }),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            .contextMenu
            {
                Toggle(isOn: $object.is_placed)
                {
                    Label("Placed", systemImage: "target")
                }
                
                if object is Robot
                {
                    Button(action: {
                        clear_preview()
                        update_file()
                    })
                    {
                        Label("Clear Preview", systemImage: "rectangle.slash")
                    }
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
                            Label("Positions Programs", systemImage: "scroll")
                        }
                    }
                    .disabled(base_workspace.robots.count < 2)
                }
                
                Divider()
                
                Button("Delete", systemImage: "trash", role: .destructive)
                {
                    delete_alert_presented = true
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
    
    private func object_type_name() -> String
    {
        switch object
        {
        case is Robot:
            return "Robot"
        case is Tool:
            return "Tool"
        case is Part:
            return "Part"
        default:
            return ""
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

struct ListBorderer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
        #if os(macOS)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(radius: 1)
        #else
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        #endif
    }
}
