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
                    Text("Clear All")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.trailing)
                
                Button(action: save_registers)
                {
                    Text("Save")
                        .frame(maxWidth: .infinity)
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
}

#Preview
{
    RegistersDataView(document: .constant(Robotic_Complex_WorkspaceDocument()), is_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 400)
}
