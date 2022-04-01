//
//  WorkspaceView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit

struct WorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    @State var cycle = false
    @State var worked = false
    @State private var wv_selection = 0
    
    private let wv_items: [String] = ["View", "Control"]
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        VStack
        {
            if wv_selection == 0
            {
                ComplexWorkspaceView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
            else
            {
                ControlProgramView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        #if os(iOS)
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        #else
            .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #endif
        
        .toolbar
        {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction)
            {
                Picker("Workspace", selection: $wv_selection)
                {
                    ForEach(0..<wv_items.count, id: \.self)
                    { index in
                        Text(self.wv_items[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
            }
            #endif
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    #if os(macOS)
                    Picker("Workspace", selection: $wv_selection)
                    {
                        ForEach(0..<wv_items.count, id: \.self)
                        { index in
                            Text(self.wv_items[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    #endif
                    
                    Button(action: change_cycle)
                    {
                        if cycle == false
                        {
                            Label("Repeat", systemImage: "repeat.1")
                        }
                        else
                        {
                            Label("Repeat", systemImage: "repeat")
                        }
                    }
                    Button(action: add_robot)
                    {
                        Label("Reset", systemImage: "stop")
                    }
                    Button(action: change_work)
                    {
                        Label("PlayPause", systemImage: "playpause")
                    }
                    /*Divider()
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "plus")
                    }*/
                }
            }
        }
    }
    
    func add_robot()
    {
        print("🪄")
    }
    
    func change_work()
    {
        print("🪄")
    }
    
    func change_cycle()
    {
        cycle.toggle()
    }
}

struct ComplexWorkspaceView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    var body: some View
    {
        #if os(macOS)
        WorkspaceSceneView_macOS()
        #else
        WorkspaceSceneView_iOS()
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            .padding(8.0)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if os(macOS)
struct WorkspaceSceneView_macOS: NSViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workspace.scn")!
    
    func scn_scene(stat: Bool, context: Context) -> SCNView
    {
        app_state.reset_view = false
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeNSView(context: Context) -> SCNView
    {
        //Begin commands
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        return scn_scene(stat: true, context: context)
    }

    func updateNSView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        //Update commands
        
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.camera_node!.rotation, duration: 0.5)]))
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: WorkspaceSceneView_macOS
        
        init(_ control: WorkspaceSceneView_macOS)
        {
            self.control = control
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
    }
    
    func scene_check()
    {
        //Parallel commands
    }
}
#else
struct WorkspaceSceneView_iOS: UIViewRepresentable
{
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    let scene_view = SCNView(frame: .zero)
    let viewed_scene = SCNScene(named: "Components.scnassets/Workspace.scn")!
    
    func scn_scene(stat: Bool, context: Context) -> SCNView
    {
        app_state.reset_view = false
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        return scene_view
    }
    
    func makeUIView(context: Context) -> SCNView
    {
        //Begin commands
        base_workspace.camera_node = viewed_scene.rootNode.childNode(withName: "camera", recursively: true)
        
        return scn_scene(stat: true, context: context)
    }

    func updateUIView(_ ui_view: SCNView, context: Context)
    {
        ui_view.allowsCameraControl = true
        ui_view.rendersContinuously = true
        
        //Update commands
        
        if app_state.reset_view == true
        {
            app_state.reset_view = false
            
            ui_view.defaultCameraController.pointOfView?.runAction(
                SCNAction.group([SCNAction.move(to: base_workspace.camera_node!.worldPosition, duration: 0.5), SCNAction.rotate(toAxisAngle: base_workspace.camera_node!.rotation, duration: 0.5)]))
        }
    }
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: WorkspaceSceneView_iOS
        
        init(_ control: WorkspaceSceneView_iOS)
        {
            self.control = control
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.scene_check()
        }
    }
    
    func scene_check()
    {
        //Parallel commands
    }
}
#endif

struct ControlProgramView: View
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @State private var program_columns = Array(repeating: GridItem(.flexible()), count: 1)
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        //Text("Robots in workspace – \(document.preset.robots_count)")
        ScrollView
        {
            LazyVGrid(columns: program_columns) {
                ForEach(base_workspace.elements)
                { element in
                    ZStack
                    {
                        ElementCardView(elements: $base_workspace.elements, element_item: element, on_delete: remove_elements)
                    }
                }
                .padding(4)
            }
            .padding()
        }
        .animation(.spring(), value: base_workspace.elements)
    }
    
    func remove_elements(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.elements.remove(atOffsets: offsets)
            //document.preset.robots_count = base_workspace.file_data().count
            //document.preset.robots = base_workspace.file_data().robots
        }
    }
}

struct ElementCardView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    
    @State var element_item: WorkspaceProgramElement
    @State var element_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    ObjectBadge()
                    VStack(alignment: .leading)
                    {
                        Text(element_item.name)
                            .font(.title3)
                        Text("\(element_item.type_info)")
                            .foregroundColor(.secondary)
                    }
                    .padding([.trailing], 32.0)
                    //Divider().padding()
                    
                    //Spacer()
                }
                //Spacer()
            }
        }
        .frame(height: 80)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
        .onTapGesture
        {
            element_view_presented.toggle()
            //element_item.clear_new_data()
        }
        .popover(isPresented: $element_view_presented,
                 arrowEdge: .trailing)
        {
            ElementView(elements: $elements, element_item: $element_item, element_view_presented: $element_view_presented, element_item2: workspace_program_struct(name: element_item.name, type: element_item.type, performer_type: element_item.performer_type, modificator_type: element_item.modificator_type, logic_type: element_item.logic_type), on_delete: on_delete)
        }
    }
}

struct ObjectBadge: View
{
    var body: some View
    {
        ZStack
        {
            Image("factory.robot") //(systemName: "applelogo")
                .foregroundColor(.white)
                .imageScale(.large)
            //.font(.system(size: 32))
        }
        .frame(width: 48, height: 48)
        .background(.green)
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .padding(16)
    }
}

struct ElementView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var element_item: WorkspaceProgramElement
    @Binding var element_view_presented: Bool
    
    @State var element_item2: workspace_program_struct
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                Picker("Type", selection: $element_item2.type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                /*.onChange(of: element_item2.type)
                { _ in
                    update_program_element()
                }*/
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.bottom, 8.0)
                
                switch element_item2.type
                {
                case .perofrmer:
                    Picker("Type", selection: $element_item2.performer_type)
                    {
                        ForEach(PerformerType.allCases, id: \.self)
                        { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                case .modificator:
                    Picker("Type", selection: $element_item2.modificator_type)
                    {
                        ForEach(ModificatorType.allCases, id: \.self)
                        { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                case .logic:
                    Picker("Type", selection: $element_item2.logic_type)
                    {
                        ForEach(LogicType.allCases, id: \.self)
                        { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                }
            }
            .padding()
            Divider()
            
            Spacer()
            
            VStack
            {
                /*switch element_item.new_type[0]
                {
                case 0:
                    switch element_item.new_type[1]
                    {
                    case 0:
                        Picker("Name", selection: $element_item.new_device_index)
                        {
                            ForEach(0..<base_workspace.robots.count, id: \.self)
                            { index in
                                Text(base_workspace.robots[index].robot_info.name).tag(index)
                            }
                        }
                    case 1:
                        Text("Tool")
                    default:
                        Text("None")
                    }
                case 1:
                    switch element_item.type[1]
                    {
                    case 0:
                        Text("Observer")
                    case 1:
                        Text("Other")
                    default:
                        Text("None")
                    }
                default:
                    Text("None")
                }*/
                
                Text("None")
            }
            .padding()
            
            Spacer()
            
            Divider()
            HStack
            {
                Button("Delete", action: { delete_program_element() })
                    .padding()
                
                Spacer()
                
                Button("Save", action: { update_program_element() })
                    .keyboardShortcut(.defaultAction)
                    .padding()
                #if os(macOS)
                    .foregroundColor(Color.white)
                #endif
            }
        }
    }
    
    func update_program_element()
    {
        element_item.type = element_item2.type
        element_item.performer_type = element_item2.performer_type
        element_item.modificator_type = element_item2.modificator_type
        element_item.logic_type = element_item2.logic_type
        
        //base_workspace.update_view()
        
        element_view_presented.toggle()
    }
    
    func delete_program_element()
    {
        delete_element()
        base_workspace.update_view()
        //document.preset.robots = base_workspace.file_data().robots
        
        element_view_presented.toggle()
    }
    
    func delete_element()
    {
        print(element_item)
        if let index = elements.firstIndex(of: element_item)
        {
            print("☕️ \(index)")
            self.on_delete(IndexSet(integer: index))
        }
    }
}

struct WorkspaceView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            WorkspaceView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .environmentObject(AppState())
            ControlProgramView(document: .constant(Robotic_Complex_WorkspaceDocument()))
                .environmentObject(Workspace())
                .frame(width: 640, height: 480)
            //ElementCardView()
            //ElementView(element_view_presented: .constant(true), element_index: 0, device_index: 0, type: [0, 0])
                //.environmentObject(Workspace())
        }
    }
}
