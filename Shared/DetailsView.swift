//
//  DetailsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import SwiftUI
import SceneKit

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
                //MARK: Scroll view for details
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.details)
                        { detail_item in
                            ZStack
                            {
                                DetailCardView(card_color: detail_item.card_info().color, card_image: detail_item.card_info().image, card_title: detail_item.card_info().title)
                                DetailDeleteButton(details: $base_workspace.details, detail_item: detail_item, on_delete: remove_details)
                            }
                            /*.onTapGesture
                            {
                                view_robot(robot_index: base_workspace.robots.firstIndex(of: robot_item) ?? 0)
                            }
                            .onDrag({
                                self.dragged_robot = robot_item
                                return NSItemProvider(object: robot_item.id.uuidString as NSItemProviderWriting)
                            }, preview: {
                                RobotCardViewPreview(card_color: robot_item.card_info().color, card_image: robot_item.card_info().image, card_title: robot_item.card_info().title, card_subtitle: robot_item.card_info().subtitle)
                            })
                            .onDrop(of: [UTType.text], delegate: RobotDropDelegate(robots: $base_workspace.robots, dragged_robot: $dragged_robot, document: $document, workspace_robots: base_workspace.file_data().robots, robot: robot_item))*/
                            .transition(AnyTransition.scale)
                        }
                    }
                    .padding(20)
                }
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
                        AddDetailView(add_detail_view_presented: $add_detail_view_presented, document: $document)
                    }
                }
            }
        }
    }
    
    //MARK: Details manage functions
    func remove_details(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.details.remove(atOffsets: offsets)
            //document.preset.robots = base_workspace.file_data().robots
        }
    }
}

struct AddDetailView: View
{
    @Binding var add_detail_view_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var new_detail_name = ""
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Add Detail")
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
            
            HStack
            {
                Text("Name")
                    .bold()
                TextField("None", text: $new_detail_name)
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal)
            
            Picker(selection: $app_state.detail_name, label: Text("Model")
                    .bold())
            {
                ForEach(app_state.details, id: \.self)
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
                
                Button("Cancel", action: { add_detail_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding([.top, .leading, .bottom])
                
                Button("Save", action: add_detail_in_workspace)
                    .keyboardShortcut(.defaultAction)
                    .padding()
            }
        }
        .controlSize(.regular)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
    }
    
    func add_detail_in_workspace()
    {
        //base_workspace.add_robot(robot: Robot(name: new_robot_name, manufacturer: app_state.manufacturer_name, dictionary: app_state.robot_model_dictionary))
        //document.preset.robots = base_workspace.file_data().robots
        
        //base_workspace.elements_check()
        
        add_detail_view_presented.toggle()
    }
}

#if os(macOS)
struct DetailSceneView_macOS: NSViewRepresentable
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
        var control: DetailSceneView_macOS
        
        init(_ control: DetailSceneView_macOS, _ scn_view: SCNView)
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
        if app_state.preview_update_scene
        {
            var remove_node = scene_view.scene?.rootNode.childNode(withName: "Figure", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_detail?.node ?? SCNNode())
            app_state.preview_update_scene = false
        }
    }
}
#else
struct DetailSceneView_iOS: UIViewRepresentable
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
        scene_view.scene?.background.contents = UIColor.clear
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        let tap_gesture_recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:)))
        scene_view.addGestureRecognizer(tap_gesture_recognizer)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
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
        var control: DetailSceneView_iOS
        
        init(_ control: DetailSceneView_iOS, _ scn_view: SCNView)
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
        if app_state.preview_update_scene
        {
            var remove_node = scene_view.scene?.rootNode.childNode(withName: "Figure", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_detail?.node ?? SCNNode())
            app_state.preview_update_scene = false
        }
    }
}
#endif

//MARK: - Details card view
struct DetailCardView: View
{
    @State var card_color: Color
    #if os(macOS)
    @State var card_image: NSImage
    #else
    @State var card_image: UIImage
    #endif
    @State var card_title: String
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    Text(card_title)
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    Rectangle()
                        .overlay
                    {
                        #if os(macOS)
                        Image(nsImage: card_image)
                            .resizable()
                            .scaledToFill()
                        #else
                        Image(uiImage: card_image)
                            .resizable()
                            .scaledToFill()
                        #endif
                    }
                    .frame(width: 64, height: 64)
                    .background(Color.clear)
                    Rectangle()
                        .foregroundColor(card_color)
                    .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
    }
}

struct DetailDeleteButton: View
{
    @Binding var details: [Detail]
    
    @State private var delete_detail_alert_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    let detail_item: Detail
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Spacer()
                Button(action: { delete_detail_alert_presented = true })
                {
                    Label("Details", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .padding(4.0)
                }
                    .foregroundColor(.black)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .frame(width: 24.0, height: 24.0)
                    .padding(8.0)
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
            }
            Spacer()
        }
        .alert(isPresented: $delete_detail_alert_presented)
        {
            Alert(
                title: Text("Delete detail?"),
                message: Text("Do you wand to delete this detail – \(detail_item.card_info().title)"),
                primaryButton: .destructive(Text("Yes"), action: delete_detail),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func delete_detail()
    {
        if let index = details.firstIndex(of: detail_item)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
    }
}

//MARK: - Previews
struct DetailsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            DetailsView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
            AddDetailView(add_detail_view_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(AppState())
                .environmentObject(Workspace())
            #if os(macOS)
            DetailCardView(card_color: Color.green, card_image: NSImage(), card_title: "Detail")
            #else
            DetailCardView(card_color: Color.green, card_image: UIImage(), card_title: "Detail")
            #endif
        }
    }
}
