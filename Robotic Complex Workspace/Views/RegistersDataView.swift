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
    
    @State private var toggle = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    private let numbers = (0...255).map { $0 }
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: register_card_maximum, maximum: register_card_maximum), spacing: 0)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ScrollView
            {
                LazyVGrid(columns: columns, spacing: register_card_spacing)
                {
                    ForEach(numbers, id: \.self)
                    { number in
                        RegisterCardView(number: number, color: app_state.register_colors[number])
                            .id(number)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                .padding()
                .modifier(DoubleModifier(update_toggle: $toggle))
                #if os(macOS)
                .padding(.vertical, 10)
                #else
                .padding(.vertical)
                #endif
            }
            
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
        toggle.toggle()
    }
    
    private func save_registers()
    {
        document.preset.registers = base_workspace.file_data().registers
    }
}

struct RegisterCardView: View
{
    @State var value: Float = 0
    @State private var appeared = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var number: Int
    var color: Color
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                VStack(spacing: 0)
                {
                    ZStack
                    {
                        TextField("0", value: $value, format: .number)
                            .font(.system(size: register_card_font_size))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .onAppear
                            {
                                value = base_workspace.data_registers[number]
                                appeared = true
                            }
                            .onChange(of: value)
                            { _, new_value in
                                if appeared
                                {
                                    base_workspace.update_register(number, new_value: new_value)
                                }
                            }
                    }
                    #if os(macOS)
                    .frame(height: 48)
                    #else
                    .frame(height: 72)
                    #endif
                    .background(Color.clear)
                    
                    Rectangle()
                        .foregroundColor(color)
                    #if os(macOS)
                        .frame(height: 32)
                    #else
                        .frame(height: 48)
                    #endif
                        .overlay(alignment: .leading)
                        {
                            Text("\(number)")
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                            #if os(iOS) || os(visionOS)
                                .font(.system(size: 20))
                            #endif
                        }
                        .shadow(radius: 2)
                }
            }
            .background(.thinMaterial)
        }
        .frame(width: register_card_scale, height: register_card_scale)
        .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
        .shadow(radius: 4)
    }
}

#Preview {
    RegistersDataView(document: .constant(Robotic_Complex_WorkspaceDocument()), is_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 400)
}

#if os(macOS)
let register_card_scale: CGFloat = 80
let register_card_spacing: CGFloat = 16
let register_card_font_size: CGFloat = 20
#else
let register_card_scale: CGFloat = 112
let register_card_spacing: CGFloat = 20
let register_card_font_size: CGFloat = 32
#endif

let register_card_maximum = register_card_scale + register_card_spacing
