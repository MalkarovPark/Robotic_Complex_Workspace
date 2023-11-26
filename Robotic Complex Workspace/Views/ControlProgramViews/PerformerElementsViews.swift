//
//  PerformerElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 26.11.2023.
//

import SwiftUI
import IndustrialKit

struct RobotPerformerElementView: View
{
    @Binding var element: WorkspaceProgramElement
    
    @State private var object_name = ""
    @State private var is_single_perfrom = true
    @State private var program_name = ""
    @State private var program_index_from = 0
    
    @EnvironmentObject var base_workspace: Workspace
    @State private var picker_is_presented = false
    
    let on_update: () -> ()
    
    init(element: Binding<WorkspaceProgramElement>, on_update: @escaping () -> ())
    {
        self._element = element
        
        _object_name = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).object_name)
        _is_single_perfrom = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).is_single_perfrom)
        _program_name = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).program_name)
        _program_index_from = State(initialValue: (_element.wrappedValue as! RobotPerformerElement).program_index_from)
        
        self.on_update = on_update
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            //MARK: Robot subview
            if base_workspace.placed_robots_names.count > 0
            {
                //MARK: Robot subview
                #if os(macOS)
                Picker("Name", selection: $object_name) //Robot picker
                {
                    ForEach(base_workspace.placed_robots_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onChange(of: object_name)
                { _, name in
                    if base_workspace.robot_by_name(name).programs_names.count > 0
                    {
                        program_name = base_workspace.robot_by_name(name).programs_names.first ?? ""
                    }
                    base_workspace.update_view()
                }
                .onAppear
                {
                    if object_name == ""
                    {
                        object_name = base_workspace.placed_robots_names.first!
                    }
                    else
                    {
                        base_workspace.update_view()
                    }
                }
                .disabled(base_workspace.placed_robots_names.count == 0)
                .frame(maxWidth: .infinity)
                .padding(.bottom)
                
                Picker("Program", selection: $program_name) //Robot program picker
                {
                    if base_workspace.robot_by_name(object_name).programs_names.count > 0
                    {
                        ForEach(base_workspace.robot_by_name(object_name).programs_names, id: \.self)
                        { name in
                            Text(name)
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .disabled(base_workspace.robot_by_name(object_name).programs_names.count == 0)
                #else
                GeometryReader
                { geometry in
                    HStack(spacing: 0)
                    {
                        VStack(spacing: 0)
                        {
                            Text("Name")
                            
                            Picker("Name", selection: $object_name) //Robot picker
                            {
                                if base_workspace.placed_robots_names.count > 0
                                {
                                    ForEach(base_workspace.placed_robots_names, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                else
                                {
                                    Text("None")
                                }
                            }
                            .onChange(of: object_name)
                            { _, name in
                                if base_workspace.robot_by_name(name).programs_names.count > 0
                                {
                                    program_name = base_workspace.robot_by_name(name).programs_names.first ?? ""
                                }
                                base_workspace.update_view()
                            }
                            .onAppear
                            {
                                if object_name == ""
                                {
                                    object_name = base_workspace.placed_robots_names[0]
                                }
                                else
                                {
                                    base_workspace.update_view()
                                }
                            }
                            .disabled(base_workspace.placed_robots_names.count == 0)
                            .pickerStyle(.wheel)
                            .compositingGroup()
                            .clipped()
                        }
                        .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                            
                        VStack(spacing: 0)
                        {
                            Text("Program")
                            
                            Picker("Program", selection: $program_name) //Robot program picker
                            {
                                if base_workspace.robot_by_name(object_name).programs_names.count > 0
                                {
                                    ForEach(base_workspace.robot_by_name(object_name).programs_names, id: \.self)
                                    { name in
                                        Text(name)
                                    }
                                }
                                else
                                {
                                    Text("None")
                                }
                            }
                            .disabled(base_workspace.robot_by_name(object_name).programs_names.count == 0)
                            .pickerStyle(.wheel)
                            .compositingGroup()
                            .clipped()
                        }
                        .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                    }
                }
                .frame(height: 128)
                #endif
            }
            else
            {
                Text("No robots placed in this workspace")
            }
        }
        #if os(iOS) || os(visionOS)
        .frame(minWidth: 256)
        #endif
    }
}

struct ToolPerformerElementView: View
{
    @Binding var object_name: String
    @Binding var program_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_tool: Tool?
    
    var body: some View
    {
        //MARK: Tool subview
        if base_workspace.placed_tools_names.count > 0
        {
            //MARK: tool subview
            #if os(macOS)
            Picker("Name", selection: $object_name) //tool picker
            {
                ForEach(base_workspace.placed_tools_names, id: \.self)
                { name in
                    Text(name)
                }
            }
            .onChange(of: object_name)
            { _, new_value in
                viewed_tool = base_workspace.tool_by_name(new_value)
                if viewed_tool?.programs_names.count ?? 0 > 0
                {
                    program_name = viewed_tool?.programs_names.first ?? ""
                }
                base_workspace.update_view()
            }
            .onAppear
            {
                if object_name == ""
                {
                    object_name = base_workspace.placed_tools_names.first!
                }
                else
                {
                    viewed_tool = base_workspace.tool_by_name(object_name)
                    base_workspace.update_view()
                }
            }
            .disabled(base_workspace.placed_tools_names.count == 0)
            .frame(maxWidth: .infinity)
            
            Picker("Program", selection: $program_name) //tool program picker
            {
                if viewed_tool?.programs_names.count ?? 0 > 0
                {
                    ForEach(viewed_tool!.programs_names, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                else
                {
                    Text("None")
                }
            }
            .disabled(viewed_tool?.programs_names.count == 0)
            #else
            GeometryReader
            { geometry in
                HStack(spacing: 0)
                {
                    VStack(spacing: 0)
                    {
                        Text("Name")
                        
                        Picker("Name", selection: $object_name) //tool picker
                        {
                            if base_workspace.placed_tools_names.count > 0
                            {
                                ForEach(base_workspace.placed_tools_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            else
                            {
                                Text("None")
                            }
                        }
                        .onChange(of: object_name)
                        { _, new_value in
                            viewed_tool = base_workspace.tool_by_name(new_value)
                            if viewed_tool?.programs_names.count ?? 0 > 0
                            {
                                program_name = viewed_tool?.programs_names.first ?? ""
                            }
                            base_workspace.update_view()
                        }
                        .onAppear
                        {
                            if object_name == ""
                            {
                                object_name = base_workspace.placed_tools_names[0]
                            }
                            else
                            {
                                viewed_tool = base_workspace.tool_by_name(object_name)
                                base_workspace.update_view()
                            }
                        }
                        .disabled(base_workspace.placed_tools_names.count == 0)
                        .pickerStyle(.wheel)
                        .compositingGroup()
                        .clipped()
                    }
                    .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                    
                    VStack(spacing: 0)
                    {
                        Text("Program")
                        
                        Picker("Program", selection: $program_name) //tool program picker
                        {
                            if viewed_tool?.programs_names.count ?? 0 > 0
                            {
                                ForEach(viewed_tool!.programs_names, id: \.self)
                                { name in
                                    Text(name)
                                }
                            }
                            else
                            {
                                Text("None")
                            }
                        }
                        .disabled(viewed_tool?.programs_names.count == 0)
                        .pickerStyle(.wheel)
                        .compositingGroup()
                        .clipped()
                    }
                    .frame(width: geometry.size.width/2, height: geometry.size.height, alignment: .center)
                }
            }
            .frame(height: 128)
            #endif
        }
        else
        {
            Text("No tools placed in this workspace")
        }
    }
}

#Preview
{
    RobotPerformerElementView(element: .constant(RobotPerformerElement()), on_update: {})
        .environmentObject(Workspace())
}
