import Foundation
import IndustrialKit
import SceneKit

public let Drill_Module = ToolModule(
    name: "Drill",
    
    operation_codes: [
        .init(value: 1, name: "Clockwise", symbol: "arrow.clockwise.circle", info: "Clockwise rotation"),
        .init(value: 2, name: "Counter", symbol: "arrow.counterclockwise.circle", info: "Counter clockwise rotation"),
        .init(value: 0, name: "Stop", symbol: "stop.circle", info: "Stop rotation")
    ],
    
    model_controller: Drill_Controller(),
    node: Drill_Node,
    nodes_names: [
        "drill"
    ],
    
    connector: Drill_Connector(),
    connection_parameters: [
        .init(name: "String", value: "Text"),
        .init(name: "Int", value: 8),
        .init(name: "Float", value: Float(6)),
        .init(name: "Bool", value: true)
    ]
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
