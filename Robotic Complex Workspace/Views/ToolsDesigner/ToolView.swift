//
//  ToolView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct ToolView: View
{
    @Binding var tool_view_presented: Bool
    @Binding var tool_item: Tool
    
    @State private var add_program_view_presented = false
    @State private var add_operation_view_presented = false
    @State private var new_operation_code = OperationCodeInfo()
    
    @State private var ready_for_save = false
    @State private var is_document_updated = false
    
    @State private var connector_view_presented = false
    @State private var statistics_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    //MARK: Horizontal window size handler
    @Environment(\.horizontalSizeClass) private var horizontal_size_class
    
    //Picker data for thin window size
    @State private var program_view_presented = false
    #endif
    
    #if os(visionOS)
    @EnvironmentObject var pendant_controller: PendantController
    #endif
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            #if os(macOS)
            HStack(spacing: 0)
            {
                ToolSceneView(tool: $tool_item)
            }
            .modifier(ViewCloseFuncButton(close_action: close_tool))
            .overlay(alignment: .bottomLeading)
            {
                HStack(spacing: 0)
                {
                    Button(action: {
                        tool_item.reset_performing()
                        base_workspace.update_view()
                    })
                    {
                        Image(systemName: "stop")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding([.vertical, .leading])
                    
                    Button(action: {
                        tool_item.start_pause_performing()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                        {
                            base_workspace.update_view()
                        }
                    })
                    {
                        Image(systemName: "playpause")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .disabled(tool_item.codes.count == 0)
                .modifier(MenuHandlingModifier(performed: $tool_item.performed, toggle_perform: tool_item.start_pause_performing, stop_perform: tool_item.reset_performing))
            }
            .overlay(alignment: .bottomTrailing)
            {
                HStack(spacing: 0)
                {
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding([.vertical, .leading])
                    
                    Button(action: { statistics_view_presented.toggle() })
                    {
                        Image(systemName: "chart.bar")
                            .frame(height: 16)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .disabled(tool_item.codes.count == 0)
            }
            
            Divider()
            
            ToolInspectorView(new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                .frame(width: 256)
            #elseif os(iOS)
            if horizontal_size_class == .compact
            {
                VStack(spacing: 0)
                {
                    ToolSceneView(tool: $tool_item)
                        .overlay(alignment: .bottom)
                    {
                        HStack
                        {
                            Button(action: {
                                base_workspace.selected_tool.reset_performing()
                                base_workspace.update_view()
                            })
                            {
                                Image(systemName: "stop")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .modifier(ButtonBorderer())
                            
                            Button(action: {
                                base_workspace.selected_tool.start_pause_performing()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                                {
                                    base_workspace.update_view()
                                }
                            })
                            {
                                Image(systemName: "playpause")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .modifier(ButtonBorderer())
                            
                            Button(action: { connector_view_presented.toggle() })
                            {
                                Image(systemName: "link")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .modifier(ButtonBorderer())
                            
                            Button(action: { statistics_view_presented.toggle() })
                            {
                                Image(systemName: "chart.bar")
                                    .frame(maxWidth: .infinity, maxHeight: 16)
                            }
                            .modifier(ButtonBorderer())
                        }
                        .padding()
                    }
                    
                    HStack
                    {
                        Button(action: { program_view_presented.toggle() })
                        {
                            Text("Operations")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .padding()
                        .popover(isPresented: $program_view_presented)
                        {
                            VStack
                            {
                                ToolInspectorView(new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                                    .presentationDetents([.medium, .large])
                            }
                            .onDisappear()
                            {
                                program_view_presented = false
                            }
                        }
                    }
                }
                .modifier(ViewCloseFuncButton(close_action: close_tool))
                .disabled(base_workspace.selected_tool.codes.count == 0)
                .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
            }
            else
            {
                HStack(spacing: 0)
                {
                    ToolSceneView(tool: $tool_item)
                }
                .modifier(ViewCloseFuncButton(close_action: close_tool))
                .overlay(alignment: .bottomLeading)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: {
                            base_workspace.selected_tool.reset_performing()
                            base_workspace.update_view()
                        })
                        {
                            Image(systemName: "stop")
                                .frame(height: 16)
                        }
                        .modifier(ButtonBorderer())
                        .padding([.vertical, .leading])
                        
                        Button(action: {
                            base_workspace.selected_tool.start_pause_performing()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                            {
                                base_workspace.update_view()
                            }
                        })
                        {
                            Image(systemName: "playpause")
                                .frame(height: 16)
                        }
                        .modifier(ButtonBorderer())
                        .padding()
                    }
                    .disabled(base_workspace.selected_tool.codes.count == 0)
                    .modifier(MenuHandlingModifier(performed: $base_workspace.selected_tool.performed, toggle_perform: base_workspace.selected_tool.start_pause_performing, stop_perform: base_workspace.selected_tool.reset_performing))
                }
                .overlay(alignment: .bottomTrailing)
                {
                    HStack(spacing: 0)
                    {
                        Button(action: { connector_view_presented.toggle() })
                        {
                            Image(systemName: "link")
                                .frame(height: 16)
                        }
                        .modifier(ButtonBorderer())
                        .padding([.vertical, .leading])
                        
                        Button(action: { statistics_view_presented.toggle() })
                        {
                            Image(systemName: "chart.bar")
                                .frame(height: 16)
                        }
                        .modifier(ButtonBorderer())
                        .padding()
                    }
                    .disabled(base_workspace.selected_tool.codes.count == 0)
                }
                
                Divider()
                
                ToolInspectorView(new_operation_code: $new_operation_code, remove_codes: remove_codes(at:), code_item_move: code_item_move(from:to:), add_operation_to_program: add_operation_to_program, delete_operations_program: delete_operations_program, update_data: update_data)
                    .frame(width: 300)
            }
            #else
            HStack(spacing: 0)
            {
                ToolSceneView(tool: $tool_item)
            }
            .modifier(ViewCloseFuncButton(close_action: close_tool))
            .overlay(alignment: .bottom)
            {
                HStack(spacing: 0)
                {
                    Button(action: { connector_view_presented.toggle() })
                    {
                        Image(systemName: "link")
                            .frame(height: 16)
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .keyboardShortcut(.cancelAction)
                    .padding([.vertical, .leading])
                    
                    Button(action: { statistics_view_presented.toggle() })
                    {
                        Image(systemName: "chart.bar")
                            .frame(height: 16)
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .keyboardShortcut(.cancelAction)
                    .padding()
                }
                .disabled(tool_item.codes_count == 0)
                .glassBackgroundEffect()
                .padding()
            }
            #endif
        }
        .sheet(isPresented: $connector_view_presented)
        {
            ConnectorView(demo: $base_workspace.selected_tool.demo, update_model: $base_workspace.selected_tool.update_model_by_connector, connector: tool_item.connector as WorkspaceObjectConnector, update_file_data: { document_handler.document_update_tools() })
                .modifier(SheetCaption(is_presented: $connector_view_presented, label: "Link"))
            #if os(macOS)
                .frame(minWidth: 320, idealWidth: 320, maxWidth: 400, minHeight: 448, idealHeight: 480, maxHeight: 512)
            #elseif os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
        .sheet(isPresented: $statistics_view_presented)
        {
            StatisticsView(is_presented: $statistics_view_presented, get_statistics: $base_workspace.selected_tool.get_statistics, charts_data: base_workspace.selected_tool.charts_binding(), states_data: tool_item.states_binding(), clear_chart_data: { tool_item.clear_chart_data() }, clear_states_data: tool_item.clear_states_data, update_file_data: { document_handler.document_update_tools() })
            #if os(visionOS)
                .frame(width: 512, height: 512)
            #endif
        }
        .controlSize(.regular)
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 640, maxWidth: 800, minHeight: 400, idealHeight: 480, maxHeight: 600)
        #endif
        .onAppear
        {
            app_state.preview_update_scene = true
            
            if tool_item.codes.count > 0
            {
                new_operation_code = tool_item.codes.first ?? OperationCodeInfo()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                ready_for_save = true
            }
            
            #if os(visionOS)
            pendant_controller.view_tool()
            #endif
        }
    }
    
    #if !os(visionOS)
    func update_data()
    {
        if ready_for_save
        {
            withAnimation
            {
                app_state.get_scene_image = true
                document_handler.document_update_tools()
                is_document_updated = true
            }
        }
    }
    
    func code_item_move(from source: IndexSet, to destination: Int)
    {
        tool_item.selected_program.codes.move(fromOffsets: source, toOffset: destination)
        update_data()
    }
    
    func remove_codes(at offsets: IndexSet) //Remove tool operation function
    {
        withAnimation
        {
            tool_item.selected_program.codes.remove(atOffsets: offsets)
        }
        
        update_data()
    }
    
    func delete_operations_program()
    {
        if tool_item.programs_names.count > 0
        {
            let current_spi = tool_item.selected_program_index
            tool_item.delete_program(index: current_spi)
            if tool_item.programs_names.count > 1 && current_spi > 0
            {
                tool_item.selected_program_index = current_spi - 1
            }
            else
            {
                tool_item.selected_program_index = 0
            }
            
            update_data()
        }
    }
    
    func add_operation_to_program()
    {
        tool_item.selected_program.add_code(OperationCode(new_operation_code.value))
        
        update_data()
    }
    #endif
    
    func close_tool()
    {
        #if os(visionOS)
        pendant_controller.view_dismiss()
        #endif
        tool_view_presented = false
        base_workspace.deselect_tool()
    }
}

//MARK: - Scene views
struct ToolSceneView: View
{
    @AppStorage("WorkspaceImagesStore") private var workspace_images_store: Bool = true
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    @Binding var tool: Tool
    
    var body: some View
    {
        ToolInternalSceneView(scene: SCNScene(named: "Components.scnassets/View.scn")!, node: tool.node ?? SCNNode(), on_render: update_view_node(scene_view:), on_tap: { _, _ in })
    }
    
    private func update_view_node(scene_view: SCNView)
    {
        if app_state.preview_update_scene
        {
            let viewed_node = scene_view.scene?.rootNode.childNode(withName: "Node", recursively: true)
            
            apply_bit_mask(node: viewed_node ?? SCNNode(), Workspace.tool_bit_mask)
            
            viewed_node?.remove_all_constraints()
            viewed_node?.position = SCNVector3(x: 0, y: 0, z: 0)
            viewed_node?.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
            
            tool.workcell_connect(scene: scene_view.scene!, name: "Node")
            
            app_state.preview_update_scene = false
        }
        
        if base_workspace.selected_object_type == .tool
        {
            if tool.performing_completed
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                {
                    tool.performing_completed = false
                    base_workspace.update_view()
                }
            }
            
            if tool.code_changed
            {
                DispatchQueue.main.asyncAfter(deadline: .now())
                {
                    base_workspace.update_view()
                    tool.code_changed = false
                }
            }
            
            tool.update_statistics_data()
        }
    }
}

struct ToolInternalSceneView: UIViewRepresentable
{
    private let scene_view = SCNView(frame: .zero)
    private let viewed_scene: SCNScene
    private let node: SCNNode
    private let on_render: ((_ scene_view: SCNView) -> Void)
    private let on_tap: ((_ recognizer: UITapGestureRecognizer, _ scene_view: SCNView) -> Void)
    
    //MARK: Init functions
    public init(scene: SCNScene, node: SCNNode, on_render: @escaping (_ scene_view: SCNView) -> Void, on_tap: @escaping (_: UITapGestureRecognizer, _: SCNView) -> Void)
    {
        self.viewed_scene = scene
        self.node = node
        
        self.on_render = on_render
        self.on_tap = on_tap
    }
    
    #if os(macOS)
    private let base_camera_position_node = SCNNode()
    #endif
    
    func scn_scene(context: Context) -> SCNView
    {
        scene_view.scene = viewed_scene
        scene_view.delegate = context.coordinator
        scene_view.scene?.background.contents = UIColor.clear
        
        let new_node = node
        new_node.name = "Node"
        
        scene_view.scene?.rootNode.addChildNode(new_node)
        
        #if os(macOS)
        base_camera_position_node.position = scene_view.pointOfView?.position ?? SCNVector3(0, 0, 2)
        base_camera_position_node.rotation = scene_view.pointOfView?.rotation ?? SCNVector4Zero
        #endif
        
        return scene_view
    }
    
    //MARK: Scene functions
    #if os(macOS)
    public func makeNSView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        scene_view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:))))
        
        //Add reset double tap recognizer for macOS
        let double_tap_gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_reset_double_tap(_:)))
        double_tap_gesture.numberOfClicksRequired = 2
        scene_view.addGestureRecognizer(double_tap_gesture)
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        return scn_scene(context: context)
    }
    #else
    public func makeUIView(context: Context) -> SCNView
    {
        //Add gesture recognizer
        scene_view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handle_tap(_:))))
        
        scene_view.allowsCameraControl = true
        scene_view.rendersContinuously = true
        scene_view.autoenablesDefaultLighting = true
        
        scene_view.backgroundColor = UIColor.clear
        
        return scn_scene(context: context)
    }
    #endif
    
    #if os(macOS)
    public func updateNSView(_ ui_view: SCNView, context: Context)
    {
        
    }
    #else
    public func updateUIView(_ ui_view: SCNView, context: Context)
    {
        
    }
    #endif
    
    public func makeCoordinator() -> Coordinator
    {
        Coordinator(self, scene_view)
    }
    
    final public class Coordinator: NSObject, SCNSceneRendererDelegate
    {
        var control: ToolInternalSceneView
        
        init(_ control: ToolInternalSceneView, _ scn_view: SCNView)
        {
            self.control = control
            
            self.scn_view = scn_view
            super.init()
        }
        
        public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
        {
            control.on_render(scn_view)
        }
        
        private let scn_view: SCNView
        
        #if os(macOS)
        private var on_reset_view = false
        #endif
        
        @objc func handle_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            control.on_tap(gesture_recognize, scn_view)
        }
        
        #if os(macOS)
        @objc func handle_reset_double_tap(_ gesture_recognize: UITapGestureRecognizer)
        {
            reset_camera_view_position(locataion: SCNVector3(0, 0, 2), rotation: SCNVector4Zero, view: scn_view)
            
            func reset_camera_view_position(locataion: SCNVector3, rotation: SCNVector4, view: SCNView)
            {
                if !on_reset_view
                {
                    on_reset_view = true
                    
                    let reset_action = SCNAction.group([SCNAction.move(to: control.base_camera_position_node.position, duration: 0.5), SCNAction.rotate(toAxisAngle: control.base_camera_position_node.rotation, duration: 0.5)])
                    scn_view.defaultCameraController.pointOfView?.runAction(
                        reset_action, completionHandler: { self.on_reset_view = false })
                }
            }
        }
        #endif
    }
}

//MARK: - Previews
#Preview
{
    ToolView(tool_view_presented: .constant(true), tool_item: .constant(Tool()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
