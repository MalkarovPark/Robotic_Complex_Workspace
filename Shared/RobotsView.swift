//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit

struct RobotsView: View
{
    @State private var display_rv = false
    
    var body: some View
    {
        HStack
        {
            if display_rv == false
            {
                RobotsTableView(display_rv: $display_rv)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    //.transition(AnyTransition.move(edge: .leading)).animation(.default)
            }
            if display_rv == true
            {
                RobotView(display_rv: $display_rv)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    //.transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #endif
    }
}

struct RobotsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            RobotsView()
            RobotView(display_rv: .constant(true))
            AddRobotView(display_arv: .constant(true))
        }
    }
}

struct RobotsTableView: View
{
    @Binding var display_rv: Bool
    @State private var display_arv = false
    
    var body: some View
    {
        VStack
        {
            Button("View Robot")
            {
                self.display_rv = true
            }
            Button(action: { display_arv.toggle() })
            {
                Text("Add Robot")
            }
            .sheet(isPresented: $display_arv)//, onDismiss: didDismiss)
            {
                AddRobotView(display_arv: $display_arv)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct AddRobotView: View
{
    @Binding var display_arv: Bool
    
    var body: some View
    {
        /*NavigationView
        {
            Text("List of notifications")
            //.navigationBarTitle(Text("Notifications"), displayMode: .inline)
        }*/
        VStack
        {
            Text("Big Label")
                .font(.title)
                .padding(50)
            Text("Text")
                .padding(50)
            Spacer()
            Divider()
            HStack
            {
                Spacer()
                Button("Cancel", action: { display_arv.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding(.top, 8.0)
                    .padding(.bottom, 16.0)
                    .padding(.trailing, 8.0)
                Button("Save", action: { display_arv.toggle() })
                    .keyboardShortcut(.defaultAction)
                    .padding(.top, 8.0)
                    .padding(.bottom, 16.0)
                    .padding(.trailing, 16.0)
            }
        }
        .frame(minWidth: 320, minHeight: 240)
    }
}

struct RobotView: View
{
    @Binding var display_rv: Bool
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        HStack
        {
            RobotSceneView()
            RobotInspectorView(display_rv: $display_rv)//.frame(width: 80)
        }
        
        .toolbar
        {
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "stop")
                    }
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "playpause")
                    }
                }
            }
        }
    }
    
    func add_robot()
    {
        print("🔮")
    }
}

struct RobotSceneView: View
{
    let robot_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    var viewed_scene: SCNScene?
    {
        robot_scene
    }
    
    var camera_node: SCNNode?
    {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        return cameraNode
    }
    
    var body: some View
    {
        SceneView(scene: viewed_scene, pointOfView: camera_node, options: [.allowsCameraControl, .autoenablesDefaultLighting])
        .onAppear
        {
            print("View Loaded")
        }
        #if os(iOS)
        .cornerRadius(8)
        .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))//(20)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct RobotInspectorView: View
{
    @Binding var display_rv: Bool
    
    var body: some View
    {
        VStack
        {
            Button("Back to robots table")
            {
                self.display_rv = false
            }
            .padding()
            Text("Inspector View")
                .padding()
        }
    }
}
