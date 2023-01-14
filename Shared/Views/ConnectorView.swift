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
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Link Object")
                .font(.title2)
                .padding([.top, .horizontal])
            
            HStack(spacing: 0)
            {
                GroupBox(label: Text("Parameters"))
                {
                    VStack
                    {
                        //Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .padding(.horizontal)
                
                GroupBox(label: Text("Output"))
                {
                    VStack
                    {
                        //Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .padding(.trailing)
            }
            .padding(.vertical)
            
            HStack(spacing: 0)
            {
                Toggle(isOn: $demo)
                {
                    Text("Demo")
                }
                .toggleStyle(.switch)
                .padding()
                
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
                .padding()
            }
        }
        .controlSize(.large)
        #if os(macOS)
        .frame(minWidth: 448, idealWidth: 480, maxWidth: 512, minHeight: 448, idealHeight: 480, maxHeight: 512)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
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
