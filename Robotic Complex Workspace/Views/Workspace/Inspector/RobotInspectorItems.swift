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
            #if os(macOS)
            PositionView(position: origin_binding, with_steppers: true)
            #else
            PositionView(position: origin_binding)
            #endif
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
                    if let default_pointer_position = robot.default_pointer_position
                    {
                        HStack
                        {
                            Text("X \(String(format: "%.0f", default_pointer_position.x)) Y \(String(format: "%.0f", default_pointer_position.y)) Z \(String(format: "%.0f", default_pointer_position.z))")
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Divider()
                            
                            Text("R \(String(format: "%.0f", default_pointer_position.r)) P \(String(format: "%.0f", default_pointer_position.p)) W \(String(format: "%.0f", default_pointer_position.w))")
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(4)
                    }
                    else
                    {
                        Text("None")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(4)
                    }
                }
                .padding(.top, 4)
                
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
                }
            }
        }
    }
}

private struct OriginScaleView: View
{
    @ObservedObject var robot: Robot
    
    let on_update: () -> ()
    
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
                            Stepper("Scale",
                                    value: binding(for: component),
                                    in: (0)...(Float.infinity))
                            .labelsHidden()
                        }
                        #else
                        VStack(spacing: 8)
                        {
                            TextField("0", value: binding(for: component), format: .number)
                                .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                                .frame(minWidth: 60)
                                .keyboardType(.decimalPad)
                            #elseif os(visionOS)
                                .frame(minWidth: 80)
                                .keyboardType(.decimalPad)
                            #endif
                            
                            #if os(macOS)
                            Stepper("Scale",
                                    value: binding(for: component),
                                    in: (0)...(Float.infinity))
                            .labelsHidden()
                            #endif
                        }
                        #endif
                        
                        Text(component.info.text)
                            .fontWeight(.light)
                            //.font(.system(size: 13, weight: .light))
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
    VStack(spacing: 0)
    {
        RobotInspectorItems(robot: Robot(), on_update: {})
    }
}
