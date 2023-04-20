//
//  CardMenu.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 20.04.2023.
//

import SwiftUI
import IndustrialKit

struct CardMenu: ViewModifier
{
    @ObservedObject var object: WorkspaceObject //StateObject ???
    
    let clear_preview: () -> ()
    let duplicate_object: () -> ()
    let update_file: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
            .contextMenu
            {
                Toggle(isOn: $object.is_placed)
                {
                    Label("Placed", systemImage: "target")
                    /*#if os(macOS)
                    Image(systemName: "target")
                    #endif*/
                }
                .onChange(of: object.is_placed)
                { _ in
                    update_file()
                }
                
                Button(action: {
                    clear_preview()
                    update_file()
                })
                {
                    Label("Clear Preview", systemImage: "rectangle.slash")
                }
                
                #if os(macOS)
                Divider()
                #endif
                
                Button(action: {
                    duplicate_object()
                    update_file()
                })
                {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                
                Button(action: {
                    //duplicate_object()
                    //update_file()
                })
                {
                    Label("Rename", systemImage: "pencil.line")
                }
            }
    }
}
