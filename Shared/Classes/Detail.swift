//
//  Detail.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import Foundation

class Detail: Identifiable, Equatable, Hashable, ObservableObject
{
    static func == (lhs: Detail, rhs: Detail) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var name: String?
}
