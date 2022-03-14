//
//  Robotic_Complex_WorkspaceDocument.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType
{
    static let workspace_preset_document = UTType(exportedAs: "mv-park.RoboticComplexWorkspace.preset")
    
    /*static var workspace_preset_document: UTType
    {
        UTType(exportedAs: "mv-park.RoboticComplexWorkspace.preset")
    }*/
}

struct Robotic_Complex_WorkspaceDocument: FileDocument
{
    var preset: WorkspacePreset
    
    init(robots_count: Int = 0)
    {
        self.preset = WorkspacePreset(robots_count: robots_count)
    }
    
    static var readableContentTypes: [UTType] { [.workspace_preset_document] }
    
    init(configuration: ReadConfiguration) throws
    {
        guard let data = configuration.file.regularFileContents
        else
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        preset = try JSONDecoder().decode(WorkspacePreset.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        let data = try JSONEncoder().encode(preset)
        return .init(regularFileWithContents: data)
    }
}

struct WorkspacePreset: Codable
{
    var robots = [robot_struct]()
    var robots_count = Int()
}

struct program_struct: Codable
{
    var name: String
    var points = [[Double](repeating: 0.0, count: 6)] //x y z| r p w
}

struct robot_struct: Codable
{
    var name: String
    var manufacturer: String
    var model: String
    var ip_addrerss: String
    var programs: [program_struct]
}
