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
    
    private var figure: String?
    private var lenghts: [Float]? //Lenghts for detail without scene figure
    private var figure_color: [Int]? //Color for detail without scene figure
    private var material_name: String? //Material for detail without scene figure
    
    private var physics: SCNPhysicsBody?
    private var physics_name: String? //Physic body type
    
    public var enable_physics = false
    {
        didSet
        {
            if enable_physics
            {
                node?.physicsBody = physics //Return original physics
            }
            else
            {
                physics = node?.physicsBody //Save original physics
                node?.physicsBody = .static()
            }
        }
    }
    
    //MARK: - Detail init functions
    init(name: String, scene: String) //Init detial by scene_name
    {
        self.name = name
        self.detail_scene_address = scene
        
        if scene != ""
        {
            self.node = SCNScene(named: scene)!.rootNode.childNode(withName: "detail", recursively: false)!
        }
    }
    
    init(name: String, dictionary: [String: Any]) //Init detail by dictionary
    {
        self.name = name
        
        //Get values form dictionary
        if dictionary.keys.contains("Figure")
        {
            self.figure = dictionary["Figure"] as? String ?? ""
        }
        
        if dictionary.keys.contains("Color")
        {
            var figure_color = [Int]()
            let elements = dictionary["Color"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                figure_color.append((element as? Int) ?? 0)
            }
            
            self.figure_color = figure_color
        }
        
        if dictionary.keys.contains("Material")
        {
            self.figure = dictionary["Material"] as? String ?? ""
        }
        
        if dictionary.keys.contains("Lengths")
        {
            var lenghts = [Float]()
            let elements = dictionary["Lengths"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                lenghts.append((element as? Float) ?? 0)
            }
            
            self.lenghts = lenghts
        }
        
        if dictionary.keys.contains("Physics")
        {
            self.physics_name = dictionary["Physics"] as? String ?? ""
        }
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.detail_scene_address = dictionary["Scene"] as? String ?? ""
            if self.detail_scene_address != ""
            {
                self.node = SCNScene(named: self.detail_scene_address)!.rootNode.childNode(withName: "detail", recursively: false)!
            }
        }
        else
        {
            node_by_description()
        }
    }
    
    func node_by_description()
    {
        node = SCNNode()
        
        #if os(macOS)
        var lenghts = self.lenghts as! [CGFloat]
        #else
        var lenghts = self.lenghts as! [Float]
        #endif
        
        //Set geometry
        var geometry: SCNGeometry?
        switch figure
        {
        case "plane":
            if lenghts.count == 2
            {
                geometry = SCNPlane(width: lenghts[0], height: lenghts[1])
            }
            else
            {
                geometry = SCNPlane(width: 4, height: 4)
            }
        case "box":
            if lenghts.count >= 3 && lenghts.count <= 4
            {
                geometry = SCNBox(width: lenghts[0], height: lenghts[1], length: lenghts[2], chamferRadius: lenghts.count == 3 ? 0 : lenghts[3]) //If lenghts 4 – set chamer radius by element 3
            }
            else
            {
                geometry = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 1)
            }
        case "sphere":
            if lenghts.count == 1
            {
                geometry = SCNSphere(radius: lenghts[0])
            }
            else
            {
                geometry = SCNSphere(radius: 2)
            }
        case "pyramid":
            if lenghts.count == 3
            {
                geometry = SCNPyramid(width: lenghts[0], height: lenghts[1], length: lenghts[2])
            }
            else
            {
                geometry = SCNPyramid(width: 4, height: 2, length: 4)
            }
        case "cylinder":
            if lenghts.count == 2
            {
                geometry = SCNCylinder(radius: lenghts[0], height: lenghts[1])
            }
            else
            {
                geometry = SCNCylinder(radius: 2, height: 4)
            }
        case "cone":
            if lenghts.count == 3
            {
                geometry = SCNCone(topRadius: lenghts[0], bottomRadius: lenghts[1], height: lenghts[2])
            }
            else
            {
                geometry = SCNCone(topRadius: 1, bottomRadius: 2, height: 4)
            }
        case "tube":
            if lenghts.count == 3
            {
                geometry = SCNTube(innerRadius: lenghts[0], outerRadius: lenghts[1], height: lenghts[2])
            }
            else
            {
                geometry = SCNTube(innerRadius: 1, outerRadius: 2, height: 4)
            }
        case "capsule":
            if lenghts.count == 2
            {
                geometry = SCNCapsule(capRadius: lenghts[0], height: lenghts[1])
            }
            else
            {
                geometry = SCNCapsule(capRadius: 2, height: 4)
            }
        case "torus":
            if lenghts.count == 2
            {
                geometry = SCNTorus(ringRadius: lenghts[0], pipeRadius: lenghts[1])
            }
            else
            {
                geometry = SCNTorus(ringRadius: 4, pipeRadius: 2)
            }
        default:
            geometry = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 1)
        }
        node?.geometry = geometry
        
        //Set color by components
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor(red: CGFloat(figure_color?[0] ?? 0), green: CGFloat(figure_color?[1] ?? 0), blue: CGFloat(figure_color?[2] ?? 0), alpha: 255)
        #else
        node?.geometry.firstMaterial?.diffuse.contents = UIColor(red: figure_color?[0] ?? 0, green: figure_color?[1] ?? 0, blue: figure_color?[2] ?? 0, alpha: 255)
        #endif
        
        //Set shading type
        switch material_name
        {
        case "blinn":
            node?.geometry?.firstMaterial?.lightingModel = .blinn
        case "constant":
            node?.geometry?.firstMaterial?.lightingModel = .constant
        case "lambert":
            node?.geometry?.firstMaterial?.lightingModel = .lambert
        case "phong":
            node?.geometry?.firstMaterial?.lightingModel = .phong
        case "physically based":
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        case "shadow only":
            node?.geometry?.firstMaterial?.lightingModel = .shadowOnly
        default:
            break
        }
        
        //Set physics type
        switch physics_name
        {
        case "static":
            physics = .static()
        case "dynamic":
            physics = .dynamic()
        case "kinematic":
            physics = .kinematic()
        default:
            physics = .none
        }
        //node?.physicsBody = physics
    }
}
