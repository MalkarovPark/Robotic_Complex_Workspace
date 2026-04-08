//
//  DocumentUpdateHandler.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 08.03.2024.
//

import Foundation
import SwiftUI

import IndustrialKit

final class DocumentUpdateHandler: ObservableObject
{
    enum Event: Hashable
    {
        case robots
        case tools
        case parts
        case programs
        case registers
    }
    
    @Published var event: Event?
    
    public func update_robots() { fire(.robots) }
    public func update_tools() { fire(.tools) }
    public func update_parts() { fire(.parts) }
    public func update_programs() { fire(.programs) }
    public func update_registers() { fire(.registers) }
    
    private func fire(_ event: Event)
    {
        self.event = event
    }
}

struct DocumentUpdateModifier: ViewModifier
{
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    var base_workspace: Workspace
    
    public func body(content: Content) -> some View
    {
        content
            .task(id: document_handler.event)
            {
                guard let event = document_handler.event else { return }
                
                let data = base_workspace.file_data()
                
                switch event
                {
                case .robots:
                    document.preset.robots = data.robots
                case .tools:
                    document.preset.tools = data.tools
                case .parts:
                    document.preset.parts = data.parts
                case .programs:
                    document.preset.programs = data.programs
                    document.preset.registers = data.registers
                case .registers:
                    break//document.preset.registers = data.registers
            }
        }
    }
}
