import Foundation
import IndustrialKit
import SceneKit

public let Gripper_Module = ToolModule(
    name: "Gripper",
    
    operation_codes: [
        .init(value: 0, name: "Grab", symbol: "arrow.right.and.line.vertical.and.arrow.left", info: "Grab jaws"),
        .init(value: 1, name: "Release", symbol: "arrow.left.and.line.vertical.and.arrow.right", info: "Release jaws")
    ],
    
    model_controller: Gripper_Controller(),
    node: Gripper_Node,
    nodes_names: [
        "jaw",
        "jaw2"
    ],
    
    connector: Gripper_Connector(),
    connection_parameters: [
        .init(name: "String", value: "Text"),
        .init(name: "Int", value: 8),
        .init(name: "Float", value: Float(6)),
        .init(name: "Bool", value: true)
    ]
)

public var Gripper_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "Gripper_Resources.scnassets/gripper.scn")
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
