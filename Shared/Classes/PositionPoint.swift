//
//  PositionPoint.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation
import SwiftUI

class PositionPoint: Identifiable, Codable, Hashable
{
    static func == (lhs: PositionPoint, rhs: PositionPoint) -> Bool
    {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var x, y, z: Double //Point location
    public var r, p, w: Double //Point rotation
    public var move_type: MoveType
    
    //MARK: - Initialization
    init()
    {
        self.x = 0
        self.y = 0
        self.z = 0
        
        self.r = 0
        self.p = 0
        self.w = 0
        
        self.move_type = .linear
    }
    
    init(x: Double, y: Double, z: Double, r: Double, p: Double, w: Double, move_type: MoveType)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = move_type
    }
    
    init(x: Double, y: Double, z: Double)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = 0
        self.p = 0
        self.w = 0
        
        self.move_type = .linear
    }
}

enum MoveType: String, Codable, Equatable, CaseIterable
{
    case linear = "Linear"
    case fine = "Fine"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
