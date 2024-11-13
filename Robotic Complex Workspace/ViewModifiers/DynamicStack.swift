//
//  DynamicStack.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Artem on 24.11.2022.
//

import SwiftUI
import IndustrialKit

#if os(iOS) || os(visionOS)
struct SafeAreaToggler: ViewModifier
{
    var enabled: Bool
    public func body(content: Content) -> some View
    {
        if enabled
        {
            content
        }
        else
        {
            content
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct PickerNamer: ViewModifier
{
    var name: String
    
    public func body(content: Content) -> some View
    {
        HStack(spacing: 0)
        {
            Text(name)
                .font(.subheadline)
                .padding(.trailing)
            content
            #if os(iOS)
                .modifier(PickerBorderer())
            #endif
        }
    }
}
#endif
