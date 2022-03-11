//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI

struct WorkspaceView: View
{
    //@Binding var document: Robotic_Complex_WorkspaceDocument
    @EnvironmentObject var document: Robotic_Complex_WorkspaceDocument
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        //TextEditor(text: $document.text)
        Text("\(document.preset.robots_count)")
        //Label($document.preset.robots_count, systemImage: "stop")
        
        #if os(iOS)
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        #else
            .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #endif
        
        .toolbar
        {
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "stop")
                    }
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "play")
                    }
                    Divider()
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "arrow.uturn.backward")
                    }
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "arrow.uturn.forward")
                    }
                    Divider()
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    func add_robot()
    {
        print("🪄")
    }
}

struct WorkspaceView_Previews: PreviewProvider
{
    static var previews: some View
    {
        WorkspaceView()//document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
