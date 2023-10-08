//
//  StatisticsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 06.12.2022.
//

import SwiftUI
import IndustrialKit

struct StatisticsView: View
{
    @Binding var is_presented: Bool
    @Binding var document: Robotic_Complex_WorkspaceDocument
    
    @Binding var get_statistics: Bool
    @Binding var charts_data: [WorkspaceObjectChart]?
    @Binding var state_data: [StateItem]?
    
    //Picker data for chart view
    @State private var stats_selection = 0
    private let stats_items: [String] = ["Charts", "State"]
    
    @EnvironmentObject var base_workspace: Workspace
    
    var clear_chart_data: () -> Void
    var clear_state_data: () -> Void
    var update_file_data: () -> Void
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if stats_selection == 0
            {
                if get_statistics && charts_data?.count ?? 0 > 0
                {
                    ChartsView(charts_data: $charts_data)
                }
                else
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .horizontal])
                    EmptyView()
                }
            }
            else
            {
                if get_statistics && state_data?.count ?? 0 > 0
                {
                    StateView(state_data: $state_data)
                }
                else
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .horizontal])
                    EmptyView()
                }
            }
            
            #if os(macOS)
            Toggle(isOn: $get_statistics)
            {
                Text("Enable Collection")
            }
            .toggleStyle(.switch)
            .padding(.horizontal)
            .onChange(of: get_statistics)
            { _ in
                update_file_data()
            }
            #else
            HStack(spacing: 0)
            {
                Text("Enable Collection")
                    .padding(.trailing)
                Toggle(isOn: $get_statistics)
                {
                    Text("Enable Collection")
                }
                .toggleStyle(.switch)
                .tint(.accentColor)
                .labelsHidden()
            }
            .padding(.horizontal)
            .onChange(of: get_statistics)
            { _ in
                update_file_data()
            }
            #endif
            
            HStack(spacing: 0)
            {
                Button(action: clear_chart_view)
                {
                    Image(systemName: "eraser")
                }
                .buttonStyle(.bordered)
                .padding([.vertical, .leading])
                
                Button(action: update_file_data)
                {
                    Image(systemName: "arrow.down.doc")
                }
                .buttonStyle(.bordered)
                .padding([.vertical, .leading])
                
                Picker("Statistics", selection: $stats_selection)
                {
                    ForEach(0..<stats_items.count, id: \.self)
                    { index in
                        Text(stats_items[index]).tag(index)
                    }
                }
                .frame(maxWidth: 128)
                .labelsHidden()
                .buttonStyle(.bordered)
                .padding([.vertical, .leading])
                
                Button(action: { is_presented.toggle() })
                {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .padding()
            }
        }
        #if os(macOS)
        .controlSize(.large)
        .frame(minWidth: 448, idealWidth: 480, maxWidth: 512, minHeight: 448, idealHeight: 480, maxHeight: 512)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
    
    private func clear_chart_view()
    {
        if stats_selection == 0
        {
            clear_chart_data()
        }
        else
        {
            clear_state_data()
        }
        
        base_workspace.update_view()
    }
}

struct EmptyView: View
{
    var body: some View
    {
        VStack(spacing: 0)
        {
            Spacer()
            Text("None")
                .font(.largeTitle)
                .foregroundColor(quaternary_label_color)
            Spacer()
        }
    }
}

struct StatisticsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        StatisticsView(is_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), get_statistics: .constant(true), charts_data: .constant([WorkspaceObjectChart(name: "Chart 1", style: .line), WorkspaceObjectChart(name: "Chart 2", style: .line)]), state_data: .constant([
            StateItem(name: "Temperature", image: "thermometer", children: [StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")])]), clear_chart_data: {}, clear_state_data: {}, update_file_data: {})
            .environmentObject(Workspace())
    }
}
