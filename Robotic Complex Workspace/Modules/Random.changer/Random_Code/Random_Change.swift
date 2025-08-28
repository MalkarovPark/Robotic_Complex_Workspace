//
// Change Func
//

import Foundation

func Random_Change(registers: inout [Float])
{
    for i in 0..<registers.count
    {
        registers[i] = Float(Int.random(in: 0...200))
    }
}
