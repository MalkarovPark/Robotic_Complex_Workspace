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
    
    @State private var add_detail_view_presented = false
    @State private var detail_view_presented = false
    @State private var dragged_detail: Detail?
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.details.count > 0
            {
                
            }
            else
            {
                Text("Press «+» to add new detail")
                    .font(.largeTitle)
                    .foregroundColor(quaternary_label_color)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(Color.white)
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600) //Window sizes for macOS
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar
        {
            //MARK: Toolbar
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button (action: { add_detail_view_presented.toggle() })
                    {
                        Label("Add Detail", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_detail_view_presented)
                    {
                        //AddToolView(add_robot_view_presented: $add_robot_view_presented, document: $document)
                    }
                }
            }
        }
    }
}

struct DetailsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        DetailsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
    }
}
