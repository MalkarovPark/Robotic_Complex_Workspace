//
//  ToolsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 17.03.2022.
//

import SwiftUI
import SceneKit

struct ToolsView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var add_tool_view_presented = false
    @State private var tool_view_presented = false
    @State private var dragged_tool: Tool?
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 192, maximum: .infinity), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.tools.count > 0
            {
                
            }
            else
            {
                Text("Press «+» to add new tool")
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
                    Button (action: { add_tool_view_presented.toggle() })
                    {
                        Label("Add Tool", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_tool_view_presented)
                    {
                        AddToolView(add_tool_view_presented: $add_tool_view_presented, document: $document)
                    }
                }
            }
        }
    }
}

struct AddToolView:View
{
    @Binding var add_tool_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_tool_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Add Tool")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            #if os(macOS)
            DetailSceneView_macOS()
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                .padding(.vertical, 8.0)
                .padding(.horizontal)
            #else
            DetailSceneView_iOS()
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                .padding(.vertical, 8.0)
                .padding(.horizontal)
            #endif

            /*RoundedRectangle(cornerRadius: 8, style: .continuous)
                .foregroundColor(.accentColor)
                .padding(.vertical, 8.0)
                .padding(.horizontal)*/
            
            Picker(selection: $app_state.tool_name, label: Text("Model")
                    .bold())
            {
                ForEach(app_state.tools, id: \.self)
                {
                    Text($0)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 8.0)
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            //MARK: Cancel and Save buttons
            HStack(spacing: 0)
            {
                Spacer()
                
                Button("Cancel", action: { add_tool_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: { add_tool_in_workspace() })
                    .keyboardShortcut(.defaultAction)
                    .padding()
            }
        }
        .controlSize(.regular)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
    }
    
    func add_tool_in_workspace()
    {
        
    }
}

#if os(macOS)
struct ToolSceneView_macOS: NSViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/View.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        app_state.reset_view_enabled = true
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = NSColor.clear
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        let tap_gesture_recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = NSColor.clear
        
        return scn_scene(context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        if app_state.reset_view && app_state.reset_view_enabled
        {
            app_state.reset_view = false
            app_state.reset_view_enabled = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.selected_robot.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.selected_robot.camera_node!.rotation, duration: 0.5)]), completionHandler: { app_state.reset_view_enabled = true })
        }
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_macOS
        
        init(_ control: ToolSceneView_macOS, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        @objc func handle_tap(_ gesture_recognize: NSGestureRecognizer)
        {
            let tap_location = gesture_recognize.location(in: scn_view)
            let hit_results = scn_view.hitTest(tap_location, options: [:])
            var result = SCNHitTestResult()
            
            if hit_results.count > 0
            {
                result = hit_results[0]
                
                print(result.localCoordinates)
                print("🍮 tapped – \(result.node.name!)")
            }
        }
    }
    
    func scene_check() //Render functions
    {
        base_workspace.selected_robot.update_robot()
        if base_workspace.selected_robot.moving_completed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        if base_workspace.selected_robot.performed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}
#else
struct ToolSceneView_iOS: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    
    func scn_scene(context: Context) -> SCNView
    {
        app_state.reset_view = false
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        //Connect workcell box and pointer
        base_workspace.selected_robot.workcell_connect(scene: viewed_scene, name: "unit", connect_camera: true)
        
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        
        return scn_scene(context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        if base_workspace.selected_robot.programs_count > 0
        {
            if base_workspace.selected_robot.selected_program.points_count > 0
            {
                base_workspace.selected_robot.points_node?.addChildNode(base_workspace.selected_robot.selected_program.positions_group)
            }
        }
        
        if app_state.reset_view && app_state.reset_view_enabled
        {
            app_state.reset_view = false
            app_state.reset_view_enabled = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.selected_robot.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.selected_robot.camera_node!.rotation, duration: 0.5)]), completionHandler: { app_state.reset_view_enabled = true })
        }
        
        if app_state.get_scene_image == true
        {
            app_state.get_scene_image = false
            
            base_workspace.selected_robot.image = ui_view.snapshot()
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolSceneView_iOS
        
        init(_ control: ToolSceneView_iOS, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
        
        private let scn_view: SCNView
        @objc func handle_tap(_ gesture_recognize: UIGestureRecognizer)
        {
            let tap_location = gesture_recognize.location(in: scn_view)
            let hit_results = scn_view.hitTest(tap_location, options: [:])
            var result = SCNHitTestResult()
            
            if hit_results.count > 0
            {
                result = hit_results[0]
                
                print(result.localCoordinates)
                print("🍮 tapped – \(result.node.name!)")
            }
        }
    }
    
    func scene_check()
    {
        base_workspace.selected_robot.update_robot()
        if base_workspace.selected_robot.moving_completed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.selected_robot.moving_completed = false
                base_workspace.update_view()
            }
        }
        if base_workspace.selected_robot.performed == true
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
            {
                base_workspace.update_view()
            }
        }
    }
}
#endif

struct ToolsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            ToolsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            AddToolView(add_tool_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
        }
        
    }
}
