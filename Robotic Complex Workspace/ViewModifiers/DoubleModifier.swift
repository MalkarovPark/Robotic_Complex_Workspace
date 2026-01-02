//
//  DoubleModifier.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2022.
//

import SwiftUI
import IndustrialKit

struct DoubleModifier: ViewModifier
{
    @Binding var update_toggle: Bool
    
    func body(content: Content) -> some View
    {
        if update_toggle
        {
            content
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
        else
        {
            content
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}

struct ForceUpdateModifier: ViewModifier
{
    public func body(content: Content) -> some View
    {
        content
            //.onAppear(perform: { perform_update() })
            //.onDisappear(perform: { disable_update() })
    }
    
    /*@State private var view_update_task: Task<Void, Never>?
    @State private var view_updated = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    private func perform_update(interval: Double = 0.001)
    {
        view_updated = true
        
        view_update_task = Task
        {
            while view_updated
            {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await MainActor.run
                {
                    base_workspace.update_view()
                }
                
                if view_update_task == nil
                {
                    return
                }
            }
        }
    }
    
    private func disable_update()
    {
        view_updated = false
        view_update_task?.cancel()
        view_update_task = nil
    }*/
}

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
