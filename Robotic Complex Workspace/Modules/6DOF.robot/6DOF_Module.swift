//
//  Gripper tool module
//

import Foundation
import IndustrialKit
import SceneKit

public let _6DOF_Module = ToolModule(
    name: "Gripper",
    model_controller: Gripper_Controller(),
    connector: Gripper_Connector(),
    operation_codes: Gripper_Codes,
    node: Gripper_Node
)

public var _6DOF_Node: SCNNode
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
