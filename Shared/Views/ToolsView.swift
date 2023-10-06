//
//  ToolsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.03.2022.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers
import IndustrialKit

struct ToolsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_tool_view_presented = false
    @State private var tool_view_presented = false
    @State private var dragged_tool: Tool?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.tools.count > 0
            {
                //MARK: Scroll view for robots
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.tools)
                        { tool_item in
                            ToolCardView(document: $document, tool_item: tool_item)
                            .onDrag({
                                self.dragged_tool = tool_item
                                return NSItemProvider(object: tool_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                LargeCardViewPreview(color: tool_item.card_info.color, image: tool_item.card_info.image, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
                            })
                            .onDrop(of: [UTType.text], delegate: ToolDropDelegate(tools: $base_workspace.tools, dragged_tool: $dragged_tool, document: $document, workspace_tools: base_workspace.file_data().tools, tool: tool_item))
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
                .animation(.spring(), value: base_workspace.tools)
                .modifier(DoubleModifier(update_toggle: $app_state.view_update_state))
            }
            else
            {
                Text("Press «+» to add new tool")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(Color.white)
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_tool_view_presented.toggle() })
                    {
                        Label("Add Tool", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_tool_view_presented)
                    {
                        AddToolView(add_tool_view_presented: $add_tool_view_presented, document: $document)
                    }
                }
            }
        }
    }
}

//MARK: - Tools card view
struct ToolCardView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var tool_item: Tool
    @State private var tool_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        LargeCardView(color: tool_item.card_info.color, image: tool_item.card_info.image, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
            .modifier(CircleDeleteButtonModifier(workspace: base_workspace, object_item: tool_item, objects: base_workspace.tools, on_delete: remove_tools, object_type_name: "tool"))
            .modifier(CardMenu(object: tool_item, clear_preview: tool_item.clear_preview, duplicate_object: {
                base_workspace.duplicate_tool(name: tool_item.name!)
            }, update_file: update_file, pass_preferences: {
                
            }, pass_programs: {
                
            }))
            .onTapGesture
            {
                base_workspace.select_tool(name: tool_item.name!)
                tool_view_presented = true
            }
            .sheet(isPresented: $tool_view_presented)
            {
                ToolView(tool_view_presented: $tool_view_presented, document: $document)
            }
    }
    
    func remove_tools(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.tools.remove(atOffsets: offsets)
            document.preset.tools = base_workspace.file_data().tools
        }
    }
    
    private func update_file()
    {
        document.preset.tools = base_workspace.file_data().tools
    }
}

//MARK: - Drag and Drop delegate
struct ToolDropDelegate : DropDelegate
{
    @Binding var tools : [Tool]
    @Binding var dragged_tool : Tool?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_tools: [ToolStruct]
    
    let tool: Tool
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.tools = workspace_tools //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_tool = self.dragged_tool else
        {
            return
        }
        
        if dragged_tool != tool
        {
            let from = tools.firstIndex(of: dragged_tool)!
            let to = tools.firstIndex(of: tool)!
            withAnimation(.default)
            {
                self.tools.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Add tool view
struct AddToolView:View
{
    @Binding var add_tool_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_tool_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            ToolSceneView_macOS()
                .overlay(alignment: .top)
                {
                    Text("Add Tool")
                        .font(.title2)
                        .padding(8)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding([.top, .leading, .trailing])
                }
            #else
            ToolSceneView_iOS()
                .overlay(alignment: .top)
                {
                    Text("Add Tool")
                        .font(.title2)
                        .padding(8)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding([.top, .leading, .trailing])
                }
            #endif
            
            Divider()
            Spacer()
            
            HStack
            {
                Text("Name")
                    .bold()
                TextField("None", text: $new_tool_name)
                #if os(iOS) || os(visionOS)
                    .textFieldStyle(.roundedBorder)
                #endif
            }
            .padding(.top, 8)
            .padding(.horizontal)
            
            HStack(spacing: 0)
            {
                #if os(iOS) || os(visionOS)
                Spacer()
                #endif
                Picker(selection: $app_state.tool_name, label: Text("Model")
                        .bold())
                {
                    ForEach(app_state.tools, id: \.self)
                    {
                        Text($0)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .buttonStyle(.bordered)
                .padding(.vertical, 8)
                .padding(.leading)
                
                Button("Cancel", action: { add_tool_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: add_tool_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #endif
        .onAppear()
        {
            app_state.update_tool_info()
        }
    }
    
    func add_tool_in_workspace()
    {
        if new_tool_name == ""
        {
            new_tool_name = "None"
        }
        
        app_state.get_scene_image = true
        app_state.previewed_object?.name = new_tool_name
        base_workspace.add_tool(app_state.previewed_object! as! Tool)
        
        document.preset.tools = base_workspace.file_data().tools
        
        add_tool_view_presented.toggle()
    }
}

//MARK: - Tool view
struct ToolView: View
{
    @Binding var tool_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_program_view_presented = false
    @State private var add_operation_view_presented = false
    @State private var new_operation_code = 0
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
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
            HStack(spacing: 0)
            {
                ToolSceneView_macOS()
            }
            .overlay(alignment: .topLeading)
            {
                Button(action: close_tool)
                {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding()
            }
            .overlay(alignment: .bottomLeading)
            {
                HStack(spacing: 0)
                {
                    Button(action: {
                        base_workspace.selected_tool.reset_performing()
                        base_workspace.update_view()
                    })
                    {
                        Image(systemName: "stop")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding([.vertical, .leading])
                    
                    Button(action: {
                        base_workspace.selected_tool.start_pause_performing()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                        {
                            base_workspace.update_view()
                        }
                    })
                    {
                        Image(systemName: "playpause")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .disabled(base_workspace.selected_tool.codes_count == 0)
                .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
            }
            .overlay(alignment: .bottomTrailing)
            {
                HStack(spacing: 0)
                {
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .padding([.vertical, .leading])
                    
                    Button(action: { statistics_view_presented.toggle() })
                    {
                        Image(systemName: "chart.bar")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .padding()
                }
                .disabled(base_workspace.selected_tool.codes_count == 0)
            }
            
            Divider()
            
            ToolInspectorView(document: $document, new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    ToolSceneView_iOS()
                        .overlay(alignment: .bottom)
                    {
                        HStack
                        {
                            Button(action: {
                                base_workspace.selected_tool.reset_performing()
                                base_workspace.update_view()
                            })
                            {
                                Image(systemName: "stop")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                base_workspace.selected_tool.start_pause_performing()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                                {
                                    base_workspace.update_view()
                                }
                            })
                            {
                                Image(systemName: "playpause")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: { connector_view_presented.toggle() })
                            {
                                Image(systemName: "link")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.cancelAction)
                            
                            Button(action: { statistics_view_presented.toggle() })
                            {
                                Image(systemName: "chart.bar")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.cancelAction)
                        }
                        .padding()
                    }
                    
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
                                ToolInspectorView(document: $document, new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                                    //.disabled(base_workspace.selected_robot.performed == true)
                                    .presentationDetents([.medium, .large])
                            }
                            .onDisappear()
                            {
                                program_view_presented = false
                            }
                        }
                    }
                }
                .overlay(alignment: .topLeading)
                {
                    Button(action: close_tool)
                    {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .padding()
                }
                .disabled(base_workspace.selected_tool.codes_count == 0)
                .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
            }
            else
            {
                HStack(spacing: 0)
                {
                    ToolSceneView_iOS()
                }
                .overlay(alignment: .topLeading)
                {
                    Button(action: close_tool)
                    {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    .padding()
                }
                .overlay(alignment: .bottomLeading)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: {
                            base_workspace.selected_tool.reset_performing()
                            base_workspace.update_view()
                        })
                        {
                            Image(systemName: "stop")
                                .frame(height: 16)
                        }
                        .buttonStyle(.bordered)
                        .padding([.vertical, .leading])
                        
                        Button(action: {
                            base_workspace.selected_tool.start_pause_performing()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                            {
                                base_workspace.update_view()
                            }
                        })
                        {
                            Image(systemName: "playpause")
                                .frame(height: 16)
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                    .disabled(base_workspace.selected_tool.codes_count == 0)
                    .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
                }
                .overlay(alignment: .bottomTrailing)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: { connector_view_presented.toggle() })
                        {
                            Image(systemName: "link")
                                .frame(height: 16)
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)
                        .padding([.vertical, .leading])
                        
                        Button(action: { statistics_view_presented.toggle() })
                        {
                            Image(systemName: "chart.bar")
                                .frame(height: 16)
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)
                        .padding()
                    }
                    .disabled(base_workspace.selected_tool.codes_count == 0)
                }
                
                Divider()
                
                ToolInspectorView(document: $document, new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                    .frame(width: 256)
            }
            #endif
        }
        .sheet(isPresented: $connector_view_presented)
        {
            ConnectorView(is_presented: $connector_view_presented, document: $document, demo: $base_workspace.selected_tool.demo, update_model: $base_workspace.selected_tool.update_model_by_connector, connector: base_workspace.selected_tool.connector as WorkspaceObjectConnector, update_file_data: { document.preset.tools = base_workspace.file_data().tools })
        }
        .sheet(isPresented: $statistics_view_presented)
        {
            StatisticsView(is_presented: $statistics_view_presented, document: $document, get_statistics: $base_workspace.selected_tool.get_statistics, charts_data: $base_workspace.selected_tool.charts_data, state_data: $base_workspace.selected_tool.state_data, clear_chart_data: { base_workspace.selected_tool.clear_chart_data() }, clear_state_data: base_workspace.selected_tool.clear_state_data, update_file_data: { document.preset.tools = base_workspace.file_data().tools })
                .onDisappear
                {
                    app_state.get_scene_image = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                    {
                        base_workspace.selected_tool.image = app_state.previewed_object!.image
                    }
                    is_document_updated = true
                }
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 640, maxWidth: 800, minHeight: 400, idealHeight: 480, maxHeight: 600)
        #endif
        .onAppear
        {
            app_state.previewed_object?.node = base_workspace.selected_tool.node
            
            app_state.object_view_was_open = true
            app_state.preview_update_scene = true
            
            app_state.reset_previewed_node_position()
            
            app_state.previewed_object?.image = base_workspace.selected_tool.image
            
            if base_workspace.selected_tool.codes_count > 0
            {
                new_operation_code = base_workspace.selected_tool.codes.first ?? 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                ready_for_save = true
            }
        }
    }
    
    func update_data()
    {
        if ready_for_save
        {
            app_state.get_scene_image = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_tool.image = app_state.previewed_object!.image
                document.preset.tools = base_workspace.file_data().tools
            }
            is_document_updated = true
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        base_workspace.selected_tool.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        update_data()
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            base_workspace.selected_tool.selected_program.codes.remove(atOffsets: offsets)
        }
        
        update_data()
    }
    
    func delete_operations_program()
    {
        if base_workspace.selected_tool.programs_names.count > 0
        {
            let current_spi = base_workspace.selected_tool.selected_program_index
            base_workspace.selected_tool.delete_program(index: current_spi)
            if base_workspace.selected_tool.programs_names.count > 1 && current_spi > 0
            {
                base_workspace.selected_tool.selected_program_index = current_spi - 1
            }
            else
            {
                base_workspace.selected_tool.selected_program_index = 0
            }
            
            update_data()
        }
    }
    
    func add_operation_to_program()
    {
        
        base_workspace.selected_tool.selected_program.add_code(OperationCode(new_operation_code))
        
        document.preset.tools = base_workspace.file_data().tools
        app_state.get_scene_image = true
    }
    
    func close_tool()
    {
        base_workspace.selected_tool.reset_performing()
        base_workspace.selected_tool.workcell_disconnect()
        
        base_workspace.deselect_tool()
        tool_view_presented = false
        
        app_state.object_view_was_open = false
        app_state.preview_update_scene = false
        
        app_state.previewed_object = Tool()
        
        if is_document_updated
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                app_state.view_update_state.toggle()
                base_workspace.update_view()
            }
        }
    }
}

struct ToolInspectorView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var new_operation_code: Int
    
    @State private var add_program_view_presented = false
    @State private var add_operation_view_presented = false
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let remove_codes: (IndexSet) -> ()
    let code_item_move: (IndexSet, Int) -> ()
    let add_operation_to_program: () -> ()
    let delete_operations_program: () -> ()
    let update_data: () -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if base_workspace.selected_tool.codes_count > 0
            {
                Text("Operations")
                    .padding(.vertical)
                
                ZStack
                {
                    List
                    {
                        if base_workspace.selected_tool.programs_count > 0
                        {
                            if base_workspace.selected_tool.selected_program.codes_count > 0
                            {
                                ForEach(base_workspace.selected_tool.selected_program.codes)
                                { code in
                                    OperationItemListView(codes: $base_workspace.selected_tool.selected_program.codes, document: $document, code_item: code, on_delete: remove_codes)
                                        .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                                }
                                .onMove(perform: code_item_move)
                                .onChange(of: base_workspace.tools)
                                { _ in
                                    document.preset.tools = base_workspace.file_data().tools
                                    app_state.get_scene_image = true
                                }
                            }
                        }
                    }
                    #if os(iOS) || os(visionOS)
                    .listStyle(.plain)
                    #endif
                    
                    if base_workspace.selected_tool.programs_count == 0
                    {
                        Text("No program selected")
                            .foregroundColor(.gray)
                    }
                    else
                    {
                        if base_workspace.selected_tool.selected_program.codes_count == 0
                        {
                            Text("Empty Program")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing)
                {
                    ZStack(alignment: .trailing)
                    {
                        Button(action: add_operation_to_program) //Add element button
                        {
                            HStack
                            {
                                Image(systemName: "plus")
                            }
                            .padding()
                        }
                        .disabled(base_workspace.selected_tool.programs_count == 0)
                        #if os(macOS)
                        .frame(maxWidth: 80, alignment: .leading)
                        #else
                        .frame(maxWidth: 86, alignment: .leading)
                        #endif
                        .background(.thinMaterial)
                        .cornerRadius(32)
                        .shadow(radius: 4)
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding()
                        
                        Button(action: { add_operation_view_presented = true }) //Configure new element button
                        {
                            Circle()
                                .foregroundColor(.accentColor)
                                .overlay(
                                    base_workspace.selected_tool.code_info(new_operation_code).image
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: base_workspace.selected_tool.code_info(new_operation_code).image)
                                )
                                .frame(width: 32, height: 32)
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .popover(isPresented: $add_operation_view_presented)
                        {
                            #if os(macOS)
                            HStack
                            {
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes_count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(base_workspace.selected_tool.code_info(code).label)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .padding()
                                .disabled(base_workspace.selected_tool.codes_count == 0)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.radioGroup)
                                .labelsHidden()
                            }
                            #else
                            VStack
                            {
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes_count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(base_workspace.selected_tool.code_info(code).label)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(base_workspace.selected_tool.codes_count == 0)
                                .pickerStyle(.wheel)
                                .frame(maxWidth: 192)
                                .buttonStyle(.borderedProminent)
                            }
                            #endif
                        }
                        .padding(.trailing, 24)
                        
                    }
                    .padding(8)
                }
                
                //Divider()
                
                HStack(spacing: 0)
                {
                    #if os(iOS) || os(visionOS)
                    Text("Program")
                        .font(.subheadline)
                    #endif
                    
                    Picker("Program", selection: $base_workspace.selected_tool.selected_program_index)
                    {
                        if base_workspace.selected_tool.programs_names.count > 0
                        {
                            ForEach(0 ..< base_workspace.selected_tool.programs_names.count, id: \.self)
                            {
                                if base_workspace.selected_tool.programs_names.count > 0
                                {
                                    Text(base_workspace.selected_tool.programs_names[$0])
                                }
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(base_workspace.selected_tool.programs_names.count == 0)
                    .frame(maxWidth: .infinity)
                    #if os(iOS) || os(visionOS)
                    .buttonStyle(.borderedProminent)
                    #endif
                    
                    Button("-")
                    {
                        delete_operations_program()
                    }
                    .disabled(base_workspace.selected_tool.programs_names.count == 0)
                    .padding(.horizontal)
                    
                    Button("+")
                    {
                        add_program_view_presented.toggle()
                    }
                    .popover(isPresented: $add_program_view_presented)
                    {
                        AddOperationProgramView(add_program_view_presented: $add_program_view_presented, selected_program_index: $base_workspace.selected_tool.selected_program_index)
                        #if os(macOS)
                            .frame(height: 72)
                        #else
                            .presentationDetents([.height(96)])
                        #endif
                    }
                    .onChange(of: base_workspace.selected_tool.programs_count)
                    { _ in
                        update_data()
                    }
                }
                .padding()
            }
            else
            {
                Text("This tool has no control")
            }
        }
    }
}

struct OperationDropDelegate: DropDelegate
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

//MARK: Position parameter view
struct OperationParameterView: View
{
    @Binding var position_parameter_view_presented: Bool
    @Binding var parameter_value: Float
    @Binding var limit_min: Float
    @Binding var limit_max: Float
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    parameter_value = 0
                }
                //parameter_value = 0
                position_parameter_view_presented.toggle()
            })
            {
                Image(systemName: "counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 8)
            #endif
            
            TextField("0", value: $parameter_value, format: .number)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
            #endif
            
            Stepper("Enter", value: $parameter_value, in: Float(limit_min)...Float(limit_max))
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        .padding(8)
    }
}

//MARK: Add program view
struct AddOperationProgramView: View
{
    @Binding var add_program_view_presented: Bool
    @Binding var selected_program_index: Int
    
    @State var new_program_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack
        {
            Text("New operations program")
                .font(.title3)
            #if os(macOS)
                .padding(.top, 12)
            #else
                .padding([.leading, .top, .trailing])
                .padding(.bottom, 8)
            #endif
            
            HStack(spacing: 12)
            {
                TextField("None", text: $new_program_name)
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
                    
                    base_workspace.selected_tool.add_program(OperationsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_tool.programs_names.count - 1
                    
                    app_state.get_scene_image = true
                    add_program_view_presented.toggle()
                }
                .fixedSize()
                .keyboardShortcut(.defaultAction)
            }
            .padding([.leading, .bottom, .trailing], 12)
        }
    }
}

//MARK: - Position item view for list
struct OperationItemListView: View
{
    @Binding var codes: [OperationCode]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var code_item: OperationCode
    @State private var new_code_value = 0
    @State private var update_data = false
    
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
                .foregroundColor(base_workspace.selected_tool.inspector_code_color(code: code_item))
            #if os(macOS)
                .padding(.trailing)
            #endif
            
            Picker("Code", selection: $new_code_value)
            {
                if base_workspace.selected_tool.codes_count > 0
                {
                    ForEach(base_workspace.selected_tool.codes, id:\.self)
                    { code in
                        Text(base_workspace.selected_tool.code_info(code).label)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(base_workspace.selected_tool.codes_count == 0)
            .frame(maxWidth: .infinity)
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: new_code_value)
            { newValue in
                if update_data == true
                {
                    code_item.value = new_code_value
                    document.preset.tools = base_workspace.file_data().tools
                }
            }
            base_workspace.selected_tool.code_info(new_code_value).image
            
            Button(action: delete_code_item)
            {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            #if os(macOS)
            .padding(.leading)
            #endif
        }
        .onAppear
        {
            update_data = false
            new_code_value = code_item.value
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                update_data = true
            }
        }
    }
    
    func delete_code_item()
    {
        base_workspace.selected_tool.selected_program.delete_code(index: base_workspace.selected_tool.selected_program.codes.firstIndex(of: code_item) ?? 0)
        document.preset.tools = base_workspace.file_data().tools
    }
}

//MARK: - Scene views
#if os(macOS)
struct ToolSceneView_macOS: NSViewRepresentable
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/View.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = NSColor.clear
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = NSColor.clear
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            app_state.previewed_object?.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_macOS
        
        init(_ control: ToolSceneView_macOS, _ scn_view: SCNView)
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
        @objc func handle_tap(_ gesture_recognize: NSGestureRecognizer)
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
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Tool", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Tool"
            apply_bit_mask(node: app_state.previewed_object!.node ?? SCNNode(), Workspace.tool_bit_mask)
            app_state.preview_update_scene = false
        }
        
        if app_state.object_view_was_open //Provide scene connection to model controller if tool was opened
        {
            base_workspace.selected_tool.workcell_connect(scene: scene_view.scene!, name: "Tool")
            app_state.object_view_was_open = false
        }
        
        if base_workspace.selected_object_type == .tool
        {
            if base_workspace.selected_tool.performing_completed == true
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    base_workspace.selected_tool.performing_completed = false
                    base_workspace.update_view()
                }
            }
            
            if base_workspace.selected_tool.code_changed
            {
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    base_workspace.update_view()
                    base_workspace.selected_tool.code_changed = false
                }
            }
        }
    }
}
#else
struct ToolSceneView_iOS: UIViewRepresentable
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/View.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = UIColor.clear
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        app_state.reset_camera_view_position(workspace: base_workspace, view: ui_view)
        
        if app_state.get_scene_image && workspace_images_store
        {
            app_state.get_scene_image = false
            app_state.previewed_object?.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_iOS
        
        init(_ control: ToolSceneView_iOS, _ scn_view: SCNView)
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
        @objc func handle_tap(_ gesture_recognize: UIGestureRecognizer)
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
    
    func scene_check()
    {
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Tool", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Tool"
            apply_bit_mask(node: app_state.previewed_object!.node ?? SCNNode(), Workspace.tool_bit_mask)
            app_state.preview_update_scene = false
        }
        
        if app_state.object_view_was_open //Provide scene connection to model controller if tool was opened
        {
            base_workspace.selected_tool.workcell_connect(scene: scene_view.scene!, name: "Tool")
            app_state.object_view_was_open = false
        }
        
        if base_workspace.selected_object_type == .tool
        {
            if base_workspace.selected_tool.performing_completed == true
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    base_workspace.selected_tool.performing_completed = false
                    base_workspace.update_view()
                }
            }
            
            if base_workspace.selected_tool.code_changed
            {
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    base_workspace.update_view()
                    base_workspace.selected_tool.code_changed = false
                }
            }
        }
    }
}
#endif

//MARK: - Previews
struct ToolsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ToolsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            AddToolView(add_tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            ToolView(tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            OperationItemListView(codes: .constant([OperationCode]()), document: .constant(Robotic_Complex_WorkspaceDocument()), code_item: OperationCode(1)) { IndexSet in }
            .environmentObject(Workspace())
        }
    }
}
