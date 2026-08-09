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

#if os(visionOS)
public struct SimpleCaption: ViewModifier
{
    let label: String
    let plain: Bool
    let clear_background: Bool
    
    public init(label: String = String(), plain: Bool = true, clear_background: Bool = false)
    {
        self.label = label
        self.plain = plain
        self.clear_background = clear_background
    }
    
    public func body(content: Content) -> some View
    {
        if plain
        {
            VStack(spacing: 0)
            {
                SimpleCaptionView(label: label, plain: plain, clear_background: clear_background)
                content
            }
        }
        else
        {
            ZStack(alignment: .top)//(spacing: 0)
            {
                content
                
                SimpleCaptionView(label: label, plain: plain, clear_background: clear_background)
            }
        }
    }
}

private struct SimpleCaptionView: View
{
    let label: String
    let plain: Bool
    let clear_background: Bool
    
    public init(label: String = String(), plain: Bool = true, clear_background: Bool = false)
    {
        self.label = label
        self.plain = plain
        self.clear_background = clear_background
    }
    
    var body: some View
    {
        ZStack
        {
            HStack(alignment: .center)
            {
                Text(label)
                    .padding(0)
                    .font(.title2)
                    .padding(.vertical)
            }
            .padding(.horizontal, 10)
            .padding(12)
        }
        .background
        {
            if !plain && !clear_background
            {
                HStack
                {
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
            }
        }
    }
}
#endif
