//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit
import Charts
import UniformTypeIdentifiers
import IndustrialKit

struct RobotsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var robot_view_presented = false
    
    var body: some View
    {
        HStack
        {
            if robot_view_presented == false
            {
                //Display robots table view
                RobotsTableView(robot_view_presented: $robot_view_presented, document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                #if os(macOS) || os(iOS)
                    .background(Color.white)
                #endif
            }
            else
            {
                //Display robot view when selected
                RobotView(robot_view_presented: $robot_view_presented, document: $document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #endif
    }
}

struct RobotsTableView: View
{
    @Binding var robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_robot_view_presented = false
    @State private var dragged_robot: Robot?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
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
                            RobotCardView(document: $document, robot_view_presented: $robot_view_presented, add_robot_view_presented: $add_robot_view_presented, robot_item: robot_item)
                                .onDrag({
                                    self.dragged_robot = robot_item
                                    return NSItemProvider(object: robot_item.id.uuidString as NSItemProviderWriting)
                                }, preview: {
                                    LargeCardViewPreview(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle)
                                })
                                .onDrop(of: [UTType.text], delegate: RobotDropDelegate(robots: $base_workspace.robots, dragged_robot: $dragged_robot, document: $document, workspace_robots: base_workspace.file_data().robots, robot: robot_item))
                                .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.robots)
            }
            else
            {
                Text("Press «+» to add new robot")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
            }
        }
        .onDisappear
        {
            app_state.clear_pass()
        }
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_robot_view_presented.toggle() })
                    {
                        Label("Add Robot", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_robot_view_presented)
                    {
                        AddRobotView(add_robot_view_presented: $add_robot_view_presented, document: $document)
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
        
        document.preset.robots = base_workspace.file_data().robots
        
        dismiss_pass()
    }
}

struct RobotCardView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var robot_view_presented: Bool
    @Binding var add_robot_view_presented: Bool
    
    @State var robot_item: Robot
    @State private var pass_preferences_presented = false
    @State private var pass_programs_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        LargeCardView(color: robot_item.card_info.color, image: robot_item.card_info.image, title: robot_item.card_info.title, subtitle: robot_item.card_info.subtitle)
            .modifier(CircleDeleteButtonModifier(workspace: base_workspace, object_item: robot_item, objects: base_workspace.robots, on_delete: delete_robots, object_type_name: "robot"))
            .modifier(CardMenu(object: robot_item, name: robot_item.name ?? "", clear_preview: robot_item.clear_preview, duplicate_object: {
                base_workspace.duplicate_robot(name: robot_item.name!)
            }, update_file: update_file, pass_preferences: {
                app_state.robot_from = robot_item
                pass_preferences_presented = true
            }, pass_programs: {
                app_state.robot_from = robot_item
                pass_programs_presented = true
            }))
        .onTapGesture
        {
            view_robot(robot_index: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
        }
        .popover(isPresented: $pass_preferences_presented, arrowEdge: .bottom)
        {
            PassPreferencesView(is_presented: $pass_preferences_presented)
            #if os(iOS) || os(visionOS)
                .presentationDetents([.height(256)])
            #endif
        }
        .sheet(isPresented: $pass_programs_presented)
        {
            PassProgramsView(is_presented: $pass_programs_presented, items: robot_item.programs_names)
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
    }
    
    //MARK: Robots manage functions
    private func view_robot(robot_index: Int)
    {
        base_workspace.select_robot(index: robot_index)
        self.robot_view_presented = true
    }
    
    private func delete_robots(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.robots.remove(atOffsets: offsets)
            document.preset.robots = base_workspace.file_data().robots
        }
    }
    
    private func update_file()
    {
        document.preset.robots = base_workspace.file_data().robots
    }
}

//MARK: - Drag and Drop delegate
struct RobotDropDelegate : DropDelegate
{
    @Binding var robots : [Robot]
    @Binding var dragged_robot : Robot?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_robots: [RobotStruct]
    
    let robot: Robot
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.robots = workspace_robots //Update file after elements reordering
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
            let from = robots.firstIndex(of: dragged_robot)!
            let to = robots.firstIndex(of: robot)!
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
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_robot_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        #if os(macOS)
        VStack(spacing: 0)
        {
            Text("Add Robot")
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
            Text("Add Robot")
                .font(.title2)
                .padding()
            
            Divider()
            
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
                Button("Save", action: add_robot_in_workspace)
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
        document.preset.robots = base_workspace.file_data().robots
        
        base_workspace.elements_check()
        
        add_robot_view_presented.toggle()
    }
}

//MARK: Robot view
struct RobotView: View
{
    @Binding var robot_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    
    //Picker data for thin window size
    @State private var program_view_presented = false
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            #if os(macOS)
            RobotSceneView(document: $document)
                .onDisappear(perform: close_robot)
            
            Divider()
            
            RobotInspectorView(document: $document)
                .disabled(base_workspace.selected_robot.performed == true)
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    RobotSceneView(document: $document)
                        .padding()
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    
                    HStack
                    {
                        Button(action: { program_view_presented.toggle() })
                        {
                            Text("Inspector")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .padding()
                        .popover(isPresented: $program_view_presented)
                        {
                            VStack
                            {
                                RobotInspectorView(document: $document)
                                    .disabled(base_workspace.selected_robot.performed == true)
                                    .presentationDetents([.medium, .large])
                            }
                            .onDisappear()
                            {
                                program_view_presented = false
                            }
                        }
                    }
                }
                .onDisappear(perform: close_robot)
            }
            else
            {
                RobotSceneView(document: $document)
                    .onDisappear(perform: close_robot)
                RobotInspectorView(document: $document)
                    .disabled(base_workspace.selected_robot.performed == true)
                    .frame(width: 288)
            }
            #endif
        }
        .onAppear()
        {
            base_workspace.selected_robot.clear_finish_handler()
            if base_workspace.selected_robot.programs_count > 0
            {
                base_workspace.selected_robot.select_program(index: 0)
            }
        }
        
        .toolbar
        {
            //MARK: Toolbar items
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: close_robot)
                    {
                        Image(systemName: "rectangle.grid.2x2")
                    }
                    Divider()
                    
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
                        ConnectorView(is_presented: $connector_view_presented, document: $document, demo: $base_workspace.selected_robot.demo, update_model: $base_workspace.selected_robot.update_model_by_connector, connector: base_workspace.selected_robot.connector as WorkspaceObjectConnector, update_file_data: { document.preset.robots = base_workspace.file_data().robots })
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
                    }
                    .sheet(isPresented: $statistics_view_presented)
                    {
                        StatisticsView(is_presented: $statistics_view_presented, document: $document, get_statistics: $base_workspace.selected_robot.get_statistics, charts_data: $base_workspace.selected_robot.charts_data, state_data: $base_workspace.selected_robot.state_data, clear_chart_data: { base_workspace.selected_robot.clear_chart_data() }, clear_state_data: base_workspace.selected_robot.clear_state_data, update_file_data: { document.preset.robots = base_workspace.file_data().robots })
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
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
                }
            }
        }
        .modifier(MenuHandlingModifier(performed: $base_workspace.selected_robot.performed, toggle_perform: base_workspace.selected_robot.start_pause_moving, stop_perform: base_workspace.selected_robot.reset_moving))
    }
    
    func close_robot()
    {
        base_workspace.selected_robot.reset_moving()
        app_state.get_scene_image = true
        robot_view_presented = false
        base_workspace.deselect_robot()
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
            
            VStack(spacing: 0)
            {
                Toggle(isOn: $origin_location)
                {
                    Text("Location")
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom)
                
                Toggle(isOn: $origin_rotation)
                {
                    Text("Rotation")
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom)
                
                Toggle(isOn: $space_scale)
                {
                    Text("Scale")
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom)
            }
            #if os(macOS)
            .frame(width: 96)
            #else
            .frame(maxWidth: .infinity)
            #endif
            
            #if os(iOS) || os(visionOS)
            Spacer()
            #endif
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Dismiss")
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
        #if os(macOS)
        .frame(width: 192)
        #else
        .frame(minWidth: 256)
        #endif
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
            #if os(iOS) || os(visionOS)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            #endif
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Button(action: { is_presented.toggle() })
                {
                    Text("Dismiss")
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
        #if os(macOS)
        .frame(minWidth: 256, maxWidth: 288, minHeight: 256, maxHeight: 512)
        #endif
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
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var origin_move_view_presented = false
    @State private var origin_rotate_view_presented = false
    @State private var space_scale_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS) || os(visionOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        ZStack
        {
            CellSceneView()
            #if os(iOS) || os(visionOS)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .navigationBarTitleDisplayMode(.inline)
            #endif
            
            HStack
            {
                VStack
                {
                    Spacer()
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
                                document.preset.robots = base_workspace.file_data().robots
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
                                document.preset.robots = base_workspace.file_data().robots
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
                                document.preset.robots = base_workspace.file_data().robots
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
                #if os(iOS) || os(visionOS)
                .modifier(MountedPadding(is_padding: horizontal_size_class == .compact))
                #endif
                
                Spacer()
            }
        }
        #if os(iOS) || os(visionOS)
        .modifier(MountedPadding(is_padding: !(horizontal_size_class == .compact)))
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
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
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
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
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
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
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
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
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
        @objc func handle_tap(_ gesture_recognize: UITapGestureRecognizer)
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
        }
    }
    
    func scene_check() //Render functions
    {
        if base_workspace.selected_robot.moving_completed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        
        if base_workspace.selected_robot.performed == true
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
                Stepper("Enter", value: $space_scale[0], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $space_scale[1], in: 2...1000)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $space_scale[2], format: .number)
                    .textFieldStyle(.roundedBorder)
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
                Stepper("Enter", value: $origin_view_pos_location[0], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Y:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_location[1], in: -50...50)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("Z:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_location[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_location[2], in: -50...50)
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
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_rotation[0], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[0], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("P:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_rotation[1], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[1], in: -180...180)
                    .labelsHidden()
            }
            
            HStack(spacing: 8)
            {
                Text("W:")
                    .frame(width: 20)
                TextField("0", value: $origin_view_pos_rotation[2], format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $origin_view_pos_rotation[2], in: -180...180)
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

//MARK: - Robot inspector view
struct RobotInspectorView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_program_view_presented = false
    @State var ppv_presented_location = [false, false, false]
    @State var ppv_presented_rotation = [false, false, false]
    @State private var teach_selection = 0
    @State var dragged_point: SCNNode?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let button_padding = 12.0
    private let teach_items: [String] = ["Location", "Rotation"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Points")
                .padding(.top)
            
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
                                PositionItemListView(points: $base_workspace.selected_robot.selected_program.points, document: $document, point_item: point, on_delete: remove_points)
                                    .onDrag
                                {
                                    return NSItemProvider()
                                }
                            }
                            .onMove(perform: point_item_move)
                            .onChange(of: base_workspace.robots)
                            { _, _ in
                                document.preset.robots = base_workspace.file_data().robots
                                app_state.get_scene_image = true
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding([.horizontal, .top])
                
                if base_workspace.selected_robot.programs_count == 0
                {
                    Text("No program selected")
                        .foregroundColor(.gray)
                }
                else
                {
                    if base_workspace.selected_robot.selected_program.points_count == 0
                    {
                        Text("Empty Program")
                            .foregroundColor(.gray)
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
                    .padding(32)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            //Spacer()
            PositionControl(location: $base_workspace.selected_robot.pointer_location, rotation: $base_workspace.selected_robot.pointer_rotation, scale: $base_workspace.selected_robot.space_scale)
            
            HStack(spacing: 0) //(spacing: 12)
            {
                #if os(iOS) || os(visionOS)
                Text("Program")
                    .font(.subheadline)
                #endif
                
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
                    AddProgramView(add_program_view_presented: $add_program_view_presented, document: $document, selected_program_index: $base_workspace.selected_robot.selected_program_index)
                    #if os(iOS)
                        .presentationDetents([.height(96)])
                    #endif
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    func point_item_move(from source: IndexSet, to destination: Int)
    {
        base_workspace.selected_robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        base_workspace.selected_robot.selected_program.visual_build()
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            base_workspace.selected_robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
    
    func delete_positions_program()
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
            
            document.preset.robots = base_workspace.file_data().robots
            app_state.get_scene_image = true
            base_workspace.update_view()
        }
    }
    
    func add_point_to_program()
    {
        base_workspace.selected_robot.selected_program.add_point(PositionPoint(x: base_workspace.selected_robot.pointer_location[0], y: base_workspace.selected_robot.pointer_location[1], z: base_workspace.selected_robot.pointer_location[2], r: base_workspace.selected_robot.pointer_rotation[0], p: base_workspace.selected_robot.pointer_rotation[1], w: base_workspace.selected_robot.pointer_rotation[2], move_type: .linear))
        
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
        base_workspace.update_view()
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
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
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
                    
                    document.preset.robots = base_workspace.file_data().robots
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
struct PositionItemListView: View
{
    @Binding var points: [PositionPoint]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
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
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionItemView(points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, document: $document, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], is_compact: horizontal_size_class == .compact, on_delete: on_delete)
                    .presentationDetents([.height(576)])
                #endif
            }
            
            Spacer()
            
            Button(action: delete_point_from_program)
            {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
    
    func delete_point_from_program()
    {
        delete_point()
        base_workspace.update_view()
        base_workspace.selected_robot.selected_program.selected_point_index = -1
    }
    
    func delete_point()
    {
        if let index = base_workspace.selected_robot.selected_program.points.firstIndex(of: point_item)
        {
            self.on_delete(IndexSet(integer: index))
        }
    }
}

//MARK: - Position item edit view
struct PositionItemView: View
{
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    @State private var appeared = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
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
            HStack(spacing: 0)
            {
                ForEach(PositionComponents.allCases, id: \.self)
                { position_component in
                    GroupBox(label: Text(position_component.rawValue)
                        .font(.headline))
                    {
                        VStack(spacing: 12)
                        {
                            switch position_component
                            {
                            case .location:
                                ForEach(LocationComponents.allCases, id: \.self)
                                { location_component in
                                    HStack(spacing: 8)
                                    {
                                        Text(location_component.info.text)
                                            .frame(width: 20)
                                        TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            #if os(iOS) || os(visionOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                        Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                            .labelsHidden()
                                    }
                                }
                                .onChange(of: item_view_pos_location)
                                { _, _ in
                                    update_point_location()
                                }
                            case .rotation:
                                ForEach(RotationComponents.allCases, id: \.self)
                                { rotation_component in
                                    HStack(spacing: 8)
                                    {
                                        Text(rotation_component.info.text)
                                            .frame(width: 20)
                                        TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            #if os(iOS) || os(visionOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                        Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                            .labelsHidden()
                                    }
                                    .onChange(of: item_view_pos_rotation)
                                    { _, _ in
                                        update_point_rotation()
                                    }
                                }
                            }
                        }
                    }
                    .padding([.top, .trailing])
                }
            }
            .padding(.leading)
            #else
            if !is_compact
            {
                HStack(spacing: 0)
                {
                    ForEach(PositionComponents.allCases, id: \.self)
                    { position_component in
                        GroupBox(label: Text(position_component.rawValue)
                            .font(.headline))
                        {
                            VStack(spacing: 12)
                            {
                                switch position_component
                                {
                                case .location:
                                    ForEach(LocationComponents.allCases, id: \.self)
                                    { location_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(location_component.info.text)
                                                .frame(width: 20)
                                            TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                                .labelsHidden()
                                        }
                                    }
                                    .onChange(of: item_view_pos_location)
                                    { _, _ in
                                        update_point_location()
                                    }
                                case .rotation:
                                    ForEach(RotationComponents.allCases, id: \.self)
                                    { rotation_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(rotation_component.info.text)
                                                .frame(width: 20)
                                            TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                                .labelsHidden()
                                        }
                                        .onChange(of: item_view_pos_rotation)
                                        { _, _ in
                                            update_point_rotation()
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.top, .trailing])
                    }
                }
                .padding(.leading)
            }
            else
            {
                VStack(spacing: 0)
                {
                    ForEach(PositionComponents.allCases, id: \.self)
                    { position_component in
                        GroupBox(label: Text(position_component.rawValue)
                            .font(.headline))
                        {
                            VStack(spacing: 12)
                            {
                                switch position_component
                                {
                                case .location:
                                    ForEach(LocationComponents.allCases, id: \.self)
                                    { location_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(location_component.info.text)
                                                .frame(width: 20)
                                            TextField("0", value: $item_view_pos_location[location_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_location[location_component.info.index], in: 0...Float(base_workspace.selected_robot.space_scale[location_component.info.index]))
                                                .labelsHidden()
                                        }
                                    }
                                    .onChange(of: item_view_pos_location)
                                    { _, _ in
                                        update_point_location()
                                    }
                                case .rotation:
                                    ForEach(RotationComponents.allCases, id: \.self)
                                    { rotation_component in
                                        HStack(spacing: 8)
                                        {
                                            Text(rotation_component.info.text)
                                                .frame(width: 20)
                                            TextField("0", value: $item_view_pos_rotation[rotation_component.info.index], format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .keyboardType(.decimalPad)
                                            Stepper("Enter", value: $item_view_pos_rotation[rotation_component.info.index], in: -180...180)
                                                .labelsHidden()
                                        }
                                        .onChange(of: item_view_pos_rotation)
                                        { _, _ in
                                            update_point_rotation()
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.horizontal, .top])
                    }
                }
                
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
        document.preset.robots = base_workspace.file_data().robots
        app_state.get_scene_image = true
    }
}

//MARK: - Previews
struct RobotsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            RobotsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            AddRobotView(add_robot_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
            
            RobotView(robot_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            
            OriginRotateView(origin_rotate_view_presented: .constant(true), origin_view_pos_rotation: .constant([0, 0, 0]))
            OriginMoveView(origin_move_view_presented: .constant(true), origin_view_pos_location: .constant([0, 0, 0]))
            SpaceScaleView(space_scale_view_presented: .constant(true), space_scale: .constant([2, 2, 2]))
            
            PositionItemListView(points: .constant([PositionPoint()]), document: .constant(Robotic_Complex_WorkspaceDocument()), point_item: PositionPoint()) { IndexSet in }
                .environmentObject(Workspace())
            
            PositionItemView(points: .constant([PositionPoint()]), point_item: .constant(PositionPoint()), position_item_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), item_view_pos_location: [0, 0, 0], item_view_pos_rotation: [0, 0, 0], on_delete: { _ in })
                .environmentObject(Workspace())
                .environmentObject(AppState())
        }
    }
}
