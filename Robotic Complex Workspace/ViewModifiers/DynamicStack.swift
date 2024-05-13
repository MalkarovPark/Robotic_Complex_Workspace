//
//  DynamicStack.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Artem on 24.11.2022.
//

import SwiftUI
import IndustrialKit

struct DynamicStack<Content: View>: View
{
    @ViewBuilder var content: () -> Content
    
    @Binding var is_compact: Bool
    
    var horizontal_alignment = HorizontalAlignment.center
    var vertical_alignment = VerticalAlignment.center
    var spacing: CGFloat?
    
    var body: some View
    {
        if is_compact
        {
            VStack(alignment: horizontal_alignment, spacing: spacing, content: content)
        }
        else
        {
            HStack(alignment: vertical_alignment, spacing: spacing, content: content)
        }
    }
}

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
                .modifier(PickerBorderer())
        }
    }
}
#endif
