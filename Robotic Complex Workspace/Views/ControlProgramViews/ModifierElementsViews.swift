//
//  ModifierElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 26.11.2023.
//

import SwiftUI
import IndustrialKit

struct MoverElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var move_type: ModifierCopyType = .duplicate
    @State private var indices = [Int]()
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _move_type = State(initialValue: (_element.wrappedValue as! MoverModifierElement).move_type)
        _indices = State(initialValue: [(_element.wrappedValue as! MoverModifierElement).from_index, (_element.wrappedValue as! MoverModifierElement).to_index])
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Picker("Type", selection: $move_type)
            {
                ForEach(ModifierCopyType.allCases, id: \.self)
                { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .padding(.trailing)
            
            RegistersSelector(text: "From \(indices[0]) to \(indices[1])", registers_count: base_workspace.registers.count, colors: registers_colors, indices: $indices, names: ["From", "To"])
        }
        .onChange(of: move_type)
        { _, new_value in
            (element as! MoverModifierElement).move_type = new_value
            on_update()
        }
        .onChange(of: indices)
        { _, new_value in
            (element as! MoverModifierElement).from_index = new_value[0]
            (element as! MoverModifierElement).to_index = new_value[1]
            on_update()
        }
    }
}

struct WriterElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var value: Float = 0
    @State private var to_index = [Int]()
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _value = State(initialValue: (_element.wrappedValue as! WriterModifierElement).value)
        _to_index = State(initialValue: [(_element.wrappedValue as! WriterModifierElement).to_index])
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            HStack(spacing: 8)
            {
                Text("Write")
                    .frame(width: 34)
                TextField("0", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(iOS) || os(visionOS)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $value, in: -1000...1000)
                    .labelsHidden()
            }
            .padding(.trailing)
            
            RegistersSelector(text: "to: \(to_index[0])", registers_count: base_workspace.registers.count, colors: registers_colors, indices: $to_index, names: ["To"])
        }
        .onChange(of: value)
        { _, new_value in
            (element as! WriterModifierElement).value = new_value
            on_update()
        }
        .onChange(of: to_index)
        { _, new_value in
            (element as! WriterModifierElement).to_index = new_value[0]
            on_update()
        }
    }
}

struct MathElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State var operation: MathType = .add
    @State var value_index = [Int]()
    @State var value2_index = [Int]()
    
    let on_update: () -> ()
    
    @State private var picker_is_presented = false
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _operation = State(initialValue: (_element.wrappedValue as! MathModifierElement).operation)
        _value_index = State(initialValue: [(_element.wrappedValue as! MathModifierElement).value_index])
        _value2_index = State(initialValue: [(_element.wrappedValue as! MathModifierElement).value2_index])
        
        self.on_update = on_update
    }
    var body: some View
    {
        HStack(spacing: 8)
        {
            Text("Value of")
            
            RegistersSelector(text: "\(value_index[0])", registers_count: base_workspace.registers.count, colors: registers_colors, indices: $value_index, names: ["Value 1"])
            
            Button(operation.rawValue)
            {
                picker_is_presented = true
            }
            .popover(isPresented: $picker_is_presented)
            {
                MathTypePicker(operation: $operation)
                #if os(iOS) || os(visionOS)
                    .presentationDetents([.height(96)])
                #endif
            }
            
            Text("value of")
            
            RegistersSelector(text: "\(value2_index[0])", registers_count: base_workspace.registers.count, colors: registers_colors, indices: $value2_index, names: ["Value 2"])
        }
        .onChange(of: operation)
        { _, new_value in
            (element as! MathModifierElement).operation = new_value
            on_update()
        }
        .onChange(of: value_index)
        { _, new_value in
            (element as! MathModifierElement).value_index = new_value[0]
            on_update()
        }
        .onChange(of: value2_index)
        { _, new_value in
            (element as! MathModifierElement).value2_index = new_value[0]
            on_update()
        }
    }
}

struct MathTypePicker: View
{
    @Binding var operation: MathType
    
    var body: some View
    {
        Picker("Operation", selection: $operation)
        {
            ForEach(MathType.allCases, id: \.self)
            { math_type in
                Text(math_type.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding()
    }
}

struct ChangerElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var module_name = String()
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _module_name = State(initialValue: (_element.wrappedValue as! ChangerModifierElement).module_name)
        
        self.on_update = on_update
    }
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        //MARK: Changer subview
        #if os(macOS)
        HStack
        {
            Picker("Module:", selection: $module_name) //Changer module picker
            {
                if Workspace.changer_modules.count > 0
                {
                    ForEach(Workspace.changer_modules, id: \.self)
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
                if Workspace.changer_modules.count > 0 && module_name == ""
                {
                    module_name = Workspace.changer_modules[0]
                }
            }
            .disabled(Workspace.changer_modules.count == 0)
        }
        .onChange(of: module_name)
        { _, new_value in
            (element as! ChangerModifierElement).module_name = new_value
            on_update()
        }
        #else
        VStack
        {
            if Workspace.changer_modules.count > 0
            {
                Text("Module:")
                Picker("Module:", selection: $module_name) //Target mark picker
                {
                    ForEach(Workspace.changer_modules, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onAppear
                {
                    if Workspace.changer_modules.count > 0 && module_name == ""
                    {
                        module_name = Workspace.changer_modules[0]
                    }
                }
                .disabled(Workspace.changer_modules.count == 0)
                .pickerStyle(.wheel)
            }
            else
            {
                Text("No modules")
            }
        }
        .onChange(of: module_name)
        { _, new_value in
            (element as! ChangerModifierElement).module_name = new_value
            on_update()
        }
        #endif
    }
}

struct OutputValueItmeView: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    @Binding var from: Int
    @Binding var to: Int
    
    var body: some View
    {
        HStack
        {
            Text("From:")
            TextField("0", value: $from, format: .number)
            Stepper("Enter", value: $from, in: 0...10000)
                .labelsHidden()
            
            RegistersSelector(text: "to: \(to)", registers_count: base_workspace.registers.count, colors: registers_colors, indices: binding_for_single($to), names: ["To"])
        }
    }
    
    private func binding_for_single(_ value: Binding<Int>) -> Binding<[Int]>
    {
        Binding(
            get:
                {
                    [value.wrappedValue]
                },
            set:
                { newValue in
                if let firstValue = newValue.first
                {
                    value.wrappedValue = firstValue
                }
            }
        )
    }
}

struct ObserverElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var object_type: ObserverObjectType = .robot
    @State private var object_name = ""
    @State private var from_indices = [Int]()
    @State private var to_indices = [Int]()
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _object_type = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).object_type)
        _object_name = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).object_name)
        _from_indices = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).from_indices)
        _to_indices = State(initialValue: (_element.wrappedValue as! ObserverModifierElement).to_indices)
        
        self.on_update = on_update
    }
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_object: WorkspaceObject?
    
    var body: some View
    {
        //MARK: tool subview
        VStack(spacing: 0)
        {
            Picker("Type", selection: $object_type)
            {
                ForEach(ObserverObjectType.allCases, id: \.self)
                { object_type in
                    Text(object_type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.bottom)
            
            switch object_type
            {
            case .robot:
                if base_workspace.placed_robots_names.count > 0
                {
                    Picker("Name", selection: $object_name) //robot picker
                    {
                        ForEach(base_workspace.placed_robots_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: object_name)
                    { _, new_value in
                        viewed_object = base_workspace.robot_by_name(new_value)
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if object_name == ""
                        {
                            object_name = base_workspace.placed_robots_names[0]
                        }
                        else
                        {
                            viewed_object = base_workspace.robot_by_name(object_name)
                            base_workspace.update_view()
                        }
                    }
                    #if os(iOS) || os(visionOS)
                    .modifier(PickerNamer(name: "Name"))
                    #endif
                    .disabled(base_workspace.placed_robots_names.count == 0)
                    .padding(.bottom)
                }
                
                if base_workspace.placed_robots_names.count > 0
                {
                    if from_indices.count > 0
                    {
                        List
                        {
                            ForEach(from_indices.indices, id: \.self)
                            { index in
                                OutputValueItmeView(from: $from_indices[index], to: $to_indices[index])
                            }
                            .onDelete(perform: delete_item)
                        }
                        #if os(macOS)
                        .frame(width: 256, height: 256)
                        #else
                        .frame(width: 320, height: 256)
                        #endif
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    else
                    {
                        ZStack
                        {
                            #if os(macOS)
                            Rectangle()
                                .foregroundStyle(.white)
                            #endif
                            Text("No items to ouput")
                        }
                        .frame(width: 256, height: 64)
                        #if os(macOS)
                        .modifier(ListBorderer())
                        #endif
                        .padding(.bottom)
                    }
                    
                    Button(action: add_item)
                    {
                        Text("Add")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                else
                {
                    Text("No robots placed")
                }
            case .tool:
                if base_workspace.placed_tools_names.count > 0
                {
                    Picker("Name", selection: $object_name) //tool picker
                    {
                        ForEach(base_workspace.placed_tools_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    .onChange(of: object_name)
                    { _, new_value in
                        viewed_object = base_workspace.tool_by_name(new_value)
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
                    #if os(iOS) || os(visionOS)
                    .modifier(PickerNamer(name: "Name"))
                    #endif
                    .disabled(base_workspace.placed_tools_names.count == 0)
                    .padding(.bottom)
                }
                
                if base_workspace.placed_tools_names.count > 0
                {
                    if from_indices.count > 0
                    {
                        List
                        {
                            ForEach(from_indices.indices, id: \.self)
                            { index in
                                OutputValueItmeView(from: $from_indices[index], to: $to_indices[index])
                            }
                            .onDelete(perform: delete_item)
                        }
                        #if os(macOS)
                        .frame(width: 256, height: 256)
                        #else
                        .frame(width: 320, height: 256)
                        #endif
                        .modifier(ListBorderer())
                        .padding(.bottom)
                    }
                    else
                    {
                        ZStack
                        {
                            #if os(macOS)
                            Rectangle()
                                .foregroundStyle(.white)
                            #endif
                            Text("No items to ouput")
                        }
                        .frame(width: 256, height: 64)
                        #if os(macOS)
                        .modifier(ListBorderer())
                        #endif
                        .padding(.bottom)
                    }
                    
                    Button(action: add_item)
                    {
                        Text("Add")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                else
                {
                    Text("No tools placed")
                }
            }
        }
        .onChange(of: object_type)
        { _, new_value in
            switch object_type
            {
            case .robot:
                if base_workspace.placed_robots_names.count > 0
                {
                    object_name = base_workspace.placed_robots_names[0]
                }
                else
                {
                    object_name = ""
                }
            case .tool:
                if base_workspace.placed_tools_names.count > 0
                {
                    object_name = base_workspace.placed_tools_names[0]
                }
                else
                {
                    object_name = ""
                }
            }
            
            (element as! ObserverModifierElement).object_type = new_value
            on_update()
        }
        .onChange(of: object_name)
        { _, new_value in
            (element as! ObserverModifierElement).object_name = new_value
            on_update()
        }
        .onChange(of: from_indices)
        { _, new_value in
            (element as! ObserverModifierElement).from_indices = new_value
            on_update()
        }
        .onChange(of: to_indices)
        { _, new_value in
            (element as! ObserverModifierElement).to_indices = new_value
            on_update()
        }
    }
    
    func add_item()
    {
        from_indices.append(0)
        to_indices.append(0)
    }
    
    func delete_item(at offsets: IndexSet)
    {
        from_indices.remove(atOffsets: offsets)
        to_indices.remove(atOffsets: offsets)
    }
}

#Preview
{
    MoverElementView(element: .constant(MoverModifierElement()), on_update: {})
        .environmentObject(Workspace())
}

#Preview
{
    ChangerElementView(element: .constant(ChangerModifierElement()), on_update: {})
}

#Preview
{
    WriterElementView(element: .constant(WriterModifierElement()), on_update: {})
        .environmentObject(Workspace())
}

#Preview
{
    ObserverElementView(element: .constant(ObserverModifierElement()), on_update: {})
        .environmentObject(Workspace())
}
