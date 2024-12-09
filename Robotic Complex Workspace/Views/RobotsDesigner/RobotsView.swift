//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.10.2021.
//

import SwiftUI
import SceneKit
import Charts
import IndustrialKit

struct RobotsView: View
{
    @State private var robot_view_presented = false
    
    var body: some View
    {
        RobotsTableView(robot_view_presented: $robot_view_presented)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        #if os(macOS) || os(iOS)
            .background(Color.white)
        #endif
    }
}

//MARK: Robot view


//MARK: - Previews
#Preview
{
    RobotsView()
        .environmentObject(AppState())
        .environmentObject(Workspace())
}
