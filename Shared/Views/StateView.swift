//
//  StateView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 06.12.2022.
//

import SwiftUI

struct StateView: View
{
    @Binding var state_data: [StateItem]?
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Text("Statistics")
                .font(.title2)
                .padding()
            
            if state_data != nil
            {
                List(state_data!, children: \.children)
                { item in
                    StateItemView(item: item)
                }
                .listStyle(.plain)
                .padding(.horizontal)
            }
            else
            {
                Spacer()
            }
        }
    }
}

struct StateItemView: View
{
    var item: StateItem
    
    var body: some View
    {
        HStack
        {
            if item.image != nil
            {
                Image(systemName: item.image ?? "questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.accentColor)
            }
            Text(item.name)
            
            Spacer()
            
            Text(item.value ?? "")
        }
    }
}

struct StateView_Previews: PreviewProvider
{
    static var previews: some View
    {
        StateView(state_data: .constant([
            StateItem(name: "Temperature", image: "thermometer", children: [StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")])]))
    }
}
