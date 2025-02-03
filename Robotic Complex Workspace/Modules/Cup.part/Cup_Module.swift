import Foundation
import IndustrialKit
import SceneKit

public let Cup_Module = PartModule(
    name: "Cup",
    
    node: Cup_Node
)

public var Cup_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "Cup_Resources.scnassets/cup.scn")
    else
    {
        return SCNNode()
    }
    
    guard let node = new_scene.rootNode.childNode(withName: "part", recursively: false)
    else
    {
        return SCNNode()
    }
    
    return node
}
