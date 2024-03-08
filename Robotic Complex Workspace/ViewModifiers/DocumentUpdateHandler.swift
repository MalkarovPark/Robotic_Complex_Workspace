//
//  DocumentUpdateHandler.swift
//  RCWorkspace
//
//  Created by Artiom Malkarov on 08.03.2024.
//

import Foundation
import SwiftUI
import IndustrialKit

struct DocumentUpdateHandler: ViewModifier
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    public func body(content: Content) -> some View
    {
        content
            .onChange(of: app_state.update_robots_document_notify)
            { _, _ in
                document.preset.robots = base_workspace.file_data().robots
            }
            .onChange(of: app_state.update_tools_document_notify)
            { _, _ in
                document.preset.tools = base_workspace.file_data().tools
            }
            .onChange(of: app_state.update_parts_document_notify)
            { _, _ in
                document.preset.parts = base_workspace.file_data().parts
            }
            .onChange(of: app_state.update_elements_document_notify)
            { _, _ in
                document.preset.elements = base_workspace.file_data().elements
            }
            .onChange(of: app_state.update_registers_document_notify)
            { _, _ in
                document.preset.registers = base_workspace.file_data().registers
            }
    }
}
