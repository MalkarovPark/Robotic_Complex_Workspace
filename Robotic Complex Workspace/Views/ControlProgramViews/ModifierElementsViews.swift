//
//  ModifierElementsViews.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 26.11.2023.
//

import SwiftUI
import IndustrialKit

struct ObserverElementView: View
{
    @Binding var object_name: String
    @Binding var register_index: Int
    
    @EnvironmentObject var base_workspace: Workspace
    
    @State private var viewed_object: Tool?
    
    var body: some View
    {
        //MARK: Observer subview
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
                viewed_object = base_workspace.tool_by_name(new_value)
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
                    viewed_object = base_workspace.tool_by_name(object_name)
                    base_workspace.update_view()
                }
            }
            .disabled(base_workspace.placed_tools_names.count == 0)
            .frame(maxWidth: .infinity)
            #else
            VStack(spacing: 0)
            {
                Text("Name")
                    .padding(.bottom)
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
                    viewed_object = base_workspace.tool_by_name(new_value)
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
                        viewed_object = base_workspace.tool_by_name(object_name)
                        base_workspace.update_view()
                    }
                }
                .disabled(base_workspace.placed_tools_names.count == 0)
                .pickerStyle(.wheel)
                .compositingGroup()
                .clipped()
            }
            .frame(width: 256, height: 128)
            #endif
        }
        else
        {
            Text("No tools placed in this workspace")
        }
    }
}

struct ChangerElementView: View
{
    @Binding var module_name: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        //MARK: Changer subview
        #if os(macOS)
        HStack
        {
            Picker("Module:", selection: $module_name) //Changer module picker
            {
                if Workspace.changer_modules.count > 0
                {
                    ForEach(Workspace.changer_modules, id: \.self)
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
                if Workspace.changer_modules.count > 0 && module_name == ""
                {
                    module_name = Workspace.changer_modules[0]
                }
            }
            .disabled(Workspace.changer_modules.count == 0)
        }
        #else
        VStack
        {
            if Workspace.changer_modules.count > 0
            {
                Text("Module:")
                Picker("Module:", selection: $module_name) //Target mark picker
                {
                    ForEach(Workspace.changer_modules, id: \.self)
                    { name in
                        Text(name)
                    }
                }
                .onAppear
                {
                    if Workspace.changer_modules.count > 0 && module_name == ""
                    {
                        module_name = Workspace.changer_modules[0]
                    }
                }
                .disabled(Workspace.changer_modules.count == 0)
                .pickerStyle(.wheel)
            }
            else
            {
                Text("No modules")
            }
        }
        #endif
    }
}

#Preview
{
    EmptyView()
}
