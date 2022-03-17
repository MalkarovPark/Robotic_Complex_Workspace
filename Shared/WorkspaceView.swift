//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI

struct WorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var cycle = false
    @State var worked = false
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        Text("Robots in workspace – \(document.preset.robots_count)")
        
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
                        Label("Reset", systemImage: "stop")
                    }
                    Button(action: change_work)
                    {
                        Label("PlayPause", systemImage: "playpause")
                    }
                    Button(action: change_cycle)
                    {
                        if cycle == false
                        {
                            Label("Repeat", systemImage: "repeat.1")
                        }
                        else
                        {
                            Label("Repeat", systemImage: "repeat")
                        }
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
    
    func change_work()
    {
        print("🪄")
    }
    
    func change_cycle()
    {
        cycle.toggle()
    }
}

struct WorkspaceView_Previews: PreviewProvider
{
    static var previews: some View
    {
        WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
            .environmentObject(Workspace())
    }
}
