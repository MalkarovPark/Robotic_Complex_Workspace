//
//  DynamicStack.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Artem on 24.11.2022.
//

import SwiftUI
import IndustrialKit
import IndustrialKitUI

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
#endif
