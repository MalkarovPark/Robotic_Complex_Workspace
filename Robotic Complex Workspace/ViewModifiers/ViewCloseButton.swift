//
//  ViewCloseButton.swift
//  Robotic Complex Workspace
//
//  Created by Artiom Malkarov on 14.10.2023.
//

import SwiftUI

struct ViewCloseButton: ViewModifier
{
    @Binding var is_presented: Bool
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topLeading)
            {
                Button(action: { is_presented.toggle() })
                {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding()
            }
    }
}

struct ViewCloseFuncButton: ViewModifier
{
    var close_action: (() -> ())
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .topLeading)
            {
                Button(action: close_action)
                {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .padding()
            }
    }
}
