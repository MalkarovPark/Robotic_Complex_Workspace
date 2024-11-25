//
//  ToolInspectorView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct ToolInspectorView: View
{
    @Binding var new_operation_code: OperationCodeInfo
    
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
            if base_workspace.selected_tool.codes.count > 0
            {
                ZStack
                {
                    List
                    {
                        if base_workspace.selected_tool.programs_count > 0
                        {
                            if base_workspace.selected_tool.selected_program.codes_count > 0
                            {
                                ForEach(Array(base_workspace.selected_tool.selected_program.codes.enumerated()), id: \.element.id)
                                { index, code in
                                    OperationItemView(codes: $base_workspace.selected_tool.selected_program.codes, code_item: code)
                                        .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                                    .contextMenu
                                    {
                                        Button(role: .destructive)
                                        {
                                            remove_codes(IndexSet(integer: index))
                                        }
                                    label:
                                        {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .onMove(perform: code_item_move)
                                .onDelete(perform: remove_codes)
                                .onChange(of: base_workspace.tools)
                                { _, _ in
                                    update_data()
                                }
                            }
                        }
                    }
                    .modifier(ListBorderer())
                    .padding([.horizontal, .top])
                    
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
                                    new_operation_code.image
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: new_operation_code.image)
                                )
                                .frame(width: 32, height: 32)
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .popover(isPresented: $add_operation_view_presented, arrowEdge: default_popover_edge)
                        {
                            #if os(macOS)
                            HStack
                            {
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes.count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(code.name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .padding()
                                .disabled(base_workspace.selected_tool.codes.count == 0)
                                .frame(maxWidth: .infinity)
                                .pickerStyle(.radioGroup)
                                .labelsHidden()
                            }
                            #else
                            VStack
                            {
                                Picker("Code", selection: $new_operation_code)
                                {
                                    if base_workspace.selected_tool.codes.count > 0
                                    {
                                        ForEach(base_workspace.selected_tool.codes, id:\.self)
                                        { code in
                                            Text(code.name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(base_workspace.selected_tool.codes.count == 0)
                                .pickerStyle(.wheel)
                                .frame(maxWidth: 192)
                                .buttonStyle(.borderedProminent)
                            }
                            .presentationDetents([.height(192)])
                            #endif
                        }
                        .padding(.trailing, 24)
                    }
                    .padding(.trailing, 14)
                }
                
                HStack(spacing: 0)
                {
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
                    #if os(iOS)
                    .modifier(PickerNamer(name: "Program"))
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
                    .popover(isPresented: $add_program_view_presented, arrowEdge: default_popover_edge)
                    {
                        AddNewView(is_presented: $add_program_view_presented)
                        { new_name in
                            base_workspace.selected_tool.add_program(OperationsProgram(name: new_name))
                            base_workspace.selected_tool.selected_program_index = base_workspace.selected_tool.programs_names.count - 1
                            base_workspace.update_view()
                        }
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
            #if os(iOS)
                .padding(.trailing, 8)
            #endif
        }
        .padding(8)
    }
}

//MARK: - Position item view for list
struct OperationItemView: View
{
    @Binding var codes: [OperationCode]
    
    @State var code_item: OperationCode
    @State private var new_code = OperationCodeInfo()
    @State private var update_data = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(base_workspace.selected_tool.inspector_code_color(code: code_item))
            #if os(macOS)
                .padding(.trailing)
            #endif
            
            Picker("Code", selection: $new_code)
            {
                if base_workspace.selected_tool.codes.count > 0
                {
                    ForEach(base_workspace.selected_tool.codes, id:\.self)
                    { code in
                        Text(code.name)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(base_workspace.selected_tool.codes.count == 0)
            .frame(maxWidth: .infinity)
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: new_code)
            { _, new_value in
                if update_data
                {
                    code_item.value = new_code.value
                    document_handler.document_update_tools()
                }
            }
            new_code.image
            #if os(macOS)
            .padding(.leading)
            #endif
        }
        .onAppear
        {
            update_data = false
            new_code = base_workspace.selected_tool.code_info(code_item.value)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                update_data = true
            }
        }
    }
}

//MARK: - Previews
#Preview
{
    ToolInspectorView(new_operation_code: .constant(OperationCodeInfo()))
    { _ in
        
    } code_item_move: { _, _ in
        
    } add_operation_to_program: {
        
    } delete_operations_program: {
        
    } update_data: {
        
    }
    .environmentObject(Workspace())
}

#Preview
{
    OperationItemView(codes: .constant([OperationCode]()), code_item: OperationCode(1))
        .environmentObject(Workspace())
}
