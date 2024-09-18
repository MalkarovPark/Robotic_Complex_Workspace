//
//  Books part module
//

import Foundation
import IndustrialKit
import SceneKit

public let Books_Module = PartModule(
    name: "Books",
    node: BooksNode
)

public var BooksNode: SCNNode
{
    guard let new_scene = SCNScene(named: "Resources - Books.scnassets/books_row.scn") //Components.scnassets/Parts/books_row.scn
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
