//
//  Robotic_Complex_WorkspaceApp.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI
import SceneKit

@main
struct Robotic_Complex_WorkspaceApp: App
{
    @StateObject var app_state = AppState()
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(file_name: "\(file.fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled")", document: file.$document)
                .environmentObject(app_state)
        }
        .commands
        {
            SidebarCommands()
            
            CommandGroup(after: CommandGroupPlacement.sidebar)
            {
                Divider()
                Button("Reset Camera")
                {
                    app_state.reset_view = true
                }
                .keyboardShortcut("r", modifiers: .command)
                Divider()
            }
        }
    }
}
