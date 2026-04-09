//
//  AddObjectView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.09.2024.
//

import SwiftUI
import RealityKit

import IndustrialKit
import IndustrialKitUI

struct AddObjectView: View
{
    @Binding var is_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var base_workspace: Workspace
    
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
                AddRobotView(
                    columns: columns,
                    card_spacing: card_spacing,
                    card_height: card_height,
                    top_spacing: top_spacing,
                    bottom_spacing: bottom_spacing,
                    
                    is_presented: $is_presented,
                    on_add_object: { document.preset.robots = base_workspace.file_data().robots }
                )
            case .tools:
                AddToolView(
                    columns: columns,
                    card_spacing: card_spacing,
                    card_height: card_height,
                    top_spacing: top_spacing,
                    bottom_spacing: bottom_spacing,
                    
                    is_presented: $is_presented,
                    on_add_object: { document.preset.tools = base_workspace.file_data().tools }
                )
            case .parts:
                AddPartView(
                    columns: columns,
                    card_spacing: card_spacing,
                    card_height: card_height,
                    top_spacing: top_spacing,
                    bottom_spacing: bottom_spacing,
                    
                    is_presented: $is_presented,
                    on_add_object: { document.preset.tools = base_workspace.file_data().tools }
                )
            }
            #else
            TabView
            {
                Tab("Robots", systemImage: "r.square")
                {
                    AddRobotView(
                        columns: columns,
                        card_spacing: card_spacing,
                        card_height: card_height,
                        top_spacing: top_spacing,
                        bottom_spacing: bottom_spacing,
                        
                        is_presented: $is_presented,
                        on_add_object: { document.preset.robots = base_workspace.file_data().robots }
                    )
                }
                
                Tab("Tools", systemImage: "hammer")
                {
                    AddToolView(
                        columns: columns,
                        card_spacing: card_spacing,
                        card_height: card_height,
                        top_spacing: top_spacing,
                        bottom_spacing: bottom_spacing,
                        
                        is_presented: $is_presented,
                        on_add_object: { document.preset.tools = base_workspace.file_data().tools }
                    )
                }
                
                Tab("Parts", systemImage: "shippingbox")
                {
                    AddPartView(
                        columns: columns,
                        card_spacing: card_spacing,
                        card_height: card_height,
                        top_spacing: top_spacing,
                        bottom_spacing: bottom_spacing,
                        
                        is_presented: $is_presented,
                        on_add_object: { document.preset.tools = base_workspace.file_data().tools }
                    )
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
            }
            .glassEffect()
            .padding(14)
            .controlSize(.large)
        }
        #endif
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
                
                AddObjectView(
                    is_presented: .constant(true),
                    document: .constant(Robotic_Complex_WorkspaceDocument())
                )
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
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    @Binding var is_presented: Bool
    
    let on_add_object: () -> ()
    
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
                        add_object(module, is_internal: true)
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
                            add_object(module, is_internal: false)
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
    
    private func add_object(_ module: RobotModule, is_internal: Bool)
    {
        base_workspace.add_robot(Robot(name: "None", module: module, is_internal: is_internal))
        on_add_object()
        
        is_presented = false
    }
}

struct AddToolView: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    @Binding var is_presented: Bool
    
    let on_add_object: () -> ()
    
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
                        add_object(module, is_internal: true)
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
                            add_object(module, is_internal: false)
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
    
    private func add_object(_ module: ToolModule, is_internal: Bool)
    {
        base_workspace.add_tool(Tool(name: "None", module: module, is_internal: is_internal))
        on_add_object()
        
        is_presented = false
    }
}

struct AddPartView: View
{
    @EnvironmentObject var base_workspace: Workspace
    
    let columns: [GridItem]
    let card_spacing: CGFloat
    let card_height: CGFloat
    
    let top_spacing: CGFloat
    let bottom_spacing: CGFloat
    
    @Binding var is_presented: Bool
    
    let on_add_object: () -> ()
    
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
                        add_object(module, is_internal: true)
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
                            add_object(module, is_internal: false)
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
    
    private func add_object(_ module: PartModule, is_internal: Bool)
    {
        base_workspace.add_part(Part(name: "None", module: module, is_internal: is_internal))
        on_add_object()
        
        is_presented = false
    }
}
