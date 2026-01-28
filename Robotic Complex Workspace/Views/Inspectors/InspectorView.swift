//
//  InspectorView.swift
//  RCWorkspace
//
//  Created by Artem on 21.01.2026.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

struct InspectorView: View
{
    @ObservedObject var object: WorkspaceObject
    
    var body: some View
    {
        ScrollView
        {
            VStack//(alignment: .leading)
            {
                Text(object_type_name)
                    .font(.headline)
                    .padding(4)
                    //.font(.system(size: 28))//, design: .rounded))
                
                GroupBox("Name")
                {
                    HStack
                    {
                        TextField("None", text: $object.name)
                            .textFieldStyle(.plain)
                            //.textFieldStyle(.roundedBorder)
                    }
                    .padding(4)
                }
                
                GroupBox("Position")
                {
                    HStack
                    {
                        PositionView(position: $object.position)
                            .onChange(of: object)
                            { _, _ in
                                object.update_model_position()
                            }
                    }
                    .padding(4)
                }
                
                Spacer()
            }
            .padding(10)
        }
    }
    
    private var object_type_name: String
    {
        switch object
        {
        case is Robot:
            return "Robot"
        case is Tool:
            return "Tool"
        case is Part:
            return "Part"
        default:
            return "None"
        }
    }
}

#Preview
{
    InspectorView(object: Robot(name: "Robot"))
}
