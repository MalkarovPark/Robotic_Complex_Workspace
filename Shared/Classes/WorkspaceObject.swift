//
//  WorkspaceObject.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 29.10.2022.
//

import Foundation
import SceneKit

class WorkspaceObject: Identifiable, Equatable, Hashable, ObservableObject
{
    static func == (lhs: WorkspaceObject, rhs: WorkspaceObject) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var id = UUID() //Object identifier
    public var name: String? //Object name
    
    init()
    {
        self.name = "None"
    }
    
    init(name: String) //Init object by name. Use for mismatch.
    {
        self.name = name
    }
    
    /*init(name: String, dictionary: [String: Any]) //Init detail by dictionary
    {
        self.name = name
        init_by_dictionary(name: name, dictionary: dictionary)
    }
    
    private func init_by_dictionary(name: String, dictionary: [String: Any])
    {
        //node_by_description()
    }*/
    
    //MARK: Object in workspace handling
    public var is_placed = false
    public var location = [Float](repeating: 0, count: 3) //Position by axis – x, y, z
    public var rotation = [Float](repeating: 0, count: 3) //Rotation in postion by angles – r, p, w
    
    //MARK: Visual functions
    public var scene_address = "" //Addres of object scene. If empty – this object used defult model.
    public var node: SCNNode? //Object scene node
    
    public static var scene_node_name: String?
    public static var folder_url: URL?
    public static var folder_bookmark: Data?
    
    public func get_node_from_scene()
    {
        do
        {
            var is_stale = false
            let url = try URL(resolvingBookmarkData: Detail.folder_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                //Handle stale data here
                return
            }
            
            if scene_address != "" //If dictionary conatains scene address get node from it.
            {
                do
                {
                    //scene_node_name = "detail"
                    self.node = try SCNScene(url: URL(string: url.absoluteString + scene_address)!).rootNode.childNode(withName: WorkspaceObject.scene_node_name ?? "", recursively: false)
                }
                catch
                {
                    print("ERROR loading scene")
                    node_by_description()
                }
            }
            else
            {
                node_by_description()
            }
        }
        catch
        {
            print(error.localizedDescription)
            node_by_description()
        }
    }
    
    public func node_by_description() //Build mode by description without external scene
    {
        /*if scene_address != ""
        {
            self.node = SCNScene(named: scene_address)!.rootNode.childNode(withName: "detail", recursively: false)!
        }*/
    }
}
