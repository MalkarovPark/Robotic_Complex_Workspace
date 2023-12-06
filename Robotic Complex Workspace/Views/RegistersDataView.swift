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
                        RegisterCardView(number: number, color: registers_colors[number])
                            .id(number)
                            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
                .padding()
                .modifier(DoubleModifier(update_toggle: $update_toggle))
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
        update_toggle.toggle()
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

struct RegistersSelector: View
{
    let text: String
    
    @Binding var indices: [Int]
    @State var names: [String]
    @State var cards_colors: [Color]
    
    @State private var is_presented = false
    
    var body: some View
    {
        Button("\(text)", action: { is_presented = true })
            .popover(isPresented: $is_presented)
            {
                RegistersSelectorView(indices: $indices, names: names, cards_colors: cards_colors)
            }
    }
}

struct RegistersSelectorView: View
{
    @Binding var indices: [Int]
    @State var names: [String]
    @State var cards_colors: [Color]
    
    private let numbers = (0...255).map { $0 }
    
    @State private var current_parameter = 0
    @State private var selections = [Bool](repeating: false, count: 256)
    @State private var texts = [String](repeating: String(), count: 256)
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 70, maximum: 70), spacing: 0)]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if names.count > 1
            {
                Picker(selection: .constant(1), label: Text("placeholder")) { }
                .padding()
                .hidden()
            }
            
            ScrollView
            {
                LazyVGrid(columns: columns, spacing: 6)
                {
                    ForEach(numbers, id: \.self)
                    { number in
                        RegistersSelectorCardView(is_selected: $selections[number], number: number, color: cards_colors[number], selection_text: texts[number])
                        .onTapGesture
                        {
                            select_index(number)
                        }
                    }
                }
                .padding()
                #if os(macOS)
                .padding(.vertical, 10)
                #else
                .padding(.vertical)
                #endif
            }
        }
        .frame(width: 256, height: 256)
        .overlay(alignment: .top)
        {
            if names.count > 1
            {
                Picker("Parameters", selection: $current_parameter)
                {
                    ForEach(Array(indices.enumerated()), id: \.offset)
                    { index, _ in
                        Text("\(names[index])")
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()
                .background(.thinMaterial)
            }
        }
        .onAppear
        {
            update_selections()
            update_texts()
        }
    }
    
    private func update_selections()
    {
        selections = [Bool](repeating: false, count: 256)
        
        for index in indices
        {
            selections[index] = true
        }
    }
    
    private func update_texts()
    {
        texts = [String](repeating: String(), count: 256)
        
        for (index, value) in indices.enumerated()
        {
            texts[value] += "\(names[index]) "
        }
        
        for index in texts.indices
        {
            texts[index] = String(texts[index].dropLast())
        }
    }
    
    private func select_index(_ number: Int)
    {
        indices[current_parameter] = number
        
        update_selections()
        update_texts()
    }
}

struct RegistersSelectorCardView: View
{
    @Binding var is_selected: Bool
    
    let number: Int
    let color: Color
    
    let selection_text: String
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundStyle(Color(color).opacity(0.75))
            
            Text("\(number)")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(8)
            
            if is_selected
            {
                ZStack
                {
                    Text(selection_text)
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .padding(8)
                        //.lineLimit(1)
                }
                .frame(width: 64, height: 64)
                .background(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .frame(width: 64, height: 64)
        .shadow(radius: 2)
    }
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

#Preview
{
    RegistersDataView(document: .constant(Robotic_Complex_WorkspaceDocument()), is_presented: .constant(true))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 400)
}

#Preview
{
    RegistersSelectorView(indices: .constant([Int](repeating: 0, count: 6)), names: ["X", "Y", "Z", "R", "P", "W"], cards_colors: registers_colors)
        .environmentObject(Workspace())
}
