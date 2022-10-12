//
//  Workspace.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit
import SwiftUI

class Workspace: ObservableObject
{
    //MARK: - Workspace objects data
    @Published public var robots = [Robot]()
    @Published public var elements = [WorkspaceProgramElement]()
    @Published public var tools = [Tool]()
    @Published public var details = [Detail]()
    
    //MARK: - Robots handling functions
    //MARK: Robots manage functions
    public func add_robot(_ robot: Robot)
    {
        robot.name = mismatched_name(name: robot.name!, names: robots_names)
        robots.append(robot)
    }
    
    public func delete_robot(number: Int)
    {
        if robots.indices.contains(number)
        {
            robots.remove(at: number)
        }
    }
    
    public func delete_robot(name: String)
    {
        delete_robot(number: robot_number_by_name(name: name))
    }
    
    //MARK: Robot selection functions
    private var selected_robot_index = -1
    
    private func robot_number_by_name(name: String) -> Int //Get index number of robot by name
    {
        return robots.firstIndex(of: Robot(name: name)) ?? -1
    }
    
    public func select_robot(number: Int) //Select robot by number
    {
        selected_robot_index = number
    }
    
    public func select_robot(name: String) //Select robot by name
    {
        selected_robot_index = robot_number_by_name(name: name)
    }
    
    public func deselect_robot()
    {
        selected_robot_index = -1
    }
    
    public var selected_robot: Robot //Return robot by selected index
    {
        get
        {
            if selected_robot_index > -1
            {
                return robots[selected_robot_index]
            }
            else
            {
                return Robot()
            }
        }
        set
        {
            if selected_robot_index > -1
            {
                robots[selected_robot_index] = newValue
            }
        }
    }
    
    //MARK: Robots naming
    public func robot_by_name(name: String) -> Robot //Get index number of robot by name
    {
        return self.robots[robot_number_by_name(name: name)]
    }
    
    public var robots_names: [String] //Get names of all robots in workspace
    {
        var robots_names = [String]()
        if robots.count > 0
        {
            for robot in robots
            {
                robots_names.append(robot.name ?? "None")
            }
        }
        return robots_names
    }
    
    public var avaliable_robots_names: [String] //Array of robots names not added to workspace
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && !robot.is_placed
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    public var placed_robots_names: [String] //Array of robots names added to workspace
    {
        var names = [String]()
        for robot in robots
        {
            if robot.name != nil && robot.is_placed
            {
                names.append(robot.name!)
            }
        }
        return names
    }
    
    //MARK: - Details handling functions
    //MARK: Details manage funcions
    public func add_detail(_ detail: Detail)
    {
        detail.name = mismatched_name(name: detail.name!, names: details_names)
        details.append(detail)
    }
    
    public func delete_detail(number: Int)
    {
        if details.indices.contains(number)
        {
            robots.remove(at: number)
        }
    }
    
    /*public func delete_detail(name: String)
    {
        delete_detail(number: number_by_name(name: name))
    }*/
    
    //MARK: Details selection functions
    private var selected_detail_index = -1
    
    public var selected_detail: Detail //Return detail by selected index
    {
        get
        {
            if selected_detail_index > -1
            {
                return details[selected_detail_index]
            }
            else
            {
                return Detail(name: "None", dictionary: ["String" : "Any"])
            }
        }
        set
        {
            if selected_detail_index > -1
            {
                details[selected_detail_index] = newValue
            }
        }
    }
    
    private func detail_number_by_name(name: String) -> Int //Get index number of robot by name
    {
        return details.firstIndex(of: Detail(name: name, scene: "")) ?? -1
    }
    
    public func select_detail(number: Int) //Select detail by number
    {
        selected_detail_index = number
    }
    
    public func select_detail(name: String) //Select detail by name
    {
        selected_detail_index = detail_number_by_name(name: name)
    }
    
    public func deselect_detail()
    {
        selected_detail_index = -1
    }
    
    //MARK: Details naming
    public var details_names: [String] //Get names of all details in workspace
    {
        var details_names = [String]()
        if details.count > 0
        {
            for detail in details
            {
                details_names.append(detail.name ?? "None")
            }
        }
        return details_names
    }
    
    public var avaliable_details_names: [String] //Array of details names not added to workspace
    {
        var names = [String]()
        for detail in details
        {
            if detail.name != nil && !detail.is_placed
            {
                names.append(detail.name!)
            }
        }
        return names
    }
    
    //MARK: - Control program functions
    //MARK: Workspace program elements handling
    var marks_names: [String] //Get names of all marks in workspace program
    {
        var marks_names = [String]()
        for program_element in self.elements
        {
            if program_element.element_data.logic_type == .mark && program_element.element_data.mark_name != ""
            {
                marks_names.append(program_element.element_data.mark_name)
            }
        }
        
        return marks_names
    }
    
    public func delete_element(number: Int) //Delete program element by number
    {
        if elements.indices.contains(number)
        {
            elements.remove(at: number)
        }
    }
    
    //MARK: Workspace progem elements checking functions
    public func elements_check() //Select check by element type
    {
        for element in elements
        {
            switch element.element_data.element_type
            {
            case .perofrmer:
                switch element.element_data.performer_type
                {
                case .robot:
                    element_robot_check(element: element)
                case .tool:
                    break
                }
            case .modificator:
                break
            case .logic:
                switch element.element_data.logic_type
                {
                case .jump:
                    element_jump_check(element: element)
                default:
                    break
                }
            }
        }
        
        func element_robot_check(element: WorkspaceProgramElement) //Check element by selected robot exists
        {
            if element.element_data.robot_name != ""
            {
                if self.robot_by_name(name: element.element_data.robot_name).is_placed == false
                {
                    if self.placed_robots_names.count > 0
                    {
                        element.element_data.robot_name = self.placed_robots_names.first!
                        
                        if robot_by_name(name: element.element_data.robot_name).programs_count > 0
                        {
                            element.element_data.robot_program_name = robot_by_name(name: element.element_data.robot_name).programs_names.first!
                        }
                    }
                    else
                    {
                        element.element_data.robot_name = ""
                    }
                }
            }
            else
            {
                if self.placed_robots_names.count > 0
                {
                    element.element_data.robot_name = robots.first?.name ?? "None"
                    if robots.first?.programs_count ?? 0 > 0
                    {
                        element.element_data.robot_program_name = robot_by_name(name: element.element_data.robot_name).programs_names.first!
                    }
                }
                else
                {
                    element.element_data.robot_name = ""
                }
            }
        }
        
        func element_jump_check(element: WorkspaceProgramElement) //Check element by selected mark exists
        {
            if marks_names.count > 0
            {
                var mark_founded = false
                
                for mark_name in self.marks_names
                {
                    if mark_name == element.element_data.target_mark_name
                    {
                        mark_founded = true
                    }
                    
                    if mark_founded == true
                    {
                        break
                    }
                }
                
                if mark_founded == false && element.element_data.mark_name == ""
                {
                    element.element_data.target_mark_name = marks_names[0]
                }
            }
            else
            {
                element.element_data.target_mark_name = ""
            }
        }
    }
    
    @Published var cycled = false //Cyclic program performance flag
    
    public var performed = false
    public var workspace_scene = SCNScene()
    
    private var selected_element_index = 0
    
    public func start_pause_performing()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) //Delayed update view
        {
            self.update_view()
        }
        
        if performed == false
        {
            //Move to next point if moving was stop
            performed = true
            selected_robot.unit_origin_node?.isHidden = true
            selected_robot_index = -1
            
            defining_elements_indexes()
            
            let queue = DispatchQueue.global(qos: .utility)
            queue.async
            {
                self.perfom_next_element()
            }
        }
        else
        {
            //Remove all action if moving was perform
            performed = false
            selected_robot.start_pause_moving()
            selected_robot_index = -1
        }
    }
    
    private func defining_elements_indexes()
    {
        //Find mark elements indexes
        var marks_associations = [(String, Int)]()
        var element_data = workspace_program_element_struct()
        for i in 0..<elements.count
        {
            element_data = elements[i].element_data
            if element_data.element_type == .logic && element_data.logic_type == .mark
            {
                marks_associations.append((element_data.mark_name, i))
            }
        }
        
        //Set target element indexes of marks to jump elements.
        var target_mark_name: String
        for element in elements
        {
            if element.element_data.element_type == .logic && element.element_data.logic_type == .jump
            {
                target_mark_name = element.element_data.target_mark_name
                for marks_association in marks_associations
                {
                    if marks_association.0 == target_mark_name
                    {
                        element.target_element_index = marks_association.1
                        break
                    }
                }
            }
        }
    }
    
    public func perfom_next_element()
    {
        if selected_element_index < elements.count
        {
            update_view()
            
            let element = elements[selected_element_index]
            var jumped = false
            
            element.is_selected = true
            
            switch element.element_data.element_type
            {
            case .perofrmer:
                switch element.element_data.performer_type
                {
                case .robot:
                    select_robot(name: element.element_data.robot_name)
                    if selected_robot.programs_names.count > 0 && element.element_data.robot_program_name != ""
                    {
                        selected_robot.robot_workcell_connect(scene: workspace_scene, name: selected_robot.name!, connect_camera: false)
                        selected_robot.select_program(name: element.element_data.robot_program_name)
                        selected_robot.start_pause_moving()
                        while selected_robot.moving_completed == false && self.performed == true
                        {
                            
                        }
                    }
                    break
                case .tool:
                    break
                }
            case .modificator:
                break
            case .logic:
                switch element.element_data.logic_type
                {
                case .jump:
                    jumped = true
                default:
                    break
                }
            }
            
            if performed == true
            {
                update_view()
                elements[selected_element_index].is_selected = false
                
                if jumped == false
                {
                    selected_element_index += 1
                }
                else
                {
                    selected_element_index = element.target_element_index
                }
                
                perfom_next_element()
            }
        }
        else
        {
            selected_element_index = 0
            selected_robot_index = -1
            
            if cycled == true
            {
                perfom_next_element()
            }
            else
            {
                performed = false
                update_view()
            }
        }
    }
    
    public func reset_performing()
    {
        elements[selected_element_index].is_selected = false //Deselect performed program element
        selected_robot.reset_moving()
        selected_element_index = 0 //Select firs program element
        deselect_robot()
        performed = false //Enable workspace program edit
    }
    
    //MARK: - Work with file system
    public func file_data() -> (robots: [robot_struct], tools: [tool_struct], details: [detail_struct], elements: [workspace_program_element_struct])
    {
        //Get robots info for save to file
        var robots_file_info = [robot_struct]()
        for robot in robots
        {
            robots_file_info.append(robot.file_info)
        }
        
        //Get tools info for save to file
        var tools_file_info = [tool_struct]()
        for tool in tools
        {
            tools_file_info.append(tool.file_info)
        }
        
        //Get details info for save to file
        var details_file_info = [detail_struct]()
        for detail in details
        {
            details_file_info.append(detail.file_info)
        }
        
        //Get workspace program elements info for save to file
        var elements_file_info = [workspace_program_element_struct]()
        for element in elements
        {
            elements_file_info.append(element.element_data)
        }
        
        return(robots_file_info, tools_file_info, details_file_info, elements_file_info)
    }
    
    public var robots_bookmark: Data?
    public var details_bookmark: Data?
    public var tools_bookmark: Data?
    
    public func file_view(preset: WorkspacePreset)
    {
        //Update robots data from file
        robots.removeAll()
        for robot_struct in preset.robots
        {
            robots.append(Robot(robot_struct: robot_struct))
        }
        
        //Update tools data from file
        tools.removeAll()
        for tool_struct in preset.tools
        {
            tools.append(Tool(tool_struct: tool_struct))
        }
        
        //Update details data from file
        details.removeAll()
        if details_bookmark == nil
        {
            //Add details without scene
            for detail_struct in preset.details
            {
                details.append(Detail(detail_struct: detail_struct))
            }
        }
        else
        {
            //Add details with scene
            for detail_struct in preset.details
            {
                print(detail_struct)
                do
                {
                    var is_stale = false
                    let url = try URL(resolvingBookmarkData: details_bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
                    
                    guard !is_stale else
                    {
                        //Handle stale data here
                        return
                    }
                    
                    details.append(Detail(detail_struct: detail_struct, folder_url: url))
                }
                catch
                {
                    print(error.localizedDescription)
                }
            }
        }
        
        //Update workspace program elements data from file
        elements.removeAll()
        for element_struct in preset.elements
        {
            elements.append(WorkspaceProgramElement(element_struct: element_struct))
        }
    }
    
    //MARK: - UI Functions
    public var is_editing = false //Determines whether the robot can be selected if it is open for editing
    
    func update_view() //Force update SwiftUI view
    {
        self.objectWillChange.send()
    }
    
    public var is_selected: Bool
    {
        if selected_robot_index == -1 && selected_detail_index == -1
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    public var selected_category = 0
    
    public var selected_object_type: WorkspaceObjectType
    {
        if selected_robot_index > -1
        {
            return .robot
        }
        
        if selected_detail_index > -1
        {
            return .detail
        }
        
        return .tool
    }
    //MARK: - Visual functions
    public var camera_node: SCNNode?
    public var workcells_node: SCNNode?
    public var details_node: SCNNode?
    public var unit_node: SCNNode?
    public var detail_node: SCNNode?
    public var view_pointer_node = SCNScene(named: "Components.scnassets/View.scn")!.rootNode.childNode(withName: "pointer", recursively: false)! //: SCNNode?
    
    public func place_objects(scene: SCNScene)
    {
        if self.avaliable_robots_names.count < self.robots.count
        {
        	var connect_camera = true
            for robot in robots
            {
                if robot.is_placed == true
                {
                    workcells_node?.addChildNode(SCNScene(named: "Components.scnassets/Workcell.scn")!.rootNode.childNode(withName: "unit", recursively: false)!)
                    unit_node = workcells_node?.childNode(withName: "unit", recursively: false)! //Connect to unit node in workspace scene
                    
                    unit_node?.name = robot.name
                    robot.robot_workcell_connect(scene: scene, name: robot.name!, connect_camera: connect_camera)
                    robot.update_robot()
                    
                    connect_camera = false
                    
                    #if os(macOS)
                    unit_node?.worldPosition = SCNVector3(x: CGFloat(robot.location[1]), y: CGFloat(robot.location[2]), z: CGFloat(robot.location[0]))
                    
                    unit_node?.eulerAngles.x = CGFloat(robot.rotation[1].to_rad)
                    unit_node?.eulerAngles.y = CGFloat(robot.rotation[2].to_rad)
                    unit_node?.eulerAngles.z = CGFloat(robot.rotation[0].to_rad)
                    #else
                    unit_node?.worldPosition = SCNVector3(x: robot.location[1], y: robot.location[2], z: robot.location[0])

                    unit_node?.eulerAngles.x = robot.rotation[1].to_rad
                    unit_node?.eulerAngles.y = robot.rotation[2].to_rad
                    unit_node?.eulerAngles.z = robot.rotation[0].to_rad
                    #endif
                }
            }
        }
        
        if self.avaliable_details_names.count < self.details.count
        {
            for detail in details
            {
                if detail.is_placed
                {
                    let detail_node = detail.node
                    detail.enable_physics = true
                    detail_node?.categoryBitMask = 4
                    detail_node?.name = detail.name
                    details_node?.addChildNode(detail_node ?? SCNNode())
                    
                    #if os(macOS)
                    detail_node?.position = SCNVector3(x: CGFloat(detail.location[1]), y: CGFloat(detail.location[2]), z: CGFloat(detail.location[0]))
                    
                    detail_node?.eulerAngles.x = CGFloat(detail.rotation[1].to_rad)
                    detail_node?.eulerAngles.y = CGFloat(detail.rotation[2].to_rad)
                    detail_node?.eulerAngles.z = CGFloat(detail.rotation[0].to_rad)
                    #else
                    detail_node?.position = SCNVector3(x: Float(detail.location[1]), y: Float(detail.location[2]), z: Float(detail.location[0]))
                    
                    detail_node?.eulerAngles.x = detail.rotation[1].to_rad
                    detail_node?.eulerAngles.y = detail.rotation[2].to_rad
                    detail_node?.eulerAngles.z = detail.rotation[0].to_rad
                    #endif
                }
            }
        }
    }
}

enum WorkspaceObjectType: String, Equatable, CaseIterable
{
    case robot = "Robot"
    case detail = "Detail"
    case tool = "Tool"
}

enum PositionComponents: String, Equatable, CaseIterable
{
    case location = "Location"
    case rotation = "Rotation"
}

enum LocationComponents: Equatable, CaseIterable
{
    case x
    case y
    case z
    
    var info: (text: String, index: Int)
    {
        switch self
        {
        case .x:
            return("X: ", 0)
        case .y:
            return("Y: ", 1)
        case .z:
            return("Z: ", 2)
        }
    }
}

enum RotationComponents: Equatable, CaseIterable
{
    case r
    case p
    case w
    
    var info: (text: String, index: Int)
    {
        switch self
        {
        case .r:
            return("R: ", 0)
        case .p:
            return("P: ", 1)
        case .w:
            return("W: ", 2)
        }
    }
}

//MARK: - Structure for workspace preset document handling
struct WorkspacePreset: Codable
{
    var robots = [robot_struct]()
    var elements = [workspace_program_element_struct]()
    var tools = [tool_struct]()
    var details = [detail_struct]()
}

//MARK: Functions
func mismatched_name(name: String, names: [String]) -> String
{
    var name_count = 1
    var name_postfix: String
    {
        return name_count > 1 ? " \(name_count)" : ""
    }
    
    if names.count > 0
    {
        for _ in 0..<names.count
        {
            for viewed_name in names
            {
                if viewed_name == name + name_postfix
                {
                    name_count += 1
                }
            }
        }
    }
    
    return name + name_postfix
}

//MARK: - Angles convertion extension
extension Float
{
    var to_deg: Float
    {
        return self * 180 / .pi
    }
    
    var to_rad: Float
    {
        return self * .pi / 180
    }
}
