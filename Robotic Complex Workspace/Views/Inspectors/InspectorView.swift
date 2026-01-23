//
//  InspectorView.swift
//  RCWorkspace
//
//  Created by Artem on 21.01.2026.
//

import SwiftUI
import IndustrialKitUI

struct InspectorView: View
{
    @State private var object_name = "Workspace Object"
    @State private var position: (x: Float, y: Float, z: Float, r: Float, p: Float, w: Float) = (x: 0, y: 0, z: 0, r: 0, p: 0, w: 0)
    
    var body: some View
    {
        ScrollView
        {
            VStack
            {
                Text(object_name)
                    .font(.headline)
                    //.font(.system(size: 28))//, design: .rounded))
                
                GroupBox("Position")
                {
                    HStack
                    {
                        PositionView(position: $position)
                    }
                    .padding(4)
                }
                
                Spacer()
            }
            .padding(10)
        }
    }
}

#Preview
{
    InspectorView()
}
