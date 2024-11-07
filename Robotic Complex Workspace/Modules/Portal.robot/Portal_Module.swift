import Foundation
import IndustrialKit
import SceneKit

public let Portal_Module = RobotModule(
    name: "Portal",
    model_controller: Portal_Controller(),
    connector: Portal_Connector(),
    node: Portal_Node,
    nodes_names: ["base", "column", "frame", "d0", "d1", "d2"]
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
