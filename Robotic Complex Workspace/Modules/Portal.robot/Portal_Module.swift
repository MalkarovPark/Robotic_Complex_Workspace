import Foundation
import IndustrialKit
import SceneKit

public let Portal_Module = RobotModule(
    name: "Portal",
    
    model_controller: Portal_Controller(),
    node: Portal_Node,
    nodes_names: [
        "base",
        "column",
        "frame",
        "d0",
        "d1",
        "d2"
    ],
    
    connector: Portal_Connector(),
    connection_parameters: [
        .init(name: "String", value: "Text"),
        .init(name: "Int", value: 8),
        .init(name: "Float", value: Float(6)),
        .init(name: "Bool", value: true)
    ]
)

public var Portal_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "Portal_Resources.scnassets/Portal.scn")
    else
    {
        return SCNNode()
    }
    
    guard let node = new_scene.rootNode.childNode(withName: "robot", recursively: false)
    else
    {
        return SCNNode()
    }
    
    return node
}
