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
        return lhs.name + lhs.element_data.element_type.rawValue == rhs.name + rhs.element_data.element_type.rawValue
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name + element_data.element_type.rawValue)
    }
    
    init(name: String, element_type: ProgramElementType, performer_type: PerformerType, modificator_type: ModificatorType, logic_type: LogicType)
    {
        self.name = name
        self.element_data = workspace_program_element_struct(element_type: element_type, performer_type: performer_type, modificator_type: modificator_type, logic_type: logic_type)
    }
    
    var id = UUID()
    var name = String()
    
    //var type: ProgramElementType = .perofrmer
    var element_data: workspace_program_element_struct
    var type_info: String
    {
        var info = "\(self.element_data.element_type.rawValue) – "
        
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
    
    func update_type_data()
    {
        
    }
    
    //For Performer
    //var performer_type: PerformerType = .robot
    
    var robot_name = String()
    var tool_name = String()
    
    var program_index = Int()
    
    //For Modififcator
    //var modificator_type: ModificatorType = .observer

    //For logic
    //var logic_type: LogicType = .jump
}

struct workspace_program_element_struct: Codable, Hashable
{
    //var name = String()
    
    var element_type: ProgramElementType = .perofrmer
    
    //For Performer
    var performer_type: PerformerType = .robot
    
    //For Modififcator
    var modificator_type: ModificatorType = .observer

    //For logic
    var logic_type: LogicType = .jump
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
    case equal = "Equal"
    case unequal = "Unequal"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
