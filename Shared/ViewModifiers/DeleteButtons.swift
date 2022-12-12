//
//  DeleteButtons.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 06.12.2022.
//

import SwiftUI
import IndustrialKit

//MARK: - For large card
struct CircleDeleteButtonModifier: ViewModifier
{
    @State private var delete_alert_presented = false
    
    let workspace: Workspace
    
    let object_item: WorkspaceObject
    let objects: [WorkspaceObject]
    let on_delete: (IndexSet) -> ()
    
    var object_type_name: String
    
    func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topTrailing)
        {
            Spacer()
            
            ZStack
            {
                Image(systemName: "xmark")
                    .padding(4.0)
            }
            .frame(width: 24, height: 24)
            .background(.thinMaterial)
            .clipShape(Circle())
            .onTapGesture
            {
                delete_alert_presented = true
            }
            .padding(8.0)
        }
        .alert(isPresented: $delete_alert_presented)
        {
            Alert(
                title: Text("Delete \(object_type_name)?"),
                message: Text("Do you wand to delete this \(object_type_name) – \(object_item.name ?? "")"),
                primaryButton: .destructive(Text("Yes"), action: delete_object),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func delete_object()
    {
        if let index = objects.firstIndex(of: object_item)
        {
            self.on_delete(IndexSet(integer: index))
            workspace.elements_check()
        }
    }
}

//MARK: - For small card
struct BorderlessDeleteButtonModifier: ViewModifier
{
    @State private var delete_alert_presented = false
    
    let workspace: Workspace
    
    let object_item: WorkspaceObject
    let objects: [WorkspaceObject]
    let on_delete: (IndexSet) -> ()
    
    var object_type_name: String
    
    func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .trailing)
        {
            ZStack
            {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(4.0)
            }
            .frame(width: 24, height: 24)
            .onTapGesture
            {
                delete_alert_presented = true
            }
            .padding(4.0)
        }
        .alert(isPresented: $delete_alert_presented)
        {
            Alert(
                title: Text("Delete \(object_type_name)?"),
                message: Text("Do you wand to delete this \(object_type_name) – \(object_item.name ?? "")"),
                primaryButton: .destructive(Text("Delete"), action: delete_object),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    func delete_object()
    {
        if let index = objects.firstIndex(of: object_item)
        {
            self.on_delete(IndexSet(integer: index))
            workspace.elements_check()
        }
    }
}
