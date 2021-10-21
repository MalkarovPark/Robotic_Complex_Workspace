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

    var body: some View
    {
        #if os(macOS)
        NavigationView
        {
            Sidebar(document: $document)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        #else
        TextEditor(text: $document.text)
        .toolbar
        {
            ToolbarItem
            {
                Button(action: button_func)
                {
                    Text("КУ")
                }
            }
        }
        #endif
    }
    
    #if os(iOS)
    func button_func()
    {
        print("🔮")
    }
    #endif
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
