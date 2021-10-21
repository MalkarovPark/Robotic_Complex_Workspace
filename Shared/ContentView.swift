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
        NavigationView
        {
            Sidebar(document: $document)
            //TextEditor(text: $document.text)
        }
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
