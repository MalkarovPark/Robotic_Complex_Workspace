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
    var body: some Scene
    {
        DocumentGroup(newDocument: Robotic_Complex_WorkspaceDocument())
        {
            file in ContentView(document: file.$document, file_name: "\(file.fileURL!.deletingPathExtension().lastPathComponent)")
        }
        .commands
        {
            SidebarCommands()
            
            CommandGroup(after: CommandGroupPlacement.sidebar)
            {
                Divider()
                Button("Reset Camera")
                {
                    print("🧁")
                }
                .keyboardShortcut("r", modifiers: .command)
                Divider()
            }
        }
    }
}
