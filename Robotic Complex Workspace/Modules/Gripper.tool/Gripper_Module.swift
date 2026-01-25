import Foundation
import IndustrialKit

public let Gripper_Module = ToolModule(
    name: "Gripper",
    
    operation_codes: [
        .init(value: 0, name: "Grab", symbol: "arrow.right.and.line.vertical.and.arrow.left", info: ""),
        .init(value: 1, name: "Release", symbol: "arrow.left.and.line.vertical.and.arrow.right", info: "")
    ],
    
    model_controller: Gripper_Controller(),
    connector: Gripper_Connector()
)
