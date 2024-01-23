//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct WorkspaceView: View
{
    @AppStorage("WorkspaceVisualModeling") private var workspace_visual_modeling: Bool = true
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var worked = false
    @State private var registers_view_presented = false
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            if workspace_visual_modeling
            {
                VisualWorkspaceView(document: $document)
                    .onDisappear(perform: stop_perform)
                    .onAppear(perform: update_constrainted_positions)
            }
            else
            {
                GalleryWorkspaceView(document: $document)
            }
        }
        #if os(macOS) || os(iOS)
        .inspector(isPresented: $inspector_presented)
        {
            ControlProgramView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        #else
        .popover(isPresented: $inspector_presented)
        {
            ControlProgramView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        #endif
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SafeAreaToggler(enabled: (horizontal_size_class == .compact) || !workspace_visual_modeling))
        #else
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #endif
        .onAppear
        {
            base_workspace.elements_check()
        }
        .sheet(isPresented: $registers_view_presented)
        {
            RegistersDataView(document: $document, is_presented: $registers_view_presented)
                .onDisappear()
                {
                    registers_view_presented = false
                }
            #if os(visionOS)
                .frame(width: 600, height: 600)
            #endif
        }
        .toolbar
        {
            ToolbarItem(placement: compact_placement())
            {
                //MARK: Workspace performing elements
                HStack(alignment: .center)
                {
                    Button(action: { registers_view_presented = true })
                    {
                        Label("Registers", systemImage: "number")
                    }
                    
                    Divider()
                    
                    Button(action: change_cycle)
                    {
                        if base_workspace.cycled
                        {
                            Label("Repeat", systemImage: "repeat")
                        }
                        else
                        {
                            Label("One", systemImage: "repeat.1")
                        }
                    }
                    Button(action: stop_perform)
                    {
                        Label("Reset", systemImage: "stop")
                    }
                    Button(action: toggle_perform)
                    {
                        Label("PlayPause", systemImage: "playpause")
                    }
                    
                    Divider()
                    
                    Button(action: { inspector_presented.toggle() })
                    {
                        #if os(macOS)
                        Image(systemName: "sidebar.right")
                        #else
                        if !(horizontal_size_class == .compact)
                        {
                            Image(systemName: "sidebar.right")
                        }
                        else
                        {
                            Image(systemName: "rectangle.portrait.bottomthird.inset.filled")
                        }
                        #endif
                    }
                }
            }
        }
        .modifier(MenuHandlingModifier(performed: $base_workspace.performed, toggle_perform: toggle_perform, stop_perform: stop_perform))
    }
    
    private func stop_perform()
    {
        if base_workspace.performed
        {
            base_workspace.reset_performing()
            base_workspace.update_view()
        }
    }
    
    private func toggle_perform()
    {
        base_workspace.start_pause_performing()
    }
    
    private func change_cycle()
    {
        base_workspace.cycled.toggle()
    }
    
    private func compact_placement() -> ToolbarItemPlacement
    {
        #if os(iOS) || os(visionOS)
        if horizontal_size_class == .compact
        {
            return .bottomBar
        }
        else
        {
            return .automatic
        }
        #else
        return toolbar_item_placement_trailing
        #endif
    }
    
    private func update_constrainted_positions()
    {
        for placed_tool_name in base_workspace.placed_tools_names
        {
            if !base_workspace.tool_by_name(placed_tool_name).is_attached
            {
                base_workspace.tool_by_name(placed_tool_name).node?.remove_all_constraints()
            }
        }
    }
}

//MARK: - Workspace scene views
struct AddInWorkspaceView: View
{
    @State var selected_robot_name = String()
    @State var selected_tool_name = String()
    @State var selected_part_name = String()
    
    @State var tool_attached = false
    @State var attach_robot_name = String()
    
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var add_in_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @State var is_compact = false
    
    @State var first_select = true //This flag that specifies that the robot was not selected and disables the dismiss() function
    private let add_items: [String] = ["Add Robot", "Add Tool", "Add Part"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Picker("Workspace", selection: $app_state.add_selection)
            {
                ForEach(0..<add_items.count, id: \.self)
                { index in
                    Text(self.add_items[index]).tag(index)
                }
            }
            .onChange(of: app_state.add_selection)
            { _, _ in
                base_workspace.object_pointer_node?.isHidden = true
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top])
            
            //MARK: Object popup menu
            HStack
            {
                switch app_state.add_selection
                {
                case 0:
                    ObjectPickerView(selected_object_name: $selected_robot_name, avaliable_objects_names: .constant(base_workspace.avaliable_robots_names), workspace_object_type: .constant(.robot))
                case 1:
                    ObjectPickerView(selected_object_name: $selected_tool_name, avaliable_objects_names: .constant(base_workspace.avaliable_tools_names), workspace_object_type: .constant(.tool))
                    
                    if base_workspace.avaliable_tools_names.count > 0
                    {
                        Toggle(isOn: $tool_attached)
                        {
                            Image(systemName: "pin.fill")
                        }
                        .toggleStyle(.button)
                    }
                case 2:
                    ObjectPickerView(selected_object_name: $selected_part_name, avaliable_objects_names: .constant(base_workspace.avaliable_parts_names), workspace_object_type: .constant(.part))
                default:
                    Text("None")
                }
            }
            .padding()
            
            Divider()
            
            //MARK: Object position set
            switch app_state.add_selection
            {
            case 0:
                DynamicStack(content: {
                    PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
                }, is_compact: $is_compact, spacing: 16)
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
                { _, _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_robots_names.count == 0)
            case 1:
                ZStack
                {
                    if !tool_attached
                    {
                        DynamicStack(content: {
                            PositionView(location: $base_workspace.selected_tool.location, rotation: $base_workspace.selected_tool.rotation)
                        }, is_compact: $is_compact, spacing: 16)
                        .padding([.horizontal, .top])
                        .onChange(of: [base_workspace.selected_tool.location, base_workspace.selected_tool.rotation])
                        { _, _ in
                            base_workspace.update_object_position()
                        }
                    }
                    else
                    {
                        if base_workspace.attachable_robots_names.count > 0
                        {
                            Picker("Attached to", selection: $attach_robot_name) //Select object name for place in workspace
                            {
                                ForEach(base_workspace.attachable_robots_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            .onAppear
                            {
                                attach_robot_name = base_workspace.attachable_robots_names.first ?? "None"
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            .onDisappear
                            {
                                base_workspace.remove_attachment()
                                tool_attached = false
                            }
                            .onChange(of: attach_robot_name)
                            { _, _ in
                                base_workspace.attach_tool_to(robot_name: attach_robot_name)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding([.horizontal, .top])
                            #if os(iOS) || os(visionOS)
                            .buttonStyle(.bordered)
                            #endif
                        }
                        else
                        {
                            Text("No robots for attach")
                                .padding([.horizontal, .top])
                        }
                    }
                }
                .disabled(base_workspace.avaliable_tools_names.count == 0)
            case 2:
                DynamicStack(content: {
                    PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
                }, is_compact: $is_compact, spacing: 16)
                .padding([.horizontal, .top])
                .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
                { _, _ in
                    base_workspace.update_object_position()
                }
                .disabled(base_workspace.avaliable_parts_names.count == 0)
            default:
                Text("None")
            }
            
            #if os(iOS) || os(visionOS)
            if is_compact
            {
                Spacer()
            }
            #endif
            
            //MARK: Object place button
            HStack
            {
                Button(action: place_object)
                {
                    Text("Place")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .padding()
                .disabled((base_workspace.selected_object_unavaliable ?? true) || (app_state.add_selection == 1 && tool_attached && base_workspace.attachable_robots_names.count == 0))
            }
        }
        .onAppear
        {
            app_state.add_in_view_dismissed = false
            base_workspace.in_visual_edit_mode = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                base_workspace.update_view()
            }
        }
        .onDisappear
        {
            //base_workspace.dismiss_object()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                base_workspace.dismiss_object()
                app_state.add_in_view_dismissed = true
                base_workspace.update_view()
            }
        }
    }
    
    private var add_in_view_disabled: Bool
    {
        if !base_workspace.any_object_selected || !app_state.add_in_view_dismissed || base_workspace.performed
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    private func place_object()
    {
        let type_for_save = base_workspace.selected_object_type
        
        if tool_attached && base_workspace.selected_object_type == .tool
        {
            base_workspace.selected_tool.attached_to = attach_robot_name
            base_workspace.selected_tool.is_attached = true
        }
        
        base_workspace.place_viewed_object()
        
        switch type_for_save
        {
        case .robot:
            document.preset.robots = base_workspace.file_data().robots
            base_workspace.elements_check()
        case .tool:
            document.preset.tools = base_workspace.file_data().tools
            base_workspace.elements_check()
        case .part:
            document.preset.parts = base_workspace.file_data().parts
        default:
            break
        }
        
        add_in_view_presented.toggle()
    }
}

struct ObjectPickerView: View
{
    @Binding var selected_object_name: String
    @Binding var avaliable_objects_names: [String]
    @Binding var workspace_object_type: WorkspaceObjectType
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        if avaliable_objects_names.count > 0
        {
            #if os(iOS) || os(visionOS)
            Text("Name")
                .font(.subheadline)
            #endif
            
            Picker("Name", selection: $selected_object_name) //Select object name for place in workspace
            {
                ForEach(avaliable_objects_names, id: \.self)
                { name in
                    Text(name)
                }
            }
            .onAppear
            {
                base_workspace.view_object_node(type: workspace_object_type, name: selected_object_name)
                
                selected_object_name = avaliable_objects_names.first ?? "None"
            }
            .onChange(of: selected_object_name)
            { _, _ in
                base_workspace.view_object_node(type: workspace_object_type, name: selected_object_name)
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            #if os(iOS) || os(visionOS)
            .buttonStyle(.bordered)
            #endif
        }
        else
        {
            Text("All elements placed")
                .onAppear
            {
                base_workspace.dismiss_object()
            }
        }
    }
}

//MARK: - Previews
struct WorkspaceView_Previews: PreviewProvider
{
    @EnvironmentObject var base_workspace: Workspace
    
    static var previews: some View
    {
        Group
        {
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            AddInWorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()), add_in_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            VisualInfoView(info_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
        }
        #if os(iOS)
        .previewDevice("iPad mini (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
        #endif
    }
}
