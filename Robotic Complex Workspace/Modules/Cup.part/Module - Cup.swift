//
//  Cup part module
//

import Foundation
import IndustrialKit
import SceneKit

public let Cup_Module = PartModule(
    name: "Cup",
    node: CupNode
)

public var CupNode: SCNNode
{
    guard let new_scene = SCNScene(named: "Resources - Cup.scnassets/cup.scn")
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
