//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

enum navigation_item
{
    case WorkspaceView
    case RobotsView
}

struct ContentView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var file_name = ""

    var body: some View
    {
        NavigationView
        {
            Sidebar(document: $document, file_name: file_name)
            #if os(iOS)
            WorkspaceView(document: $document)
            #endif
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        #if os(iOS)
        .navigationBarHidden(true)
        .modifier(DismissModifier())
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
            ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
        }
        else
        {
            // Fallback on earlier versions
        }
        #else
        if #available(iOS 15.0, *)
        {
            ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
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
