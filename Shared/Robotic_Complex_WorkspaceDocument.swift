//
//  Robotic_Complex_WorkspaceDocument.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI
import UniformTypeIdentifiers

//MARK: - Extension info
extension UTType
{
    static let workspace_preset_document = UTType(exportedAs: "mv-park.RoboticComplexWorkspace.preset")
}

//MARK: - Preset file document structure
struct Robotic_Complex_WorkspaceDocument: FileDocument
{
    var preset: WorkspacePreset
    
    static var readableContentTypes: [UTType] { [.workspace_preset_document] }
    
    init()
    {
        self.preset = WorkspacePreset()
    }
    
    //MARK: Read data from preset file
    init(configuration: ReadConfiguration) throws
    {
        guard let data = configuration.file.regularFileContents
        else
        {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        preset = try JSONDecoder().decode(WorkspacePreset.self, from: data)
    }
    
    //MARK: Write data from preset file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
    {
        let data = try JSONEncoder().encode(preset)
        return .init(regularFileWithContents: data)
    }
}
