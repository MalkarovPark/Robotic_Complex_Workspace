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
        return lhs.name + lhs.type.rawValue == rhs.name + rhs.type.rawValue
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name + type.rawValue)
    }
    
    init(name: String)
    {
        self.name = name
    }
    
    var id = UUID()
    var name = String()
    
    var type: ProgramElementType = .perofrmer
    var type_info: String
    {
        var info = "\(self.type.rawValue) – "
        
        switch type
        {
        case .perofrmer:
            info += "\(self.performer_type.rawValue)"
        case .modificator:
            info += "\(self.modificator_type.rawValue)"
        case .logic:
            info += "\(self.logic_type.rawValue)"
        }
        
        return info
    }
    //var type_data = ["Perforemer", "Robot"]
    
    //For Performer
    var performer_type: PerformerType = .robot
    {
        didSet
        {
            
        }
    }
    
    var robot_name = String()
    var tool_name = String()
    
    var program_index = Int()
    
    //For Modififcator
    var modificator_type: ModificatorType = .observer

    //For logic
    var logic_type: LogicType = .jump
}

struct workspace_program_struct: Codable, Hashable
{
    var name = String()
    
    var type: ProgramElementType = .perofrmer
    
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
