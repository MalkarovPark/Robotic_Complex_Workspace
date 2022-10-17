//
//  PositionPoint.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation

class PositionPoint: Identifiable, Codable, Hashable
{
    static func == (lhs: PositionPoint, rhs: PositionPoint) -> Bool
    {
        lhs.id == rhs.id //Identity condition by id
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public var x, y, z: Float //Point location
    public var r, p, w: Float //Point rotation
    public var move_type: MoveType //Move type to point
    public var move_speed: Float //Move speed to point
    
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
        self.move_speed = 10
    }
    
    init(x: Float, y: Float, z: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = 0
        self.p = 0
        self.w = 0
        
        self.move_type = .linear
        self.move_speed = 10
    }
    
    init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float, move_type: MoveType)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = move_type
        self.move_speed = 10
    }
    
    init(x: Float, y: Float, z: Float, r: Float, p: Float, w: Float, move_type: MoveType, move_speed: Float)
    {
        self.x = x
        self.y = y
        self.z = z
        
        self.r = r
        self.p = p
        self.w = w
        
        self.move_type = move_type
        self.move_speed = move_speed
    }
}

enum MoveType: String, Codable, Equatable, CaseIterable
{
    case linear = "Linear"
    case fine = "Fine"
}
