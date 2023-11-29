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
                                LargeCardView(color: tool_item.card_info.color, image: tool_item.card_info.image, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle)
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
        #if os(macOS) || os(iOS)
        .background(Color.white)
        #endif
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: .automatic)
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
                        #if os(visionOS)
                            .frame(width: 512, height: 512)
                        #endif
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
    @State private var to_rename = false
    
    @State private var update_toggle = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        LargeCardView(color: tool_item.card_info.color, node: tool_item.node!, title: tool_item.card_info.title, subtitle: tool_item.card_info.subtitle, to_rename: $to_rename, edited_name: $tool_item.name, on_rename: update_file)
            .shadow(radius: 8)
            .modifier(CircleDeleteButtonModifier(workspace: base_workspace, object_item: tool_item, objects: base_workspace.tools, on_delete: remove_tools, object_type_name: "tool"))
            .modifier(CardMenu(object: tool_item, to_rename: $to_rename, clear_preview: tool_item.clear_preview, duplicate_object: {
                base_workspace.duplicate_tool(name: tool_item.name)
            }, update_file: update_file, pass_preferences: {
                
            }, pass_programs: {
                
            }))
            .modifier(DoubleModifier(update_toggle: $update_toggle))
            .onTapGesture
            {
                base_workspace.select_tool(name: tool_item.name)
                tool_view_presented = true
            }
            .sheet(isPresented: $tool_view_presented)
            {
                ToolView(tool_view_presented: $tool_view_presented, document: $document, tool_item: $tool_item)
                #if os(visionOS)
                    .frame(width: 512, height: 512)
                #endif
            }
            .onAppear(perform: remove_tool_constraints)
    }
    
    private func remove_tool_constraints()
    {
        if tool_item.node?.constraints?.count ?? 0 > 0 //tool_item.is_attached
        {
            tool_item.node?.remove_all_constraints()
            tool_item.node?.position = SCNVector3Zero
            tool_item.node?.rotation = SCNVector4Zero
            
            update_toggle.toggle()
        }
    }
    
    private func remove_tools(at offsets: IndexSet)
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
            ToolPreviewSceneView()
                .overlay(alignment: .top)
                {
                    Text("Add Tool")
                        .font(.title2)
                        .padding(8)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding([.top, .leading, .trailing])
                }
            
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
        .onChange(of: app_state.tool_name)
        { _, _ in
            app_state.update_tool_info()
        }
        .onAppear
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
        
        //app_state.get_scene_image = true
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
    @Binding var tool_item: Tool
    
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
                ToolSceneView(tool: $tool_item)
            }
            .modifier(ViewCloseFuncButton(close_action: close_tool))
            .overlay(alignment: .bottomLeading)
            {
                HStack(spacing: 0)
                {
                    Button(action: {
                        tool_item.reset_performing()
                        base_workspace.update_view()
                    })
                    {
                        Image(systemName: "stop")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding([.vertical, .leading])
                    
                    Button(action: {
                        tool_item.start_pause_performing()
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
                .disabled(tool_item.codes_count == 0)
                .modifier(MenuHandlingModifier(performed: $tool_item.performed, toggle_perform: tool_item.start_pause_performing, stop_perform: tool_item.reset_performing))
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
                .disabled(tool_item.codes_count == 0)
            }
            
            Divider()
            
            ToolInspectorView(document: $document, new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    ToolSceneView(tool: $tool_item)
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
                .modifier(ViewCloseFuncButton(close_action: close_tool))
                .disabled(base_workspace.selected_tool.codes_count == 0)
                .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
            }
            else
            {
                HStack(spacing: 0)
                {
                    ToolSceneView(tool: $tool_item)
                }
                .modifier(ViewCloseFuncButton(close_action: close_tool))
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
            ConnectorView(is_presented: $connector_view_presented, document: $document, demo: $base_workspace.selected_tool.demo, update_model: $base_workspace.selected_tool.update_model_by_connector, connector: tool_item.connector as WorkspaceObjectConnector, update_file_data: { document.preset.tools = base_workspace.file_data().tools })
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
        .sheet(isPresented: $statistics_view_presented)
        {
            StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_tool.get_statistics, charts_data: $base_workspace.selected_tool.charts_data, state_data: $tool_item.state_data, clear_chart_data: { tool_item.clear_chart_data() }, clear_state_data: tool_item.clear_state_data, update_file_data: { document.preset.tools = base_workspace.file_data().tools })
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 640, maxWidth: 800, minHeight: 400, idealHeight: 480, maxHeight: 600)
        #endif
        .onAppear
        {
            app_state.preview_update_scene = true
            
            if tool_item.codes_count > 0
            {
                new_operation_code = tool_item.codes.first ?? 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                ready_for_save = true
            }
        }
        .onDisappear
        {
            if is_document_updated
            {
                tool_item.image = app_state.hold_card_image
                app_state.view_update_state.toggle()
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
                document.preset.tools = base_workspace.file_data().tools
                is_document_updated = true
            }
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        tool_item.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        update_data()
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            tool_item.selected_program.codes.remove(atOffsets: offsets)
        }
        
        update_data()
    }
    
    func delete_operations_program()
    {
        if tool_item.programs_names.count > 0
        {
            let current_spi = tool_item.selected_program_index
            tool_item.delete_program(index: current_spi)
            if tool_item.programs_names.count > 1 && current_spi > 0
            {
                tool_item.selected_program_index = current_spi - 1
            }
            else
            {
                tool_item.selected_program_index = 0
            }
            
            update_data()
        }
    }
    
    func add_operation_to_program()
    {
        tool_item.selected_program.add_code(OperationCode(new_operation_code))
        
        update_data()
    }
    
    func close_tool()
    {
        tool_view_presented = false
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
                                    OperationItemView(codes: $base_workspace.selected_tool.selected_program.codes, document: $document, code_item: code, on_delete: remove_codes)
                                        .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                                }
                                .onMove(perform: code_item_move)
                                .onChange(of: base_workspace.tools)
                                { _, _ in
                                    update_data()
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
                        #if os(iOS)
                            .presentationDetents([.height(96)])
                        #endif
                    }
                    .onChange(of: base_workspace.selected_tool.programs_count)
                    { _, _ in
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
                    
                    base_workspace.selected_tool.add_program(OperationsProgram(name: new_program_name))
                    selected_program_index = base_workspace.selected_tool.programs_names.count - 1
                    
                    //app_state.get_scene_image = true
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
struct OperationItemView: View
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
            { _, new_value in
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
struct ToolPreviewSceneView: View
{
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, on_render: update_preview_node(scene_view:), on_tap: { _, _ in })
    }
    
    private func update_preview_node(scene_view: SCNView)
    {
        if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            remove_node?.removeFromParentNode()
            
            app_state.update_tool_info()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Node"
            app_state.preview_update_scene = false
        }
    }
}

struct ToolSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @Binding var tool: Tool
    
    var body: some View
    {
        ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, node: tool.node ?? SCNNode(), on_render: update_view_node(scene_view:), on_tap: { _, _ in })
    }
    
    private func update_view_node(scene_view: SCNView)
    {
        if app_state.preview_update_scene
        {
            let viewed_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            
            apply_bit_mask(node: viewed_node ?? SCNNode(), Workspace.tool_bit_mask)
            
            viewed_node?.remove_all_constraints()
            viewed_node?.position = SCNVector3(x: 0, y: 0, z: 0)
            viewed_node?.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
            
            tool.workcell_connect(scene: scene_view.scene!, name: "Node")
            
            app_state.preview_update_scene = false
        }
        
        if base_workspace.selected_object_type == .tool
        {
            if tool.performing_completed == true
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    tool.performing_completed = false
                    base_workspace.update_view()
                }
            }
            
            if tool.code_changed
            {
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    base_workspace.update_view()
                    tool.code_changed = false
                }
            }
        }
    }
}

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
            ToolView(tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), tool_item: .constant(Tool()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            OperationItemView(codes: .constant([OperationCode]()), document: .constant(Robotic_Complex_WorkspaceDocument()), code_item: OperationCode(1)) { IndexSet in }
            .environmentObject(Workspace())
        }
    }
}
