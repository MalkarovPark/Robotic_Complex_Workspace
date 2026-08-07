//
//  DeviceInspector.swift
//  RCWorkspace
//
//  Created by Artem Malkarov on 06.08.2026.
//

import SwiftUI

import IndustrialKit
import IndustrialKitUI

struct ObjectInspectorView: View
{
    @ObservedObject var controller: ObjectInspectorController
    @ObservedObject var workspace: Workspace
    
    @State private var selected_tab = 0
    
    public init(
        controller: ObjectInspectorController,
        
        on_update_workspace: @escaping () -> () = {},
        
        on_update_robot: @escaping () -> () = {},
        on_update_tool: @escaping () -> () = {},
        on_update_part: @escaping () -> () = {}
    )
    {
        self.controller = controller
        self.workspace = controller.workspace
        
        //self.controller.set_document_functions(on_update_workspace, on_update_robot, on_update_tool, on_update_part)
    }
    
    private var tab_size: CGSize
    {
        switch selected_tab
        {
        case 0:
            return .init(width: 400, height: 800)
        case 1:
            return .init(width: 448, height: 448)
        case 2:
            return .init(width: 512, height: 512)
        default:
            return .init(width: 400, height: 640)
        }
    }

    var body: some View
    {
        ZStack
        {
            if workspace.selected_object != nil
            {
                TabView(selection: $selected_tab)
                {
                    Tab("Model", systemImage: symbol_name, value: 0)
                    {
                        InspectorView(document: $controller.document, workspace: workspace)
                    }
                    
                    if workspace.selected_object is any StateOutputCapable
                    {
                        Tab("Device Output", systemImage: "chart.pie", value: 1)
                        {
                            if let selected_object = workspace.selected_object
                            {
                                DeviceOutputView(object: selected_object, shows_output_indices: true)
                                {
                                    switch workspace.selected_object
                                    {
                                    case is Robot: controller.on_update_robot()
                                    case is Tool: controller.on_update_tool()
                                    default: break
                                    }
                                }
                            }
                        }
                    }
                    
                    if workspace.selected_object is any DeviceTwin
                    {
                        Tab("Connector", systemImage: "link", value: 2)
                        {
                            if let selected_object = workspace.selected_object
                            {
                                ConnectorView(object: selected_object)
                                {
                                    switch workspace.selected_object
                                    {
                                    case is Robot: controller.on_update_robot()
                                    case is Tool: controller.on_update_tool()
                                    default: break
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                ZStack{}.onAppear { controller.is_opened = false }
            }
        }
        .frame(width: tab_size.width, height: tab_size.height)
    }
    
    private var symbol_name: String
    {
        switch workspace.selected_object
        {
        case is Robot: "r.square"
        case is Tool: "hammer"
        case is Part: "shippingbox"
        default: String()
        }
    }
}

public struct ObjectInspector: SwiftUI.Scene
{
    var window_id: String
    let controller: ObjectInspectorController
    
    public init(
        window_id: String = ObjectInspectorDefaultID,
        controller: ObjectInspectorController
    )
    {
        self.window_id = window_id
        self.controller = controller
    }
    
    @SceneBuilder public var body: some SwiftUI.Scene
    {
        WindowGroup(id: window_id)
        {
            ObjectInspectorView(controller: controller)//, workspace: controller.workspace)
                .onDisappear(perform: controller.on_dismiss)
                //.glassBackgroundEffect(in: .rect(cornerRadius: 24, style: .continuous))
                //.frame(minHeight: 640, idealHeight: 640, maxHeight: 800)
        }
        //.windowStyle(.plain)
        .windowResizability(.contentSize)
    }
}

public let ObjectInspectorDefaultID = "object_inspector"

@MainActor public class ObjectInspectorController: ObservableObject
{
    //public init() {}
    
    // MARK: - Workspace management
    @Published public var workspace = Workspace()
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    /*public*/ init(workspace: Workspace, document: Binding<Robotic_Complex_WorkspaceDocument>)
    {
        self.workspace = workspace
        self._document = document
    }
    
    // MARK: - Space management
    @Published public var is_opened = false
    {
        didSet
        {
            if is_opened { open() }
            else { dismiss() }
        }
    }
    
    public func on_dismiss() { is_opened = false }
    
    public func set_window_functions(
        _ open: @escaping () -> (),
        _ dismiss: @escaping () -> ()
    )
    {
        self.open = open
        self.dismiss = dismiss
    }
    
    private var open = {}
    private var dismiss = {}
    
    // MARK: - Document management
    public var on_update_workspace = {}
    
    public var on_update_robot = {}
    public var on_update_tool = {}
    public var on_update_part = {}
    
    /*public*/ func set_document_functions(
        document: Binding<Robotic_Complex_WorkspaceDocument>,
        
        _ on_update_workspace: @escaping () -> (),
        
        _ on_update_robot: @escaping () -> (),
        _ on_update_tool: @escaping () -> (),
        _ on_update_part: @escaping () -> ()
    )
    {
        self._document = document
        
        self.on_update_workspace = on_update_workspace
        
        self.on_update_robot = on_update_robot
        self.on_update_tool = on_update_tool
        self.on_update_part = on_update_part
    }
}

#Preview
{
    @Previewable @State var controller = ObjectInspectorController(workspace: Workspace(), document: .constant(Robotic_Complex_WorkspaceDocument()))
    ObjectInspectorView(controller: controller)
}
