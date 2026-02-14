//
//  RobotInspectorItems.swift
//  RCWorkspace
//
//  Created by Artem Malkarov on 14.02.2026.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

struct RobotInspectorItems: View
{
    @ObservedObject var robot: Robot
    
    public let on_update: () -> ()
    
    @State private var origin_is_expanded: Bool = false
    @State private var space_is_expanded: Bool = false
    
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
        
        DisclosureGroup(isExpanded: $origin_is_expanded)
        {
            #if os(macOS)
            PositionView(position: origin_binding)
            #else
            PositionView(position: origin_binding, with_steppers: false)
            #endif
        }
        label:
        {
            Text("Origin")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
        
        DisclosureGroup(isExpanded: $space_is_expanded)
        {
            OriginScaleView(robot: robot, on_update: on_update)
        }
        label:
        {
            Text("Working Area")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(10)
        
        Divider()
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
                Text("Scale")
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
                            #if os(iOS)
                                .frame(minWidth: 60)
                                .keyboardType(.decimalPad)
                            #elseif os(visionOS)
                                .frame(minWidth: 80)
                                .keyboardType(.decimalPad)
                            #endif
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
                return ("X ", 0)
            case .y:
                return ("Y ", 1)
            case .z:
                return ("Z ", 2)
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
