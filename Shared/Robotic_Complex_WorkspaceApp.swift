//
//  Robotic_Complex_WorkspaceApp.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

@main
struct Robotic_Complex_WorkspaceApp: App
{
    #if os(macOS)
    @StateObject var app_state = AppState()
    #endif
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document, file_name: "\(file.fileURL!.deletingPathExtension().lastPathComponent)")
            #if os(macOS)
                .environmentObject(app_state)
            #endif
        }
        .commands
        {
            SidebarCommands()
            
            #if os(macOS)
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
            #endif
        }
    }
}

#if os(macOS)
class AppState : ObservableObject
{
    @Published var reset_view = false
}
#endif
