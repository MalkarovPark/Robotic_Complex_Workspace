//
//  ControlProgramView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 23.12.2022.
//

import SwiftUI
import UniformTypeIdentifiers
import IndustrialKit

struct ControlProgramView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var program_columns = Array(repeating: GridItem(.flexible()), count: 1)
    @State private var dragged_element: WorkspaceProgramElement?
    @State private var add_element_view_presented = false
    @State private var add_new_element_data = WorkspaceProgramElementStruct()
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
            //MARK: Scroll view for program elements
            ScrollView
            {
                LazyVGrid(columns: program_columns)
                {
                    ForEach(base_workspace.elements)
                    { element in
                        ElementCardView(elements: $base_workspace.elements, document: $document, element_item: element, on_delete: remove_elements)
                        .onDrag({
                            self.dragged_element = element
                            return NSItemProvider(object: element.id.uuidString as NSItemProviderWriting)
                        }, preview: {
                            ElementCardViewPreview(element_item: element)
                        })
                        .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $base_workspace.elements, dragged_element: $dragged_element, document: $document, workspace_elements: base_workspace.file_data().elements, element: element))
                    }
                    .padding(4)
                }
                .padding()
                .disabled(base_workspace.performed)
            }
            .animation(.spring(), value: base_workspace.elements)
            
            //MARK: New program element button
            VStack
            {
                Spacer()
                HStack
                {
                    Spacer()
                    ZStack(alignment: .trailing)
                    {
                        Button(action: add_new_program_element) //Add element button
                        {
                            HStack
                            {
                                Image(systemName: "plus")
                                Spacer()
                            }
                            .padding()
                        }
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
                        
                        Button(action: { add_element_view_presented.toggle() }) //Configure new element button
                        {
                            Circle()
                                .foregroundColor(add_button_color())
                                .overlay(
                                    add_button_image()
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: add_button_image())
                                )
                                .frame(width: 32, height: 32)
                                .animation(.easeInOut(duration: 0.2), value: add_button_color())
                        }
                        .popover(isPresented: $add_element_view_presented)
                        {
                            AddElementView(add_element_view_presented: $add_element_view_presented, add_new_element_data: $add_new_element_data)
                            #if os(iOS)
                                .presentationDetents([.height(128)])
                            #endif
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding(.trailing, 24)
                    }
                }
            }
        }
    }
    
    func add_new_program_element()
    {
        base_workspace.update_view()
        //let new_program_element = WorkspaceProgramElement(element_type: add_new_element_data.element_type, performer_type: add_new_element_data.performer_type, modifier_type: add_new_element_data.modifier_type, logic_type: add_new_element_data.logic_type)
        let new_program_element = WorkspaceProgramElement(element_struct: add_new_element_data)
        
        //Checking for existing workspace components for element selection
        switch new_program_element.element_data.element_type
        {
        case .perofrmer:
            switch new_program_element.element_data.performer_type
            {
            case .robot:
                if base_workspace.placed_robots_names.count > 0
                {
                    new_program_element.element_data.robot_name = base_workspace.placed_robots_names.first!
                    base_workspace.select_robot(name: new_program_element.element_data.robot_name)
                    
                    if base_workspace.selected_robot.programs_count > 0
                    {
                        new_program_element.element_data.program_name = base_workspace.selected_robot.programs_names.first!
                    }
                    base_workspace.deselect_robot()
                }
            case .tool:
                break
            }
        case .modifier:
            break
        case .logic:
            break
        }
        
        //Add new program element and save to file
        base_workspace.elements.append(new_program_element)
        document.preset.elements = base_workspace.file_data().elements
    }
    
    //MARK: Button image by element subtype
    func add_button_image() -> Image
    {
        var badge_image: Image
        
        switch add_new_element_data.element_type
        {
        case .perofrmer:
            switch add_new_element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modifier:
            switch add_new_element_data.modifier_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch add_new_element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "exclamationmark")
            }
        }
        
        return badge_image
    }
    
    //MARK: Button color by element type
    func add_button_color() -> Color
    {
        var badge_color: Color
        
        switch add_new_element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modifier:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
    
    func remove_elements(at offsets: IndexSet) //Remove program element function
    {
        withAnimation
        {
            base_workspace.elements.remove(atOffsets: offsets)
        }
        
        document.preset.elements = base_workspace.file_data().elements
    }
}

//MARK: - Drag and Drop delegate
struct WorkspaceDropDelegate : DropDelegate
{
    @Binding var elements : [WorkspaceProgramElement]
    @Binding var dragged_element : WorkspaceProgramElement?
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var workspace_elements: [WorkspaceProgramElementStruct]
    
    let element: WorkspaceProgramElement
    
    func performDrop(info: DropInfo) -> Bool
    {
        document.preset.elements = workspace_elements //Update file after elements reordering
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_element = self.dragged_element else
        {
            return
        }
        
        if dragged_element != element
        {
            let from = elements.firstIndex(of: dragged_element)!
            let to = elements.firstIndex(of: element)!
            withAnimation(.default)
            {
                self.elements.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Workspace program element card view
struct ElementCardView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var element_item: WorkspaceProgramElement
    @State var element_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        badge_image()
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: badge_image())
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: badge_color())
                    
                    HStack(spacing: 0)
                    {
                        HStack(spacing: 0)
                        {
                            VStack(alignment: .leading)
                            {
                                Text(element_item.subtype)
                                    .font(.title3)
                                    .animation(.easeInOut(duration: 0.2), value: element_item.element_data.element_type.rawValue)
                                Text(element_item.info)
                                    .foregroundColor(.secondary)
                                    .animation(.easeInOut(duration: 0.2), value: element_item.info)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 8)
        .onTapGesture
        {
            element_view_presented.toggle()
        }
        .popover(isPresented: $element_view_presented,
                 arrowEdge: .trailing)
        {
            ElementView(elements: $elements, element_item: $element_item, element_view_presented: $element_view_presented, document: $document, new_element_item_data: element_item.element_data, on_delete: on_delete)
        }
        .overlay(alignment: .topTrailing)
        {
            if base_workspace.is_current_element(element: element_item)
            {
                Circle()
                    .foregroundColor(Color.yellow)
                    .frame(width: 16, height: 16)
                    .padding()
                    .shadow(radius: 8)
                    .transition(AnyTransition.scale)
            }
        }
    }
    
    //MARK: Badge image by element subtype
    func badge_image() -> Image
    {
        var badge_image: Image
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            switch element_item.element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modifier:
            switch element_item.element_data.modifier_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch element_item.element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "exclamationmark")
            }
        }
        
        return badge_image
    }
    
    //MARK: Badge color by element type
    func badge_color() -> Color
    {
        var badge_color: Color
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modifier:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
}

//MARK: - Workspace program element card preview for drag
struct ElementCardViewPreview: View
{
    @State var element_item: WorkspaceProgramElement
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ZStack
                    {
                        badge_image()
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: badge_image())
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(16)
                    
                    HStack(spacing: 0)
                    {
                        HStack(spacing: 0)
                        {
                            VStack(alignment: .leading)
                            {
                                Text(element_item.subtype)
                                    .font(.title3)
                                Text(element_item.info)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    func badge_image() -> Image
    {
        var badge_image: Image
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            switch element_item.element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modifier:
            switch element_item.element_data.modifier_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch element_item.element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    func badge_color() -> Color
    {
        var badge_color: Color
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modifier:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
}

//MARK: - Add element view
struct AddElementView: View
{
    @Binding var add_element_view_presented: Bool
    @Binding var add_new_element_data: WorkspaceProgramElementStruct
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                //MARK: Type picker
                Picker("Type", selection: $add_new_element_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 8)
                
                //MARK: Subtype pickers cases
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch add_new_element_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $add_new_element_data.performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    case .modifier:
                        Picker("Type", selection: $add_new_element_data.modifier_type)
                        {
                            ForEach(ModifierType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    case .logic:
                        Picker("Type", selection: $add_new_element_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
    }
}

struct ElementView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var element_item: WorkspaceProgramElement
    @Binding var element_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var new_element_item_data: WorkspaceProgramElementStruct
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                //MARK: Type picker
                Picker("Type", selection: $new_element_item_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 8)
                
                //MARK: Subtype pickers cases
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch new_element_item_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $new_element_item_data.performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    case .modifier:
                        Picker("Type", selection: $new_element_item_data.modifier_type)
                        {
                            ForEach(ModifierType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    case .logic:
                        Picker("Type", selection: $new_element_item_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .buttonStyle(.bordered)
                        #endif
                    }
                }
            }
            .padding()
            Divider()
            
            Spacer()
            
            //MARK: Type views cases
            VStack
            {
                switch new_element_item_data.element_type
                {
                case .perofrmer:
                    PerformerElementView(performer_type: $new_element_item_data.performer_type, robot_name: $new_element_item_data.robot_name, program_name: $new_element_item_data.program_name, tool_name: $new_element_item_data.tool_name)
                case .modifier:
                    ModifierElementView(modifier_type: $new_element_item_data.modifier_type, object_name: $new_element_item_data.object_name, is_push: $new_element_item_data.is_push, register_index: $new_element_item_data.register_index)
                case .logic:
                    LogicElementView(logic_type: $new_element_item_data.logic_type, mark_name: $new_element_item_data.mark_name, target_mark_name: $new_element_item_data.target_mark_name, compared_value: $new_element_item_data.compared_value)
                }
            }
            .padding()
            
            Spacer()
            
            //MARK: Delete and save buttons
            Divider()
            HStack
            {
                Button("Delete", action: delete_program_element)
                    .padding()
                
                Spacer()
                
                Button("Update", action: update_program_element)
                    .keyboardShortcut(.defaultAction)
                    .padding()
                #if os(macOS)
                    .foregroundColor(Color.white)
                #endif
            }
        }
    }
    
    //MARK: Program elements manage functions
    func update_program_element()
    {
        element_item.element_data = new_element_item_data
        base_workspace.elements_check()
        
        document.preset.elements = base_workspace.file_data().elements
        
        element_view_presented.toggle()
    }
    
    func delete_program_element()
    {
        delete_element()
        base_workspace.update_view()
        
        element_view_presented.toggle()
    }
    
    func delete_element()
    {
        if let index = elements.firstIndex(of: element_item)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
    }
}

//MARK: - Performer element view
struct PerformerElementView: View
{
    @Binding var performer_type: PerformerType
    @Binding var robot_name: String
    @Binding var program_name: String
    @Binding var tool_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_robot: Robot?
    @State private var viewed_tool: Tool?
    
    var body: some View
    {
        VStack
        {
            switch performer_type
            {
            case .robot:
                //MARK: Robot subview
                if base_workspace.placed_robots_names.count > 0
                {
                    //MARK: Robot subview
                    #if os(macOS)
                    Picker("Name", selection: $robot_name) //Robot picker
                    {
                        ForEach(base_workspace.placed_robots_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: robot_name)
                    { _ in
                        viewed_robot = base_workspace.robot_by_name(robot_name)
                        if viewed_robot?.programs_names.count ?? 0 > 0
                        {
                            program_name = viewed_robot?.programs_names.first ?? ""
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if robot_name == ""
                        {
                            robot_name = base_workspace.placed_robots_names.first!
                        }
                        else
                        {
                            viewed_robot = base_workspace.robot_by_name(robot_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.placed_robots_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $program_name) //Robot program picker
                    {
                        if viewed_robot?.programs_names.count ?? 0 > 0
                        {
                            ForEach(viewed_robot!.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(viewed_robot?.programs_names.count == 0)
                    #else
                    GeometryReader
                    { geometry in
                        HStack(spacing: 0)
                        {
                            VStack(spacing: 0)
                            {
                                Text("Name")
                                
                                Picker("Name", selection: $robot_name) //Robot picker
                                {
                                    if base_workspace.placed_robots_names.count > 0
                                    {
                                        ForEach(base_workspace.placed_robots_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .onChange(of: robot_name)
                                { _ in
                                    viewed_robot = base_workspace.robot_by_name(robot_name)
                                    if viewed_robot?.programs_names.count ?? 0 > 0
                                    {
                                        program_name = viewed_robot?.programs_names.first ?? ""
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if robot_name == ""
                                    {
                                        robot_name = base_workspace.placed_robots_names[0]
                                    }
                                    else
                                    {
                                        viewed_robot = base_workspace.robot_by_name(robot_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.placed_robots_names.count == 0)
                                .pickerStyle(.wheel)
                                .compositingGroup()
                                .clipped()
                            }
                            .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                
                            VStack(spacing: 0)
                            {
                                Text("Program")
                                
                                Picker("Program", selection: $program_name) //Robot program picker
                                {
                                    if viewed_robot?.programs_names.count ?? 0 > 0
                                    {
                                        ForEach(viewed_robot!.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(viewed_robot?.programs_names.count == 0)
                                .pickerStyle(.wheel)
                                .compositingGroup()
                                .clipped()
                            }
                            .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                        }
                    }
                    .frame(height: 128)
                    #endif
                }
                else
                {
                    Text("No robots placed in this workspace")
                }
            case .tool:
                //MARK: Tool subview
                if base_workspace.placed_tools_names.count > 0
                {
                    //MARK: tool subview
                    #if os(macOS)
                    Picker("Name", selection: $tool_name) //tool picker
                    {
                        ForEach(base_workspace.placed_tools_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: tool_name)
                    { _ in
                        viewed_tool = base_workspace.tool_by_name(tool_name)
                        if viewed_tool?.programs_names.count ?? 0 > 0
                        {
                            program_name = viewed_tool?.programs_names.first ?? ""
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if tool_name == ""
                        {
                            tool_name = base_workspace.placed_tools_names.first!
                        }
                        else
                        {
                            viewed_tool = base_workspace.tool_by_name(tool_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.placed_tools_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $program_name) //tool program picker
                    {
                        if viewed_tool?.programs_names.count ?? 0 > 0
                        {
                            ForEach(viewed_tool!.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(viewed_tool?.programs_names.count == 0)
                    #else
                    GeometryReader
                    { geometry in
                        HStack(spacing: 0)
                        {
                            VStack(spacing: 0)
                            {
                                Text("Name")
                                
                                Picker("Name", selection: $tool_name) //tool picker
                                {
                                    if base_workspace.placed_tools_names.count > 0
                                    {
                                        ForEach(base_workspace.placed_tools_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .onChange(of: tool_name)
                                { _ in
                                    viewed_tool = base_workspace.tool_by_name(tool_name)
                                    if viewed_tool?.programs_names.count ?? 0 > 0
                                    {
                                        program_name = viewed_tool?.programs_names.first ?? ""
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if tool_name == ""
                                    {
                                        tool_name = base_workspace.placed_tools_names[0]
                                    }
                                    else
                                    {
                                        viewed_tool = base_workspace.tool_by_name(tool_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.placed_tools_names.count == 0)
                                .pickerStyle(.wheel)
                                .compositingGroup()
                                .clipped()
                            }
                            .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                            
                            VStack(spacing: 0)
                            {
                                Text("Program")
                                
                                Picker("Program", selection: $program_name) //tool program picker
                                {
                                    if viewed_tool?.programs_names.count ?? 0 > 0
                                    {
                                        ForEach(viewed_tool!.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(viewed_tool?.programs_names.count == 0)
                                .pickerStyle(.wheel)
                                .compositingGroup()
                                .clipped()
                            }
                            .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                        }
                    }
                    .frame(height: 128)
                    #endif
                }
                else
                {
                    Text("No tools placed in this workspace")
                }
            }
        }
    }
}

//MARK: - Modifier element view
struct ModifierElementView: View
{
    @Binding var modifier_type: ModifierType
    @Binding var object_name: String
    @Binding var is_push: Bool
    @Binding var register_index: Int
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_object: Tool?
    
    var body: some View
    {
        VStack
        {
            switch modifier_type
            {
            case .observer:
                //MARK: Observer subview
                if base_workspace.placed_tools_names.count > 0
                {
                    //MARK: tool subview
                    #if os(macOS)
                    Picker("Name", selection: $object_name) //tool picker
                    {
                        ForEach(base_workspace.placed_tools_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: object_name)
                    { _ in
                        viewed_object = base_workspace.tool_by_name(object_name)
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if object_name == ""
                        {
                            object_name = base_workspace.placed_tools_names.first!
                        }
                        else
                        {
                            viewed_object = base_workspace.tool_by_name(object_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.placed_tools_names.count == 0)
                    .frame(maxWidth: .infinity)
                    #else
                    VStack(spacing: 0)
                    {
                        Text("Name")
                            .padding(.bottom)
                        Picker("Name", selection: $object_name) //tool picker
                        {
                            if base_workspace.placed_tools_names.count > 0
                            {
                                ForEach(base_workspace.placed_tools_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            else
                            {
                                Text("None")
                            }
                        }
                        .onChange(of: object_name)
                        { _ in
                            viewed_object = base_workspace.tool_by_name(object_name)
                            base_workspace.update_view()
                        }
                        .onAppear
                        {
                            if object_name == ""
                            {
                                object_name = base_workspace.placed_tools_names[0]
                            }
                            else
                            {
                                viewed_object = base_workspace.tool_by_name(object_name)
                                base_workspace.update_view()
                            }
                        }
                        .disabled(base_workspace.placed_tools_names.count == 0)
                        .pickerStyle(.wheel)
                        .compositingGroup()
                        .clipped()
                    }
                    .frame(width: 256, height: 128)
                    #endif
                }
                else
                {
                    Text("No tools placed in this workspace")
                }
            case .changer:
                //MARK: Changer subview
                VStack
                {
                    Picker("LR", selection: $is_push)
                    {
                        Image(systemName: "tray.and.arrow.down")
                            .tag(true)
                        Image(systemName: "tray.and.arrow.up")
                            .tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.bottom)
                    
                    HStack(spacing: 8)
                    {
                        Text("Register")
                        TextField("0", value: $register_index, format: .number)
                            .textFieldStyle(.roundedBorder)
                        Stepper("Enter", value: $register_index, in: 0...255)
                            .labelsHidden()
                    }
                }
            }
        }
    }
}

//MARK: - Logic element view
struct LogicElementView: View
{
    @Binding var logic_type: LogicType
    @Binding var mark_name: String
    @Binding var target_mark_name: String
    @Binding var compared_value: Int
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            switch logic_type
            {
            case .jump:
                //MARK: Jump subview
                #if os(macOS)
                HStack
                {
                    Picker("To Mark:", selection: $target_mark_name) //Target mark picker
                    {
                        if base_workspace.marks_names.count > 0
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .onAppear
                    {
                        if base_workspace.marks_names.count > 0 && target_mark_name == ""
                        {
                            target_mark_name = base_workspace.marks_names[0]
                        }
                    }
                    .disabled(base_workspace.marks_names.count == 0)
                }
                #else
                VStack
                {
                    if base_workspace.marks_names.count > 0
                    {
                        Text("To mark:")
                        Picker("To Mark:", selection: $target_mark_name) //Target mark picker
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .onAppear
                        {
                            if base_workspace.marks_names.count > 0 && target_mark_name == ""
                            {
                                target_mark_name = base_workspace.marks_names[0]
                            }
                        }
                        .disabled(base_workspace.marks_names.count == 0)
                        .pickerStyle(.wheel)
                    }
                    else
                    {
                        Text("No marks")
                    }
                }
                #endif
            case .mark:
                //MARK: Mark subview
                HStack
                {
                    Text("Name")
                    TextField("None", text: $mark_name) //Mark name field
                        .textFieldStyle(.roundedBorder)
                }
            default:
                //MARK: Equal subview
                HStack(spacing: 8)
                {
                    Text("Compare with")
                    TextField("0", value: $compared_value, format: .number)
                        .textFieldStyle(.roundedBorder)
                    Stepper("Enter", value: $compared_value, in: 0...255)
                        .labelsHidden()
                }
            }
        }
    }
}

struct ControlProgramView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ControlProgramView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
            ElementCardView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), document: .constant(Robotic_Complex_WorkspaceDocument()), element_item: WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            ElementView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), element_item: .constant(WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)), element_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), new_element_item_data: WorkspaceProgramElementStruct(element_type: .logic, performer_type: .robot, modifier_type: .changer, logic_type: .jump), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            ModifierElementView(modifier_type: .constant(.changer), object_name: .constant("None"), is_push: .constant(true), register_index: .constant(0))
                .environmentObject(Workspace())
            LogicElementView(logic_type: .constant(.mark), mark_name: .constant("Mark Name"), target_mark_name: .constant("Target Mark Name"), compared_value: .constant(0))
        }
    }
}
