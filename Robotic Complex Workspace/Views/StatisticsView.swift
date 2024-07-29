//
//  StatisticsView.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 06.12.2022.
//

import SwiftUI
import IndustrialKit

struct StatisticsView: View
{
    @Binding var is_presented: Bool
    
    @Binding var get_statistics: Bool
    @Binding var charts_data: [WorkspaceObjectChart]?
    @Binding var states_data: [StateItem]?
    
    //Picker data for chart view
    @State private var stats_selection = 0
    private let stats_items: [String] = ["Charts", "State"]
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var clear_chart_data: () -> Void
    var clear_states_data: () -> Void
    var update_file_data: () -> Void
    
    public init(is_presented: Binding<Bool>, get_statistics: Binding<Bool>, charts_data: Binding<[WorkspaceObjectChart]?>, states_data: Binding<[StateItem]?>, stats_selection: Int = 0, clear_chart_data: @escaping () -> Void, clear_states_data: @escaping () -> Void, update_file_data: @escaping () -> Void)
    {
        self._is_presented = is_presented
        self._get_statistics = get_statistics
        self._charts_data = charts_data
        self._states_data = states_data
        self.stats_selection = stats_selection
        self.clear_chart_data = clear_chart_data
        self.clear_states_data = clear_states_data
        self.update_file_data = update_file_data
    }
    
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
                    EmptyStatisticsView()
                }
            }
            else
            {
                if get_statistics && states_data?.count ?? 0 > 0
                {
                    StateView(states_data: $states_data)
                }
                else
                {
                    Text("Statistics")
                        .font(.title2)
                        .padding([.top, .horizontal])
                    EmptyStatisticsView()
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
            { _, _ in
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
            { _, _ in
                update_file_data()
            }
            #endif
            
            HStack(spacing: 0)
            {
                Button(role: .destructive, action: clear_chart_view)
                {
                    Image(systemName: "eraser")
                }
                #if !os(iOS)
                .buttonStyle(.bordered)
                #else
                .modifier(Squarer(side: 34))
                .modifier(ButtonBorderer())
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
                .padding([.vertical, .leading])
                
                Button(action: update_file_data)
                {
                    Image(systemName: "arrow.down.doc")
                }
                #if !os(iOS)
                .buttonStyle(.bordered)
                #else
                .modifier(Squarer(side: 34))
                .modifier(ButtonBorderer())
                #endif
                #if os(visionOS)
                .buttonBorderShape(.circle)
                #endif
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
                #if !os(iOS)
                .buttonStyle(.bordered)
                #else
                .modifier(PickerBorderer())
                #endif
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
            clear_states_data()
        }
        
        base_workspace.update_view()
    }
}

struct EmptyStatisticsView: View
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
        StatisticsView(is_presented: .constant(true), get_statistics: .constant(true), charts_data: .constant([WorkspaceObjectChart(name: "Chart 1", style: .line), WorkspaceObjectChart(name: "Chart 2", style: .line)]), states_data: .constant([
            StateItem(name: "Temperature", image: "thermometer", children: [StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")])]), clear_chart_data: {}, clear_states_data: {}, update_file_data: {})
            .environmentObject(Workspace())
    }
}
