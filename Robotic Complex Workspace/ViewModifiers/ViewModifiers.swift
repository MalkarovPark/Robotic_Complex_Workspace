//
//  ViewModifiers.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2022.
//

import SwiftUI
import IndustrialKit

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
