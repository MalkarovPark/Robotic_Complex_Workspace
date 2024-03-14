//
//  ViewPendantButton.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.02.2024.
//

#if os(visionOS)
import Foundation
import SwiftUI
import IndustrialKit

struct ViewPendantButton: ViewModifier
{
    @EnvironmentObject var pendant_controller: PendantController
    
    public func body(content: Content) -> some View
    {
        content
            .ornament(attachmentAnchor: .scene(.trailing))
            {
                Button(action: pendant_controller.toggle_pendant)
                {
                    ZStack
                    {
                        Image(systemName: "slider.horizontal.2.square")
                            .resizable()
                            .imageScale(.large)
                            .padding()
                    }
                    .frame(width: 64, height: 64)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .glassBackgroundEffect()
                .frame(depth: 24)
                .padding(32)
            }
    }
}

#endif
