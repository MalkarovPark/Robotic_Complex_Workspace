import Foundation
import IndustrialKit
import SceneKit

public let Books_Module = PartModule(
    name: "Books",
    node: Books_Node
)

public var Books_Node: SCNNode
{
    guard let new_scene = SCNScene(named: "Books_Resources.scnassets/books_row.scn")
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
