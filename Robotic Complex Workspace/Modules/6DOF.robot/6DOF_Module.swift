import Foundation
import IndustrialKit
import SceneKit

public let _6DOF_Module = RobotModule(
    name: "6DOF",
    
    model_controller: _6DOF_Controller(),
    node: _6DOF_Node,
    nodes_names: [
        "base",
        "column",
        "d0",
        "d1",
        "d2",
        "d3",
        "d4",
        "d5",
        "d6"
    ],
    
    connector: _6DOF_Connector(),
    connection_parameters: [
        .init(name: "String", value: "Text"),
        .init(name: "Int", value: 8),
        .init(name: "Float", value: Float(6)),
        .init(name: "Bool", value: true)
    ]
)

public var _6DOF_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "6DOF_Resources.scnassets/6DOF.scn")
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
