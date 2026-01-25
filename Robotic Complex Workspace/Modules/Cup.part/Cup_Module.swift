import Foundation
import IndustrialKit
import SceneKit

public let Cup_Module = PartModule(
    name: "Cup"
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
