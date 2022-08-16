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
        #if os(macOS)
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document)
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
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!app_state.reset_view_enabled)
                Divider()
            }
        }
        #else
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document, file_name: "\(file.fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled")", file_url: file.fileURL!)
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
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!app_state.reset_view_enabled)
                Divider()
            }
        }
        #endif
    }
}
