//
//  BackgroundExtensionModifier.swift
//  RCWorkspace
//
//  Created by Artem on 21.08.2025.
//

import Foundation
import SwiftUI

struct BackgroundExtensionModifier: ViewModifier
{
    let color: Color
    
    func body(content: Content) -> some View
    {
        ZStack
        {
            ScrollView(.vertical) {
                VStack
                {
                    Rectangle()
                        .foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255))
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .backgroundExtensionEffect()
                }
            }
            .background(color)
            
            content
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                //.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                //.shadow(color: .black.opacity(0.2), radius: 8)
                //.padding(8)
        }
    }
}
