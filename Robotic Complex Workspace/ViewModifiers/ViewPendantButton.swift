//
//  ViewPendantButton.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.02.2024.
//

import Foundation
import SwiftUI
import IndustrialKit
import IndustrialKitUI

#if os(visionOS)
struct ViewPendantButton: ViewModifier
{
    @EnvironmentObject var pendant_controller: PendantController
    
    public func body(content: Content) -> some View
    {
        content
            .overlay(alignment: .bottomTrailing)
            {
                Button(action: pendant_controller.toggle_pendant)
                {
                    Image(systemName: "slider.horizontal.2.square")
                }
                .controlSize(.large)
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .glassBackgroundEffect()
                .frame(depth: 24)
                .padding(32)
            }
    }
}
#else
// MARK: - Workspace scene views
struct ViewPendantButton: View
{
    let operation: () -> ()
    
    var body: some View
    {
        Button(action: operation)
        {
            Image(systemName: "slider.horizontal.2.square")
                .modifier(CircleButtonImageFramer())
        }
        .modifier(CircleButtonGlassBorderer())
        .padding()
    }
}
#endif

/*#if os(macOS) || os(iOS)
// MARK: - Glass Button Modifiers
struct CircleButtonGlassBorderer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
            .buttonBorderShape(.circle)
        #if os(macOS)
            .buttonStyle(.glass)
        #else
            .glassEffect(.regular.interactive())
        #endif
            //.padding()
    }
}

struct CircleButtonImageFramer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
            .imageScale(.large)
        #if os(macOS)
            .frame(width: 16, height: 16)
        #else
            .frame(width: 24, height: 24)
        #endif
            .padding(8)
        #if os(iOS)
            .padding(6)
            .foregroundStyle(.black)
        #endif
    }
}
#endif*/
