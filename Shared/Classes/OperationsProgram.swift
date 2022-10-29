//
//  OperationsProgram.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.10.2022.
//

import Foundation

class OperationsProgram: Identifiable, Codable, ObservableObject, Hashable
{
    static func == (lhs: OperationsProgram, rhs: OperationsProgram) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var name: String?
    public var codes = [Int]()
    
    //MARK: - Positions program init functions
    init()
    {
        self.name = "None"
    }
    
    init(name: String?)
    {
        self.name = name ?? "None"
    }
}
