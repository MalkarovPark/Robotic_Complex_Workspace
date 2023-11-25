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
    
    @EnvironmentObject var app_state: AppState
    //@State private var new_program_element: WorkspaceProgramElement = RobotPerformerElement()
    
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
                        ProgramElementItemView(elements: $base_workspace.elements, document: $document, element: element, on_delete: remove_elements)
                        .onDrag({
                            self.dragged_element = element
                            return NSItemProvider(object: element.id.uuidString as NSItemProviderWriting)
                        }, preview: {
                            ElementCardView(title: element.title, info: element.info, image: element.image, color: element.color)
                        })
                        .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $base_workspace.elements, dragged_element: $dragged_element, document: $document, workspace_elements: base_workspace.file_data().elements, element: element))
                    }
                    .padding(4)
                    
                    Spacer(minLength: 64)
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
                                .foregroundStyle(app_state.new_program_element.color)
                                .overlay(
                                    app_state.new_program_element.image
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: app_state.new_program_element.image)
                                )
                                .frame(width: 32, height: 32)
                                .animation(.easeInOut(duration: 0.2), value: app_state.new_program_element.color)
                        }
                        .popover(isPresented: $add_element_view_presented)
                        {
                            AddElementView(add_element_view_presented: $add_element_view_presented, new_program_element: $app_state.new_program_element)
                            #if os(iOS) || os(visionOS)
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
        let new_program_element = app_state.new_program_element
        
        //Checking for existing workspace components for element selection
        switch new_program_element
        {
        case let element_item as RobotPerformerElement:
            if base_workspace.placed_robots_names.count > 0
            {
                element_item.object_name = base_workspace.placed_robots_names.first!
                base_workspace.select_robot(name: element_item.object_name)
                
                if base_workspace.selected_robot.programs_count > 0
                {
                    element_item.object_name = base_workspace.selected_robot.programs_names.first!
                }
                base_workspace.deselect_robot()
            }
        default:
            break
        }
        
        //Add new program element and save to file
        base_workspace.elements.append(new_program_element)
        document.preset.elements = base_workspace.file_data().elements
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
    
    @State var workspace_elements: [WorkspaceProgramElement]
    
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
struct ProgramElementItemView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State var element: WorkspaceProgramElement
    @State var element_view_presented = false
    @State private var is_current = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ElementCardView(title: element.title, info: element.info, image: element.image, color: element.color, is_current: base_workspace.is_current_element(element: element))
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
            VStack(spacing: 0)
            {
                ElementView(element: $element, on_update: update_program_element)
                
                Divider()
                
                HStack
                {
                    Button(role: .destructive, action: delete_program_element)
                    {
                        Text("Delete")
                    }
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
    }
    
    //MARK: Program elements manage functions
    private func update_program_element()
    {
        base_workspace.elements_check()
        
        document.preset.elements = base_workspace.file_data().elements
        
        //element_view_presented.toggle()
    }
    
    private func delete_program_element()
    {
        if let index = elements.firstIndex(of: element)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
        
        base_workspace.update_view()
        
        element_view_presented.toggle()
    }
}

//MARK: - Add element view
struct AddElementView: View
{
    @Binding var add_element_view_presented: Bool
    @Binding var new_program_element: WorkspaceProgramElement
    
    @State private var element_type: ProgramElementType = .perofrmer
    @State private var performer_type: PerformerType = .robot
    @State private var modifier_type: ModifierType = .mover
    @State private var logic_type: LogicType = .comparator
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                //MARK: Type picker
                Picker("Type", selection: $element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                    .onChange(of: element_type)
                    { _, _ in
                        build_element()
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 8)
                
                //MARK: Subtype pickers cases
                HStack(spacing: 16)
                {
                    #if os(iOS) || os(visionOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch element_type
                    {
                    case .perofrmer:
                        Picker("Type", selection: $performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .onChange(of: performer_type) { _, _ in
                            build_element()
                        }
                    case .modifier:
                        Picker("Type", selection: $modifier_type)
                        {
                            ForEach(ModifierType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .onChange(of: modifier_type) { _, _ in
                            build_element()
                        }
                    case .logic:
                        Picker("Type", selection: $logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .onChange(of: logic_type) { _, _ in
                            build_element()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func build_element()
    {
        switch element_type
        {
        case .perofrmer:
            switch performer_type
            {
            case .robot:
                new_program_element = RobotPerformerElement()
            case .tool:
                new_program_element = ToolPerformerElement()
            }
        case .modifier:
            switch modifier_type
            {
            case .mover:
                new_program_element = MoverModifierElement()
            case .copy:
                new_program_element = CopyModifierElement()
            case .write:
                new_program_element = WriteModifierElement()
            case .clear:
                new_program_element = ClearModifierElement()
            case .changer:
                new_program_element = ChangerModifierElement()
            case .observer:
                new_program_element = ObserverModifierElement()
            }
        case .logic:
            switch logic_type
            {
            case .comparator:
                new_program_element = ComparatorLogicElement()
            case .mark:
                new_program_element = MarkLogicElement()
            }
        }
    }
}

struct ElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    let on_update: () -> ()
    
    var body: some View
    {
        ZStack
        {
            switch element
            {
            case is RobotPerformerElement:
                EmptyView()
            case is ToolPerformerElement:
                EmptyView()
            case is MoverModifierElement:
                EmptyView()
            case is CopyModifierElement:
                EmptyView()
            case is WriteModifierElement:
                EmptyView()
            case is ClearModifierElement:
                EmptyView()
            case is ChangerModifierElement:
                EmptyView()
            case is ObserverModifierElement:
                EmptyView()
            case is ComparatorLogicElement:
                EmptyView()
            case is MarkLogicElement:
                MarkLogicElementView(element: $element, on_update: on_update)
            default:
                EmptyView()
            }
        }
        .padding()
    }
}

/*struct ElementView: View
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
                    #if os(iOS) || os(visionOS)
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
                        #if os(iOS) || os(visionOS)
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
                        #if os(iOS) || os(visionOS)
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
                        #if os(iOS) || os(visionOS)
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
                    ModifierElementView(modifier_type: $new_element_item_data.modifier_type, object_name: $new_element_item_data.object_name, is_push: $new_element_item_data.is_push, register_index: $new_element_item_data.register_index, module_name: $new_element_item_data.module_name)
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
                Button(role: .destructive, action: delete_program_element)
                {
                    Text("Delete")
                }
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
}*/

//MARK: - Type enums
///A program element type enum.
public enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modifier = "Modifier"
    case logic = "Logic"
}

///A performer program element type enum.
public enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
}

///A modifier program element type enum.
public enum ModifierType: String, Codable, Equatable, CaseIterable
{
    case mover = "Move"
    case copy = "Copy"
    case write = "Write"
    case clear = "Clear"
    case changer = "Changer"
    case observer = "Observer"
}

///A logic program element type enum.
public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case comparator = "Comparator"
    case mark = "Mark"
}

//MARK: - Previews
struct ControlProgramView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ControlProgramView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            ElementView(element: .constant(WorkspaceProgramElement()), on_update: {})
        }
    }
}
