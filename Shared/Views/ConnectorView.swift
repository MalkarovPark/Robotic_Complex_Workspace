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
    @Binding var connector: WorkspaceObjectConnector
    
    @EnvironmentObject var base_workspace: Workspace
    
    var update_file_data: () -> Void
    
    @State var connected = false
    @State var text = ""
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Link Object")
                .font(.title2)
                .padding([.top, .horizontal])
            
            VStack(spacing: 0)
            {
                GroupBox(label: Text("Parameters"))
                {
                    List
                    {
                        //Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    //.padding()
                }
                .padding([.horizontal, .bottom])
                
                TextEditor(text: $text)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: 128)
                    .shadow(radius: 1)
                    .padding(.horizontal)
            }
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
                
                Spacer()
                
                Toggle(isOn: $connected)
                {
                    HStack
                    {
                        if !connected
                        {
                            Text("Connect")
                            Image(systemName: "circle.fill")
                                .foregroundColor(.gray)
                        }
                        else
                        {
                            Text("Disconnect")
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .disabled(demo)
                .toggleStyle(.button)
                #if os(iOS)
                .buttonStyle(.bordered)
                #endif
            }
            .padding([.bottom, .horizontal])
        }
        #if os(macOS)
        .controlSize(.large)
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
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
    
    private func close_connector()
    {
        is_presented = false
    }
}

struct ConnectorView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ConnectorView(is_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), demo: .constant(true), connector: .constant(WorkspaceObjectConnector()), update_file_data: {})
    }
}
