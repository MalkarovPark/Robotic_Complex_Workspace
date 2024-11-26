//
//  ViewPendantButton.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 21.02.2024.
//

import Foundation
import SwiftUI
import IndustrialKit

#if os(visionOS)
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
#else
//MARK: - Workspace scene views
struct ViewPendantButton: View
{
    let operation: () -> ()
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Button(action: operation)
            {
                Image(systemName: "slider.horizontal.2.square")
                    .imageScale(.large)
                    .padding()
            }
            .buttonStyle(.borderless)
            #if os(iOS)
            .foregroundColor(.black)
            #endif
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(radius: 8)
        .fixedSize(horizontal: true, vertical: false)
        .padding()
    }
}
#endif
