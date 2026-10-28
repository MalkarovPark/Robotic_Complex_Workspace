//
//  DuoStateTracker.swift
//  RCWorkspace
//
//  Created by Artem Malkarov on 19.10.2026.
//

import SwiftUI

@available(iOS 27.1, *) // iPhone Duo Only
struct DuoStateTracker: ViewModifier
{
    @Binding var device_state: DuoDeviceState
    
    @State private var current_hinge_context: DeviceHingeContext? = nil
    @State private var latest_size: CGSize? = nil
    
    func body(content: Content) -> some View
    {
        content
            .onHingeChange // on fold
            { _, new_context in
                self.current_hinge_context = new_context
                update_state(with: new_context, size: nil)
            }
            .onGeometryChange(for: CGSize.self) // on rotate
            { proxy in
                proxy.size
            }
            action:
            { new_size in
                latest_size = new_size
                update_state(with: current_hinge_context, size: new_size)
            }
    }
    
    private func update_state(with context: DeviceHingeContext?, size: CGSize?)
    {
        guard let context = context, let hinge = context.hinge
        else
        {
            withAnimation(.spring())
            {
                device_state = .none
            }
            return
        }
        
        let is_vertical_hinge: Bool
        if let current_size = size ?? latest_size
        {
            is_vertical_hinge = current_size.width > current_size.height
        }
        else
        {
            is_vertical_hinge = false
        }
        
        withAnimation(.spring())
        {
            switch (is_vertical_hinge, hinge.status)
            {
            case (true, .closed):
                device_state = .hClosed
            case (true, .partiallyOpen):
                device_state = .hPartiallyOpen
            case (true, .fullyOpen):
                device_state = .hOpen
                
            case (false, .closed):
                device_state = .vClosed
            case (false, .partiallyOpen):
                device_state = .vPartiallyOpen
            case (false, .fullyOpen):
                device_state = .vOpen
                
            case (_, _):
                device_state = .none
            @unknown default:
                device_state = .none
            }
        }
    }
}

//@available(iOS 27.1, *) // iPhone Duo Only
enum DuoDeviceState: String
{
    case none
    
    case vClosed
    case vPartiallyOpen
    case vOpen
    
    case hClosed
    case hPartiallyOpen
    case hOpen
}

@available(iOS 27.1, *) // iPhone Duo Only
extension View
{
    func trackDuoState(_ state: Binding<DuoDeviceState>) -> some View
    {
        self.modifier(DuoStateTracker(device_state: state))
    }
}
