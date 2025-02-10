//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.10.2021.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct WorkspaceView: View
{
    @AppStorage("RepresentationType") private var representation_type: RepresentationType = .visual
    
    @State private var worked = false
    @State private var registers_view_presented = false
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class // Horizontal window size handler
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    var body: some View
    {
        ZStack
        {
            switch representation_type
            {
            case .visual:
                VisualWorkspaceView()
                    .onDisappear(perform: stop_perform)
                    .onAppear(perform: update_constrainted_positions)
                #if !os(visionOS)
                    .overlay(alignment: .bottomTrailing)
                    {
                        ViewPendantButton(operation: { inspector_presented.toggle() })
                    }
                #endif
            case .gallery:
                GalleryWorkspaceView()
                #if !os(visionOS)
                    .overlay(alignment: .bottomTrailing)
                    {
                        ViewPendantButton(operation: { inspector_presented.toggle() })
                    }
                #endif
            case .spatial:
                EmptyView()
            }
        }
        #if !os(visionOS)
        .inspector(isPresented: $inspector_presented)
        {
            ControlProgramView()
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        #endif
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) // Window sizes for macOS
        #endif
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .modifier(SafeAreaToggler(enabled: (horizontal_size_class == .compact) || representation_type != .visual))
        #endif
        #if os(visionOS)
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .onAppear
        {
            pendant_controller.view_workspace()
        }
        #endif
        .onAppear
        {
            base_workspace.elements_check()
        }
        .sheet(isPresented: $registers_view_presented)
        {
            RegistersDataView(is_presented: $registers_view_presented)
            {
                document_handler.document_update_registers()
            }
            .onDisappear()
            {
                registers_view_presented = false
            }
            #if os(macOS)
                .frame(width: 420, height: 480)
            #elseif os(visionOS)
                .frame(width: 600, height: 600)
            #endif
        }
        #if !os(visionOS)
        .toolbar(id: "workspace")
        {
            #if !os(visionOS)
            ToolbarItem(id: "Registers")
            {
                Button(action: { registers_view_presented = true })
                {
                    Label("Registers", systemImage: "number")
                }
            }
            
            ToolbarItem(id: "Controls", placement: compact_placement())
            {
                ControlGroup
                {
                    Button(action: change_cycle)
                    {
                        if base_workspace.cycled
                        {
                            Label("Cycle", systemImage: "repeat")
                        }
                        else
                        {
                            Label("Cycle", systemImage: "repeat.1")
                        }
                    }
                    
                    Button(action: stop_perform)
                    {
                        Label("Stop", systemImage: "stop")
                    }
                    
                    Button(action: toggle_perform)
                    {
                        Label("Perform", systemImage: "playpause")
                    }
                }
            }
            #else
            ToolbarItem(id: "Registers")
            {
                Button(action: { registers_view_presented = true })
                {
                    Label("Registers", systemImage: "number")
                }
            }
            
            ToolbarItem(id: "Controls", placement: compact_placement())
            {
                ControlGroup
                {
                    Button(action: change_cycle)
                    {
                        if base_workspace.cycled
                        {
                            Label("Cycle", systemImage: "repeat")
                        }
                        else
                        {
                            Label("Cycle", systemImage: "repeat.1")
                        }
                    }
                    .buttonBorderShape(.circle)
                    .padding(.trailing)
                    
                    #if !os(visionOS)
                    Button(action: stop_perform)
                    {
                        Label("Stop", systemImage: "stop")
                    }
                    
                    Button(action: toggle_perform)
                    {
                        Label("Perform", systemImage: "playpause")
                    }
                    #endif
                }
            }
            #endif
        }
        #endif
        .toolbarRole(.editor)
        .modifier(MenuHandlingModifier(performed: $base_workspace.performed, toggle_perform: toggle_perform, stop_perform: stop_perform))
    }
    
    private func stop_perform()
    {
        base_workspace.reset_performing()
        
        if base_workspace.performed
        {
            base_workspace.update_view()
        }
        
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
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
        
        #if os(visionOS)
        pendant_controller.view_workspace()
        #endif
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
    
    @Binding var add_in_view_presented: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    @State var is_compact = false
    
    @State var first_select = true // This flag that specifies that the robot was not selected and disables the dismiss() function
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
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top])
            
            // MARK: Object popup menu
            switch app_state.add_selection
            {
            case 0:
                AddRobotInWorkspaceView(selected_robot_name: $selected_robot_name, add_in_view_presented: $add_in_view_presented, is_compact: $is_compact)
            case 1:
                AddToolInWorkspaceView(selected_tool_name: $selected_tool_name, tool_attached: $tool_attached, attach_robot_name: $attach_robot_name, add_in_view_presented: $add_in_view_presented, is_compact: $is_compact)
            case 2:
                AddPartInWorkspaceView(selected_part_name: $selected_part_name, add_in_view_presented: $add_in_view_presented, is_compact: $is_compact)
            default:
                EmptyView()
            }
            
            #if os(iOS)
            if is_compact
            {
                Spacer()
            }
            #endif
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
            // base_workspace.dismiss_object()
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
            document_handler.document_update_robots()
            base_workspace.elements_check()
        case .tool:
            document_handler.document_update_tools()
            base_workspace.elements_check()
        case .part:
            document_handler.document_update_parts()
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
            
            Picker("Name", selection: $selected_object_name) // Select object name for place in workspace
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

struct AddRobotInWorkspaceView: View
{
    @Binding var selected_robot_name: String
    
    @Binding var add_in_view_presented: Bool
    @Binding var is_compact: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    @EnvironmentObject var sidebar_controller: SidebarController
    
    var body: some View
    {
        if base_workspace.avaliable_robots_names.count > 0
        {
            HStack
            {
                ObjectPickerView(selected_object_name: $selected_robot_name, avaliable_objects_names: .constant(base_workspace.avaliable_robots_names), workspace_object_type: .constant(.robot))
            }
            .padding()
            
            Divider()
            
            DynamicStack(content: {
                PositionView(location: $base_workspace.selected_robot.location, rotation: $base_workspace.selected_robot.rotation)
            }, is_compact: $is_compact, spacing: 16)
            .padding([.horizontal, .top])
            .onChange(of: [base_workspace.selected_robot.location, base_workspace.selected_robot.rotation])
            { _, _ in
                base_workspace.update_object_position()
            }
            
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
            }
        }
        else
        {
            GroupBox
            {
                VStack(spacing: 0)
                {
                    Text("No avalaible robots")
                        .padding(.bottom)
                    
                    Button(action: new_object)
                    {
                        Label("New", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear
            {
                base_workspace.object_pointer_node?.isHidden = true
                base_workspace.edited_object_node?.removeFromParentNode()
                base_workspace.edited_object_node = SCNNode()
            }
            .frame(height: 160)
            .padding()
        }
    }
    
    private func place_object()
    {
        base_workspace.place_viewed_object()
        
        document_handler.document_update_robots()
        base_workspace.elements_check()
        
        add_in_view_presented.toggle()
    }
    
    private func new_object()
    {
        sidebar_controller.from_workspace_view = true
        sidebar_controller.sidebar_selection = .RobotsView
    }
}

struct AddToolInWorkspaceView: View
{
    @Binding var selected_tool_name: String
    @Binding var tool_attached: Bool
    @Binding var attach_robot_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    @EnvironmentObject var sidebar_controller: SidebarController
    
    @Binding var add_in_view_presented: Bool
    @Binding var is_compact: Bool
    
    var body: some View
    {
        if base_workspace.avaliable_tools_names.count > 0
        {
            HStack
            {
                ObjectPickerView(selected_object_name: $selected_tool_name, avaliable_objects_names: .constant(base_workspace.avaliable_tools_names), workspace_object_type: .constant(.tool))
                
                if base_workspace.avaliable_tools_names.count > 0
                {
                    Toggle(isOn: $tool_attached)
                    {
                        Image(systemName: "pin.fill")
                    }
                    .toggleStyle(.button)
                }
            }
            .padding()
            
            Divider()
            
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
                        Picker("Attached to", selection: $attach_robot_name) // Select object name for place in workspace
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
            }
        }
        else
        {
            GroupBox
            {
                VStack(spacing: 0)
                {
                    Text("No avalaible tools")
                        .padding(.bottom)
                    
                    Button(action: new_object)
                    {
                        Label("New", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear
            {
                base_workspace.object_pointer_node?.isHidden = true
                base_workspace.edited_object_node?.removeFromParentNode()
                base_workspace.edited_object_node = SCNNode()
            }
            .frame(height: 160)
            .padding()
        }
    }
    
    private func place_object()
    {
        if tool_attached
        {
            base_workspace.selected_tool.attached_to = attach_robot_name
            base_workspace.selected_tool.is_attached = true
        }
        
        base_workspace.place_viewed_object()
        
        document_handler.document_update_tools()
        base_workspace.elements_check()
        
        add_in_view_presented.toggle()
    }
    
    private func new_object()
    {
        sidebar_controller.from_workspace_view = true
        sidebar_controller.sidebar_selection = .ToolsView
    }
}

struct AddPartInWorkspaceView: View
{
    @Binding var selected_part_name: String
    
    @Binding var add_in_view_presented: Bool
    @Binding var is_compact: Bool
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    @EnvironmentObject var sidebar_controller: SidebarController
    
    var body: some View
    {
        if base_workspace.avaliable_parts_names.count > 0
        {
            HStack
            {
                ObjectPickerView(selected_object_name: $selected_part_name, avaliable_objects_names: .constant(base_workspace.avaliable_parts_names), workspace_object_type: .constant(.part))
            }
            .padding()
            
            Divider()
            
            DynamicStack(content: {
                PositionView(location: $base_workspace.selected_part.location, rotation: $base_workspace.selected_part.rotation)
            }, is_compact: $is_compact, spacing: 16)
            .padding([.horizontal, .top])
            .onChange(of: [base_workspace.selected_part.location, base_workspace.selected_part.rotation])
            { _, _ in
                base_workspace.update_object_position()
            }
            .disabled(base_workspace.avaliable_parts_names.count == 0)
            
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
            }
        }
        else
        {
            GroupBox
            {
                VStack(spacing: 0)
                {
                    Text("No avalaible parts")
                        .padding(.bottom)
                    
                    Button(action: new_object)
                    {
                        Label("New", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear
            {
                base_workspace.object_pointer_node?.isHidden = true
                base_workspace.edited_object_node?.removeFromParentNode()
                base_workspace.edited_object_node = SCNNode()
            }
            .frame(height: 160)
            .padding()
        }
    }
    
    private func place_object()
    {
        base_workspace.place_viewed_object()
        
        document_handler.document_update_parts()
        
        add_in_view_presented.toggle()
    }
    
    private func new_object()
    {
        sidebar_controller.from_workspace_view = true
        sidebar_controller.sidebar_selection = .PartsView
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
            WorkspaceView()
                .environmentObject(Workspace())
                .environmentObject(AppState())
            AddInWorkspaceView(add_in_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            VisualInfoView(info_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
        }
        #if os(iOS)
        .previewDevice("iPad mini (6th generation)")
        .previewInterfaceOrientation(.landscapeLeft)
        #endif
    }
}
