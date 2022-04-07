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
    @State var add_element_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
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
            
            VStack
            {
                Spacer()
                HStack
                {
                    Spacer()
                    Button(action: { add_element_view_presented.toggle() })
                    {
                        Label("Add Element", systemImage: "plus")
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .padding(8.0)
                    }
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .frame(width: 16.0, height: 16.0)
                    .shadow(radius: 4.0)
                    .popover(isPresented: $add_element_view_presented)
                    {
                        AddElementView(add_element_view_presented: $add_element_view_presented)
                    }
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                    .padding(32.0)
                }
            }
        }
    }
    
    func remove_elements(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.elements.remove(atOffsets: offsets)
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
                    ZStack
                    {
                        badge_image()
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .animation(.easeInOut(duration: 0.2), value: badge_image())
                        //("factory.robot") //(systemName: "applelogo")
                        //.font(.system(size: 32))
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: badge_color())
                    
                    VStack(alignment: .leading)
                    {
                        Text(element_item.element_data.element_type.rawValue)
                            .font(.title3)
                            .animation(.easeInOut(duration: 0.2), value: element_item.element_data.element_type.rawValue)
                        Text(element_item.type_info)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: element_item.type_info)
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
        }
        .popover(isPresented: $element_view_presented,
                 arrowEdge: .trailing)
        {
            ElementView(elements: $elements, element_item: $element_item, element_view_presented: $element_view_presented, new_element_item_data: element_item.element_data, on_delete: on_delete)
        }
    }
    
    func badge_image() -> Image
    {
        var badge_image: Image
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            switch element_item.element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modificator:
            switch element_item.element_data.modificator_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch element_item.element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    func badge_color() -> Color
    {
        var badge_color: Color
        
        switch element_item.element_data.element_type
        {
        case .perofrmer:
            badge_color = .green
        case .modificator:
            badge_color = .pink
        case .logic:
            badge_color = .gray
        }
        
        return badge_color
    }
}

struct AddElementView: View
{
    @Binding var add_element_view_presented: Bool
    
    var body: some View
    {
        VStack
        {
            Text("None")
                .padding(64)
        }
    }
}

struct ElementView: View
{
    @Binding var elements: [WorkspaceProgramElement]
    @Binding var element_item: WorkspaceProgramElement
    @Binding var element_view_presented: Bool
    
    @State var new_element_item_data: workspace_program_element_struct
    
    @EnvironmentObject var base_workspace: Workspace
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                Picker("Type", selection: $new_element_item_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                /*.onChange(of: new_element_item_data.element_type)
                { _ in
                    update_program_element()
                }*/
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.bottom, 8.0)
                
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch new_element_item_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $new_element_item_data.performer_type)
                        {
                            ForEach(PerformerType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .modificator:
                        Picker("Type", selection: $new_element_item_data.modificator_type)
                        {
                            ForEach(ModificatorType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    case .logic:
                        Picker("Type", selection: $new_element_item_data.logic_type)
                        {
                            ForEach(LogicType.allCases, id: \.self)
                            { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        #if os(iOS)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous) .stroke(Color.accentColor, lineWidth: 2))
                        #endif
                    }
                }
            }
            .padding()
            Divider()
            
            Spacer()
            
            VStack
            {
                Text("None")
            }
            .padding()
            
            Spacer()
            
            Divider()
            HStack
            {
                Button("Delete", action: delete_program_element)
                    .padding()
                
                Spacer()
                
                Button("Save", action: update_program_element)
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
        element_item.element_data = new_element_item_data
        
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
            self.on_delete(IndexSet(integer: index))
        }
    }
}

struct ElementAddButton: View
{
    var body: some View
    {
        VStack
        {
            Spacer()
            HStack
            {
                Spacer()
                Button(action: { print("🍪") })
                {
                    Label("Add Point", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .padding(8.0)
                }
                .foregroundColor(.white)
                .background(Color.accentColor)
                .clipShape(Circle())
                .frame(width: 24.0, height: 24.0)
                .shadow(radius: 4.0)
                #if os(macOS)
                .buttonStyle(BorderlessButtonStyle())
                #endif
                .padding(32.0)
            }
        }
    }
}

struct WorkspaceView_Previews: PreviewProvider
{
    @EnvironmentObject var base_workspace: Workspace
    
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
            //ElementView(elements: <#T##[WorkspaceProgramElement]#>, element_item: <#T##WorkspaceProgramElement#>, element_view_presented: <#T##Bool#>, new_element_item_data: <#T##workspace_program_element_struct#>, base_workspace: <#T##Workspace#>, on_delete: <#T##(IndexSet) -> Void#>)
        }
    }
}
