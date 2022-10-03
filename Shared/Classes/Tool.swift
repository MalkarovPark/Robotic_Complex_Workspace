//
//  Tool.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.06.2022.
//

import Foundation
import SceneKit

class Tool: Identifiable, Equatable, Hashable, ObservableObject
{
    static func == (lhs: Tool, rhs: Tool) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(name)
    }
    
    public var name: String?
    public var node: SCNNode?
    public var scene_address = "" //Addres of detail scene. If empty – this detail used defult model.
    
    //MARK: - Init functions
    init(tool_struct: tool_struct) //Init by detail structure
    {
        self.name = tool_struct.name
        self.scene_address = tool_struct.scene!
    }
    
    //MARK: - Control functions
    public var operation_code: Int?
    public var info_code: Int?
    
    //MARK: - Work with file system
    public var file_info: tool_struct
    {
        return tool_struct(name: self.name, scene: self.scene_address)
    }
}

//MARK: - Tool structure for workspace preset document handling
struct tool_struct: Codable
{
    var name: String?
    var scene: String?
}
