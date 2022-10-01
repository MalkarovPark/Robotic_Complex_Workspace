//
//  SettingsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 18.08.2022.
//

import SwiftUI
#if os(iOS)
import UniformTypeIdentifiers
#endif

struct SettingsView: View
{
    #if os(iOS)
    @Binding var setting_view_presented: Bool
    #endif
    
    private enum Tabs: Hashable
    {
        case general, properties, advanced //Settings view tab bar items
    }
    
    var body: some View
    {
        TabView
        {
            GeneralSettingsView()
                .tabItem
            {
                Label("General", systemImage: "gear")
            }
            .tag(Tabs.general)
            
            PropertiesSettingsView()
                .tabItem
            {
                Label("Properties", systemImage: "doc.text")
            }
            
            AdvancedSettingsView()
                .tabItem
            {
                Label("Advanced", systemImage: "star")
            }
            .tag(Tabs.advanced)
        }
        #if os(macOS)
        .padding(20)
        #endif
    }
}

//MARK: - Settings view with tab bar
struct GeneralSettingsView: View
{
    //Default robot origin location properties from user defaults
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
    //Default robot origion rotation properties from user defaults
    @AppStorage("DefaultScale_X") private var scale_x: Double = 200
    @AppStorage("DefaultScale_Y") private var scale_y: Double = 200
    @AppStorage("DefaultScale_Z") private var scale_z: Double = 200
    
    var body: some View
    {
        VStack
        {
            Form
            {
                #if os(macOS)
                GroupBox(label: Text("Default Values")
                            .font(.headline))
                {
                    VStack(alignment: .leading)
                    {
                        Text("Origin location")
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_x, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_x)
                        { _ in
                            Robot.default_origin_location[0] = Float(location_x)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_y, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_y)
                        { _ in
                            Robot.default_origin_location[1] = Float(location_y)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $location_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $location_z, in: -50...50)
                                .labelsHidden()
                        }
                        .onChange(of: location_z)
                        { _ in
                            Robot.default_origin_location[2] = Float(location_z)
                        }
                    }
                    .padding(8)
                    
                    VStack(alignment: .leading)
                    {
                        Text("Space scale")
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 8)
                        {
                            Text("X:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_x, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_x, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_x)
                        { _ in
                            Robot.default_space_scale[0] = Float(scale_x)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Y:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_y, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_y, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_y)
                        { _ in
                            Robot.default_space_scale[1] = Float(scale_y)
                        }
                        
                        HStack(spacing: 8)
                        {
                            Text("Z:")
                                .frame(width: 20.0)
                            TextField("0", value: $scale_z, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                            Stepper("Enter", value: $scale_z, in: 0...400)
                                .labelsHidden()
                        }
                        .onChange(of: scale_z)
                        { _ in
                            Robot.default_space_scale[2] = Float(scale_z)
                        }
                    }
                    .padding(8)
                }
                .frame(width: 192)
                #else
                Section(header: Text("Origin location"))
                {
                    HStack(spacing: 8)
                    {
                        Text("X:")
                            .frame(width: 20.0)
                        TextField("0", value: $location_x, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_x, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_x)
                    { _ in
                        Robot.default_origin_location[0] = Float(location_x)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y:")
                            .frame(width: 20.0)
                        TextField("0", value: $location_y, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_y, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_y)
                    { _ in
                        Robot.default_origin_location[1] = Float(location_y)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z:")
                            .frame(width: 20.0)
                        TextField("0", value: $location_z, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $location_z, in: -50...50)
                            .labelsHidden()
                    }
                    .onChange(of: location_z)
                    { _ in
                        Robot.default_origin_location[2] = Float(location_z)
                    }
                }
                
                Section(header: Text("Space scale"))
                {
                    HStack(spacing: 8)
                    {
                        Text("X:")
                            .frame(width: 20.0)
                        TextField("0", value: $scale_x, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_x, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_x)
                    { _ in
                        Robot.default_space_scale[0] = Float(scale_x)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Y:")
                            .frame(width: 20.0)
                        TextField("0", value: $scale_y, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_y, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_y)
                    { _ in
                        Robot.default_space_scale[1] = Float(scale_y)
                    }
                    
                    HStack(spacing: 8)
                    {
                        Text("Z:")
                            .frame(width: 20.0)
                        TextField("0", value: $scale_z, format: .number)
                            .labelsHidden()
                        Stepper("Enter", value: $scale_z, in: 0...400)
                            .labelsHidden()
                    }
                    .onChange(of: scale_z)
                    { _ in
                        Robot.default_space_scale[2] = Float(scale_z)
                    }
                }
                #endif
            }
        }
    }
}

//MARK: - Property list settings view
struct PropertiesSettingsView: View
{
    //Viewed property lists URLs
    @AppStorage("RobotsPlistURL") private var robots_plist_url: URL?
    @AppStorage("ToolsPlistURL") private var tools_plist_url: URL?
    @AppStorage("DetailsPlistURL") private var details_plist_url: URL?
    
    //User defaults with additive data from imported property lists
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    @AppStorage("AdditiveToolsData") private var additive_tools_data: Data?
    @AppStorage("AdditiveDetailsData") private var additive_details_data: Data?
    
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    //Flags for file iOS/iPadOS dialogs presentaion
    @State private var load_panel_presented = false
    @State private var clear_message_presented = false
    #endif
    
    var body: some View
    {
        Form
        {
            #if os(macOS)
            VStack(alignment: .leading)
            {
                //MARK: Robots data handling view
                GroupBox(label: Text("Robots").font(.headline))
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            VStack
                            {
                                Text(app_state.property_files_info.Brands)
                                    .foregroundColor(Color.gray)
                                Text("Brands")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.leading)
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_files_info.Series)
                                    .foregroundColor(Color.gray)
                                Text("Series")
                                    .foregroundColor(Color.gray)
                            }
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.property_files_info.Models)
                                    .foregroundColor(Color.gray)
                                Text("Models")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.trailing)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Text("File – " + (robots_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                            Spacer()
                            
                            Button(action: show_save_panel)
                            {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                            }
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .robot)
                                robots_plist_url = nil
                                additive_robots_data = nil
                            })
                            {
                                Label("Clear", systemImage: "arrow.counterclockwise")
                                    .labelStyle(.iconOnly)
                            }
                            Button("Load", action: { show_load_panel(type: .robot) })
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom, 8.0)
                
                //MARK: Tools data handling view
                GroupBox
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Tools")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text("–")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text(app_state.property_files_info.Tools)
                                .foregroundColor(Color.gray)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Text("File – " + (tools_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                            Spacer()
                            
                            Button(action: show_save_panel)
                            {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                            }
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .tool
                                )
                                tools_plist_url = nil
                                additive_tools_data = nil
                            })
                            {
                                Label("Clear", systemImage: "arrow.counterclockwise")
                                    .labelStyle(.iconOnly)
                            }
                            Button("Load", action: { show_load_panel(type: .tool) })
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.bottom, 8.0)
                
                //MARK: Details data handling view
                GroupBox
                {
                    VStack(spacing: 4)
                    {
                        HStack
                        {
                            Text("Details")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text("–")
                                .foregroundColor(Color.gray)
                            Spacer()
                            
                            Text(app_state.property_files_info.Details)
                                .foregroundColor(Color.gray)
                        }
                        .padding(4)
                        
                        Divider()
                        
                        HStack
                        {
                            Text("File – " + (details_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                            Spacer()
                            
                            Button(action: show_save_panel)
                            {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                            }
                            
                            Button(action: {
                                app_state.clear_additive_data(type: .detail)
                                details_plist_url = nil
                                additive_details_data = nil
                            })
                            {
                                Label("Clear", systemImage: "arrow.counterclockwise")
                                    .labelStyle(.iconOnly)
                            }
                            Button("Load", action: { show_load_panel(type: .detail) })
                        }
                        .padding(4)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            #else
            //MARK: Robots data handling view
            Section(header: Text("Robots"))
            {
                HStack
                {
                    VStack
                    {
                        Text(app_state.property_files_info.Brands)
                            .foregroundColor(Color.gray)
                        Text("Brands")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.leading)
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.property_files_info.Series)
                            .foregroundColor(Color.gray)
                        Text("Series")
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.property_files_info.Models)
                            .foregroundColor(Color.gray)
                        Text("Models")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.trailing)
                }
                
                HStack
                {
                    Text("File – " + (robots_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                    Spacer()
                    
                    Button("Export", action: show_save_panel)
                    Button("Load", action: { show_load_panel(type: .robot) })
                }
            }
            
            //MARK: Tools data handling view
            Section
            {
                HStack
                {
                    Text("Tools")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text("–")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text(app_state.property_files_info.Tools)
                        .foregroundColor(Color.gray)
                }
                
                HStack
                {
                    Text("File – " + (tools_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                    Spacer()
                    
                    Button("Export", action: show_save_panel)
                    Button("Load", action: { show_load_panel(type: .tool) })
                }
            }
            
            //MARK: Details data handling view
            Section
            {
                HStack
                {
                    Text("Details")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text("–")
                        .foregroundColor(Color.gray)
                    Spacer()
                    
                    Text(app_state.property_files_info.Details)
                        .foregroundColor(Color.gray)
                }
                
                HStack
                {
                    Text("File – " + (details_plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                    Spacer()
                    
                    Button("Export", action: show_save_panel)
                    Button("Load", action: { show_load_panel(type: .detail) })
                }
            }
            
            //Clear data elements
            Button("Clear", role: .destructive)
            {
                clear_message_presented = true
            }
            .confirmationDialog(Text("None"), isPresented: $clear_message_presented)
            {
                Button("Robots")
                {
                    app_state.clear_additive_data(type: .robot)
                    robots_plist_url = nil
                    additive_robots_data = nil
                }
                Button("Tools")
                {
                    app_state.clear_additive_data(type: .tool)
                    tools_plist_url = nil
                    additive_tools_data = nil
                }
                Button("Details")
                {
                    app_state.clear_additive_data(type: .detail)
                    details_plist_url = nil
                    additive_details_data = nil
                }
                Button("Cancel", role: .cancel) { }
            }
            #endif
        }
        #if os(macOS)
        .frame(width: 256)
        #else
        .sheet(isPresented: $load_panel_presented)
        {
            DocumentPickerView()
        }
        #endif
    }
    
    //MARK: Save and load dialogs
    func show_load_panel(type: WorkspaceObjecTypes)
    {
        #if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["plist"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        
        switch type
        {
        case .robot:
            robots_plist_url = response == .OK ? openPanel.url : nil
            
            do
            {
                if ((robots_plist_url?.startAccessingSecurityScopedResource()) != nil)
                {
                    additive_robots_data = try Data(contentsOf: robots_plist_url!)
                    app_state.update_additive_data()
                }
            }
            catch
            {
                print("error reading")
                print(error.localizedDescription)
            }
        case .tool:
            tools_plist_url = response == .OK ? openPanel.url : nil
            
            do
            {
                if ((tools_plist_url?.startAccessingSecurityScopedResource()) != nil)
                {
                    additive_tools_data = try Data(contentsOf: tools_plist_url!)
                    app_state.update_additive_data()
                }
            }
            catch
            {
                print("error reading")
                print(error.localizedDescription)
            }
        case .detail:
            details_plist_url = response == .OK ? openPanel.url : nil
            
            do
            {
                if ((details_plist_url?.startAccessingSecurityScopedResource()) != nil)
                {
                    additive_details_data = try Data(contentsOf: details_plist_url!)
                    app_state.update_additive_data()
                }
            }
            catch
            {
                print("error reading")
                print(error.localizedDescription)
            }
        }
        #else
        app_state.plist_file_type = type
        load_panel_presented = true
        #endif
    }
    
    func show_save_panel()
    {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["plist"]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save your text"
        savePanel.message = "Choose a folder and a name to store your text."
        savePanel.nameFieldLabel = "File name:"
        
        let response = savePanel.runModal()
        print(response == .OK ? savePanel.url : nil)
        #endif
    }
}

//MARK: - Advanced settings view
struct AdvancedSettingsView: View
{
    var body: some View
    {
        Form
        {
            
        }
        .padding(20)
        .frame(width: 400, height: 256)
    }
}

#if os(iOS)
//MARK: - Document dialog for iOS/iPadOS
struct DocumentPickerView: UIViewControllerRepresentable
{
    @AppStorage("RobotsPlistURL") private var robots_plist_url: URL?
    @AppStorage("ToolsPlistURL") private var tools_plist_url: URL?
    @AppStorage("DetailsPlistURL") private var details_plist_url: URL?
    
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    @AppStorage("AdditiveToolsData") private var additive_tools_data: Data?
    @AppStorage("AdditiveDetailsData") private var additive_details_data: Data?
    
    @EnvironmentObject var app_state: AppState
    
    func makeCoordinator() -> Coordinator
    {
        return DocumentPickerView.Coordinator(parent1: self, app_state: app_state)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController
    {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.propertyList], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context)
    {
        
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate
    {
        var parent: DocumentPickerView
        var app_state: AppState
        
        init(parent1: DocumentPickerView, app_state: AppState)
        {
            parent = parent1
            self.app_state = app_state
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
        {
            switch app_state.plist_file_type
            {
            case .robot:
                parent.robots_plist_url = urls[0]
                do
                {
                    if ((parent.robots_plist_url?.startAccessingSecurityScopedResource()) != nil)
                    {
                        parent.additive_robots_data = try Data(contentsOf: parent.robots_plist_url!)
                        parent.app_state.update_additive_data()
                    }
                }
                catch
                {
                    print ("error reading")
                    print (error.localizedDescription)
                }
            case .tool:
                parent.tools_plist_url = urls[0]
                do
                {
                    if ((parent.tools_plist_url?.startAccessingSecurityScopedResource()) != nil)
                    {
                        parent.additive_tools_data = try Data(contentsOf: parent.tools_plist_url!)
                        parent.app_state.update_additive_data()
                    }
                }
                catch
                {
                    print ("error reading")
                    print (error.localizedDescription)
                }
            case .detail:
                parent.details_plist_url = urls[0]
                do
                {
                    if ((parent.details_plist_url?.startAccessingSecurityScopedResource()) != nil)
                    {
                        parent.additive_details_data = try Data(contentsOf: parent.details_plist_url!)
                        parent.app_state.update_additive_data()
                    }
                }
                catch
                {
                    print ("error reading")
                    print (error.localizedDescription)
                }
            default:
                break
            }
            
            print(urls[0].absoluteString)
        }
    }
}
#endif

//MARK: - Previews
struct SettingsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            #if os(macOS)
            SettingsView()
                .environmentObject(AppState())
            #else
            SettingsView(setting_view_presented: .constant(true))
                .environmentObject(AppState())
            #endif
            GeneralSettingsView()
            PropertiesSettingsView()
                .environmentObject(AppState())
            AdvancedSettingsView()
        }
    }
}
