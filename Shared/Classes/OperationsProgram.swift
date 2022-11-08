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
    
    public var codes_count: Int
    {
        return codes.count
    }
    
    //MARK: - Code manage functions
    public func add_code(_ code: Int)
    {
        codes.append(code)
        new_code_check()
    }
    
    public func update_point(number: Int, _ code: Int)
    {
        if codes.indices.contains(number) //Checking for the presence of a point with a given number to update
        {
            codes[number] = code
            new_code_check()
        }
    }
    
    public func delete_point(number: Int) //Checking for the presence of a point with a given number to delete
    {
        if codes.indices.contains(number)
        {
            codes.remove(at: number)
            new_code_check()
        }
    }
    
    private func new_code_check()
    {
        if codes.last ?? 0 < 1
        {
            codes[codes.count] = 1
        }
    }
    
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
