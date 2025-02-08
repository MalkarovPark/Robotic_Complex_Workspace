//
//  DocumentBorderer.swift
//  RCWorkspace
//
//  Created by Artem on 25.11.2024.
//

import SwiftUI

struct DocumentBorderer: ViewModifier
{
    public func body(content: Content) -> some View
    {
        ZStack
        {
            content
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.2), radius: 5)
        .frame(maxWidth: .infinity)
        .padding(.top)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
