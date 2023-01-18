//
//  ConnectorView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 13.01.2023.
//

import SwiftUI
import IndustrialKit

struct ConnectorView: View
{
    @Binding var is_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @Binding var demo: Bool
    @StateObject var connector: WorkspaceObjectConnector
    
    @EnvironmentObject var base_workspace: Workspace
    
    var update_file_data: () -> Void
    
    @State private var connected = false
    @State private var first_loaded = true
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Link Object")
                .font(.title2)
                .padding([.top, .horizontal])
            
            VStack(spacing: 0)
            {
                #if os(macOS)
                GroupBox(label: Text("Parameters"))
                {
                    if connector.parameters.count > 0
                    {
                        List($connector.parameters)
                        { item in
                            ConnectionParameterView(parameter: item)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        //.controlSize(.regular)
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
                    Rectangle()
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .shadow(radius: 1)
                    GroupBox(label: Text("Parameters"))
                    {
                        if connector.parameters.count > 0
                        {
                            List($connector.parameters)
                            { item in
                                ConnectionParameterView(parameter: item)
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
                    .backgroundStyle(.white)
                }
                .padding([.horizontal, .bottom])
                #endif
                
                TextEditor(text: $connector.output)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .shadow(radius: 1)
                    .frame(maxWidth: .infinity, maxHeight: 96)
                    .overlay(alignment: .bottomTrailing)
                    {
                        VStack(spacing: 0)
                        {
                            Toggle(isOn: $connector.get_output)
                            {
                                Image(systemName: "scroll")
                            }
                            .toggleStyle(.button)
                            #if os(iOS)
                            .buttonStyle(.bordered)
                            #endif
                            .padding([.horizontal, .leading])
                            
                            Button(action: {
                                connector.clear_output()
                            })
                            {
                                Image(systemName: "eraser")
                            }
                            .buttonStyle(.bordered)
                            .padding()
                        }
                    }
                    //.shadow(radius: 1)
                    .padding(.horizontal)
            }
            .controlSize(.regular)
            .padding(.vertical)
            
            HStack(spacing: 0)
            {
                #if os(iOS)
                Text("Demo")
                    .padding(.trailing)
                #endif
                
                Toggle(isOn: $demo)
                {
                    Text("Demo")
                }
                .toggleStyle(.switch)
                #if os(iOS)
                .tint(.accentColor)
                .labelsHidden()
                #endif
                .onChange(of: demo)
                { _ in
                    update_file_data()
                }
                
                Spacer()
                
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
                { newValue in
                    if !first_loaded
                    {
                        if newValue
                        {
                            connector.connect()
                        }
                        else
                        {
                            connector.disconnect()
                        }
                    }
                }
            }
            .padding([.bottom, .horizontal])
        }
        #if os(macOS)
        .frame(minWidth: 320, idealWidth: 400, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
        .overlay(alignment: .topLeading)
        {
            Button(action: close_connector)
            {
                Image(systemName: "xmark")
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
            .padding()
        }
        .controlSize(.regular)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .onAppear
        {
            connected = connector.connected
            first_loaded = false
        }
    }
    
    private func close_connector()
    {
        is_presented = false
    }
}

struct ConnectionParameterView: View
{
    @Binding var parameter: ConnectionParameter
    
    @State private var new_string_value = String()
    @State private var new_int_value = Int()
    @State private var new_float_value = Float()
    @State private var new_bool_value = Bool()
    
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
                }
                .onChange(of: new_string_value)
                { newValue in
                    parameter.value = newValue
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
                }
                .onChange(of: new_int_value)
                { newValue in
                    parameter.value = newValue
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
                }
                .onChange(of: new_float_value)
                { newValue in
                    parameter.value = newValue
                }
            case is Bool:
                Toggle(isOn: $new_bool_value)
                {
                    Text("Bool")
                }
                #if os(iOS)
                .tint(.accentColor)
                #endif
                .labelsHidden()
                .onAppear
            {
                new_bool_value = parameter.value as! Bool
            }
            .onChange(of: new_bool_value)
            { newValue in
                parameter.value = newValue
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
            ConnectorView(is_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), demo: .constant(true), connector: PortalConnector(), update_file_data: {})
            
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "String", value: "Text")))
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Int", value: 8)))
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Float", value: Float(6.0))))
            ConnectionParameterView(parameter: .constant(ConnectionParameter(name: "Bool", value: true)))
        }
    }
}
