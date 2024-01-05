//
//  RegistersDataView.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 15.10.2023.
//

import SwiftUI
import IndustrialKit

struct RegistersDataView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @Binding var is_presented: Bool
    
    @State private var update_toggle = false
    @State private var is_registers_count_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            RegistersView(registers: $base_workspace.registers, colors: registers_colors)
                .modifier(DoubleModifier(update_toggle: $update_toggle))
            
            Divider()
            
            HStack(spacing: 0)
            {
                Button(role: .destructive, action: clear_registers)
                {
                    Image(systemName: "eraser")
                        //.frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.trailing)
                
                Button(action: save_registers)
                {
                    Image(systemName: "arrow.down.doc")
                        //.frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.trailing)
                
                Button(action: { is_registers_count_presented = true })
                {
                    Image(systemName: "square.grid.2x2")
                        //.frame(maxWidth: .infinity)
                }
                .popover(isPresented: $is_registers_count_presented)
                {
                    RegistersCountView(is_presented: $is_registers_count_presented, registers_count: base_workspace.registers.count)
                    {
                        update_toggle.toggle()
                    }
                    #if os(iOS)
                    .presentationDetents([.height(96)])
                    #endif
                }
                .buttonStyle(.bordered)
                .padding(.trailing)
                
                Button(action: { is_presented = false })
                {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .controlSize(.large)
        #if os(macOS)
        .frame(minWidth: 420, maxWidth: 512, minHeight: 400, maxHeight: 480)
        #endif
    }
    
    private func clear_registers()
    {
        base_workspace.clear_registers()
        update_toggle.toggle()
    }
    
    private func save_registers()
    {
        document.preset.registers = base_workspace.file_data().registers
    }
    
    private func update_registers_count()
    {
        base_workspace.update_registers_count(Workspace.default_registers_count)
        update_toggle.toggle()
    }
}

struct RegistersCountView: View
{
    @Binding var is_presented: Bool
    @State var registers_count: Int
    
    @EnvironmentObject var base_workspace: Workspace
    
    let additive_func: () -> ()
    
    var body: some View
    {
        HStack(spacing: 8)
        {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                {
                    base_workspace.update_registers_count(Workspace.default_registers_count)
                    additive_func()
                    //registers_count = Workspace.default_registers_count
                }
                is_presented.toggle()
            })
            {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            #if os(macOS)
            .foregroundColor(Color.white)
            #else
            .padding(.leading, 8)
            #endif
            
            TextField("\(Workspace.default_registers_count)", value: $registers_count, format: .number)
                .textFieldStyle(.roundedBorder)
            #if os(macOS)
                .frame(width: 64)
            #else
                .frame(width: 128)
            #endif
            
            Stepper("Enter", value: $registers_count, in: 1...1000)
                .labelsHidden()
            #if os(iOS) || os(visionOS)
                .padding(.trailing, 8)
            #endif
        }
        .onChange(of: registers_count)
        { _, new_value in
            if new_value > 0
            {
                base_workspace.update_registers_count(new_value)
                additive_func()
            }
        }
        .padding(8)
        .controlSize(.regular)
    }
}

#Preview
{
    RegistersDataView(document: .constant(Robotic_Complex_WorkspaceDocument()), is_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 400)
}
