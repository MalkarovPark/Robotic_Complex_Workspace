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
    
    #if os(macOS)
    @EnvironmentObject var app_state: AppState
    #endif
    
    var body: some View
    {
        ZStack
        {
            if !robot_view_presented
            {
                //Display robots table view
                RobotsTableView(robot_view_presented: $robot_view_presented)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                #if os(macOS) || os(iOS)
                    .background(Color.white)
                #endif
            }
            else
            {
                //Display robot view when selected
                RobotView(robot_view_presented: $robot_view_presented)
                #if os(macOS)
                    .frame(maxWidth: app_state.force_resize_view ? 32 : .infinity, maxHeight: app_state.force_resize_view ? 32 : .infinity)
                #endif
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
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
