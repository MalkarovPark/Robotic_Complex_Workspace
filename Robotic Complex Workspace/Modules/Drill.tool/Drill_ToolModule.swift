//
// Drill Tool
// Internal Module Declaration
//

import Foundation
import IndustrialKit

@MainActor public let Drill_ToolModule = ToolModule(
    name: "Drill",
    
    operation_codes: [
        .init(value: 0, name: "Clockwise", symbol_name: "arrow.clockwise.circle", description: ""),
        .init(value: 1, name: "Counter", symbol_name: "arrow.counterclockwise.circle", description: ""),
        .init(value: 2, name: "Stop", symbol_name: "stop.circle", description: "")
    ],
    
    model_controller: Drill_Controller(),
    connector: Drill_Connector()
)
