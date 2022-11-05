//
//  ContentView.swift
//  Shared
//
//  Created by Malkarov Park on 15.10.2021.
//

import SwiftUI

struct ContentView: View
{
    //Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    //Default robot origion rotation properties from user defaults
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    @AppStorage("RobotsBookmark") private var robots_bookmark: Data?
    @AppStorage("ToolsBookmark") private var tools_bookmark: Data?
    @AppStorage("DetailsBookmark") private var details_bookmark: Data?
    
    @AppStorage("RobotsEmpty") private var robots_empty: Bool?
    @AppStorage("ToolsEmpty") private var tools_empty: Bool?
    @AppStorage("DetailsEmpty") private var details_empty: Bool?
    
    @Binding var document: Robotic_Complex_WorkspaceDocument //Opened document
    
    #if os(iOS)
    @State var file_name = "" //Visible file name
    @State var file_url: URL //Visible file URL
    #endif
    @State var first_loaded = true //Fade in workspace scene property
    
    @StateObject private var base_workspace = Workspace() //Workspace object for opened file
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    //MARK: Main view
    @ViewBuilder var body: some View
    {
        #if os(macOS)
        Sidebar(document: $document, first_loaded: $first_loaded)
            .environmentObject(base_workspace)
            .onAppear
            {
                get_file_data()
                update_preferences()
            }
        #else
        Sidebar(document: $document, first_loaded: $first_loaded, file_url: $file_url, file_name: $file_name)
            .environmentObject(base_workspace)
            .onAppear
            {
                get_file_data()
                update_preferences()
            }
        #endif
    }
    
    func get_file_data() //Store preset file data into workspace
    {
        //Pass bookmarks data into workspace for the models access
        base_workspace.robots_bookmark = robots_empty ?? true ? nil : robots_bookmark
        base_workspace.tools_bookmark = tools_empty ?? true ? nil : tools_bookmark
        base_workspace.details_bookmark = details_empty ?? true ? nil : details_bookmark
        
        base_workspace.file_view(preset: document.preset) //Get file data from document
    }
    
    func update_preferences() //Pass default parameters from preferences
    {
        Robot.default_origin_location[0] = Float(location_x)
        Robot.default_origin_location[1] = Float(location_y)
        Robot.default_origin_location[2] = Float(location_z)
        
        Robot.default_space_scale[0] = Float(scale_x)
        Robot.default_space_scale[1] = Float(scale_y)
        Robot.default_space_scale[2] = Float(scale_z)
    }
}

//MARK: - Previews
struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        #if os(macOS)
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()))
            .environmentObject(AppState())
            .frame(width: 800, height: 600)
        #else
        ContentView(document: .constant(Robotic_Complex_WorkspaceDocument()), file_url: URL(fileURLWithPath: ""))
            .environmentObject(AppState())
            .frame(width: 800, height: 600)
        #endif
    }
}
