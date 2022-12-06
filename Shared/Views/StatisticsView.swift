//
//  StatisticsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 06.12.2022.
//

import SwiftUI

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
                if get_statistics
                {
                    ChartsView(charts_data: $charts_data)
                }
                else
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                    EmptyChart()
                }
            }
            else
            {
                if get_statistics
                {
                    StateView(state_data: $state_data)
                }
                else
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .leading, .trailing])
                    EmptyChart()
                }
            }
            
            Toggle(isOn: $get_statistics)
            {
                Text("Enable collection")
            }
            .toggleStyle(.switch)
            .padding([.leading, .trailing])
            .onChange(of: get_statistics)
            { _ in
                update_file_data()
            }
            
            HStack(spacing: 0)
            {
                Button(action: clear_chart_view)
                {
                    Image(systemName: "eraser")
                }
                .padding([.vertical, .leading])
                
                Button(action: update_file_data)
                {
                    Image(systemName: "arrow.down.doc")
                }
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
        .controlSize(.large)
        #if os(macOS)
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

struct StatisticsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        StatisticsView(is_presented: .constant(true), document: .constant(Robotic_Complex_WorkspaceDocument()), get_statistics: .constant(true), charts_data: .constant([WorkspaceObjectChart(name: "Chart 1", style: .line), WorkspaceObjectChart(name: "Chart 2", style: .line)]), state_data: .constant([
            StateItem(name: "Temperature", image: "thermometer", children: [StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")])]), clear_chart_data: {}, clear_state_data: {}, update_file_data: {})
            .environmentObject(Workspace())
    }
}
