//
//  AppState.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 20.05.2022.
//

import Foundation
import SwiftUI
import IndustrialKit

// MARK: - Class for work with various application data
@MainActor
class AppState: ObservableObject
{
    // Commands
    @Published var run_command = false
    @Published var stop_command = false
    
    #if os(iOS) || os(visionOS)
    @Published var settings_view_presented = false // Flag for showing setting view for iOS and iPadOS
    #endif
    
    // Pass data
    @Published var preferences_pass_mode = false
    @Published var programs_pass_mode = false
    
    public var robot_from = Robot()
    public var robots_to_names = [String]()
    
    public var origin_location_flag = false
    public var origin_rotation_flag = false
    public var space_scale_flag = false
    
    public var passed_programs_names_list = [String]()
    
    public func clear_pass()
    {
        if preferences_pass_mode || programs_pass_mode
        {
            robot_from = Robot()
            robots_to_names.removeAll()
            
            origin_location_flag = false
            origin_rotation_flag = false
            space_scale_flag = false
            
            passed_programs_names_list = [String]()
        }
    }
    
    // Visual workspace view
    // If add in view presented or not dismissed state.
    public var add_in_view_dismissed = true
    
    // Gallery workspace view
    @Published var gallery_disabled = false
    #if os(iOS) || os(visionOS)
    @Published var locked = false // Does not allow you to make a duplicate connection to the scene caused by unknown reasons
    #endif
    
    // MARK: - Application state init function
    init()
    {
        import_internal_modules()
        import_external_modules(bookmark: modules_folder_bookmark)
    }
    
    // MARK: - Modules handling functions
    // MARK: Internal modules
    @Published public var internal_modules_list: (robot: [String], tool: [String], part: [String], changer: [String]) = (robot: [], tool: [], part: [], changer: [])
    
    public func import_internal_modules()
    {
        Robot.internal_modules = internal_modules.robot
        Tool.internal_modules = internal_modules.tool
        Part.internal_modules = internal_modules.part
        Changer.internal_modules = internal_modules.changer
        
        internal_modules_list.robot = internal_modules.robot.map { $0.name }
        internal_modules_list.tool = internal_modules.tool.map { $0.name }
        internal_modules_list.part = internal_modules.part.map { $0.name }
        internal_modules_list.changer = internal_modules.changer.map { $0.name }
        
        Changer.internal_modules_list = internal_modules_list.changer
    }
    
    // MARK: External modules
    @AppStorage("ModulesFolderBookmark") private var modules_folder_bookmark: Data?
    
    public var modules_folder_url: URL? = nil
    
    @Published public var external_modules_list: (robot: [String], tool: [String], part: [String], changer: [String]) = (robot: [], tool: [], part: [], changer: [])
    
    public func update_external_modules_bookmark(url: URL?)
    {
        guard url!.startAccessingSecurityScopedResource() else
        {
            return
        }
        
        do
        {
            clear_modules()
            modules_folder_bookmark = try url!.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            import_external_modules(bookmark: modules_folder_bookmark)
            #if os(macOS)
            start_external_modules_servers()
            #endif
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        do { url?.stopAccessingSecurityScopedResource() }
    }
    
    public func import_external_modules(bookmark: Data?)
    {
        do
        {
            var is_stale = false
            modules_folder_url = try URL(resolvingBookmarkData: bookmark ?? Data(), bookmarkDataIsStale: &is_stale)
            
            guard !is_stale else
            {
                return
            }
            
            var modules_names: [String] = []
            
            for file_url in directory_contents(url: try URL(resolvingBookmarkData: bookmark ?? Data(), bookmarkDataIsStale: &is_stale))
            {
                modules_names.append(file_url.lastPathComponent) // Append file name
            }
            
            external_modules_list.robot = modules_names.filter { $0.contains(".robot") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.tool = modules_names.filter { $0.contains(".tool") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.part = modules_names.filter { $0.contains(".part") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            external_modules_list.changer = modules_names.filter { $0.contains(".changer") }.map { $0.components(separatedBy: ".").dropLast().joined(separator: ".") }
            
            Changer.external_modules_list = external_modules_list.changer
            
            WorkspaceObject.modules_folder_bookmark = bookmark
            
            Robot.external_modules_import(by: external_modules_list.robot)
            Tool.external_modules_import(by: external_modules_list.tool)
            Part.external_modules_import(by: external_modules_list.part)
            Changer.external_modules_import(by: external_modules_list.changer)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    public func directory_contents(url: URL) -> [URL] // Get all files URLs from frolder url
    {
        do
        {
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        }
        catch
        {
            print(error.localizedDescription)
            return []
        }
    }
    
    public func clear_modules()
    {
        modules_folder_bookmark = nil
        external_modules_list = (robot: [], tool: [], part: [], changer: [])
        
        #if os(macOS)
        stop_external_modules_servers()
        #endif
        
        Robot.external_modules.removeAll()
        Tool.external_modules.removeAll()
        Part.external_modules.removeAll()
        Changer.external_modules.removeAll()
        
        modules_folder_url = nil
    }
    
    /*public func is_module_avalibale(for workspace_object: WorkspaceObject) -> Bool
    {
        switch workspace_object
        {
        case is Robot:
            return workspace_object.is_internal_module ? Robot.internal_modules.contains(where: { $0.name == workspace_object.name }) : Robot.external_modules.contains(where: { $0.name == workspace_object.name })
        case is Tool:
            return workspace_object.is_internal_module ? Tool.internal_modules.contains(where: { $0.name == workspace_object.name }) : Tool.external_modules.contains(where: { $0.name == workspace_object.name })
        case is Part:
            return workspace_object.is_internal_module ? Part.internal_modules.contains(where: { $0.name == workspace_object.name }) : Part.external_modules.contains(where: { $0.name == workspace_object.name })
        default:
            return false
        }
    }*/
    
    // Documents count handling for external modules servers
    #if os(macOS)
    private var opened_documents_count = 0
    
    public func inc_documents_count()
    {
        opened_documents_count += 1
        
        start_external_modules_servers()
    }
    
    public func dec_documents_count()
    {
        opened_documents_count -= 1
        
        //print(opened_documents_count)
        
        if opened_documents_count == 0
        {
            stop_external_modules_servers()
        }
    }
    
    private func stop_external_modules_servers()
    {
        Robot.external_modules_servers_stop()
        Tool.external_modules_servers_stop()
        Changer.external_modules_servers_stop()
    }
    
    private func start_external_modules_servers()
    {
        //print(opened_documents_count)
        
        if opened_documents_count == 1
        {
            Robot.external_modules_servers_start()
            Tool.external_modules_servers_start()
            Changer.external_modules_servers_start()
        }
    }
    #endif
    
    // MARK: - UI Output
    public var modules_folder_name: String
    {
        return get_relative_path(from: modules_folder_url) ?? "No folder selected"
    }
    
    private func get_relative_path(from urlString: URL?) -> String?
    {
        if let fileURL = URL(string: urlString?.absoluteString ?? "")
        {
            let pathComponents = fileURL.pathComponents
            let filteredComponents = pathComponents.dropFirst(2)
            return filteredComponents.joined(separator: "/")
        }
        return nil
    }
    
    private func names_to_list(_ names: [String]) -> String
    {
        return "· " + names.map { $0.components(separatedBy: ".")[0] }.joined(separator: "\n· ")
    }
    
    // Internal
    public var internal_robot_modules_names: String
    {
        return internal_modules_list.robot.count > 0 ? names_to_list(internal_modules_list.robot) : "No Modules"
    }
    
    public var internal_tool_modules_names: String
    {
        return internal_modules_list.tool.count > 0 ? names_to_list(internal_modules_list.tool) : "No Modules"
    }
    
    public var internal_part_modules_names: String
    {
        return internal_modules_list.part.count > 0 ? names_to_list(internal_modules_list.part) : "No Modules"
    }
    
    public var internal_changer_modules_names: String
    {
        return internal_modules_list.changer.count > 0 ? names_to_list(internal_modules_list.changer) : "No Modules"
    }
    
    // External    
    public var external_robot_modules_names: String
    {
        external_modules_list.robot.count > 0 ? names_to_list(external_modules_list.robot) : "No Modules"
    }
    
    public var external_tool_modules_names: String
    {
        external_modules_list.tool.count > 0 ? names_to_list(external_modules_list.tool) : "No Modules"
    }
    
    public var external_part_modules_names: String
    {
        external_modules_list.part.count > 0 ? names_to_list(external_modules_list.part) : "No Modules"
    }
    
    public var external_changer_modules_names: String
    {
        external_modules_list.changer.count > 0 ? names_to_list(external_modules_list.changer) : "No Modules"
    }
    
    // MARK: - Program elements functions
    @Published var new_program_element: WorkspaceProgramElement = RobotPerformerElement()
    
    #if !os(visionOS)
    @Published public var view_program_as_text = false
    #endif
}

// MARK: - Control modifier
struct MenuHandlingModifier: ViewModifier
{
    @EnvironmentObject var app_state: AppState
    
    @Binding var performed: Bool
    
    let toggle_perform: () -> ()
    let stop_perform: () -> ()
    
    public func body(content: Content) -> some View
    {
        content
            .onChange(of: app_state.run_command)
            { _, _ in
                toggle_perform()
            }
            .onChange(of: app_state.stop_command)
            { _, _ in
                stop_perform()
            }
    }
}

func colors_by_seed(seed: Int) -> [Color]
{
    var colors = [Color]()

    srand48(seed)
    
    for _ in 0..<256
    {
        var color = [Double]()
        for _ in 0..<3
        {
            let random_number = Double(drand48() * Double(128) + 64)
            
            color.append(random_number)
        }
        colors.append(Color(red: color[0] / 255, green: color[1] / 255, blue: color[2] / 255))
    }

    return colors
}

let registers_colors = colors_by_seed(seed: 5433)

typealias Changer = ChangerModifierElement

@MainActor
extension IndustrialModule
{
    func perform_load_entity_async() async
    {
        await withCheckedContinuation
        { continuation in
            perform_load_entity
            {
                continuation.resume()
            }
        }
    }
}
