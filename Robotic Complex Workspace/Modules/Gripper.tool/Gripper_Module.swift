import Foundation
import IndustrialKit
import SceneKit

public let Gripper_Module = ToolModule(
    name: "Gripper",
    model_controller: Gripper_Controller(),
    connector: Gripper_Connector(),
    operation_codes: Gripper_Codes,
    node: Gripper_Node,
    nodes_names: ["jaw", "jaw2"]
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

public var Gripper_Codes: [OperationCodeInfo]
{
    return [
        OperationCodeInfo(value: 0, name: "Grab", symbol: "arrow.right.and.line.vertical.and.arrow.left", info: "Grab jaws"),
        OperationCodeInfo(value: 1, name: "Release", symbol: "arrow.left.and.line.vertical.and.arrow.right", info: "Release jaws")
    ]
}
