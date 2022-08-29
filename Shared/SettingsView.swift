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
        case general, properties, advanced
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

struct GeneralSettingsView: View
{
    @AppStorage("DefaultLocation_X") private var location_x: Double = 0
    @AppStorage("DefaultLocation_Y") private var location_y: Double = 20
    @AppStorage("DefaultLocation_Z") private var location_z: Double = 0
    
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

struct PropertiesSettingsView: View
{
    @AppStorage("RobotsPlistURL") private var plist_url: URL?
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    
    @EnvironmentObject var app_state: AppState
    
    #if os(iOS)
    @State var load_panel_presented = false
    #endif
    
    var body: some View
    {
        Form
        {
            #if os(macOS)
            VStack(alignment: .leading)
            {
                HStack
                {
                    Text("File – " + (plist_url?.deletingPathExtension().lastPathComponent ?? "None"))
                    Spacer()
                    
                    Button("Save", action: show_save_panel)
                    Button("Load", action: show_load_panel)
                }
                
                GroupBox
                {
                    VStack
                    {
                        HStack
                        {
                            VStack
                            {
                                Text(app_state.robots_property_file_info.Brands)
                                    .foregroundColor(Color.gray)
                                Text("Brands")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.leading)
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.robots_property_file_info.Series)
                                    .foregroundColor(Color.gray)
                                Text("Series")
                                    .foregroundColor(Color.gray)
                            }
                            Spacer()
                            
                            VStack
                            {
                                Text(app_state.robots_property_file_info.Models)
                                    .foregroundColor(Color.gray)
                                Text("Models")
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.trailing)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.vertical, 8.0)
                
                HStack
                {
                    Spacer()
                    Button("Clear Data")
                    {
                        app_state.clear_additive_data()
                        plist_url = nil
                        additive_robots_data = nil
                    }
                }
            }
            #else
            Section(header: Text("File"))
            {
                HStack
                {
                    Text(plist_url?.deletingPathExtension().lastPathComponent ?? "None")
                    Spacer()
                    
                    Button("Save", action: show_save_panel)
                    Button("Load", action: show_load_panel)
                }
            }
            
            Section(header: Text("Data"))
            {
                HStack
                {
                    VStack
                    {
                        Text(app_state.robots_property_file_info.Brands)
                            .foregroundColor(Color.gray)
                        Text("Brands")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.leading)
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.robots_property_file_info.Series)
                            .foregroundColor(Color.gray)
                        Text("Series")
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    
                    VStack
                    {
                        Text(app_state.robots_property_file_info.Models)
                            .foregroundColor(Color.gray)
                        Text("Models")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.trailing)
                }
                
                HStack
                {
                    Button("Clear")
                    {
                        app_state.clear_additive_data()
                        plist_url = nil
                        additive_robots_data = nil
                    }
                }
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
    
    func show_load_panel()
    {
        #if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["plist"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        
        plist_url = response == .OK ? openPanel.url : nil
        do
        {
            if ((plist_url?.startAccessingSecurityScopedResource()) != nil)
            {
                additive_robots_data = try Data(contentsOf: plist_url!)
                app_state.update_additive_data()
            }
        }
        catch
        {
            print ("error reading")
            print (error.localizedDescription)
        }
        #else
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
struct DocumentPickerView: UIViewControllerRepresentable
{
    @AppStorage("RobotsPlistURL") private var plist_url: URL?
    @AppStorage("AdditiveRobotsData") private var additive_robots_data: Data?
    
    @EnvironmentObject var app_state: AppState
    
    func makeCoordinator() -> Coordinator
    {
        return DocumentPickerView.Coordinator(parent1: self)
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
        
        init(parent1: DocumentPickerView)
        {
            parent = parent1
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
        {
            parent.plist_url = urls[0]
            do
            {
                if ((parent.plist_url?.startAccessingSecurityScopedResource()) != nil)
                {
                    parent.additive_robots_data = try Data(contentsOf: parent.plist_url!)
                    parent.app_state.update_additive_data()
                }
            }
            catch
            {
                print ("error reading")
                print (error.localizedDescription)
            }
            
            print(urls[0].absoluteString)
        }
    }
}
#endif

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
