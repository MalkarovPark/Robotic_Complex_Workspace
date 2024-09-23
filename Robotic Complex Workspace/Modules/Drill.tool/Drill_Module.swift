import Foundation
import IndustrialKit
import SceneKit

public let Drill_Module = ToolModule(
    name: "Drill",
    model_controller: Drill_Controller(),
    connector: Drill_Connector(),
    operation_codes: Drill_Codes,
    node: Drill_Node
)

public var Drill_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "Drill_Resources.scnassets/drill.scn")
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
        OperationCodeInfo(value: 1, name: "Clockwise", symbol: "arrow.clockwise.circle", info: "Clockwise rotation"),
        OperationCodeInfo(value: 2, name: "Counter", symbol: "arrow.counterclockwise.circle", info: "Counter clockwise rotation"),
        OperationCodeInfo(value: 0, name: "Stop", symbol: "stop.circle", info: "Stop rotation")
    ]
}
