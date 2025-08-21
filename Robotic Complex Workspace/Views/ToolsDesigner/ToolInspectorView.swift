//
//  ToolInspectorView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit
import IndustrialKitUI

struct ToolInspectorView: View
{
    @Binding var tool: Tool
    
    @State private var add_program_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if tool.codes.count > 0
            {
                // MARK: Program Picker
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
                    .frame(maxWidth: .infinity)
                    .disabled(tool.programs_names.count == 0)
                    .padding(.leading, 8)
                    
                    Button(action: delete_operations_program)
                    {
                        Image(systemName: "minus")
                            .imageScale(.large)
                        #if os(macOS)
                            .frame(width: 16, height: 16)
                        #else
                            .frame(width: 24, height: 24)
                        #endif
                            .padding(8)
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    
                    Button(action: { add_program_view_presented.toggle() })
                    {
                        Image(systemName: "plus")
                            .imageScale(.large)
                        #if os(macOS)
                            .frame(width: 16, height: 16)
                        #else
                            .frame(width: 24, height: 24)
                        #endif
                            .padding(8)
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    .popover(isPresented: $add_program_view_presented, arrowEdge: .top)
                    {
                        AddNewView(is_presented: $add_program_view_presented)
                        { new_name in
                            tool.add_program(OperationsProgram(name: new_name))
                            tool.selected_program_index = tool.programs_names.count - 1
                            
                            document_handler.document_update_tools()
                            add_program_view_presented.toggle()
                            base_workspace.update_view()
                        }
                    }
                }
                .glassEffect(.regular.tint(.white).interactive(), in: .rect(cornerRadius: 8))
                .padding([.horizontal, .top])
                
                // MARK: Program Editor
                ZStack
                {
                    List
                    {
                        if tool.programs_count > 0
                        {
                            if tool.selected_program.codes_count > 0
                            {
                                ForEach(Array(tool.selected_program.codes.enumerated()), id: \.element.id)
                                { index, code in
                                    OperationItemView(tool: $tool, code_item: code)
                                        .onDrag
                                    {
                                        return NSItemProvider()
                                    }
                                    .contextMenu
                                    {
                                        Button(role: .destructive)
                                        {
                                            remove_codes(at: IndexSet(integer: index))
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
                                    document_handler.document_update_tools()
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .glassEffect(.regular.tint(.white).interactive(), in: .rect(cornerRadius: 8))
                    //.modifier(ListBorderer())
                    .padding([.horizontal, .top])
                    
                    if tool.programs_count == 0
                    {
                        Text("No program selected")
                            .foregroundColor(.gray)
                    }
                    else
                    {
                        if tool.selected_program.codes_count == 0
                        {
                            Text("Empty Program")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.bottom)
                .overlay(alignment: .bottomTrailing)
                {
                    AddOperationCodeButton(tool: $tool)
                }
            }
            else
            {
                Text("This tool has no control")
            }
        }
        #if !os(macOS)
        .ignoresSafeArea(.container, edges: [.bottom])
        #endif
    }
    
    private func code_item_move(from source: IndexSet, to destination: Int)
    {
        tool.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        document_handler.document_update_tools()
    }
    
    private func remove_codes(at offsets: IndexSet) // Remove tool operation function
    {
        withAnimation
        {
            tool.selected_program.codes.remove(atOffsets: offsets)
        }
        
        document_handler.document_update_tools()
    }
    
    private func delete_operations_program()
    {
        if tool.programs_names.count > 0
        {
            let current_spi = tool.selected_program_index
            tool.delete_program(index: current_spi)
            if tool.programs_names.count > 1 && current_spi > 0
            {
                tool.selected_program_index = current_spi - 1
            }
            else
            {
                tool.selected_program_index = 0
            }
            
            document_handler.document_update_tools()
        }
    }
}

// MARK: New program element button
struct AddOperationCodeButton: View
{
    @Binding var tool: Tool
    
    @State private var new_operation_code = OperationCodeInfo()
    
    @State private var add_operation_view_presented = false
    
    //@EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Button(action: add_operation_to_program) // Add opcode button
            {
                Image(systemName: "plus")
                #if os(macOS)
                    .frame(width: 16, height: 16)
                #else
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.black)
                #endif
                    //.padding(8)
            }
            #if os(macOS)
            .padding(.leading, 10)
            #else
            .padding(.leading, 14)
            #endif
            .buttonStyle(.borderless)
            
            Button(action: { add_operation_view_presented.toggle() }) // Configure new opcode button
            {
                new_operation_code.image
                    .foregroundColor(.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: new_operation_code.image)
                #if os(macOS)
                    .imageScale(.medium)
                    .frame(width: 16, height: 16)
                #else
                    .imageScale(.large)
                    .frame(width: 24, height: 24)
                #endif
                    .padding(4)
            }
            #if os(macOS)
            .foregroundStyle(Color.accent.opacity(0.75))
            #else
            .buttonStyle(.bordered)
            .tint(Color.accent.opacity(0.75))
            #endif
            .buttonBorderShape(.circle)
            .padding(6)
            #if !os(macOS)
            .padding(.vertical, 4)
            #endif
            .popover(isPresented: $add_operation_view_presented, arrowEdge: default_popover_edge)
            {
                #if os(macOS)
                HStack
                {
                    Picker("Code", selection: $new_operation_code)
                    {
                        if tool.codes.count > 0
                        {
                            ForEach(tool.codes, id:\.self)
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
                    .disabled(tool.codes.count == 0)
                    .frame(maxWidth: .infinity)
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
                #else
                VStack
                {
                    Picker("Code", selection: $new_operation_code)
                    {
                        if tool.codes.count > 0
                        {
                            ForEach(tool.codes, id:\.self)
                            { code in
                                Text(code.name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(tool.codes.count == 0)
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 192)
                    .buttonStyle(.borderedProminent)
                }
                .presentationDetents([.height(192)])
                #endif
            }
        }
        .glassEffect(.regular.interactive())
        .padding(.trailing, 14)
        .padding(.bottom)
        .padding()
        .onAppear
        {
            if tool.codes.count > 0
            {
                new_operation_code = tool.codes.first ?? OperationCodeInfo()
            }
        }
    }
    
    private func add_operation_to_program()
    {
        tool.selected_program.add_code(OperationCode(new_operation_code.value))
        
        document_handler.document_update_tools()
    }
}

// MARK: Drag and Drop delegate
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

// MARK: Position parameter view
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

// MARK: - Position item view for list
struct OperationItemView: View
{
    @Binding var tool: Tool
    @StateObject var code_item: OperationCode
    
    @State private var new_code = OperationCodeInfo()
    @State private var update_data = false
    
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class // Horizontal window size handler
    #endif
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(code_item.performing_state.color)
            #if os(macOS)
                .padding(.trailing)
            #endif
            
            Picker("Code", selection: $new_code)
            {
                if tool.codes.count > 0
                {
                    ForEach(tool.codes, id:\.self)
                    { code in
                        Text(code.name)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(tool.codes.count == 0)
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
            new_code = tool.code_info(code_item.value)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                update_data = true
            }
        }
    }
}

// MARK: - Previews
#Preview
{
    ToolInspectorView(tool: .constant(Tool()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 256)
}

#Preview
{
    OperationItemView(tool: .constant(Tool()), code_item: OperationCode(1))
        .environmentObject(Workspace())
}
