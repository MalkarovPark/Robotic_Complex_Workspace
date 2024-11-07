import Foundation
import IndustrialKit
import SceneKit

public let _6DOF_Module = RobotModule(
    name: "6DOF",
    model_controller: _6DOF_Controller(),
    connector: _6DOF_Connector(),
    node: _6DOF_Node,
    nodes_names: ["base", "column", "d0", "d1", "d2", "d3", "d4", "d5", "d6"]
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
