//
//  LogicElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 26.11.2023.
//

import SwiftUI
import IndustrialKit

struct ComparatorElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State var compare_type: CompareType = .equal
    @State var value_index = [Int]()
    @State var value2_index = [Int]()
    @State var target_mark_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _compare_type = State(initialValue: (_element.wrappedValue as! ComparatorLogicElement).compare_type)
        _value_index = State(initialValue: [(_element.wrappedValue as! ComparatorLogicElement).value_index])
        _value2_index = State(initialValue: [(_element.wrappedValue as! ComparatorLogicElement).value2_index])
        _target_mark_name = State(initialValue: (_element.wrappedValue as! ComparatorLogicElement).target_mark_name)
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            HStack(spacing: 8)
            {
                Text("If value of")
                
                RegistersSelector(text: "\(value_index[0])", indices: $value_index, names: ["Value 1"], cards_colors: registers_colors)
                
                Button(compare_type.rawValue)
                {
                    picker_is_presented = true
                }
                .popover(isPresented: $picker_is_presented)
                {
                    CompareTypePicker(compare_type: $compare_type)
                    #if os(iOS) || os(visionOS)
                        .presentationDetents([.height(96)])
                    #endif
                }
                
                Text("value of")
                
                RegistersSelector(text: "\(value2_index[0])", indices: $value2_index, names: ["Value 2"], cards_colors: registers_colors)
            }
            .padding(.bottom)
            
            HStack
            {
                Picker("jump to:", selection: $target_mark_name) //Target mark picker
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
                .buttonStyle(.bordered)
                .disabled(base_workspace.marks_names.count == 0)
            }
        }
        .onChange(of: compare_type)
        { _, new_value in
            (element as! ComparatorLogicElement).compare_type = new_value
            on_update()
        }
        .onChange(of: value_index)
        { _, new_value in
            (element as! ComparatorLogicElement).value_index = new_value[0]
            on_update()
        }
        .onChange(of: value2_index)
        { _, new_value in
            (element as! ComparatorLogicElement).value2_index = new_value[0]
            on_update()
        }
        .onChange(of: target_mark_name)
        { _, new_value in
            (element as! ComparatorLogicElement).target_mark_name = new_value
            on_update()
        }
    }
}

struct CompareTypePicker: View
{
    @Binding var compare_type: CompareType
    
    var body: some View
    {
        Picker("Compare", selection: $compare_type)
        {
            ForEach(CompareType.allCases, id: \.self)
            { compare_type in
                Text(compare_type.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding()
    }
}

struct MarkLogicElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var name: String
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        _name = State(initialValue: (_element.wrappedValue as! MarkLogicElement).name)
        self.on_update = on_update
    }
    
    var body: some View
    {
        HStack
        {
            Text("Name")
            TextField("Mark name", text: $name) //Mark name field
                .textFieldStyle(.roundedBorder)
        }
        .onChange(of: name)
        { _, new_value in
            (element as! MarkLogicElement).name = new_value
            on_update()
        }
    }
}

#Preview
{
    ComparatorElementView(element: .constant(ComparatorLogicElement()), on_update: {})
        .environmentObject(Workspace())
        .frame(width: 256)
}

#Preview
{
    MarkLogicElementView(element: .constant(MarkLogicElement()), on_update: {})
        .environmentObject(Workspace())
        .frame(width: 256)
}
