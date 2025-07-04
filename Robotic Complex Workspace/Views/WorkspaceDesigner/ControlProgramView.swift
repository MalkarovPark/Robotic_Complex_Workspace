//
//  ControlProgramView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 23.12.2022.
//

import SwiftUI
import UniformTypeIdentifiers
import IndustrialKit

struct ControlProgramView: View
{
    @State private var program_columns = Array(repeating: GridItem(.flexible()), count: 1)
    @State private var dragged_element: WorkspaceProgramElement?
    
    //@State private var view_program_as_text: Bool = false
    
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack
        {
            if !app_state.view_program_as_text
            {
                // MARK: Scroll view for program elements
                ScrollView
                {
                    LazyVGrid(columns: program_columns)
                    {
                        ForEach(base_workspace.elements)
                        { element in
                            ProgramElementItemView(elements: $base_workspace.elements, element: element, on_delete: remove_elements)
                            .onDrag({
                                self.dragged_element = element
                                return NSItemProvider(object: element.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                ElementCardView(program_element: element)
                            })
                            .onDrop(of: [UTType.text], delegate: WorkspaceDropDelegate(elements: $base_workspace.elements, dragged_element: $dragged_element, workspace_elements: base_workspace.file_data().elements, element: element, document_handler: document_handler))
                        }
                        .padding(4)
                        
                        Spacer(minLength: 64)
                    }
                    .padding()
                    .disabled(base_workspace.performed)
                }
                .animation(.spring(), value: base_workspace.elements)
                .transition(.move(edge: .leading))
            }
            else
            {
                ControlProgramTextView(elements: $base_workspace.elements)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: app_state.view_program_as_text)
        .overlay(alignment: .bottomTrailing)
        {
            AddProgramElementButton()
        }
        .overlay(alignment: .bottomLeading)
        {
            Button(action: { app_state.view_program_as_text.toggle() })
            {
                ZStack
                {
                    Circle()
                        .foregroundStyle(.thinMaterial)
                        #if !os(visionOS)
                        .shadow(radius: 4)
                        #endif
                    
                    program_representation_image
                        .animation(.easeInOut(duration: 0.2), value: app_state.new_program_element.image)
                        .animation(.easeInOut(duration: 0.2), value: app_state.view_program_as_text)
                }
                .frame(width: 32, height: 32)
            }
            #if !os(visionOS)
            .buttonStyle(BorderlessButtonStyle())
            #endif
            #if os(visionOS)
            .glassBackgroundEffect()
            #endif
            .padding()
            .padding(.vertical, 8)
        }
    }
    
    private func remove_elements(at offsets: IndexSet) // Remove program element function
    {
        withAnimation
        {
            base_workspace.elements.remove(atOffsets: offsets)
        }
        
        document_handler.document_update_elements()
    }
    
    private var program_representation_image: Image
    {
        if app_state.view_program_as_text
        {
            return Image(systemName: "rectangle.grid.1x2")
        }
        else
        {
            return Image(systemName: "text.justify.left")
        }
    }
}

// MARK: New program element button
struct AddProgramElementButton: View
{
    @State private var add_element_view_presented = false
    
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if !os(visionOS)
    @EnvironmentObject var sidebar_controller: SidebarController
    #endif
    
    var body: some View
    {
        ZStack(alignment: .trailing)
        {
            Button(action: add_new_program_element) // Add element button
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
            
            Button(action: { add_element_view_presented.toggle() }) // Configure new element button
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
    
    private func add_new_program_element()
    {
        base_workspace.update_view()
        let new_program_element = app_state.new_program_element
        
        // Add new program element and save to file
        base_workspace.elements.append(element_from_struct(new_program_element.file_info))
        base_workspace.elements_check()
        
        document_handler.document_update_elements()
    }
}

// MARK: - Drag and Drop delegate
struct WorkspaceDropDelegate: DropDelegate
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var dragged_element: WorkspaceProgramElement?
    
    @State var workspace_elements: [WorkspaceProgramElementStruct]
    
    let element: WorkspaceProgramElement
    let document_handler: DocumentUpdateHandler
    
    func performDrop(info: DropInfo) -> Bool
    {
        document_handler.document_update_elements() // Update file after elements reordering
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
            let from = elements.firstIndex(of: dragged_element) ?? 0
            let to = elements.firstIndex(of: element) ?? 0
            withAnimation(.default)
            {
                self.elements.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// MARK: - Workspace program element card view
struct ProgramElementItemView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    
    @State var element: WorkspaceProgramElement
    @State var element_view_presented = false
    @State private var is_current = false
    
    @State private var is_deliting = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ZStack
        {
            ElementCardView(program_element: element)
                .shadow(radius: 8)
                .onTapGesture
            {
                element_view_presented = true
            }
            
            if !is_deliting && !(element is CleanerModifierElement)
            {
                Rectangle()
                    .foregroundStyle(.clear)
                    .popover(isPresented: $element_view_presented,
                             arrowEdge: .trailing)
                    {
                        ElementView(element: $element, on_update: update_program_element)
                        #if os(iOS) || os(visionOS)
                            .presentationDetents([.height(240)])
                        #endif
                    }
            }
        }
        .disabled(is_deliting)
        .contextMenu
        {
            Button(action: duplicate_program_element)
            {
                Label("Duplicate", systemImage: "square.on.square")
            }
            Button(role: .destructive, action: {
                delete_program_element()
            })
            {
                Label("Delete", systemImage: "xmark")
            }
        }
    }
    
    // MARK: Program elements manage functions
    private func update_program_element()
    {
        base_workspace.elements_check()
        document_handler.document_update_elements()
    }
    
    private func duplicate_program_element()
    {
        let new_program_element_data = element.file_info
        var new_program_element = WorkspaceProgramElement()
        
        switch new_program_element_data.identifier
        {
        case .robot_performer:
            new_program_element = RobotPerformerElement(element_struct: new_program_element_data)
        case .tool_performer:
            new_program_element = ToolPerformerElement(element_struct: new_program_element_data)
        case .mover_modifier:
            new_program_element = MoverModifierElement(element_struct: new_program_element_data)
        case .writer_modifier:
            new_program_element = WriterModifierElement(element_struct: new_program_element_data)
        case .math_modifier:
            new_program_element = MathModifierElement(element_struct: new_program_element_data)
        case .changer_modifier:
            new_program_element = ChangerModifierElement(element_struct: new_program_element_data)
        case .observer_modifier:
            new_program_element = ObserverModifierElement(element_struct: new_program_element_data)
        case .cleaner_modifier:
            new_program_element = CleanerModifierElement(element_struct: new_program_element_data)
        case .jump_logic:
            new_program_element = JumpLogicElement(element_struct: new_program_element_data)
        case .comparator_logic:
            new_program_element = ComparatorLogicElement(element_struct: new_program_element_data)
        case .mark_logic:
            new_program_element = MarkLogicElement(element_struct: new_program_element_data)
        case .none:
            break
        }
        
        base_workspace.elements.append(new_program_element)
        
        base_workspace.elements_check()
        document_handler.document_update_elements()
    }
    
    private func delete_program_element()
    {
        is_deliting = true
        if let index = elements.firstIndex(of: element)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
        
        base_workspace.update_view()
        
        element_view_presented.toggle()
    }
}

// MARK: - Add element view
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
                // MARK: Type picker
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
                
                // MARK: Subtype pickers cases
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
        .onAppear(perform: get_parameters)
    }
    
    private func get_parameters()
    {
        switch new_program_element.file_info.identifier
        {
        case .robot_performer:
            element_type = .perofrmer
            performer_type = .robot
        case .tool_performer:
            element_type = .perofrmer
            performer_type = .tool
        case .mover_modifier:
            element_type = .modifier
            modifier_type = .mover
        case .writer_modifier:
            element_type = .modifier
            modifier_type = .writer
        case .math_modifier:
            element_type = .modifier
            modifier_type = .math
        case .changer_modifier:
            element_type = .modifier
            modifier_type = .changer
        case .observer_modifier:
            element_type = .modifier
            modifier_type = .observer
        case .cleaner_modifier:
            element_type = .modifier
            modifier_type = .cleaner
        case .jump_logic:
            element_type = .logic
            logic_type = .jump
        case .comparator_logic:
            element_type = .logic
            logic_type = .comparator
        case .mark_logic:
            element_type = .logic
            logic_type = .mark
        case .none:
            break
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
            case .writer:
                new_program_element = WriterModifierElement()
            case .math:
                new_program_element = MathModifierElement()
            case .changer:
                new_program_element = ChangerModifierElement()
            case .observer:
                new_program_element = ObserverModifierElement()
            case .cleaner:
                new_program_element = CleanerModifierElement()
            }
        case .logic:
            switch logic_type
            {
            case .jump:
                new_program_element = JumpLogicElement()
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
                RobotPerformerElementView(element: $element, on_update: on_update)
            case is ToolPerformerElement:
                ToolPerformerElementView(element: $element, on_update: on_update)
            case is MoverModifierElement:
                MoverElementView(element: $element, on_update: on_update)
            case is WriterModifierElement:
                WriterElementView(element: $element, on_update: on_update)
            case is MathModifierElement:
                MathElementView(element: $element, on_update: on_update)
            case is ChangerModifierElement:
                ChangerElementView(element: $element, on_update: on_update)
            case is ObserverModifierElement:
                ObserverElementView(element: $element, on_update: on_update)
                #if os(macOS)
                    .frame(width: 192)
                #endif
            case is CleanerModifierElement:
                EmptyView()
            case is JumpLogicElement:
                JumpElementView(element: $element, on_update: on_update)
            case is ComparatorLogicElement:
                ComparatorElementView(element: $element, on_update: on_update)
            case is MarkLogicElement:
                MarkLogicElementView(element: $element, on_update: on_update)
            default:
                EmptyView()
            }
        }
        .padding()
    }
}

// MARK: - Type enums
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
    case mover = "Mover"
    case writer = "Writer"
    case math = "Math"
    case changer = "Changer"
    case observer = "Observer"
    case cleaner = "Cleaner"
}

///A logic program element type enum.
public enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case comparator = "Comparator"
    case mark = "Mark"
}

// MARK: - Previews
struct ControlProgramView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ControlProgramView()
                .environmentObject(AppState())
                .environmentObject(Workspace())
                .frame(width: 256)
            
            ElementView(element: .constant(WorkspaceProgramElement()), on_update: {})
        }
    }
}
