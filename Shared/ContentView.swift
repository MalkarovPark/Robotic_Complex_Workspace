//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

struct ContentView: View
{
    @State var file_name = ""
    @StateObject private var base_workspace = Workspace()
    @StateObject var document: Robotic_Complex_WorkspaceDocument

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    #endif

    @ViewBuilder var body: some View
    {
        #if os(iOS)
        if horizontal_size_class == .compact
        {
            TabBar()
                .environmentObject(base_workspace)
                .environmentObject(document)
        }
        else
        {
            Sidebar(file_name: file_name)
                .environmentObject(base_workspace)
                .environmentObject(document)
        }
        #else
        Sidebar(file_name: file_name)
            .environmentObject(base_workspace)
            .environmentObject(document)
        #endif
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        #if os(macOS)
        if #available(macOS 11.0, *)
        {
            ContentView(document: Robotic_Complex_WorkspaceDocument())//document: .constant(Robotic_Complex_WorkspaceDocument()))
        }
        else
        {
            // Fallback on earlier versions
        }
        #else
        if #available(iOS 15.0, *)
        {
            ContentView(document: Robotic_Complex_WorkspaceDocument())
                .previewDevice("iPad Pro (11-inch) (3rd generation)")
                .previewInterfaceOrientation(.landscapeLeft)
        }
        else
        {
            // Fallback on earlier versions
        }
        #endif
    }
}
