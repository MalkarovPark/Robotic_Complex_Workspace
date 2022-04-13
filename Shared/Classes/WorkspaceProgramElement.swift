//
//  WorkspaceProgramElement.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.04.2022.
//

import Foundation
import SwiftUI

class WorkspaceProgramElement: Codable, Hashable, Identifiable
{
    static func == (lhs: WorkspaceProgramElement, rhs: WorkspaceProgramElement) -> Bool
    {
        return lhs.id.uuidString + lhs.element_data.element_type.rawValue == rhs.id.uuidString + rhs.element_data.element_type.rawValue
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id.uuidString + element_data.element_type.rawValue)
    }
    
    init(element_type: ProgramElementType, performer_type: PerformerType, modificator_type: ModificatorType, logic_type: LogicType)
    {
        self.element_data = workspace_program_element_struct(element_type: element_type, performer_type: performer_type, modificator_type: modificator_type, logic_type: logic_type)
    }
    init(element_type: ProgramElementType, performer_type: PerformerType)
    {
        self.element_data.element_type = element_type
        self.element_data.performer_type = performer_type
    }
    init(element_type: ProgramElementType, modificator_type: ModificatorType)
    {
        self.element_data.element_type = element_type
        self.element_data.modificator_type = modificator_type
    }
    init(element_type: ProgramElementType, logic_type: LogicType)
    {
        self.element_data.logic_type = logic_type
        self.element_data.logic_type = logic_type
    }
    
    var id = UUID()
    
    var element_data = workspace_program_element_struct(element_type: .perofrmer, performer_type: .robot, modificator_type: .observer, logic_type: .jump)
    var type_info: String
    {
        var info = "Type – "
        
        switch element_data.element_type
        {
        case .perofrmer:
            info += "\(self.element_data.performer_type.rawValue)"
        case .modificator:
            info += "\(self.element_data.modificator_type.rawValue)"
        case .logic:
            info += "\(self.element_data.logic_type.rawValue)"
        }
        
        return info
    }
}

struct workspace_program_element_struct: Codable, Hashable
{
    var element_type: ProgramElementType = .perofrmer
    
    //For Performer
    var performer_type: PerformerType = .robot
    
    var robot_name = String()
    var robot_program_name = String()
    var tool_name = String()
    
    //For Modififcator
    var modificator_type: ModificatorType = .observer
    
    var target_mark_name = String()

    //For logic
    var logic_type: LogicType = .jump
    
    var mark_name = String()
}

enum ProgramElementType: String, Codable, Equatable, CaseIterable
{
    case perofrmer = "Performer"
    case modificator = "Modificator"
    case logic = "Logic"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum PerformerType: String, Codable, Equatable, CaseIterable
{
    case robot = "Robot"
    case tool = "Tool"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum ModificatorType: String, Codable, Equatable, CaseIterable
{
    case observer = "Observer"
    case changer = "Changer"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

enum LogicType: String, Codable, Equatable, CaseIterable
{
    case jump = "Jump"
    case mark = "Mark"
    case equal = "Equal"
    case unequal = "Unequal"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
