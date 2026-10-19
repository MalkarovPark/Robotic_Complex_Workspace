//
//  SafeAreaToggler.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Artem on 19.10.2026.
//

import SwiftUI

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
