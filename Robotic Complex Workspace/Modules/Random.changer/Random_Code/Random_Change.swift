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

/*func Random_Change(registers: inout [Float]) throws
{
    if registers[2] > 0
    {
        throw NSError(
            domain: "Performing Error",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "\(registers[2]) > 0"
            ]
        )
    }
    else
    {
        registers[2] += 1
    }
}*/
