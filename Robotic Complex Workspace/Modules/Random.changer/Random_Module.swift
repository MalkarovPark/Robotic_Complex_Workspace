/*import Foundation
import IndustrialKit

public let Random_Module = ChangerModule(
    name: "Random",
    
    changer_function: change
)

private func change(registers: inout [Float])
{
    for i in 0..<registers.count
    {
        registers[i] = Float(Int.random(in: 0...200))
    }
}
*/

import Foundation
import IndustrialKit

public let Random_Module = ChangerModule(
    name: "Random",
    
    changer_function_code: changer_function_code
)

private var changer_function_code: String =
"""
for (let i = 0; i < registers.length; i++)
{
    registers[i] = Math.floor(Math.random() * 201)
}

registers
"""
