//
//  AddObjectView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.09.2024.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI
import RealityKit

struct AddObjectView: View
{
    @Binding var is_presented: Bool
    
    private let columns: [GridItem] = [.init(.adaptive(minimum: 128, maximum: .infinity), spacing: 24)]
    private let card_spacing: CGFloat = 24
    private let card_height: CGFloat = 128
    
    #if !os(visionOS)
    private let top_spacing: CGFloat = 48
    private let bottom_spacing: CGFloat = 0//40
    #else
    private let top_spacing: CGFloat = 96
    private let bottom_spacing: CGFloat = 44
    #endif
    
    #if os(macOS)
    @State var tab_selection: ObjectItem = .robots
    #endif
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            switch tab_selection
            {
            case .robots:
                AddRobotView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
            case .tools:
                AddToolView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
            case .parts:
                AddPartView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
            }
            #else
            TabView
            {
                Tab("Robots", systemImage: "r.square")
                {
                    AddRobotView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
                }
                
                Tab("Tools", systemImage: "hammer")
                {
                    AddToolView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
                }
                
                Tab("Parts", systemImage: "shippingbox")
                {
                    AddPartView(columns: columns, card_spacing: card_spacing, card_height: card_height, top_spacing: top_spacing, bottom_spacing: bottom_spacing)
                }
            }
            .tabViewStyle(.tabBarOnly)
            #endif
        }
        .modifier(ViewCloseButton(is_presented: $is_presented))
        #if os(macOS)
        .overlay(alignment: .top)
        {
            HStack
            {
                // MARK: Type picker
                Picker("Type", selection: $tab_selection)
                {
                    ForEach(ObjectItem.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                //.padding(10)
            }
            .glassEffect()
            .padding(14)
            .controlSize(.large)
        }
        #endif
        //.modifier(SheetCaption(is_presented: $is_presented, label: "Library", plain: false))
    }
}

#if os(macOS)
enum ObjectItem: String, Codable, Equatable, CaseIterable
{
    case robots = "Robots"
    case tools = "Tools"
    case parts = "Parts"
    
    var image_name: String // Names of sidebar items symbols
    {
        switch self
        {
        case .robots:
            return "r.square"
        case .tools:
            return "hammer"
        case .parts:
            return "shippingbox"
        }
    }
}
#endif

/*#Preview
{
    AddObjectView(is_presented: .constant(true))
}*/

struct AddObjectView_PreviewsContainer: PreviewProvider
{
    struct Container: View
    {
        var body: some View
        {
            ZStack
            {
                Rectangle()
                    .foregroundStyle(.white)
                
                AddObjectView(is_presented: .constant(true))
                    .frame(width: 420, height: 480)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 16)
                    .padding(48)
            }
        }
    }
    
    static var previews: some View
    {
        Container()
    }
}

struct AddRobotView: View
{
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    var body: some View
    {
        ScrollView
        {
            if top_spacing > 0
            {
                Spacer(minLength: top_spacing)
            }
            
            LazyVGrid(columns: columns, spacing: card_spacing)
            {
                ForEach(Robot.internal_modules)
                { module in
                    GlassBoxCard(
                        title: module.name,
                        entity: module.entity,
                        vertical_repostion: true,
                    )
                    .frame(height: card_height)
                    .onTapGesture
                    {
                        print("Tapped – \(module.name)")
                    }
                }
            }
            .padding()
            
            if Robot.external_modules.count > 0
            {
                Text("External")
                    .font(.headline)
                
                LazyVGrid(columns: columns, spacing: card_spacing)
                {
                    ForEach(Robot.external_modules)
                    { module in
                        GlassBoxCard(
                            title: module.name,
                            entity: module.entity,
                            vertical_repostion: true,
                        )
                        .frame(height: card_height)
                        .onTapGesture
                        {
                            print("Tapped – \(module.name)")
                        }
                    }
                }
                .padding()
            }
            
            if bottom_spacing > 0
            {
                Spacer(minLength: bottom_spacing)
            }
        }
    }
}

struct AddToolView: View
{
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    var body: some View
    {
        ScrollView
        {
            if top_spacing > 0
            {
                Spacer(minLength: top_spacing)
            }
            
            LazyVGrid(columns: columns, spacing: card_spacing)
            {
                ForEach(Tool.internal_modules)
                { module in
                    GlassBoxCard(
                        title: module.name,
                        entity: module.entity,
                        vertical_repostion: true,
                    )
                    .frame(height: card_height)
                    .onTapGesture
                    {
                        print("Tapped – \(module.name)")
                    }
                }
            }
            .padding()
            
            if Tool.external_modules.count > 0
            {
                Text("External")
                    .font(.headline)
                
                LazyVGrid(columns: columns, spacing: card_spacing)
                {
                    ForEach(Tool.external_modules)
                    { module in
                        GlassBoxCard(
                            title: module.name,
                            entity: module.entity,
                            vertical_repostion: true,
                        )
                        .frame(height: card_height)
                        .onTapGesture
                        {
                            print("Tapped – \(module.name)")
                        }
                    }
                }
                .padding()
            }
            
            if bottom_spacing > 0
            {
                Spacer(minLength: bottom_spacing)
            }
        }
    }
}

struct AddPartView: View
{
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    var body: some View
    {
        ScrollView
        {
            if top_spacing > 0
            {
                Spacer(minLength: top_spacing)
            }
            
            LazyVGrid(columns: columns, spacing: card_spacing)
            {
                ForEach(Part.internal_modules)
                { module in
                    GlassBoxCard(
                        title: module.name,
                        entity: module.entity,
                        vertical_repostion: true,
                    )
                    .frame(height: card_height)
                    .onTapGesture
                    {
                        print("Tapped – \(module.name)")
                    }
                }
            }
            .padding()
            
            if Part.external_modules.count > 0
            {
                Text("External")
                    .font(.headline)
                
                LazyVGrid(columns: columns, spacing: card_spacing)
                {
                    ForEach(Part.external_modules)
                    { module in
                        GlassBoxCard(
                            title: module.name,
                            entity: module.entity,
                            vertical_repostion: true,
                        )
                        .frame(height: card_height)
                        .onTapGesture
                        {
                            print("Tapped – \(module.name)")
                        }
                    }
                }
                .padding()
            }
            
            if bottom_spacing > 0
            {
                Spacer(minLength: bottom_spacing)
            }
        }
    }
}

/*struct AddObjectView: View
{
    @Binding var is_presented: Bool
    
    @State private var new_object_name = ""
    
    let previewed_object: WorkspaceObject?
    
    @Binding var previewed_object_name: String
    @Binding var internal_modules_list: [String]
    @Binding var external_modules_list: [String]
    
    private var update_object_info: () -> Void
    private var add_object: (String) -> Void
    
    public init(is_presented: Binding<Bool>,
                previewed_object: WorkspaceObject?,
                previewed_object_name: Binding<String>,
                internal_modules_list: Binding<[String]>,
                external_modules_list: Binding<[String]>,
                update_object_info: @escaping () -> Void,
                add_object: @escaping (String) -> Void)
    {
        self._is_presented = is_presented
        
        self.previewed_object = previewed_object
        
        self._previewed_object_name = previewed_object_name
        self._internal_modules_list = internal_modules_list
        self._external_modules_list = external_modules_list
        
        self.update_object_info = update_object_info
        self.add_object = add_object
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ObjectPreviewSceneView()
                .overlay(alignment: .top)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: { is_presented = false })
                        {
                            Image(systemName: "xmark")
                                .imageScale(.large)
                            #if os(macOS)
                                .frame(width: 16, height: 16)
                            #else
                                .frame(width: 24, height: 24)
                            #endif
                                .padding(6)
                            #if os(iOS)
                                .padding(4)
                                .foregroundStyle(.black)
                            #endif
                        }
                        .keyboardShortcut(.cancelAction)
                        #if !os(visionOS)
                        .modifier(CircleButtonGlassBorderer())
                        #else
                        .buttonBorderShape(.circle)
                        .glassBackgroundEffect()
                        #endif
                        .keyboardShortcut(.cancelAction)
                        
                        Spacer()
                        
                        Button(action: add_object_in_workspace)
                        {
                            Image(systemName: "checkmark")
                                .imageScale(.large)
                            #if os(macOS)
                                .frame(width: 16, height: 16)
                            #else
                                .frame(width: 24, height: 24)
                            #endif
                                .padding(6)
                            #if os(iOS)
                                .padding(4)
                                .foregroundStyle(.white)
                            #endif
                        }
                        .keyboardShortcut(.defaultAction)
                        #if !os(visionOS)
                        .buttonBorderShape(.circle)
                        #if os(macOS)
                        .buttonStyle(.glassProminent)
                        #else
                        .glassEffect(.regular.tint(.accentColor).interactive())
                        #endif
                        #else
                        .buttonBorderShape(.circle)
                        .glassBackgroundEffect()
                        #endif
                    }
                    #if os(macOS) || os(iOS)
                    .padding(10)
                    #else
                    .padding(16)
                    #endif
                }
                .overlay(alignment: .bottom)
                {
                    HStack(spacing: 0)
                    {
                        TextField("Name", text: $new_object_name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                        
                        Picker(selection: $previewed_object_name, label: Text("Model")
                                .bold())
                        {
                            if internal_modules_list.count > 0
                            {
                                Section(header: Text("Internal"))
                                {
                                    ForEach(internal_modules_list, id: \.self)
                                    {
                                        Text($0).tag($0)
                                    }
                                }
                            }
                            
                            if external_modules_list.count > 0
                            {
                                Section(header: Text("External"))
                                {
                                    ForEach(external_modules_list, id: \.self)
                                    {
                                        Text($0).tag(".\($0)")
                                    }
                                }
                            }
                        }
                        #if os(macOS)
                        .buttonStyle(.bordered)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                    .padding(10)
                    #if !os(visionOS)
                    .glassEffect(in: .rect(cornerRadius: 16.0))
                    #else
                    .glassBackgroundEffect()
                    #endif
                    .padding()
                }
        }
        .controlSize(.regular)
        #if os(macOS)
        .presentationSizing(.fitted)
        .frame(minWidth: 400, idealWidth: 480, maxWidth: 640, minHeight: 400, maxHeight: 480)
        #elseif os(visionOS)
        .frame(width: 512, height: 512)
        #endif
        .onAppear
        {
            update_object_info()
        }
    }
    
    private func add_object_in_workspace()
    {
        if new_object_name == ""
        {
            new_object_name = "None"
        }
        
        add_object(new_object_name)
        
        is_presented.toggle()
    }
}

struct ObjectPreviewSceneView: View
{
    @EnvironmentObject var app_state: AppState
    
    var body: some View
    {
        EmptyView()
        //ObjectSceneView(scene: SCNScene(named: "Components.scnassets/View.scn") ?? SCNScene(), on_render: update_preview_node(scene_view:))
    }
    
    private func update_preview_node(scene_view: SCNView)
    {
        /*if app_state.preview_update_scene
        {
            let remove_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            remove_node?.removeFromParentNode()
            
            scene_view.scene?.rootNode.addChildNode(app_state.previewed_object?.node ?? SCNNode())
            app_state.previewed_object?.node?.name = "Node"
            app_state.preview_update_scene = false
        }*/
    }
}

#Preview
{
    AddObjectView(is_presented: .constant(true), previewed_object: nil, previewed_object_name: .constant("Name"), internal_modules_list: .constant([String]()), external_modules_list: .constant([String]()), update_object_info: {}, add_object: {_ in})
}*/

