import Foundation
import IndustrialKit
import SceneKit

public let Drill_Module = ToolModule(
    name: "Drill",
    model_controller: DrillController(),
    connector: DrillConnector(),
    operation_codes: Drill_Codes,
    node: DrillNode
)

public var DrillNode: SCNNode
{
    guard let new_scene = SCNScene(named: "Resources - Drill.scnassets/drill.scn")
    else
    {
        return SCNNode()
    }
    
    guard let node = new_scene.rootNode.childNode(withName: "tool", recursively: false)
    else
    {
        return SCNNode()
    }
    
    return node
}

public var Drill_Codes: [OperationCodeInfo]
{
    return [
        OperationCodeInfo(value: 0, name: "Clockwise", symbol: "arrow.clockwise.circle", info: "Clockwise rotation"),
        OperationCodeInfo(value: 0, name: "Counter", symbol: "arrow.counterclockwise.circle", info: "Counter clockwise rotation")
    ]
}
