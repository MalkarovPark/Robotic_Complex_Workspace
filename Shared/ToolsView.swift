//
//  ToolsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.03.2022.
//

import SwiftUI

struct ToolsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    var body: some View
    {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ToolsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ToolsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
