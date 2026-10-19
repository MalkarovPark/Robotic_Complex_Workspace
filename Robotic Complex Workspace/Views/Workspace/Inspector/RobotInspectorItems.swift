//
//  RobotInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem on 14.02.2026.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

struct RobotInspectorItems: View
{
    @ObservedObject var robot: Robot
    
    public let on_update: () -> ()
    
    var body: some View
    {
        let origin_binding = Binding(
            get: { robot.origin_position },
            set:
                { new_value in
                    robot.origin_position = new_value
                    
                    on_update()
                }
        )
        
        InspectorItem(label: "Origin", is_expanded: false)
        {
            PositionView(position: origin_binding, with_steppers: true)
        }
        
        InspectorItem(label: "Working Area", is_expanded: false)
        {
            OriginScaleView(robot: robot, on_update: on_update)
        }
        
        InspectorItem(label: "Default Pointer Position", is_expanded: false)
        {
            VStack(spacing: 10)
            {
                GroupBox
                {
                    HStack
                    {
                        if let default_pointer_position = robot.default_pointer_position
                        {
                            Text("X \(String(format: "%.0f", default_pointer_position.x)) Y \(String(format: "%.0f", default_pointer_position.y)) Z \(String(format: "%.0f", default_pointer_position.z))")
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Divider()
                            
                            Text("R \(String(format: "%.0f", default_pointer_position.r)) P \(String(format: "%.0f", default_pointer_position.p)) W \(String(format: "%.0f", default_pointer_position.w))")
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        else
                        {
                            Text("None")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    #if os(macOS)
                    .frame(height: 24)
                    #else
                    .frame(height: 16)
                    #endif
                }
                #if os(visionOS)
                .clipShape(Capsule(style: .continuous))
                #endif
                
                HStack
                {
                    Button
                    {
                        robot.set_default_pointer_position()
                        on_update()
                    }
                    label:
                    {
                        Text("Set")
                            .frame(maxWidth: .infinity)
                    }
                    #if os(iOS)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    .tint(.black)
                    #endif
                    
                    Button
                    {
                        robot.clear_default_pointer_position()
                        on_update()
                    }
                    label:
                    {
                        Text("Clear")
                            .frame(maxWidth: .infinity)
                    }
                    #if os(iOS)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    .tint(.black)
                    #endif
                    
                    Button
                    {
                        robot.restore_default_pointer_position()
                    }
                    label:
                    {
                        Text("Restore")
                            .frame(maxWidth: .infinity)
                            .disabled(robot.default_pointer_position == nil)
                    }
                    #if os(iOS)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    .tint(.black)
                    #endif
                }
            }
        }
    }
}

private struct OriginScaleView: View
{
    @ObservedObject var robot: Robot
    
    let on_update: () -> ()
    
    let with_steppers = true
    
    public var body: some View
    {
        VStack(spacing: 10)
        {
            HStack
            {
                Text("Scale (mm)")
                    .fontWeight(.light)
                    //.font(.system(size: 14, weight: .light))
                Spacer()
            }
            
            HStack(spacing: 12)
            {
                ForEach(ScaleComponents.allCases, id: \.self)
                { component in
                    VStack
                    {
                        #if os(macOS)
                        HStack(spacing: 8)
                        {
                            TextField("0", value: binding(for: component), format: .number)
                                .textFieldStyle(.roundedBorder)
                            
                            if with_steppers
                            {
                                Stepper("Position",
                                        value: binding(for: component),
                                        in: group == .location ? (-Float.infinity)...(Float.infinity) : -180...180)
                                .labelsHidden()
                            }
                        }
                        #else
                        VStack
                        {
                            TextField("0", value: binding(for: component), format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            
                            if with_steppers
                            {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 42)
                                    .overlay
                                    {
                                        Stepper("Position",
                                                value: binding(for: component),
                                                in: (0)...(Float.infinity))
                                            .labelsHidden()
                                            #if os(visionOS)
                                            .scaleEffect(0.85)
                                            #endif
                                }
                            }
                        }
                        #endif
                        
                        Text(component.info.text)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func binding(for component: ScaleComponents) -> Binding<Float>
    {
        switch component
        {
        case .x:
            return Binding(get: { robot.space_scale.x }, set: { robot.space_scale.x = $0; on_update() })
        case .y:
            return Binding(get: { robot.space_scale.y }, set: { robot.space_scale.y = $0; on_update() })
        case .z:
            return Binding(get: { robot.space_scale.z }, set: { robot.space_scale.z = $0; on_update() })
        }
    }
    
    private enum ScaleComponents: Equatable, CaseIterable
    {
        case x
        case y
        case z
        
        var info: (text: String, order: Int)
        {
            switch self
            {
            case .x:
                return ("X", 0)
            case .y:
                return ("Y", 1)
            case .z:
                return ("Z", 2)
            }
        }
        
        static var ordered: [ScaleComponents]
        {
            Self.allCases.sorted { $0.info.order < $1.info.order }
        }
    }
}

#Preview
{
    #if !os(visionOS)
    ZStack
    {
        
    }
    .inspector(isPresented: .constant(true))
    {
        ScrollView
        {
            VStack(spacing: 0)
            {
                RobotInspectorItems(robot: Robot(), on_update: {})
            }
        }
        #if os(macOS)
        .inspectorColumnWidth(300)
        #else
        .inspectorColumnWidth(400)
        #endif
    }
    .frame(width: 420, height: 600)
    #else
    ScrollView
    {
        RobotInspectorItems(robot: Robot(), on_update: {})
    }
    .modifier(SimpleCaption(label: "Model", plain: true, clear_background: true))
    .frame(width: 400, height: 600)
    .glassBackgroundEffect(in: .rect(cornerRadius: 30, style: .continuous))
    #endif
}
