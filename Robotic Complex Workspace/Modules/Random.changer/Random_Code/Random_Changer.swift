//
//  Random_Changer.swift
//  RCWorkspace
//
//  Created by Artem Malkarov on 22.09.2024.
//

import Foundation

func Random_Changer(registers: inout [Float])
{
    for i in 0..<registers.count
    {
        registers[i] = Float(Int.random(in: 0...10))
    }
}
