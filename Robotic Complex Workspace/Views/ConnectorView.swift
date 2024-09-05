//
//  ConnectorView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.01.2023.
//

import SwiftUI
import IndustrialKit

struct ConnectorView: View
{
    @Binding var is_presented: Bool
    
    @Binding var demo: Bool
    @Binding var update_model: Bool
    
    @StateObject var connector: WorkspaceObjectConnector
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var update_file_data: () -> Void
    
    @State private var connected = false
    @State private var toggle_enabled = true
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack(spacing: 0)
            {
                #if os(macOS)
                GroupBox(label: Text("Parameters"))
                {
                    if connector.parameters.count > 0
                    {
                        List($connector.parameters)
                        { item in
                            ConnectionParameterView(parameter: item, update_file_data: update_file_data)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    else
                    {
                        Text("Connector without parameters")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding([.horizontal, .bottom])
                #else
                ZStack
                {
                    #if os(iOS)
                    Rectangle()
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .shadow(radius: 1)
                    #endif
                    
                    GroupBox(label: Text("Parameters"))
                    {
                        if connector.parameters.count > 0
                        {
                            List($connector.parameters)
                            { item in
                                ConnectionParameterView(parameter: item, update_file_data: update_file_data)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .listStyle(.plain)
                            //.controlSize(.regular)
                        }
                        else
                        {
                            Text("Connector without parameters")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    #if os(iOS)
                    .backgroundStyle(.white)
                    #endif
                }
                .padding([.horizontal, .bottom])
                #endif
                
                HStack(spacing: 8)
                {
                    TextEditor(text: $connector.output)
                    #if os(visionOS)
                        .textEditorStyle(.roundedBorder)
                    #endif
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    #if !os(visionOS)
                        .shadow(radius: 1)
                    #endif
                    
                    VStack(spacing: 0)
                    {
                        Toggle(isOn: $connector.get_output)
                        {
                            Image(systemName: "scroll")
                        }
                        .frame(maxHeight: .infinity)
                        #if os(iOS) || os(visionOS)
                        .buttonStyle(.bordered)
                        #endif
                        #if os(visionOS)
                        .buttonBorderShape(.circle)
                        #endif
                        .toggleStyle(.button)
                        
                        Button(action: {
                            connector.clear_output()
                        })
                        {
                            Image(systemName: "eraser")
                        }
                        .frame(maxHeight: .infinity)
                        .buttonStyle(.bordered)
                        #if os(visionOS)
                        .buttonBorderShape(.circle)
                        #endif
                    }
                    //.padding(.leading)
                    .controlSize(.large)
                }
                #if os(macOS)
                    .frame(maxWidth: .infinity, maxHeight: 96)
                #else
                    .frame(maxWidth: .infinity, maxHeight: 128)
                #endif
                    .padding(.horizontal)
                    
            }
            .controlSize(.regular)
            .padding(.vertical)
            
            HStack(spacing: 0)
            {
                #if os(iOS) || os(visionOS)
                Text("Demo")
                    .padding(.trailing)
                #endif
                
                Toggle(isOn: $demo)
                {
                    Text("Demo")
                }
                .toggleStyle(.switch)
                #if os(iOS) || os(visionOS)
                .tint(.accentColor)
                .labelsHidden()
                #endif
                .onChange(of: demo)
                { _, new_value in
                    if new_value && connected
                    {
                        connected = false
                        //connector.disconnect()
                    }
                }
                
                Spacer()
                
                Toggle(isOn: $update_model)
                {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .onChange(of: update_model)
                { _, _ in
                    update_file_data()
                }
                .disabled(demo)
                #if os(macOS)
                .controlSize(.large)
                #else
                .buttonStyle(.bordered)
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
                .toggleStyle(.button)
                .padding(.trailing)
                
                //Spacer()
                
                Toggle(isOn: $connected)
                {
                    HStack
                    {
                        Text(connector.connection_button.label)
                        Image(systemName: "circle.fill")
                            .foregroundColor(connector.connection_button.color)
                    }
                }
                .disabled(demo)
                .toggleStyle(.button)
                #if os(macOS)
                .controlSize(.large)
                #else
                .buttonStyle(.bordered)
                #endif
                .onChange(of: connected)
                { _, new_value in
                    if !toggle_enabled
                    {
                        if new_value
                        {
                            connector.connect()
                        }
                        else
                        {
                            connector.disconnect()
                        }
                    }
                }
                .onChange(of: connector.connection_failure)
                { _, new_value in
                    if new_value
                    {
                        toggle_enabled = true
                        connected = false
                        toggle_enabled = false
                    }
                }
            }
            .padding([.bottom, .horizontal])
        }
        .modifier(SheetCaption(is_presented: $is_presented, label: "Link Object"))
        #if os(macOS)
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .onAppear
        {
            connected = connector.connected
            toggle_enabled = false
        }
        .controlSize(.regular)
    }
    
    /*private func close_connector()
    {
        is_presented = false
    }*/
}

struct ConnectionParameterView: View
{
    @Binding var parameter: ConnectionParameter
    
    @State private var new_string_value = String()
    @State private var new_int_value = Int()
    @State private var new_float_value = Float()
    @State private var new_bool_value = Bool()
    
    var update_file_data: () -> Void
    @State private var appeared = false
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            Text(parameter.name)
            
            Spacer()
            
            switch parameter.value
            {
            case is String:
                TextField(parameter.name, text: $new_string_value)
                #if os(macOS)
                    .textFieldStyle(.squareBorder)
                #endif
                    .labelsHidden()
                    .onAppear
                {
                    new_string_value = parameter.value as! String
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                    {
                        appeared = true
                    }
                }
                .onChange(of: new_string_value)
                { _, new_value in
                    parameter.value = new_value
                    
                    if appeared
                    {
                        update_file_data()
                    }
                }
            case is Int:
                TextField("0", value: $new_int_value, format: .number)
                #if os(macOS)
                    .textFieldStyle(.roundedBorder)
                #endif
                Stepper("Enter", value: $new_int_value, in: -1000...1000)
                    .labelsHidden()
                    .padding(.leading, 8)
                #if os(macOS)
                    .padding(.trailing, 2)
                #endif
                    .onAppear
                {
                    new_int_value = parameter.value as! Int
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                    {
                        appeared = true
                    }
                }
                .onChange(of: new_int_value)
                { _, new_value in
                    parameter.value = new_value
                    
                    if appeared
                    {
                        update_file_data()
                    }
                }
            case is Float:
                TextField("0", value: $new_float_value, format: .number)
                #if os(macOS)
                    .textFieldStyle(.roundedBorder)
                #endif
                Stepper("Enter", value: $new_float_value, in: -1000...1000)
                    .labelsHidden()
                    .padding(.leading, 8)
                #if os(macOS)
                    .padding(.trailing, 2)
                #endif
                    .onAppear
                {
                    new_float_value = parameter.value as! Float
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                    {
                        appeared = true
                    }
                }
                .onChange(of: new_float_value)
                { _, new_value in
                    parameter.value = new_value
                    
                    if appeared
                    {
                        update_file_data()
                    }
                }
            case is Bool:
                Toggle(isOn: $new_bool_value)
                {
                    Text("Bool")
                }
                #if os(iOS) || os(visionOS)
                .tint(.accentColor)
                #endif
                .labelsHidden()
                .onAppear
                {
                    new_bool_value = parameter.value as! Bool
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
                    {
                        appeared = true
                    }
                }
                .onChange(of: new_bool_value)
                { _, new_value in
                    parameter.value = new_value
                    
                    if appeared
                    {
                        update_file_data()
                    }
                }
            default:
                Text("Unknown parameter")
            }
        }
    }
}

struct ConnectorView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ConnectorView(is_presented: .constant(true), demo: .constant(true), update_model: .constant(true), connector: PortalConnector(), update_file_data: {})
            
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "String", value: "Text")), update_file_data: {})
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Int", value: 8)), update_file_data: {})
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Float", value: Float(6))), update_file_data: {})
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Bool", value: true)), update_file_data: {})
        }
    }
}
