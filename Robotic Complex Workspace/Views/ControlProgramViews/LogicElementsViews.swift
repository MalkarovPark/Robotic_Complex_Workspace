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
    @Binding var logic_type: LogicType
    @Binding var target_mark_name: String
    @Binding var compared_value: Float
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        HStack(spacing: 0)
        {
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
            //MARK: Equal subview
            HStack(spacing: 8)
            {
                Text("Compare with")
                #if os(iOS) || os(visionOS)
                    .frame(minWidth: 120)
                #endif
                TextField("0", value: $compared_value, format: .number)
                    .textFieldStyle(.roundedBorder)
                Stepper("Enter", value: $compared_value, in: 0...255)
                    .labelsHidden()
            }
        }
    }
}

struct MarkLogicElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var new_element: MarkLogicElement
    
    @State private var new_name: String
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        _new_element = State(initialValue: _element.wrappedValue as! MarkLogicElement)
        _new_name = State(initialValue: (_element.wrappedValue as! MarkLogicElement).name)
        self.on_update = on_update
    }
    
    var body: some View
    {
        HStack
        {
            Text("Name")
            TextField("Mark name", text: $new_name) //Mark name field
                .textFieldStyle(.roundedBorder)
        }
        .onChange(of: new_name)
        { _, new_value in
            (element as! MarkLogicElement).name = new_value
            on_update()
        }
        //Make codable structs for program elements
    }
}

#Preview
{
    MarkLogicElementView(element: .constant(WorkspaceProgramElement()), on_update: {})
}
