//
//  DocumentUpdateHandler.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 08.03.2024.
//

import Foundation
import SwiftUI
import IndustrialKit

class DocumentUpdateHandler: ObservableObject
{
    //MARK: - Document handling
    @Published var update_elements_document_notify = true
    @Published var update_registers_document_notify = true
    
    @Published var update_robots_document_notify = true
    @Published var update_tools_document_notify = true
    @Published var update_parts_document_notify = true
    
    public func document_update_elements() { update_elements_document_notify.toggle() }
    public func document_update_registers() { update_registers_document_notify.toggle() }
    
    public func document_update_robots() { update_robots_document_notify.toggle() }
    public func document_update_tools() { update_tools_document_notify.toggle() }
    public func document_update_parts() { update_parts_document_notify.toggle() }
}

struct DocumentUpdateModifier: ViewModifier
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var base_workspace: Workspace
    
    public func body(content: Content) -> some View
    {
        content
            .onChange(of: document_handler.update_robots_document_notify)
            { _, _ in
                document.preset.robots = base_workspace.file_data().robots
            }
            .onChange(of: document_handler.update_tools_document_notify)
            { _, _ in
                document.preset.tools = base_workspace.file_data().tools
            }
            .onChange(of: document_handler.update_parts_document_notify)
            { _, _ in
                document.preset.parts = base_workspace.file_data().parts
            }
            .onChange(of: document_handler.update_elements_document_notify)
            { _, _ in
                document.preset.elements = base_workspace.file_data().elements
            }
            .onChange(of: document_handler.update_registers_document_notify)
            { _, _ in
                document.preset.registers = base_workspace.file_data().registers
            }
    }
}
