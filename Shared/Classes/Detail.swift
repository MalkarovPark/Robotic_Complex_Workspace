//
//  Detail.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import Foundation
import SceneKit

class Detail: Identifiable, Equatable, Hashable, ObservableObject
{
    static func == (lhs: Detail, rhs: Detail) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var name: String? //Detail name
    public var node: SCNNode? //Detail scene node
    public var detail_scene_address = "" //Adders of detail scene. If empty – this detail used defult model.
    
    public var gripable: Bool? //Can this detail be gripped and picked up
    
    private var lenghts: [Float]? //Lenghts for detail without scene figure
    private var color_name: String? //Color for detail without scene figure
    private var material_name: String? //Material for detail without scene figure
    
    //MARK: - Detail init functions
    init(name: String, dictionary: [String: Any]) //Init detail by dictionary
    {
        
    }
}
