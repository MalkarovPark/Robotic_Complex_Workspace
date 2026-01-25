import Foundation
import IndustrialKit

public let Drill_Module = ToolModule(
    name: "Drill",
    
    operation_codes: [
        .init(value: 1, name: "Clockwise", symbol: "arrow.clockwise.circle", info: ""),
        .init(value: 2, name: "Counter", symbol: "arrow.counterclockwise.circle", info: ""),
        .init(value: 0, name: "Stop", symbol: "stop.circle", info: "")
    ],
    
    model_controller: Drill_Controller(),
    connector: Drill_Connector()
)
