//
//  RobotsTableView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import IndustrialKit
import UniformTypeIdentifiers

struct RobotsTableView: View
{
    @Binding var robot_view_presented: Bool
    
    @State private var add_robot_view_presented = false
    @State private var dragged_robot: Robot?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.robots.count > 0
            {
                //MARK: Scroll view for robots
                ScrollView(.vertical)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.robots)
                        { robot_item in
                            RobotCardView(robot_view_presented: $robot_view_presented, add_robot_view_presented: $add_robot_view_presented, robot_item: robot_item)
                                .onDrag({
                                    self.dragged_robot = robot_item
                                    return NSItemProvider(object: robot_item.id.uuidString as NSItemProviderWriting)
                                }, preview: {
                                    LargeCardView(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle)
                                })
                                .onDrop(of: [UTType.text], delegate: RobotDropDelegate(robots: $base_workspace.robots, dragged_robot: $dragged_robot, workspace_robots: base_workspace.file_data().robots, robot: robot_item, document_handler: document_handler))
                                .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.robots)
            }
            else
            {
                ContentUnavailableView
                {
                    Label("No robots in preset", systemImage: "r.square")
                }
                description:
                {
                    Text("Press «+» to add new robot")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onDisappear
        {
            //app_state.clear_pass()
            dismiss_pass()
        }
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: .automatic)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_robot_view_presented.toggle() })
                    {
                        Label("Add Robot", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_robot_view_presented)
                    {
                        AddObjectView(is_presented: $add_robot_view_presented, title: "Robot", previewed_object: app_state.previewed_object, previewed_object_name: $app_state.previewed_robot_module_name, internal_modules_list: $app_state.internal_modules_list.robot, external_modules_list: $app_state.external_modules_list.robot)
                        {
                            app_state.update_robot_info()
                        }
                        add_object:
                        { new_name in
                            app_state.previewed_object?.name = new_name

                            base_workspace.add_robot(app_state.previewed_object! as! Robot)
                            document_handler.document_update_robots()
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom)
        {
            if app_state.preferences_pass_mode || app_state.programs_pass_mode
            {
                HStack(spacing: 0)
                {
                    Spacer()
                    HStack(spacing: 0)
                    {
                        Button(action: dismiss_pass)
                        {
                            Text("Cancel")
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)
                        .padding(.trailing)
                        
                        Button(action: perform_pass)
                        {
                            Text("Pass")
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding()
                }
                .background(.thinMaterial)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.1)))
            }
        }
    }
    
    private func dismiss_pass()
    {
        app_state.clear_pass()
        
        if app_state.preferences_pass_mode
        {
            app_state.preferences_pass_mode = false
        }
        else
        {
            app_state.programs_pass_mode = false
        }
    }
    
    private func perform_pass()
    {
        if app_state.preferences_pass_mode
        {
            for robot_to_name in app_state.robots_to_names
            {
                pass_robot_preferences(app_state.origin_location_flag, app_state.origin_rotation_flag, app_state.space_scale_flag, from: app_state.robot_from, to: base_workspace.robot_by_name(robot_to_name))
            }
        }
        
        if app_state.programs_pass_mode
        {
            for robot_to_name in app_state.robots_to_names
            {
                pass_positions_programs(names: app_state.passed_programs_names_list, from: app_state.robot_from, to: base_workspace.robot_by_name(robot_to_name))
            }
        }
        
        document_handler.document_update_robots()
        
        dismiss_pass()
    }
}

struct RobotCardView: View
{
    @Binding var robot_view_presented: Bool
    @Binding var add_robot_view_presented: Bool
    
    @State var robot_item: Robot
    @State private var pass_preferences_presented = false
    @State private var pass_programs_presented = false
    @State private var to_rename = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    var body: some View
    {
        ZStack
        {
            LargeCardView(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle, to_rename: $to_rename, edited_name: $robot_item.name, on_rename: update_file)
            #if !os(visionOS)
                .shadow(radius: 8)
            /*#else
                .frame(depth: 24)*/
            #endif
                .modifier(CardMenu(object: robot_item, to_rename: $to_rename, name: robot_item.name, clear_preview: robot_item.clear_preview, duplicate_object: {
                    base_workspace.duplicate_robot(name: robot_item.name)
                }, delete_object: delete_robot, update_file: update_file, set_default_position: {
                    robot_item.set_default_pointer_position()
                    document_handler.document_update_robots()
                }, clear_default_position: {
                    robot_item.clear_default_pointer_position()
                    document_handler.document_update_robots()
                }, reset_robot_to: robot_item.reset_pointer_to_default, pass_preferences: {
                    app_state.robot_from = robot_item
                    pass_preferences_presented = true
                }, pass_programs: {
                    app_state.robot_from = robot_item
                    pass_programs_presented = true
                }))
        }
        .onTapGesture
        {
            if !app_state.preferences_pass_mode && !app_state.programs_pass_mode
            {
                view_robot(robot_index: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
            }
        }
        .popover(isPresented: $pass_preferences_presented, arrowEdge: default_popover_edge)
        {
            PassPreferencesView(is_presented: $pass_preferences_presented)
                #if os(macOS)
                .frame(width: 192, height: 196)
                #else
                .frame(minWidth: 288, minHeight: 320)
                .presentationDetents([.medium])
                #endif
        }
        .sheet(isPresented: $pass_programs_presented)
        {
            PassProgramsView(is_presented: $pass_programs_presented, items: robot_item.programs_names)
                .fitted()
            #if os(macOS)
                .frame(minWidth: 256, maxWidth: 288, minHeight: 256, maxHeight: 512)
            #endif
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
    }
    
    //MARK: Robots manage functions
    private func view_robot(robot_index: Int)
    {
        base_workspace.select_robot(index: robot_index)
        robot_view_presented = true
        
        #if os(visionOS)
        pendant_controller.view_robot()
        #endif
    }
    
    private func delete_robot()
    {
        withAnimation
        {
            base_workspace.robots.remove(at: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
            base_workspace.elements_check()
            document_handler.document_update_robots()
        }
    }
    
    private func update_file()
    {
        document_handler.document_update_robots()
        if !robot_item.is_placed
        {
            tool_unplace(workspace: base_workspace, from_robot_name: robot_item.name)
        }
        document_handler.document_update_tools()
    }
}

//MARK: - Drag and Drop delegate
struct RobotDropDelegate : DropDelegate
{
    @Binding var robots : [Robot]
    @Binding var dragged_robot : Robot?
    
    @State var workspace_robots: [Robot]
    
    let robot: Robot
    let document_handler: DocumentUpdateHandler
    
    func performDrop(info: DropInfo) -> Bool
    {
        document_handler.document_update_robots() //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_robot = self.dragged_robot else
        {
            return
        }
        
        if dragged_robot != robot
        {
            let from = robots.firstIndex(of: dragged_robot) ?? 0
            let to = robots.firstIndex(of: robot) ?? 0
            withAnimation(.default)
            {
                self.robots.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Previews
#Preview
{
    RobotsTableView(robot_view_presented: .constant(false))
        .environmentObject(AppState())
        .environmentObject(Workspace())
}

#Preview
{
    RobotCardView(robot_view_presented: .constant(false), add_robot_view_presented: .constant(false), robot_item: Robot())
}
