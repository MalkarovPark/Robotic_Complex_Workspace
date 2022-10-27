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
    public var operation_code: Int? = -1
    {
        didSet
        {
            //Checking for positive value of operation code number
            if operation_code! >= 0
            {
                //Perform function by opcode as array number
                print("\(operation_code ?? 0) 🍩")
            }
            else
            {
                //Reset tool perfroming by negative code
                print("\(operation_code ?? 0) 🍷")
            }
        }
    }
    
    private(set) var info_code: Int? = 0
    
    public var performed: Bool //Performing state of tool
    {
        if operation_code ?? 0 >= 0
        {
            return true
        }
        else
        {
            return false
        }
    }
    
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
