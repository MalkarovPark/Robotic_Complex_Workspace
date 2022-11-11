//
//  Detail.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 28.08.2022.
//

import Foundation
import SceneKit
import SwiftUI

class Detail: WorkspaceObject
{
    private var figure: String? //Detail figure name
    private var lengths: [Float]? //lengths for detail without scene figure
    private var figure_color: [Int]? //Color for detail without scene figure
    private var material_name: String? //Material for detail without scene figure
    
    public var gripable: Bool? //Can this detail be gripped and picked up
    
    public var physics: SCNPhysicsBody?
    {
        switch physics_type
        {
        case .ph_static:
            return .static()
        case .ph_dynamic:
            return .dynamic()
        case .ph_kinematic:
            return .kinematic()
        default:
            return .none
        }
    }
    
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
                //physics = node?.physicsBody //Save original physics
                node?.physicsBody = nil
            }
        }
    }
    
    //MARK: - Detail init functions
    override init(name: String)
    {
        super.init(name: name)
    }
    
    init(name: String, scene: String) //Init detail by scene_name
    {
        super.init(name: name)
        
        self.scene_address = scene
        
        if scene != ""
        {
            self.node = SCNScene(named: scene)!.rootNode.childNode(withName: "detail", recursively: false)!
        }
    }
    
    init(name: String, dictionary: [String: Any]) //Init detail by dictionary and use models folder
    {
        super.init()
        init_by_dictionary(name: name, dictionary: dictionary)
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            get_node_from_scene()
        }
        else
        {
            node_by_description()
        }
    }
    
    private func init_by_dictionary(name: String, dictionary: [String: Any])
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
            var lengths = [Float]()
            let elements = dictionary["Lengths"] as! NSArray
            
            for element in elements //Add elements from NSArray to floats array
            {
                lengths.append((element as? Float) ?? 0)
            }
            
            self.lengths = lengths
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
    }
    
    init(detail_struct: DetailStruct) //Init by detail structure
    {
        super.init()
        init_by_struct(detail_struct: detail_struct)
    }
    
    private func init_by_struct(detail_struct: DetailStruct)
    {
        self.name = detail_struct.name
        
        self.figure = detail_struct.figure
        self.lengths = detail_struct.lengths
        
        self.figure_color = detail_struct.figure_color
        self.material_name = detail_struct.material_name
        self.physics_type = detail_struct.physics_type
        
        self.gripable = detail_struct.gripable
        
        self.is_placed = detail_struct.is_placed
        self.location = detail_struct.location
        self.rotation = detail_struct.rotation
        
        self.scene_address = detail_struct.scene
        
        self.image_data = detail_struct.image_data
        
        get_node_from_scene()
    }
    
    //MARK: - Visual build functions
    override var scene_node_name: String { "detail" }
    
    override func node_by_description()
    {
        node = SCNNode()
        
        //Convert Float array to GFloat array
        var lengths = [CGFloat]()
        for length in self.lengths ?? []
        {
            lengths.append(CGFloat(length))
        }
        
        //Set geometry
        var geometry: SCNGeometry?
        switch figure
        {
        case "plane":
            if lengths.count == 2
            {
                geometry = SCNPlane(width: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNPlane(width: 4, height: 4)
            }
        case "box":
            if lengths.count >= 3 && lengths.count <= 4
            {
                geometry = SCNBox(width: lengths[0], height: lengths[1], length: lengths[2], chamferRadius: lengths.count == 3 ? 0 : lengths[3]) //If lengths 4 – set chamer radius by element 3
            }
            else
            {
                geometry = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 1)
            }
        case "sphere":
            if lengths.count == 1
            {
                geometry = SCNSphere(radius: lengths[0])
            }
            else
            {
                geometry = SCNSphere(radius: 2)
            }
        case "pyramid":
            if lengths.count == 3
            {
                geometry = SCNPyramid(width: lengths[0], height: lengths[1], length: lengths[2])
            }
            else
            {
                geometry = SCNPyramid(width: 4, height: 2, length: 4)
            }
        case "cylinder":
            if lengths.count == 2
            {
                geometry = SCNCylinder(radius: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNCylinder(radius: 2, height: 4)
            }
        case "cone":
            if lengths.count == 3
            {
                geometry = SCNCone(topRadius: lengths[0], bottomRadius: lengths[1], height: lengths[2])
            }
            else
            {
                geometry = SCNCone(topRadius: 1, bottomRadius: 2, height: 4)
            }
        case "tube":
            if lengths.count == 3
            {
                geometry = SCNTube(innerRadius: lengths[0], outerRadius: lengths[1], height: lengths[2])
            }
            else
            {
                geometry = SCNTube(innerRadius: 1, outerRadius: 2, height: 4)
            }
        case "capsule":
            if lengths.count == 2
            {
                geometry = SCNCapsule(capRadius: lengths[0], height: lengths[1])
            }
            else
            {
                geometry = SCNCapsule(capRadius: 2, height: 4)
            }
        case "torus":
            if lengths.count == 2
            {
                geometry = SCNTorus(ringRadius: lengths[0], pipeRadius: lengths[1])
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
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        }
        
        node?.name = "Figure"
    }
    
    //MARK: Detail in workspace handling
    public func model_position_reset()
    {
        node?.position = SCNVector3(0, 0, 0)
        node?.rotation.x = 0
        node?.rotation.y = 0
        node?.rotation.z = 0
    }
    
    //MARK: - UI functions
    public var color: Color
    {
        get
        {
            return Color(red: Double(figure_color?[0] ?? 0) / 255, green: Double(figure_color?[1] ?? 0) / 255, blue: Double(figure_color?[2] ?? 0) / 255)
        }
        set
        {
            #if os(macOS)
            let viewed_color_components = NSColor(newValue).cgColor.components
            #else
            let viewed_color_components = UIColor(newValue).cgColor.components
            #endif
            
            for i in 0..<(figure_color?.count ?? 3)
            {
                self.figure_color?[i] = Int((viewed_color_components?[i] ?? 0) * 255)
            }
            
            //Update color by components
            #if os(macOS)
            node?.geometry?.firstMaterial?.diffuse.contents = NSColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
            #else
            node?.geometry?.firstMaterial?.diffuse.contents = UIColor(red: CGFloat(figure_color?[0] ?? 0) / 255, green: CGFloat(figure_color?[1] ?? 0) / 255, blue: CGFloat(figure_color?[2] ?? 0) / 255, alpha: 1)
            #endif
        }
    }
    
    #if os(macOS)
    override var card_info: (title: String, subtitle: String, color: Color, image: NSImage) //Get info for robot card view
    {
        return("\(self.name ?? "Detail")", "Subtitle", self.color, self.image)
    }
    #else
    override var card_info: (title: String, subtitle: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Detail")", "Subtitle", self.color, self.image)
    }
    #endif
    
    //MARK: - Work with file system
    public var file_info: DetailStruct
    {
        return DetailStruct(name: self.name ?? "None", scene: self.scene_address, figure: self.figure ?? "box", lengths: self.lengths ?? [0, 0, 0], figure_color: self.figure_color ?? [0, 0, 0], material_name: self.material_name ?? "blinn", physics_type: self.physics_type, gripable: self.gripable ?? false, is_placed: self.is_placed, location: self.location, rotation: self.rotation, image_data: self.image_data)
    }
}

enum PhysicsType: String, Codable, Equatable, CaseIterable
{
    case ph_static = "Static"
    case ph_dynamic = "Dynamic"
    case ph_kinematic = "Kinematic"
    case ph_none = "None"
}

//MARK: - Detail structure for workspace preset document handling
struct DetailStruct: Codable
{
    var name: String
    
    var scene: String
    
    var figure: String
    var lengths: [Float]
    
    var figure_color: [Int]
    var material_name: String
    var physics_type: PhysicsType
    
    var gripable: Bool
    
    var is_placed: Bool
    var location: [Float]
    var rotation: [Float]
    
    var image_data: Data
}
