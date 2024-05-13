//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.10.2021.
//

import SwiftUI
import SceneKit
import Charts
import UniformTypeIdentifiers
import IndustrialKit

struct RobotsView: View
{
    @State private var robot_view_presented = false
    
    #if os(macOS)
    @EnvironmentObject var app_state: AppState
    #endif
    
    var body: some View
    {
        ZStack
        {
            if !robot_view_presented
            {
                //Display robots table view
                RobotsTableView(robot_view_presented: $robot_view_presented)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                #if os(macOS) || os(iOS)
                    .background(Color.white)
                #endif
            }
            else
            {
                //Display robot view when selected
                RobotView(robot_view_presented: $robot_view_presented)
                #if os(macOS)
                    .frame(maxWidth: app_state.force_resize_view ? 32 : .infinity, maxHeight: app_state.force_resize_view ? 32 : .infinity)
                #endif
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

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
                ScrollView(.vertical, showsIndicators: true)
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
                Text("Press to add new robot ↑")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
                        AddRobotView(add_robot_view_presented: $add_robot_view_presented)
                        #if os(iOS) || os(visionOS)
                            .presentationDetents([.height(512), .large])
                        #endif
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
                    }
                    #if os(visionOS)
                    .frame(width: 512, height: 512)
                    #endif
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
        .popover(isPresented: $pass_preferences_presented, arrowEdge: .bottom)
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
    
    @State var workspace_robots: [RobotStruct]
    
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

//MARK: - Add robot view
struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    
    @State private var new_robot_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        #if os(macOS)
        VStack(spacing: 0)
        {
            Text("New Robot")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            //MARK: Robot model selection
            VStack
            {
                HStack
                {
                    Text("Name")
                        .bold()
                    TextField("None", text: $new_robot_name)
                }
                
                Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                        .bold())
                {
                    ForEach(app_state.manufacturers, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker(selection: $app_state.series_name, label: Text("Series")
                        .bold())
                {
                    ForEach(app_state.series, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4)
                
                Picker(selection: $app_state.model_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.models, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                
                Button("Save", action: add_robot_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        .controlSize(.regular)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #else
        VStack(spacing: 0)
        {
            Text("New Robot")
                .font(.title2)
                .padding()
            
            #if os(iOS)
            Divider()
            #endif
            
            //MARK: Robot model selection
            Form
            {
                Section(header: Text("Name"))
                {
                    TextField(text: $new_robot_name, prompt: Text("None"))
                    {
                        Text("Name")
                    }
                }
                
                Section(header: Text("Parameters"))
                {
                    Picker(selection: $app_state.manufacturer_name, label: Text("Brand")
                            .bold())
                    {
                        ForEach(app_state.manufacturers, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.series_name, label: Text("Series")
                            .bold())
                    {
                        ForEach(app_state.series, id: \.self)
                        {
                            Text($0)
                        }
                    }
                    
                    Picker(selection: $app_state.model_name, label: Text("Model")
                            .bold())
                    {
                        ForEach(app_state.models, id: \.self)
                        {
                            Text($0)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .buttonStyle(.bordered)
                Button("Add", action: add_robot_in_workspace)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .padding(.leading)
            }
            .padding()
        }
        #endif
    }
    
    func add_robot_in_workspace()
    {
        if new_robot_name == ""
        {
            new_robot_name = "None"
        }
        
        base_workspace.add_robot(Robot(name: new_robot_name, manufacturer: app_state.manufacturer_name, dictionary: app_state.robot_dictionary))
        document_handler.document_update_robots()
        
        add_robot_view_presented.toggle()
    }
}

//MARK: Robot view
struct RobotView: View
{
    @Binding var robot_view_presented: Bool
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @State private var inspector_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    @EnvironmentObject var sidebar_controller: SidebarController
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            RobotSceneView()
                .onDisappear(perform: close_view)
            #if os(iOS) || os(visionOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
                .ignoresSafeArea(.container, edges: !(horizontal_size_class == .compact) ? .bottom : .leading)
            #elseif os(visionOS)
                .ignoresSafeArea(.container, edges: .bottom)
            #endif
        }
        #if !os(visionOS)
        .inspector(isPresented: $inspector_presented)
        {
            RobotInspectorView()
                .disabled(base_workspace.selected_robot.performed)
        }
        #endif
        .onAppear()
        {
            base_workspace.selected_robot.clear_finish_handler()
            if base_workspace.selected_robot.programs_count > 0
            {
                base_workspace.selected_robot.select_program(index: 0)
            }
            
            #if os(macOS)
            app_state.force_resize_view = false
            #endif
        }
        .toolbar
        {
            //MARK: Toolbar items
            ToolbarItem(placement: toolbar_item_placement_leading)
            {
                Button(action: close_robot)
                {
                    #if os(macOS)
                    Image(systemName: "chevron.left")
                    #else
                    Image(systemName: "xmark")
                    #endif
                }
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
            }
            
            ToolbarItem(placement: compact_placement())
            {
                #if !os(visionOS)
                HStack(alignment: .center)
                {
                    
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                    }
                    
                    Button(action: { statistics_view_presented.toggle()
                    })
                    {
                        Image(systemName: "chart.bar")
                    }
                    .sheet(isPresented: $connector_view_presented)
                    {
                        ConnectorView(is_presented: $connector_view_presented, demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_robots() })
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document_handler.document_update_robots() })
                    }
                    
                    Button(action: { base_workspace.selected_robot.reset_moving()
                    })
                    {
                        Image(systemName: "stop")
                    }
                    Button(action: { base_workspace.selected_robot.start_pause_moving()
                    })
                    {
                        Image(systemName: "playpause")
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
                #else
                HStack(alignment: .center, spacing: 0)
                {
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                    }
                    .buttonBorderShape(.circle)
                    .padding(.trailing)
                    
                    Button(action: { statistics_view_presented.toggle()
                    })
                    {
                        Image(systemName: "chart.bar")
                    }
                    .buttonBorderShape(.circle)
                    .sheet(isPresented: $connector_view_presented)
                    {
                        ConnectorView(is_presented: $connector_view_presented, demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_robots() })
                            .frame(width: 512, height: 512)
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document_handler.document_update_robots() })
                            .frame(width: 512, height: 512)
                    }
                }
                #endif
            }
        }
        .modifier(MenuHandlingModifier(performed: $base_workspace.selected_robot.performed, toggle_perform: base_workspace.selected_robot.start_pause_moving, stop_perform: base_workspace.selected_robot.reset_moving))
    }
    
    private func close_view()
    {
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
        #if os(visionOS)
        if sidebar_controller.sidebar_selection != .WorkspaceView
        {
            pendant_controller.view_dismiss()
        }
        else
        {
            pendant_controller.view_workspace()
        }
        #endif
        #if os(macOS)
        app_state.force_resize_view = true
        #endif
        base_workspace.deselect_robot()
    }
    
    private func close_robot()
    {
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
        #if os(macOS)
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        base_workspace.deselect_robot()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
        {
            app_state.force_resize_view = true
            robot_view_presented = false
        }
        #else
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
        base_workspace.deselect_robot()
        #endif
    }
    
    private func compact_placement() -> ToolbarItemPlacement
    {
        #if os(iOS)
        if horizontal_size_class == .compact
        {
            return .bottomBar
        }
        else
        {
            return .automatic
        }
        #else
        return .automatic
        #endif
    }
}

//MARK: Pass preferences view
struct PassPreferencesView: View
{
    @Binding var is_presented: Bool
    
    @State private var origin_location = false
    @State private var origin_rotation = false
    @State private var space_scale = false
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Pass Preferences")
                .font(.title2)
                .padding(.bottom)
            
            List
            {
                Toggle(isOn: $origin_location)
                {
                    Text("Location")
                }
                
                Toggle(isOn: $origin_rotation)
                {
                    Text("Rotation")
                }
                
                Toggle(isOn: $space_scale)
                {
                    Text("Scale")
                }
            }
            .modifier(BackgroundListBorderer())
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding(.trailing)
                
                Button(action: {
                    pass_perform()
                    is_presented.toggle()
                })
                {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!origin_location && !origin_rotation && !space_scale)
            }
        }
        .padding()
    }
    
    private func pass_perform()
    {
        app_state.preferences_pass_mode = true
        
        app_state.origin_location_flag = origin_location
        app_state.origin_rotation_flag = origin_rotation
        app_state.space_scale_flag = space_scale
    }
}

//MARK: Pass programs view
struct PassProgramsView: View
{
    @Binding var is_presented: Bool
    
    @State private var selected_programs = Set<String>()
    @State var items: [String]
    
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Pass Programs")
                .font(.title2)
                .padding(.bottom)
            
            List(items, id: \.self)
            { item in
                Toggle(isOn: Binding(get: {
                    self.selected_programs.contains(item)
                }, set: { new_value in
                    if new_value
                    {
                        self.selected_programs.insert(item)
                    }
                    else
                    {
                        self.selected_programs.remove(item)
                    }
                }))
                {
                    Text(item)
                }
            }
            .modifier(ListBorderer())
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding(.trailing)
                
                Button(action: {
                    pass_perform()
                    is_presented.toggle()
                })
                {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selected_programs.count == 0)
            }
        }
        .padding()
    }
    
    private func pass_perform()
    {
        app_state.programs_pass_mode = true
        app_state.passed_programs_names_list = Array(selected_programs).sorted()
    }
}

//MARK: - Cell scene views
struct RobotSceneView: View
{
    @State private var origin_move_view_presented = false
    @State private var origin_rotate_view_presented = false
    @State private var space_scale_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        CellSceneView()
        #if !os(visionOS)
            .overlay(alignment: .bottomLeading)
            {
                VStack(spacing: 0)
                {
                    Button(action: { origin_rotate_view_presented.toggle() })
                    {
                        Image(systemName: "rotate.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_rotate_view_presented)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        origin_rotate_view_presented.toggle()
                    }
                    Divider()
                    
                    Button(action: { origin_move_view_presented.toggle() })
                    {
                        Image(systemName: "move.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $origin_move_view_presented)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        origin_move_view_presented.toggle()
                    }
                    Divider()
                    
                    Button(action: { space_scale_view_presented.toggle() })
                    {
                        Image(systemName: "scale.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    #if os(iOS)
                    .foregroundColor(.black)
                    #endif
                    .popover(isPresented: $space_scale_view_presented)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        space_scale_view_presented.toggle()
                    }
                    .buttonStyle(.borderless)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(radius: 8)
                .fixedSize(horizontal: true, vertical: false)
                .padding()
            }
        #else
            .ornament(attachmentAnchor: .scene(.bottom))
            {
                HStack(spacing: 0)
                {
                    Button(action: { origin_rotate_view_presented.toggle() })
                    {
                        Image(systemName: "rotate.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $origin_rotate_view_presented)
                    {
                        OriginRotateView(origin_rotate_view_presented: $origin_rotate_view_presented, origin_view_pos_rotation: $base_workspace.selected_robot.origin_rotation)
                            .onChange(of: base_workspace.selected_robot.origin_rotation)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        origin_rotate_view_presented.toggle()
                    }
                    
                    Button(action: { origin_move_view_presented.toggle() })
                    {
                        Image(systemName: "move.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $origin_move_view_presented)
                    {
                        OriginMoveView(origin_move_view_presented: $origin_move_view_presented, origin_view_pos_location: $base_workspace.selected_robot.origin_location)
                            .onChange(of: base_workspace.selected_robot.origin_location)
                        { _, _ in
                            //base_workspace.selected_robot.robot_location_place()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        origin_move_view_presented.toggle()
                    }
                    
                    Button(action: { space_scale_view_presented.toggle() })
                    {
                        Image(systemName: "scale.3d")
                            .imageScale(.large)
                            .padding()
                    }
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $space_scale_view_presented)
                    {
                        SpaceScaleView(space_scale_view_presented: $space_scale_view_presented, space_scale: $base_workspace.selected_robot.space_scale)
                            .onChange(of: base_workspace.selected_robot.space_scale)
                        { _, _ in
                            base_workspace.selected_robot.update_space_scale()
                            base_workspace.update_view()
                            document_handler.document_update_robots()
                            app_state.get_scene_image = true
                        }
                    }
                    .onDisappear
                    {
                        space_scale_view_presented.toggle()
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .labelStyle(.iconOnly)
                .glassBackgroundEffect()
            }
        #endif
    }
}

struct CellSceneView: UIViewRepresentable
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    
    #if os(macOS)
    private let base_camera_position_node = SCNNode()
    #endif
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        
        #if os(macOS)
        base_camera_position_node.position = scene_view.pointOfView?.position ?? SCNVector3(0, 0, 2)
        base_camera_position_node.rotation = scene_view.pointOfView?.rotation ?? SCNVector4Zero
        #endif
        
        #if os(visionOS)
        scene_view.scene?.background.contents = UIColor.clear
        #endif
        
        return scene_view
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        //let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        
        //Add reset double tap recognizer for macOS
        let double_tap_gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_reset_double_tap(_:)))
        double_tap_gesture.numberOfClicksRequired = 2
        scene_view.addGestureRecognizer(double_tap_gesture)
        
        //scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }
    #else
    func makeUIView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        //let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        //scene_view.addGestureRecognizer(tap_gesture_recognizer)
        #if os(visionOS)
        scene_view.backgroundColor = UIColor.clear
        #endif
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        return scn_scene(context: context)
    }
    #endif
    
    #if os(macOS)
    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    #else
    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        //Update commands
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    #endif
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: CellSceneView
        
        init(_ control: CellSceneView, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        
        #if os(macOS)
        private var on_reset_view = false
        #endif
        
        /*@objc func handle_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            let tap_location = gesture_recognize.location(in: scn_view)
            let hit_results = scn_view.hitTest(tap_location, options: [:])
            var result = SCNHitTestResult()
            
            if hit_results.count > 0
            {
                result = hit_results[0]
                
                print(result.localCoordinates)
                print("🍮 tapped – \(result.node.name!)")
            }
        }*/
        
        #if os(macOS)
        @objc func handle_reset_double_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            reset_camera_view_position(locataion: SCNVector3(0, 0, 2), rotation: SCNVector4Zero, view: scn_view)
            
            func reset_camera_view_position(locataion: SCNVector3, rotation: SCNVector4, view: SCNView)
            {
                if !on_reset_view
                {
                    on_reset_view = true
                    
                    let reset_action = SCNAction.group([SCNAction.move(to: control.base_camera_position_node.position, duration: 0.5), SCNAction.rotate(toAxisAngle: control.base_camera_position_node.rotation, duration: 0.5)])
                    scn_view.defaultCameraController.pointOfView?.runAction(
                        reset_action, completionHandler: { self.on_reset_view = false })
                }
            }
        }
        #endif
    }
    
    func scene_check() //Render functions
    {
        //base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
        
        if base_workspace.selected_robot.moving_completed
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        
        if base_workspace.selected_robot.performed
        {
            base_workspace.selected_robot.update_model()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}

//MARK: Scale elements
struct SpaceScaleView: View
{
    @Binding var space_scale_view_presented: Bool
    @Binding var space_scale: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Space Scale")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("X:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[0], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[1], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $space_scale[2], in: 2...1000)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #endif
    }
}

//MARK: Move elements
struct OriginMoveView: View
{
    @Binding var origin_move_view_presented: Bool
    @Binding var origin_view_pos_location: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Origin Location")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("X:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[0], in: -20000...20000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[1], in: -20000...20000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_location[2], in: -20000...20000)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #else
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #endif
    }
}

//MARK: Rotate elements
struct OriginRotateView: View
{
    @Binding var origin_rotate_view_presented: Bool
    @Binding var origin_view_pos_rotation: [Float]
    
    var body: some View
    {
        VStack(spacing: 12)
        {
            Text("Origin Rotation")
                .font(.title3)
                .padding([.top, .leading, .trailing])
            
            HStack(spacing: 8)
            {
                Text("R:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[0], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("P:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[1], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("W:")
                    .frame(width: label_width)
                TextField("0", value: $origin_view_pos_rotation[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $origin_view_pos_rotation[2], in: -180...180)
                    .labelsHidden()
            }
        }
        .padding([.bottom, .leading, .trailing])
        #if os(macOS)
        .frame(minWidth: 128, idealWidth: 192, maxWidth: 256)
        #elseif os(iOS)
        .frame(minWidth: 192, idealWidth: 256, maxWidth: 288)
        #else
        .frame(minWidth: 256, idealWidth: 288, maxWidth: 320)
        #endif
    }
}

#if !os(visionOS)
let label_width = 20.0
#else
let label_width = 26.0
#endif

//MARK: - Robot inspector view
#if !os(visionOS)
struct RobotInspectorView: View
{
    @State private var add_program_view_presented = false
    @State var ppv_presented_location = [false, false, false]
    @State var ppv_presented_rotation = [false, false, false]
    @State private var teach_selection = 0
    @State var dragged_point: SCNNode?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    let button_padding = 12.0
    private let teach_items: [String] = ["Location", "Rotation"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ZStack
            {
                List
                {
                    if base_workspace.selected_robot.programs_count > 0
                    {
                        if base_workspace.selected_robot.selected_program.points_count > 0
                        {
                            ForEach(base_workspace.selected_robot.selected_program.points, id: \.self)
                            { point in
                                PositionItemView(points: $base_workspace.selected_robot.selected_program.points, point_item: point, on_delete: remove_points)
                                    .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                            }
                            .onMove(perform: point_item_move)
                            .onDelete(perform: remove_points)
                            .onChange(of: base_workspace.robots)
                            { _, _ in
                                document_handler.document_update_robots()
                                app_state.get_scene_image = true
                            }
                        }
                    }
                }
                .modifier(BackgroundListBorderer())
                .padding([.horizontal, .top])
                
                if base_workspace.selected_robot.programs_count == 0
                {
                    Text("No program selected")
                        .foregroundColor(.secondary)
                }
                else
                {
                    if base_workspace.selected_robot.selected_program.points_count == 0
                    {
                        Text("Empty Program")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing)
            {
                if base_workspace.selected_robot.programs_count > 0
                {
                    Spacer()
                    Button(action: add_point_to_program)
                    {
                        Image(systemName: "plus")
                            .padding(8)
                    }
                    .disabled(base_workspace.selected_robot.programs_count == 0)
                    #if os(macOS) || os(iOS)
                    .foregroundColor(.white)
                    #endif
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .frame(width: 24, height: 24)
                    .shadow(radius: 4)
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                    .padding(.trailing, 32)
                    .padding(.bottom, 16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            //Spacer()
            PositionControl(location: $base_workspace.selected_robot.pointer_location, rotation: $base_workspace.selected_robot.pointer_rotation, scale: $base_workspace.selected_robot.space_scale)
            
            HStack(spacing: 0) //(spacing: 12)
            {
                Picker("Program", selection: $base_workspace.selected_robot.selected_program_index)
                {
                    if base_workspace.selected_robot.programs_names.count > 0
                    {
                        ForEach(0 ..< base_workspace.selected_robot.programs_names.count, id: \.self)
                        {
                            Text(base_workspace.selected_robot.programs_names[$0])
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .pickerStyle(.menu)
                .disabled(base_workspace.selected_robot.programs_names.count == 0)
                .frame(maxWidth: .infinity)
                #if os(iOS) || os(visionOS)
                .modifier(PickerNamer(name: "Program"))
                #endif
                #if os(visionOS)
                .buttonStyle(.borderedProminent)
                #endif
                
                Button("-")
                {
                    delete_positions_program()
                }
                .disabled(base_workspace.selected_robot.programs_names.count == 0)
                .padding(.horizontal)
                
                Button("+")
                {
                    add_program_view_presented.toggle()
                }
                .popover(isPresented: $add_program_view_presented)
                {
                    AddProgramView(add_program_view_presented: $add_program_view_presented, selected_program_index: $base_workspace.selected_robot.selected_program_index)
                    #if os(iOS)
                        .presentationDetents([.height(96)])
                    #endif
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private func point_item_move(from source: IndexSet, to destination: Int)
    {
        base_workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        base_workspace.selected_robot.selected_program.visual_build()
        
        update_data()
    }
    
    private func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            base_workspace.selected_robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        update_data()
        
        base_workspace.selected_robot.selected_program.selected_point_index = -1
    }
    
    private func delete_positions_program()
    {
        if base_workspace.selected_robot.programs_names.count > 0
        {
            let current_spi = base_workspace.selected_robot.selected_program_index
            base_workspace.selected_robot.delete_program(index: current_spi)
            if base_workspace.selected_robot.programs_names.count > 1 && current_spi > 0
            {
                base_workspace.selected_robot.selected_program_index = current_spi - 1
            }
            else
            {
                base_workspace.selected_robot.selected_program_index = 0
            }
            
            update_data()
        }
    }
    
    private func add_point_to_program()
    {
        base_workspace.selected_robot.selected_program.add_point(PositionPoint(x: base_workspace.selected_robot.pointer_location[0], y: base_workspace.selected_robot.pointer_location[1], z: base_workspace.selected_robot.pointer_location[2], r: base_workspace.selected_robot.pointer_rotation[0], p: base_workspace.selected_robot.pointer_rotation[1], w: base_workspace.selected_robot.pointer_rotation[2]))
        
        update_data()
    }
    
    private func update_data()
    {
        withAnimation
        {
            document_handler.document_update_robots()
            app_state.get_scene_image = true
            base_workspace.update_view()
        }
    }
}

struct PositionDropDelegate: DropDelegate
{
    @Binding var points: [SCNNode]
    @Binding var dragged_point: SCNNode?
    
    let point: SCNNode
    
    func performDrop(info: DropInfo) -> Bool
    {
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_point = self.dragged_point else
        {
            return
        }
        
        if dragged_point != point
        {
            let from = points.firstIndex(of: dragged_point)!
            let to = points.firstIndex(of: point)!
            withAnimation(.default)
            {
                self.points.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: Add program view
struct AddProgramView: View
{
    @Binding var add_program_view_presented: Bool
    @Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack
        {
            HStack(spacing: 12)
            {
                TextField("Name", text: $new_program_name)
                    .frame(minWidth: 128, maxWidth: 256)
                #if os(iOS) || os(visionOS)
                    .frame(idealWidth: 256)
                    .textFieldStyle(.roundedBorder)
                #endif
                
                Button("Add")
                {
                    if new_program_name == ""
                    {
                        new_program_name = "None"
                    }
                    
                    base_workspace.selected_robot.add_program(PositionsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_robot.programs_names.count - 1
                    
                    document_handler.document_update_robots()
                    app_state.get_scene_image = true
                    add_program_view_presented.toggle()
                }
                .fixedSize()
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
    }
}

//MARK: - Position item view for list
struct PositionItemView: View
{
    @Binding var points: [PositionPoint]
    
    @State var point_item: PositionPoint
    @State var position_item_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(base_workspace.selected_robot.inspector_point_color(point: point_item)) //.gray)
            
            Spacer()
            
            VStack
            {
                Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                    .font(.caption)
                
                Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                    .font(.caption)
            }
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .leading)
            {
                #if os(macOS)
                PositionPointView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionPointView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], is_compact: horizontal_size_class == .compact, on_delete: on_delete)
                    .presentationDetents([.height(576)])
                #endif
            }
            
            Spacer()
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
}

//MARK: - Position item edit view
struct PositionPointView: View
{
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    @State private var appeared = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS) || os(visionOS)
    @State var is_compact = false
    #endif
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            HStack
            {
                PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
            }
            .padding([.horizontal, .top])
            #else
            if !is_compact
            {
                HStack
                {
                    PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                }
                .padding([.horizontal, .top])
            }
            else
            {
                VStack
                {
                    PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                }
                .padding([.horizontal, .top])
                
                Spacer()
            }
            #endif
            
            HStack
            {
                Picker("Type", selection: $item_view_pos_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                #if os(macOS)
                .frame(maxWidth: .infinity)
                #else
                .frame(width: 96)
                .buttonStyle(.borderedProminent)
                #endif
                
                Text("Speed")
                #if os(macOS)
                    .frame(width: 40)
                #else
                    .frame(width: 60)
                #endif
                TextField("0", value: $item_view_pos_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(macOS)
                    .frame(width: 48)
                #else
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $item_view_pos_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
            .onChange(of: item_view_pos_type)
            { _, new_value in
                if appeared
                {
                    point_item.move_type = new_value
                    update_workspace_data()
                }
            }
            .onChange(of: item_view_pos_speed)
            { _, new_value in
                if appeared
                {
                    point_item.move_speed = new_value
                    update_workspace_data()
                }
            }
        }
        .onChange(of: item_view_pos_location)
        { _, _ in
            update_point_location()
        }
        .onChange(of: item_view_pos_rotation)
        { _, _ in
            update_point_rotation()
        }
        .onAppear()
        {
            base_workspace.selected_robot.selected_program.selected_point_index = base_workspace.selected_robot.selected_program.points.firstIndex(of: point_item) ?? -1
            
            item_view_pos_type = point_item.move_type
            item_view_pos_speed = point_item.move_speed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                appeared = true
            }
        }
        .onDisappear()
        {
            base_workspace.selected_robot.selected_program.selected_point_index = -1
        }
    }
    
    //MARK: Point manage functions
    func update_point_location()
    {
        point_item.x = item_view_pos_location[0]
        point_item.y = item_view_pos_location[1]
        point_item.z = item_view_pos_location[2]
        
        base_workspace.selected_robot.point_shift(&point_item)
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        point_item.r = item_view_pos_rotation[0]
        point_item.p = item_view_pos_rotation[1]
        point_item.w = item_view_pos_rotation[2]
        
        update_workspace_data()
    }
    
    func update_workspace_data()
    {
        base_workspace.update_view()
        base_workspace.selected_robot.selected_program.visual_build()
        document_handler.document_update_robots()
        app_state.get_scene_image = true
    }
}
#endif

//MARK: - Previews
struct RobotsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            RobotsView()
                .environmentObject(AppState())
                .environmentObject(Workspace())
            AddRobotView(add_robot_view_presented: .constant(true))
                .environmentObject(AppState())
            
            RobotView(robot_view_presented: .constant(true))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            
            OriginRotateView(origin_rotate_view_presented: .constant(true), origin_view_pos_rotation: .constant([0, 0, 0]))
            OriginMoveView(origin_move_view_presented: .constant(true), origin_view_pos_location: .constant([0, 0, 0]))
            SpaceScaleView(space_scale_view_presented: .constant(true), space_scale: .constant([2, 2, 2]))
            
            #if !os(visionOS)
            PositionItemView(points: .constant([PositionPoint()]), point_item: PositionPoint()) { IndexSet in }
                .environmentObject(Workspace())
            
            PositionPointView(points: .constant([PositionPoint()]), point_item: .constant(PositionPoint()), position_item_view_presented: .constant(true), item_view_pos_location: [0, 0, 0], item_view_pos_rotation: [0, 0, 0], on_delete: { _ in })
                .environmentObject(Workspace())
                .environmentObject(AppState())
            #endif
        }
    }
}
