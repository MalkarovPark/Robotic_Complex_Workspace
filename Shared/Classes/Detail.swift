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
    public var scene_address = "" //Addres of detail scene. If empty – this detail used defult model.
    
    private var figure: String? //Detail figure name
    private var lenghts: [Float]? //Lenghts for detail without scene figure
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
    init(name: String, scene: String) //Init detail by scene_name
    {
        self.name = name
        self.scene_address = scene
        
        if scene != ""
        {
            self.node = SCNScene(named: scene)!.rootNode.childNode(withName: "detail", recursively: false)!
        }
    }
    
    init(name: String, dictionary: [String: Any]) //Init detail by dictionary
    {
        init_by_dictionary(name: name, dictionary: dictionary)
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.figure = "box"
        }
        node_by_description()
    }
    
    init(name: String, dictionary: [String: Any], folder_url: URL) //Init detail by dictionary and use models folder
    {
        init_by_dictionary(name: name, dictionary: dictionary)
        
        if dictionary.keys.contains("Scene") //If dictionary conatains scene address get node from it.
        {
            self.scene_address = dictionary["Scene"] as? String ?? ""
            if self.scene_address != ""
            {
                do
                {
                    self.node = try SCNScene(url: URL(string: folder_url.absoluteString + scene_address)!).rootNode.childNode(withName: "detail", recursively: false)?.clone()
                }
                catch
                {
                    print("ERROR loading scene")
                }
            }
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
    }
    
    init(detail_struct: detail_struct) //Init by detail structure
    {
        init_by_struct(detail_struct: detail_struct)
        
        if detail_struct.scene != ""
        {
            self.figure = "box"
        }
        node_by_description()
    }
    
    init(detail_struct: detail_struct, folder_url: URL) //Init by detail structure
    {
        init_by_struct(detail_struct: detail_struct)
        
        if detail_struct.scene != "" //If dictionary conatains scene address get node from it.
        {
            do
            {
                self.scene_address = detail_struct.scene
                self.node = try SCNScene(url: URL(string: folder_url.absoluteString + detail_struct.scene)!).rootNode.childNode(withName: "detail", recursively: false)
            }
            catch
            {
                print("ERROR loading scene")
            }
        }
        else
        {
            node_by_description()
        }
    }
    
    private func init_by_struct(detail_struct: detail_struct)
    {
        self.name = detail_struct.name
        
        self.figure = detail_struct.figure
        self.lenghts = detail_struct.lenghts
        
        self.figure_color = detail_struct.figure_color
        self.material_name = detail_struct.material_name
        self.physics_type = detail_struct.physics_type
        
        self.gripable = detail_struct.gripable
        
        self.is_placed = detail_struct.is_placed
        self.location = detail_struct.location
        self.rotation = detail_struct.rotation
        
        self.image_data = detail_struct.image_data
    }
    
    private func node_by_description()
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
            node?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        }
    }
    
    //MARK: Detail in workspace handling
    public var is_placed = false
    public var location = [Float](repeating: 0, count: 3) //[0, 0, 0] x, y, z
    public var rotation = [Float](repeating: 0, count: 3) //[0, 0, 0] r, p, w
    
    public func model_position_reset()
    {
        node?.position = SCNVector3(0, 0, 0)
        node?.rotation.x = 0
        node?.rotation.y = 0
        node?.rotation.z = 0
    }
    
    //MARK: - UI functions
    private var image_data = Data()
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
    public var image: NSImage
    {
        get
        {
            return NSImage(data: image_data) ?? NSImage()
        }
        set
        {
            image_data = newValue.tiffRepresentation ?? Data()
        }
    }
    
    public func card_info() -> (title: String, color: Color, image: NSImage) //Get info for robot card view (in RobotsView)
    {
        return("\(self.name ?? "Detail")", self.color, self.image)
    }
    #else
    public var image: UIImage
    {
        get
        {
            return UIImage(data: image_data) ?? UIImage()
        }
        set
        {
            image_data = newValue.pngData() ?? Data()
        }
    }
    
    public func card_info() -> (title: String, color: Color, image: UIImage) //Get info for robot card view
    {
        return("\(self.name ?? "Detail")", Color(red: Double(figure_color?[0] ?? 0) / 255, green: Double(figure_color?[1] ?? 0) / 255, blue: Double(figure_color?[2] ?? 0) / 255), self.image)
    }
    #endif
    
    //MARK: - Work with file system
    public var file_info: detail_struct
    {
        return detail_struct(name: self.name ?? "None", scene: self.scene_address, figure: self.figure ?? "box", lenghts: self.lenghts ?? [0, 0, 0], figure_color: self.figure_color ?? [0, 0, 0], material_name: self.material_name ?? "blinn", physics_type: self.physics_type, gripable: self.gripable ?? false, is_placed: self.is_placed, location: self.location, rotation: self.rotation, image_data: self.image_data)
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
struct detail_struct: Codable
{
    var name: String
    
    var scene: String
    
    var figure: String
    var lenghts: [Float]
    
    var figure_color: [Int]
    var material_name: String
    var physics_type: PhysicsType
    
    var gripable: Bool
    
    var is_placed: Bool
    var location: [Float]
    var rotation: [Float]
    
    var image_data: Data
}
