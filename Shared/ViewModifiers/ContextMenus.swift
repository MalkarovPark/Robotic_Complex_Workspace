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
    
    @State var is_flipped = false
    @State var is_selected = false
    @State var name = String()
    
    let clear_preview: () -> ()
    let duplicate_object: () -> ()
    let update_file: () -> ()
    
    let pass_preferences: () -> ()
    let pass_programs: () -> ()
    
    private let duration_and_delay: CGFloat = 0.3
    
    public func body(content: Content) -> some View
    {
        ZStack
        {
            if !is_flipped
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
                                is_flipped.toggle()
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
                    { _ in
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
            else
            {
                if !(object is Part)
                {
                    LargeCardBack(color: object.card_info.color, image: object.card_info.image, title: object.card_info.title, subtitle: object.card_info.subtitle, object: object, is_renamed: $is_flipped, update_file: update_file)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
                else
                {
                    SmallCardBack(color: object.card_info.color, image: object.card_info.image, title: object.card_info.title, object: object, is_renamed: $is_flipped, update_file: update_file)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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

public struct LargeCardBack: View
{
    @State public var color: Color
    #if os(macOS)
    @State public var image: NSImage
    #else
    @State public var image: UIImage
    #endif
    @State public var title: String
    @State public var subtitle: String
    
    @State public var object: WorkspaceObject
    
    @Binding public var is_renamed: Bool
    
    @FocusState private var is_focused: Bool
    
    let update_file: () -> ()
    
    #if os(macOS)
    public init(color: Color, image: NSImage, title: String, subtitle: String, object: WorkspaceObject, is_renamed: Binding<Bool>, update_file: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.title = title
        self.subtitle = subtitle
        
        self.object = object
        self._is_renamed = is_renamed
        self.update_file = update_file
    }
    #else
    public init(color: Color, image: UIImage, title: String, subtitle: String, object: WorkspaceObject, is_renamed: Binding<Bool>, update_file: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.title = title
        self.subtitle = subtitle
        
        self.object = object
        self._is_renamed = is_renamed
        self.update_file = update_file
    }
    #endif
    
    public var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
                {
                    VStack(alignment: .leading)
                    {
                        Text(title)
                            .font(.headline)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                        
                        Text(subtitle)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 8)
                    .hidden()
                    Spacer()
                }
                .background(color.opacity(0.2))
                .background(.thinMaterial)
                .overlay
                {
                    VStack
                    {
                        HStack
                        {
                            #if os(macOS)
                            TextField("Name", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .focused($is_focused)
                                .labelsHidden()
                                .padding()
                                .onSubmit
                                {
                                    object.name = title
                                    update_file()
                                    is_renamed = false
                                }
                                .onExitCommand
                                {
                                    is_renamed = false
                                }
                            #else
                            TextField("Name", text: $title, onCommit: {
                                object.name = title
                                update_file()
                                is_renamed = false
                            })
                                .textFieldStyle(.roundedBorder)
                                .focused($is_focused)
                                .labelsHidden()
                                .padding()
                            #endif
                        }
                    }
                    .onAppear
                    {
                        is_focused = true
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(height: 192)
        .shadow(radius: 8)
    }
}

public struct SmallCardBack: View
{
    @State public var color: Color
    #if os(macOS)
    @State public var image: NSImage
    #else
    @State public var image: UIImage
    #endif
    @State public var title: String
    @State public var object: WorkspaceObject
    
    @Binding public var is_renamed: Bool
    
    @FocusState private var is_focused: Bool
    
    let update_file: () -> ()
    
    #if os(macOS)
    public init(color: Color, image: NSImage, title: String, object: WorkspaceObject, is_renamed: Binding<Bool>, update_file: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.title = title
        
        self.object = object
        self._is_renamed = is_renamed
        self.update_file = update_file
    }
    #else
    public init(color: Color, image: UIImage, title: String, object: WorkspaceObject, is_renamed: Binding<Bool>, update_file: @escaping () -> ())
    {
        self.color = color
        self.image = image
        self.title = title
        
        self.object = object
        self._is_renamed = is_renamed
        self.update_file = update_file
    }
    #endif
    
    public var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    HStack(spacing: 0)
                    {
                        #if os(macOS)
                        TextField("Name", text: $title)
                            .focused($is_focused)
                            .labelsHidden()
                            .font(.headline)
                            .padding()
                            .onSubmit
                            {
                                object.name = title
                                update_file()
                                is_renamed = false
                            }
                            .onExitCommand
                            {
                                is_renamed = false
                            }
                        #else
                        TextField("Name", text: $title, onCommit: {
                            object.name = title
                            update_file()
                            is_renamed = false
                        })
                            .focused($is_focused)
                            .labelsHidden()
                            .font(.headline)
                            .padding()
                        #endif
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            #endif
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.clear)
                    }
                    .onAppear
                    {
                        is_focused = true
                    }
                    
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 8)
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
