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
            AddRobotView(add_robot_view_presented: .constant(true))
        }
    }
}

struct RobotsTableView: View
{
    @Binding var display_rv: Bool
    @State private var add_robot_view_presented = false
    
    var body: some View
    {
        VStack
        {
            Button("View Robot")
            {
                self.display_rv = true
            }
            Button(action: { add_robot_view_presented.toggle() })
            {
                Text("Add Robot")
            }
            .sheet(isPresented: $add_robot_view_presented)//, onDismiss: didDismiss)
            {
                AddRobotView(add_robot_view_presented: $add_robot_view_presented)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    @State var new_robot_name = ""
    @State var new_robot_parameters = ["Brand", "Series", "Model"]
    @State var new_robot_parameters_index = [0, 0, 0]
    
    var brands = ["Fanuc", "Kuka"]
    var series = ["LR-Mate", "Paint"]
    var models = ["id-4s", "id-20s"]
    
    var body: some View
    {
        let button_padding = 16.0
        
        VStack
        {
            Text("Add Robot")
                .font(.title)
                .padding([.top, .leading, .trailing])
            
            VStack
            {
                HStack
                {
                    Text("Name")
                        .bold()
                    TextField("None", text: $new_robot_name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Picker(selection: .constant(1), label: Text("Brand")
                        .bold())
                {
                    Text("Fanuc").tag(1)
                    Text("Kuka").tag(2)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker(selection: .constant(1), label: Text("Series")
                        .bold())
                {
                    Text("LR-Mate").tag(1)
                    Text("Paint").tag(2)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
                
                Picker(selection: .constant(1), label: Text("Model")
                        .bold())
                {
                    Text("id-4s").tag(1)
                    Text("id-20s").tag(2)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
            }
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            HStack
            {
                Spacer()
                
                #if os(macOS)
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding - 8.0)
                
                Button("Save", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.defaultAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding)
                #else
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding - 8.0)
                
                Button("Save", action: { add_robot_view_presented.toggle() })
                    .font(.headline)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .controlSize(.large)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #endif
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
