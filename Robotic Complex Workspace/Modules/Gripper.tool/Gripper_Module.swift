import Foundation
import IndustrialKit

public let Gripper_Module = ToolModule(
    name: "Gripper",
    
    operation_codes: [
        .init(value: 0, name: "Grab", symbol_name: "arrow.right.and.line.vertical.and.arrow.left", description: ""),
        .init(value: 1, name: "Release", symbol_name: "arrow.left.and.line.vertical.and.arrow.right", description: "")
    ],
    
    model_controller: Gripper_Controller(),
    connector: Gripper_Connector()
)
