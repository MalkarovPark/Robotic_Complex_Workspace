//
//  ContextMenus.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.04.2023.
//

import SwiftUI
import IndustrialKit

struct CardMenu: ViewModifier
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @ObservedObject var object: WorkspaceObject //StateObject ???
    
    @Binding var to_rename: Bool
    
    @State private var is_selected = false
    @State var name = String()
    @State private var delete_alert_presented = false
    
    let clear_preview: () -> ()
    let duplicate_object: () -> ()
    let delete_object: () -> ()
    let update_file: () -> ()
    
    let set_default_position: () -> ()
    let clear_default_position: () -> ()
    let reset_robot_to: () -> ()
    
    let pass_preferences: () -> ()
    let pass_programs: () -> ()
    
    //Full
    public init(object: WorkspaceObject, to_rename: Binding<Bool>, name: String = String(), delete_alert_presented: Bool = false, clear_preview: @escaping () -> Void, duplicate_object: @escaping () -> Void, delete_object: @escaping () -> Void, update_file: @escaping () -> Void, set_default_position: @escaping () -> Void, clear_default_position: @escaping () -> Void, reset_robot_to: @escaping () -> Void, pass_preferences: @escaping () -> Void, pass_programs: @escaping () -> Void)
    {
        self.object = object
        self._to_rename = to_rename
        self.name = name
        self.delete_alert_presented = delete_alert_presented
        self.clear_preview = clear_preview
        self.duplicate_object = duplicate_object
        self.delete_object = delete_object
        self.update_file = update_file
        self.set_default_position = set_default_position
        self.clear_default_position = clear_default_position
        self.reset_robot_to = reset_robot_to
        self.pass_preferences = pass_preferences
        self.pass_programs = pass_programs
    }
    
    //Tool & Part
    public init(object: WorkspaceObject, to_rename: Binding<Bool>, name: String = String(), delete_alert_presented: Bool = false, duplicate_object: @escaping () -> Void, delete_object: @escaping () -> Void, update_file: @escaping () -> Void)
    {
        self.object = object
        self._to_rename = to_rename
        self.name = name
        self.delete_alert_presented = delete_alert_presented
        self.clear_preview = {}
        self.duplicate_object = duplicate_object
        self.delete_object = delete_object
        self.update_file = update_file
        self.set_default_position = {}
        self.clear_default_position = {}
        self.reset_robot_to = {}
        self.pass_preferences = {}
        self.pass_programs = {}
    }
    
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
            .onChange(of: object.is_placed)
            { _, new_value in
                if !new_value
                {
                    if object is Robot
                    {
                        tool_unplace(workspace: base_workspace, from_robot_name: object.name)
                    }
                    else if object is Tool
                    {
                        (object as! Tool).attached_to = nil
                        (object as! Tool).is_attached = false
                    }
                }
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
                    
                    Menu("Default Position")
                    {
                        Button(action: set_default_position)
                        {
                            Label("Set", systemImage: "dot.scope")
                        }
                        
                        Button(action: clear_default_position)
                        {
                            Label("Clear", systemImage: "xmark")
                        }
                        .disabled(!(base_workspace.robot_by_name(name).has_default_position))
                        
                        #if os(macOS)
                        Divider()
                        #endif
                        
                        Button(action: reset_robot_to)
                        {
                            Label("Reset to it", systemImage: "arrow.counterclockwise")
                        }
                        .disabled(!(base_workspace.robot_by_name(name).has_default_position))
                    }
                    
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
                    #if !os(visionOS)
                    .background(.regularMaterial)
                    #else
                    .glassBackgroundEffect()
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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

func tool_unplace(workspace: Workspace, from_robot_name: String)
{
    for placed_tools_name in workspace.placed_tools_names
    {
        let viewed_tool = workspace.tool_by_name(placed_tools_name)
        if viewed_tool.is_placed && viewed_tool.is_attached && viewed_tool.attached_to == from_robot_name
        {
            viewed_tool.attached_to = nil
            viewed_tool.is_attached = false
        }
    }
}

struct WorkspaceMenu: ViewModifier
{
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var flip = false
    
    let flip_func: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
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
        flip_func()
    }
}

struct Squarer: ViewModifier
{
    let side: CGFloat
    public func body(content: Content) -> some View
    {
        content
            .frame(width: side, height: side)
    }
}
