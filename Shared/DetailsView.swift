//
//  DetailsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import SwiftUI

struct DetailsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    var body: some View
    {
        HStack
        {
            Text("Press «+» to add new detail")
                .font(.largeTitle)
                .foregroundColor(quaternary_label_color)
                .padding(16)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        .background(Color.white)
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #endif
    }
}

struct DetailsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        DetailsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
