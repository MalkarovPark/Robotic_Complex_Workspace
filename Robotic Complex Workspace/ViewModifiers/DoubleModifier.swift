//
//  DoubleModifier.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2022.
//

import SwiftUI

struct DoubleModifier: ViewModifier
{
    @Binding var update_toggle: Bool
    
    func body(content: Content) -> some View
    {
        if update_toggle
        {
            content
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        else
        {
            content
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}

#if !os(macOS)
struct PickerLabelModifier: ViewModifier
{
    let text: String
    
    public func body(content: Content) -> some View
    {
        HStack(spacing: 8)
        {
            Text(text)
            
            content
                .labelsHidden()
        }
    }
}
#endif
