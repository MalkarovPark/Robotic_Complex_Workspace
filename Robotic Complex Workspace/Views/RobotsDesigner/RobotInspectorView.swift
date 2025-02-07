//
//  RobotInspectorView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 13.05.2024.
//

import SwiftUI
import SceneKit
import IndustrialKit

struct RobotInspectorView: View
{
    @Binding var robot: Robot
    
    @State private var add_program_view_presented = false
    @State var ppv_presented_location = [false, false, false]
    @State var ppv_presented_rotation = [false, false, false]
    @State private var teach_selection = 0
    @State var dragged_point: SCNNode?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    let button_padding = 12.0
    private let teach_items: [String] = ["Location", "Rotation"]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            ZStack
            {
                List
                {
                    if robot.programs_count > 0
                    {
                        if robot.selected_program.points_count > 0
                        {
                            ForEach(Array(robot.selected_program.points.enumerated()), id: \.element)
                            { index, point in
                                PositionItemView(robot: $robot, points: $robot.selected_program.points, point_item: point, on_delete: remove_points)
                                    .onDrag
                                {
                                    return NSItemProvider()
                                }
                                .contextMenu
                                {
                                    Button(role: .destructive)
                                    {
                                        remove_points(at: IndexSet(integer: index))
                                    }
                                label:
                                    {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onMove(perform: point_item_move)
                            .onDelete(perform: remove_points)
                            .onChange(of: base_workspace.robots)
                            { _, _ in
                                document_handler.document_update_robots()
                            }
                        }
                    }
                }
                .modifier(ListBorderer())
                .padding([.horizontal, .top])
                
                if robot.programs_count == 0
                {
                    Text("No program selected")
                        .foregroundColor(.secondary)
                }
                else
                {
                    if robot.selected_program.points_count == 0
                    {
                        Text("Empty Program")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing)
            {
                if robot.programs_count > 0
                {
                    Spacer()
                    Button(action: add_point_to_program)
                    {
                        Image(systemName: "plus")
                            .padding(8)
                    }
                    .disabled(robot.programs_count == 0)
                    #if os(macOS) || os(iOS)
                    .foregroundColor(.white)
                    #endif
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .frame(width: 24, height: 24)
                    .shadow(radius: 4)
                    #if os(macOS)
                    .buttonStyle(BorderlessButtonStyle())
                    #endif
                    .padding(.trailing, 32)
                    .padding(.bottom, 16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            //Spacer()
            PositionControl(location: $robot.pointer_location, rotation: $robot.pointer_rotation, scale: $robot.space_scale)
            
            HStack(spacing: 0) //(spacing: 12)
            {
                Picker("Program", selection: $robot.selected_program_index)
                {
                    if robot.programs_names.count > 0
                    {
                        ForEach(0 ..< robot.programs_names.count, id: \.self)
                        {
                            Text(robot.programs_names[$0])
                        }
                    }
                    else
                    {
                        Text("None")
                    }
                }
                .pickerStyle(.menu)
                .disabled(robot.programs_names.count == 0)
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .modifier(PickerNamer(name: "Program"))
                #endif
                
                Button("-")
                {
                    delete_positions_program()
                }
                .disabled(robot.programs_names.count == 0)
                .padding(.horizontal)
                
                Button("+")
                {
                    add_program_view_presented.toggle()
                }
                .popover(isPresented: $add_program_view_presented, arrowEdge: default_popover_edge)
                {
                    AddNewView(is_presented: $add_program_view_presented)
                    { new_name in
                        robot.add_program(PositionsProgram(name: new_name))
                        robot.selected_program_index = robot.programs_names.count - 1
                        
                        document_handler.document_update_robots()
                        add_program_view_presented.toggle()
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private func point_item_move(from source: IndexSet, to destination: Int)
    {
        robot.selected_program.points.move(fromOffsets: source, toOffset: destination)
        robot.selected_program.visual_build()
        
        update_data()
    }
    
    private func remove_points(at offsets: IndexSet) //Remove robot point function
    {
        withAnimation
        {
            robot.selected_program.points.remove(atOffsets: offsets)
        }
        
        update_data()
        
        robot.selected_program.selected_point_index = -1
    }
    
    private func delete_positions_program()
    {
        if robot.programs_names.count > 0
        {
            let current_spi = robot.selected_program_index
            robot.delete_program(index: current_spi)
            if robot.programs_names.count > 1 && current_spi > 0
            {
                robot.selected_program_index = current_spi - 1
            }
            else
            {
                robot.selected_program_index = 0
            }
            
            update_data()
        }
    }
    
    private func add_point_to_program()
    {
        robot.selected_program.add_point(PositionPoint(x: robot.pointer_location[0], y: robot.pointer_location[1], z: robot.pointer_location[2], r: robot.pointer_rotation[0], p: robot.pointer_rotation[1], w: robot.pointer_rotation[2]))
        
        update_data()
    }
    
    private func update_data()
    {
        withAnimation
        {
            document_handler.document_update_robots()
            base_workspace.update_view()
        }
    }
}

struct PositionDropDelegate: DropDelegate
{
    @Binding var points: [SCNNode]
    @Binding var dragged_point: SCNNode?
    
    let point: SCNNode
    
    func performDrop(info: DropInfo) -> Bool
    {
        return true
    }
    
    func dropEntered(info: DropInfo)
    {
        guard let dragged_point = self.dragged_point else
        {
            return
        }
        
        if dragged_point != point
        {
            let from = points.firstIndex(of: dragged_point)!
            let to = points.firstIndex(of: point)!
            withAnimation(.default)
            {
                self.points.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

//MARK: - Position item view for list
struct PositionItemView: View
{
    @Binding var robot: Robot
    @Binding var points: [PositionPoint]
    
    @State var point_item: PositionPoint
    @State var position_item_view_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) public var horizontal_size_class //Horizontal window size handler
    #endif
    
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        HStack
        {
            Image(systemName: "circle.fill")
                .foregroundColor(robot.inspector_point_color(point: point_item)) //.gray)
            
            //Spacer()
            
            ZStack(alignment: .center)
            {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 256)
                    .overlay
                    {
                        /*VStack(spacing: 0)
                        {
                            Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                                .font(.caption)
                            
                            Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)*/
                        
                        HStack(spacing: 0)
                        {
                            Spacer()
                            
                            Text("X: \(String(format: "%.0f", point_item.x)) Y: \(String(format: "%.0f", point_item.y)) Z: \(String(format: "%.0f", point_item.z))")
                                .font(.system(size: 8))
                                .frame(width: 96)
                            
                            Spacer()
                            
                            Divider()
                            
                            Spacer()
                            
                            Text("R: \(String(format: "%.0f", point_item.r)) P: \(String(format: "%.0f", point_item.p)) W: \(String(format: "%.0f", point_item.w))")
                                .font(.system(size: 8))
                                .frame(width: 96)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
            }
            .frame(height: 24)
            .popover(isPresented: $position_item_view_presented,
                     arrowEdge: .trailing)
            {
                #if os(macOS)
                PositionPointView(robot: $robot, points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], on_delete: on_delete)
                    .frame(minWidth: 256, idealWidth: 288, maxWidth: 512)
                #else
                PositionPointView(robot: $robot, points: $points, point_item: $point_item, position_item_view_presented: $position_item_view_presented, item_view_pos_location: [point_item.x, point_item.y, point_item.z], item_view_pos_rotation: [point_item.r, point_item.p, point_item.w], is_compact: horizontal_size_class == .compact, on_delete: on_delete)
                    .presentationDetents([.height(576)])
                #endif
            }
            
            //Spacer()
        }
        .onTapGesture
        {
            position_item_view_presented.toggle()
        }
    }
}

//MARK: - Position item edit view
struct PositionPointView: View
{
    @Binding var robot: Robot
    
    @Binding var points: [PositionPoint]
    @Binding var point_item: PositionPoint
    @Binding var position_item_view_presented: Bool
    
    @State var item_view_pos_location = [Float]()
    @State var item_view_pos_rotation = [Float]()
    @State var item_view_pos_type: MoveType = .fine
    @State var item_view_pos_speed = Float()
    
    @State private var appeared = false
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    @EnvironmentObject var document_handler: DocumentUpdateHandler
    
    #if os(iOS)
    @State var is_compact = false
    #endif
    
    let on_delete: (IndexSet) -> ()
    let button_padding = 12.0
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            #if os(macOS)
            HStack
            {
                PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
            }
            .padding([.horizontal, .top])
            #else
            if !is_compact
            {
                HStack
                {
                    PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                }
                .padding([.horizontal, .top])
            }
            else
            {
                VStack
                {
                    PositionView(location: $item_view_pos_location, rotation: $item_view_pos_rotation)
                }
                .padding([.horizontal, .top])
                
                Spacer()
            }
            #endif
            
            HStack
            {
                Picker("Type", selection: $item_view_pos_type)
                {
                    ForEach(MoveType.allCases, id: \.self)
                    { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                #if os(macOS)
                .frame(maxWidth: .infinity)
                #else
                .frame(width: 96)
                .buttonStyle(.borderedProminent)
                #endif
                
                Text("Speed")
                #if os(macOS)
                    .frame(width: 40)
                #else
                    .frame(width: 60)
                #endif
                TextField("0", value: $item_view_pos_speed, format: .number)
                    .textFieldStyle(.roundedBorder)
                #if os(macOS)
                    .frame(width: 48)
                #else
                    .frame(maxWidth: .infinity)
                    .keyboardType(.decimalPad)
                #endif
                Stepper("Enter", value: $item_view_pos_speed, in: 0...100)
                    .labelsHidden()
            }
            .padding()
            .onChange(of: item_view_pos_type)
            { _, new_value in
                if appeared
                {
                    point_item.move_type = new_value
                    update_workspace_data()
                }
            }
            .onChange(of: item_view_pos_speed)
            { _, new_value in
                if appeared
                {
                    point_item.move_speed = new_value
                    update_workspace_data()
                }
            }
        }
        .onChange(of: item_view_pos_location)
        { _, _ in
            update_point_location()
        }
        .onChange(of: item_view_pos_rotation)
        { _, _ in
            update_point_rotation()
        }
        .onAppear()
        {
            robot.selected_program.selected_point_index = robot.selected_program.points.firstIndex(of: point_item) ?? -1
            
            item_view_pos_type = point_item.move_type
            item_view_pos_speed = point_item.move_speed
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
            {
                appeared = true
            }
        }
        .onDisappear()
        {
            robot.selected_program.selected_point_index = -1
        }
    }
    
    //MARK: Point manage functions
    func update_point_location()
    {
        point_item.x = item_view_pos_location[0]
        point_item.y = item_view_pos_location[1]
        point_item.z = item_view_pos_location[2]
        
        robot.point_shift(&point_item)
        
        update_workspace_data()
    }
    
    func update_point_rotation()
    {
        point_item.r = item_view_pos_rotation[0]
        point_item.p = item_view_pos_rotation[1]
        point_item.w = item_view_pos_rotation[2]
        
        update_workspace_data()
    }
    
    func update_workspace_data()
    {
        base_workspace.update_view()
        robot.selected_program.visual_build()
        document_handler.document_update_robots()
    }
}

//MARK: - Previews
#Preview
{
    RobotInspectorView(robot: .constant(Robot()))
        .environmentObject(Workspace())
        .environmentObject(AppState())
        .frame(width: 256)
}

#Preview
{
    PositionItemView(robot: .constant(Robot()), points: .constant([PositionPoint()]), point_item: PositionPoint()) { IndexSet in }
        .environmentObject(Workspace())
}

#Preview
{
    PositionPointView(robot: .constant(Robot()), points: .constant([PositionPoint()]), point_item: .constant(PositionPoint()), position_item_view_presented: .constant(true), item_view_pos_location: [0, 0, 0], item_view_pos_rotation: [0, 0, 0], on_delete: { _ in })
        .environmentObject(Workspace())
        .environmentObject(AppState())
}
