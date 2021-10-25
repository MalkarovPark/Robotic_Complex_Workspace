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
    
    var body: some View
    {
        TextEditor(text: $document.text)
        #if os(iOS)
            .padding()
        #endif
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct WorkspaceView_Previews: PreviewProvider
{
    static var previews: some View
    {
        WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
