//
//  DismissModifier.swift
//  Robotic Complex Workspace (iOS)
//
//  Created by Malkarov Park on 25.10.2021.
//

import SwiftUI

struct dismiss_document_button: View
{
    @Environment(\.dismiss)
    var dismiss
    
    var body: some View
    {
        Button
        {
            dismiss()
        }
        label:
        {
            Label("Close", systemImage: "folder")
        }
    }
}

struct dismiss_document_button_Previews: PreviewProvider
{
    static var previews: some View
    {
        dismiss_document_button()
    }
}


struct dismissing_view: UIViewRepresentable
{
    let dismiss: Bool
    
    func makeUIView(context: Context) -> UIView
    {
        let view = UIView()
        if dismiss
        {
            DispatchQueue.main.async
            {
                view.dismissViewControler()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context)
    {
        if dismiss
        {
            DispatchQueue.main.async
            {
                uiView.dismissViewControler()
            }
        }
    }
}


extension UIResponder
{
    func dismissViewControler()
    {
        guard let vc = self as? UIViewController else
        {
            self.next?.dismissViewControler()
            return
        }
        vc.dismiss(animated: true)
    }
}


struct DismissModifier: ViewModifier
{
    @State
    var dismiss = false
    
    func body(content: Content) -> some View
    {
        content.background(dismissing_view(dismiss: dismiss)).environment(\.dismiss, { self.dismiss = true })
    }
}

struct dismiss_environment_key: EnvironmentKey
{
    static var defaultValue: () -> Void
    {
        {}
    }
    
    typealias Value = () -> Void
}

extension EnvironmentValues
{
    var dismiss: dismiss_environment_key.Value
    {
        get
        {
            self[dismiss_environment_key.self]
        }
        
        set
        {
            self[dismiss_environment_key.self] = newValue
        }
    }
}

