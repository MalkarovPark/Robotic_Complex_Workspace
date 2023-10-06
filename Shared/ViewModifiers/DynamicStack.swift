//
//  DynamicStack.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Malkarov Park on 24.11.2022.
//

import SwiftUI

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
struct MountedPadding: ViewModifier
{
    @State var is_padding: Bool
    
    func body(content: Content) -> some View
    {
        if is_padding
        {
            content
                .padding([.bottom, .leading])
        }
        else
        {
            content
        }
    }
}
#endif
