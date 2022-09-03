//
//  Detail.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import Foundation
import SceneKit
import SwiftUI

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
    
    var id = UUID()
    
    public var name: String? //Detail name
    public var node: SCNNode? //Detail scene node
    public var detail_scene_address = "" //Adders of detail scene. If empty – this detail used defult model.
    
    public var gripable: Bool? //Can this detail be gripped and picked up
    
    private var figure: String?
    private var lenghts: [Float]? //Lenghts for detail without scene figure
    private var figure_color: [Int]? //Color for detail without scene figure
    private var material_name: String? //Material for detail without scene figure
    
    private var physics: SCNPhysicsBody?
    public var physics_type: PhysicsType = .ph_none //Physic body type
    
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
            self.material_name = dictionary["Material"] as? String ?? ""
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
            switch dictionary["Physics"] as? String ?? ""
            {
            case "static":
                physics_type = .ph_static
            case "dynamic":
                physics_type = .ph_dynamic
            case "kinematic":
                physics_type = .ph_kinematic
            default:
                physics_type = .ph_none
            }
        }
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.detail_scene_address = dictionary["Scene"] as? String ?? ""
            if self.detail_scene_address != ""
            {
                self.node = SCNScene(named: self.detail_scene_address)?.rootNode.childNode(withName: "detail", recursively: false)
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
        
        //Convert Float array to GFloat array
        var lenghts = [CGFloat]()
        for lenght in self.lenghts ?? []
        {
            lenghts.append(CGFloat(lenght))
        }
        
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
        node?.name = "Figure"
        
        //Set color by components
        #if os(macOS)
        node?.geometry?.firstMaterial?.diffuse.contents = NSColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
        #else
        node?.geometry?.firstMaterial?.diffuse.contents = UIColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
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
            node?.geometry?.firstMaterial?.lightingModel = .blinn
            //break
        }
        
        //Set physics type
        switch physics_type
        {
        case .ph_static:
            physics = .static()
        case .ph_dynamic:
            physics = .dynamic()
        case .ph_kinematic:
            physics = .kinematic()
        default:
            physics = .none
        }
        //node?.physicsBody = physics
    }
    
    //MARK: - UI functions
    private var detail_image_data = Data()
    
    #if os(macOS)
    public var image: NSImage
    {
        get
        {
            return NSImage(data: detail_image_data) ?? NSImage()
        }
        set
        {
            detail_image_data = newValue.tiffRepresentation ?? Data()
        }
    }
    
    public func card_info() -> (title: String, color: Color, image: NSImage) //Get info for robot card view (in RobotsView)
    {
        return("\(self.name ?? "Detail")", Color(red: Double(figure_color?[0] ?? 0) / 255, green: Double(figure_color?[1] ?? 0) / 255, blue: Double(figure_color?[2] ?? 0) / 255), self.image)
    }
    #else
    public var image: UIImage
    {
        get
        {
            return UIImage(data: detail_image_data) ?? UIImage()
        }
        set
        {
            detail_image_data = newValue.pngData() ?? Data()
        }
    }
    
    public func card_info() -> (title: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Detail")", Color(red: Double(figure_color?[0] ?? 0) / 255, green: Double(figure_color?[1] ?? 0) / 255, blue: Double(figure_color?[2] ?? 0) / 255), self.image)
    }
    #endif
}

enum PhysicsType: String, Codable, Equatable, CaseIterable
{
    case ph_static = "Static"
    case ph_dynamic = "Dynamic"
    case ph_kinematic = "Kinematic"
    case ph_none = "None"
}
