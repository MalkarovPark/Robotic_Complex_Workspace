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
    
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    @State private var wv_selection = 0
    private let wv_items: [String] = ["View", "Control"]
    #endif
    
    var body: some View
    {
        #if os(macOS)
        let placement_trailing: ToolbarItemPlacement = .automatic
        #else
        let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
        #endif
        
        HStack(spacing: 0)
        {
            #if os(macOS)
            ComplexWorkspaceView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
            ControlProgramView(document: $document)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                .frame(width: 256)
            #else
            if horizontal_size_class == .compact
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
            else
            {
                ComplexWorkspaceView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                ControlProgramView(document: $document)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .frame(width: 288)
            }
            #endif
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #else
            .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #endif
        
        .toolbar
        {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction)
            {
                if horizontal_size_class == .compact
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
            }
            #endif
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button(action: change_cycle)
                    {
                        if cycle == false
                        {
                            Label("One", systemImage: "repeat.1")
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
            .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8)) //(8.0)
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
    @State var add_new_element_data = workspace_program_element_struct()
    
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
                    ZStack(alignment: .trailing)
                    {
                        Button(action: add_new_program_element)
                        {
                            HStack
                            {
                                Text("Add Element")
                                Spacer()
                            }
                            .padding()
                        }
                        #if os(macOS)
                        .frame(maxWidth: 144.0, alignment: .leading)
                        #else
                        .frame(maxWidth: 176.0, alignment: .leading)
                        #endif
                        .background(.thinMaterial)
                        .cornerRadius(32)
                        .shadow(radius: 4.0)
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding()
                        
                        Button(action: { add_element_view_presented.toggle() })
                        {
                            Circle()
                                .foregroundColor(add_button_color())
                                .overlay(
                                    add_button_image()
                                        .foregroundColor(.white)
                                        .animation(.easeInOut(duration: 0.2), value: add_button_image())
                                )
                                .frame(width: 32, height: 32)
                                .animation(.easeInOut(duration: 0.2), value: add_button_color())
                        }
                        .popover(isPresented: $add_element_view_presented)
                        {
                            AddElementView(add_element_view_presented: $add_element_view_presented, add_new_element_data: $add_new_element_data)
                        }
                        #if os(macOS)
                        .buttonStyle(BorderlessButtonStyle())
                        #endif
                        .padding(.trailing, 24)
                    }
                }
            }
        }
    }
    
    func add_new_program_element()
    {
        base_workspace.update_view()
        var new_program_element = WorkspaceProgramElement(element_type: add_new_element_data.element_type, performer_type: add_new_element_data.performer_type, modificator_type: add_new_element_data.modificator_type, logic_type: add_new_element_data.logic_type)
        
        //Checking for existing workspace components for element selection
        switch new_program_element.element_data.element_type
        {
        case .perofrmer:
            switch new_program_element.element_data.performer_type
            {
            case .robot:
                if base_workspace.robots.count > 0
                {
                    new_program_element.element_data.robot_name = base_workspace.robots[0].name!
                    if base_workspace.robots[0].programs_count > 0
                    {
                        new_program_element.element_data.robot_program_name = base_workspace.robots[0].programs_names[0]
                    }
                }
            case .tool:
                break
            }
        case .modificator:
            break
        case .logic:
            break
        }
        
        base_workspace.elements.append(new_program_element)
    }
    
    func add_button_image() -> Image
    {
        var badge_image: Image
        
        switch add_new_element_data.element_type
        {
        case .perofrmer:
            switch add_new_element_data.performer_type
            {
            case .robot:
                badge_image = Image(systemName: "r.square")
            case .tool:
                badge_image = Image(systemName: "hammer")
            }
        case .modificator:
            switch add_new_element_data.modificator_type
            {
            case .observer:
                badge_image = Image(systemName: "loupe")
            case .changer:
                badge_image = Image(systemName: "wand.and.rays")
            }
        case .logic:
            switch add_new_element_data.logic_type
            {
            case .jump:
                badge_image = Image(systemName: "arrowshape.bounce.forward")
            case .mark:
                badge_image = Image(systemName: "record.circle")
            case .equal:
                badge_image = Image(systemName: "equal")
            case .unequal:
                badge_image = Image(systemName: "lessthan")
            }
        }
        
        return badge_image
    }
    
    func add_button_color() -> Color
    {
        var badge_color: Color
        
        switch add_new_element_data.element_type
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
                        //.font(.system(size: 32))
                    }
                    .frame(width: 48, height: 48)
                    .background(badge_color())
                    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: badge_color())
                    
                    VStack(alignment: .leading)
                    {
                        Text(element_item.subtype)
                            .font(.title3)
                            .animation(.easeInOut(duration: 0.2), value: element_item.element_data.element_type.rawValue)
                        Text(element_item.info)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut(duration: 0.2), value: element_item.info)
                    }
                    .padding([.trailing], 32.0)
                }
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
            case .mark:
                badge_image = Image(systemName: "record.circle")
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
    @Binding var add_new_element_data: workspace_program_element_struct
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            VStack
            {
                Picker("Type", selection: $add_new_element_data.element_type)
                {
                    ForEach(ProgramElementType.allCases, id: \.self)
                    { type in
                        Text(type.localizedName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.bottom, 8.0)
                
                HStack(spacing: 16)
                {
                    #if os(iOS)
                    Text("Type")
                        .font(.subheadline)
                    #endif
                    switch add_new_element_data.element_type
                    {
                    case .perofrmer:
                        
                        Picker("Type", selection: $add_new_element_data.performer_type)
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
                        Picker("Type", selection: $add_new_element_data.modificator_type)
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
                        Picker("Type", selection: $add_new_element_data.logic_type)
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
                switch new_element_item_data.element_type
                {
                case .perofrmer:
                    PerformerElementView(performer_type: $new_element_item_data.performer_type, robot_name: $new_element_item_data.robot_name, robot_program_name: $new_element_item_data.robot_program_name, tool_name: $new_element_item_data.tool_name)
                case .modificator:
                    ModificatorElementView(modificator_type: $new_element_item_data.modificator_type)
                case .logic:
                    LogicElementView(logic_type: $new_element_item_data.logic_type, mark_name: $new_element_item_data.mark_name, target_mark_name: $new_element_item_data.target_mark_name)
                }
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
        base_workspace.elements_check()
        
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
        if let index = elements.firstIndex(of: element_item)
        {
            self.on_delete(IndexSet(integer: index))
            base_workspace.elements_check()
        }
    }
}

struct PerformerElementView: View
{
    @Binding var performer_type: PerformerType
    @Binding var robot_name: String
    @Binding var robot_program_name: String
    @Binding var tool_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            switch performer_type
            {
            case .robot:
                if base_workspace.robots.count > 0
                {
                    #if os(macOS)
                    Picker("Name", selection: $robot_name)
                    {
                        if base_workspace.robots_names.count > 0
                        {
                            ForEach(base_workspace.robots_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .onChange(of: robot_name)
                    { _ in
                        base_workspace.select_robot(name: robot_name)
                        if base_workspace.selected_robot.programs_names.count > 0
                        {
                            robot_program_name = base_workspace.selected_robot.programs_names[0]
                        }
                        base_workspace.update_view()
                    }
                    .onAppear
                    {
                        if robot_name == ""
                        {
                            robot_name = base_workspace.robots_names[0]
                        }
                        else
                        {
                            base_workspace.select_robot(name: robot_name)
                            base_workspace.update_view()
                        }
                    }
                    .disabled(base_workspace.robots_names.count == 0)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Program", selection: $robot_program_name)
                    {
                        if base_workspace.selected_robot.programs_names.count > 0
                        {
                            ForEach(base_workspace.selected_robot.programs_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .disabled(base_workspace.selected_robot.programs_names.count == 0)
                    #else
                    VStack
                    {
                        GeometryReader
                        { geometry in
                            HStack(spacing: 0)
                            {
                                Picker("Name", selection: $robot_name)
                                {
                                    if base_workspace.robots_names.count > 0
                                    {
                                        ForEach(base_workspace.robots_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .onChange(of: robot_name)
                                { _ in
                                    base_workspace.select_robot(name: robot_name)
                                    if base_workspace.selected_robot.programs_names.count > 0
                                    {
                                        robot_program_name = base_workspace.selected_robot.programs_names[0]
                                    }
                                    base_workspace.update_view()
                                }
                                .onAppear
                                {
                                    if robot_name == ""
                                    {
                                        robot_name = base_workspace.robots_names[0]
                                    }
                                    else
                                    {
                                        base_workspace.select_robot(name: robot_name)
                                        base_workspace.update_view()
                                    }
                                }
                                .disabled(base_workspace.robots_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                                
                                Picker("Program", selection: $robot_program_name)
                                {
                                    if base_workspace.selected_robot.programs_names.count > 0
                                    {
                                        ForEach(base_workspace.selected_robot.programs_names, id: \.self)
                                        { name in
                                            Text(name)
                                        }
                                    }
                                    else
                                    {
                                        Text("None")
                                    }
                                }
                                .disabled(base_workspace.selected_robot.programs_names.count == 0)
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                                .compositingGroup()
                                .clipped()
                            }
                        }
                    }
                    .frame(height: 128)
                    #endif
                }
                else
                {
                    Text("No robots in this workspace")
                }
            case .tool:
                Text("Tool")
            }
        }
    }
}

struct ModificatorElementView: View
{
    @Binding var modificator_type: ModificatorType
    var body: some View
    {
        Text("Modificator")
        switch modificator_type
        {
        case .observer:
            Text("Observer")
        case .changer:
            Text("Changer")
        }
    }
}

struct LogicElementView: View
{
    @Binding var logic_type: LogicType
    @Binding var mark_name: String
    @Binding var target_mark_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        VStack
        {
            switch logic_type
            {
            case .jump:
                #if os(macOS)
                HStack
                {
                    Picker("To Mark:", selection: $target_mark_name)
                    {
                        if base_workspace.marks_names.count > 0
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        else
                        {
                            Text("None")
                        }
                    }
                    .onAppear
                    {
                        if base_workspace.marks_names.count > 0 && target_mark_name == ""
                        {
                            target_mark_name = base_workspace.marks_names[0]
                        }
                    }
                    .disabled(base_workspace.marks_names.count == 0)
                }
                #else
                VStack
                {
                    if base_workspace.marks_names.count > 0
                    {
                        Text("To mark:")
                        Picker("To Mark:", selection: $target_mark_name)
                        {
                            ForEach(base_workspace.marks_names, id: \.self)
                            { name in
                                Text(name)
                            }
                        }
                        .onAppear
                        {
                            if base_workspace.marks_names.count > 0 && target_mark_name == ""
                            {
                                target_mark_name = base_workspace.marks_names[0]
                            }
                        }
                        .disabled(base_workspace.marks_names.count == 0)
                        .pickerStyle(.wheel)
                    }
                    else
                    {
                        Text("No marks")
                    }
                }
                #endif
            case .mark:
                HStack
                {
                    Text("Name")
                    TextField("None", text: $mark_name)
                }
            case .equal:
                Text("Equal")
            case .unequal:
                Text("Unequal")
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
            ElementCardView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), element_item: WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot), on_delete: { IndexSet in print("None") })
            ElementView(elements: .constant([WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)]), element_item: .constant(WorkspaceProgramElement(element_type: .perofrmer, performer_type: .robot)), element_view_presented: .constant(true), new_element_item_data: workspace_program_element_struct(element_type: .logic, performer_type: .robot, modificator_type: .changer, logic_type: .jump), on_delete: { IndexSet in print("None") })
                .environmentObject(Workspace())
            //PerformerElementView(performer_type: .constant(.robot), robot_name: .constant("Robot"), robot_program_name: .constant("Robot Program"), tool_name: .constant("Tool"))
                //.environmentObject(Workspace())
            LogicElementView(logic_type: .constant(.mark), mark_name: .constant("Mark Name"), target_mark_name: .constant("Target Mark Name"))
        }
    }
}
