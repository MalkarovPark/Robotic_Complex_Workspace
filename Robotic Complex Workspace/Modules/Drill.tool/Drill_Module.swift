import Foundation
import IndustrialKit
import SceneKit

public let Drill_Module = ToolModule(
    name: "Drill",
    
    node: Drill_Node,
    
    operation_codes: [
        .init(value: 1, name: "Clockwise", symbol: "arrow.clockwise.circle", info: ""),
        .init(value: 2, name: "Counter", symbol: "arrow.counterclockwise.circle", info: ""),
        .init(value: 0, name: "Stop", symbol: "stop.circle", info: "")
    ],
    
    model_controller: Drill_Controller(),
    connector: Drill_Connector()
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
