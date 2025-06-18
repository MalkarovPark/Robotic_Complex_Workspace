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
    @Binding var update_interval: TimeInterval
    @Binding var scope_type: ScopeType
    
    // Picker data for chart view
    @State private var stats_selection = 0
    
    @State private var update_interval_view_presented = false
    
    // View update handling
    @State private var diagram_updated = false
    @State private var diagram_update_task: Task<Void, Never>?
    
    @EnvironmentObject var base_workspace: Workspace
    //@EnvironmentObject var app_state: AppState
    
    var clear_chart_data: () -> Void
    var clear_states_data: () -> Void
    var update_file_data: () -> Void
    
    public init(
        is_presented: Binding<Bool>,
        get_statistics: Binding<Bool>,
        charts_data: Binding<[WorkspaceObjectChart]?>,
        states_data: Binding<[StateItem]?>,
        scope_type: Binding<ScopeType>,
        update_interval: Binding<TimeInterval>,
        clear_chart_data: @escaping () -> Void,
        clear_states_data: @escaping () -> Void,
        update_file_data: @escaping () -> Void
    )
    {
        self._is_presented = is_presented
        self._get_statistics = get_statistics
        self._charts_data = charts_data
        self._states_data = states_data
        self._update_interval = update_interval
        self._scope_type = scope_type
        
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
                if charts_data?.count ?? 0 > 0
                {
                    ChartsView(charts_data: $charts_data)
                }
                else
                {
                    EmptyStatisticsView()
                }
            }
            else
            {
                if states_data?.count ?? 0 > 0
                {
                    StateView(states_data: $states_data)
                }
                else
                {
                    EmptyStatisticsView()
                }
            }
            
            HStack(spacing: 0)
            {
                Toggle(isOn: $get_statistics)
                {
                    Text("Enabled")
                }
                .toggleStyle(.switch)
                .onChange(of: get_statistics)
                { _, new_value in
                    update_file_data()
                    
                    if new_value
                    {
                        perform_update()
                    }
                    else
                    {
                        disable_update()
                    }
                }
                #if !os(macOS)
                .tint(.accentColor)
                .modifier(PickerLabelModifier(text: "Enabled"))
                #endif
                .padding(.trailing)
                
                Picker(selection: $scope_type, label: Text("Scope"))
                {
                    ForEach(ScopeType.allCases, id: \.self)
                    { scope_type in
                        Text(scope_type.rawValue).tag(scope_type)
                    }
                }
                .onChange(of: scope_type)
                { _, _ in
                    //disable_update()
                    update_file_data()
                    //perform_update()
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                #if !os(macOS)
                .modifier(PickerBorderer())
                .modifier(PickerLabelModifier(text: "Scope"))
                #endif
                .padding(.trailing)
                .disabled(get_statistics)
                
                Button(action: { update_interval_view_presented = true })
                {
                    Text("Update Interval")//, systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                }
                .onChange(of: update_interval)
                { _, _ in
                    update_file_data()
                }
                #if os(iOS)
                .modifier(ButtonBorderer())
                #endif
                .popover(isPresented: $update_interval_view_presented)
                {
                    UpdateIntervalView(is_presented: $update_interval_view_presented, time_interval: $update_interval)
                }
            }
            .controlSize(.regular)
            .padding(.horizontal)
            
            HStack(spacing: 0)
            {
                Button(role: .destructive, action: clear_statistics_view)
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
                
                Picker(selection: $stats_selection, label: Text("Statistics"))
                {
                    Text("Charts").tag(0)
                    Text("State").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
                .labelsHidden()
                #if !os(iOS)
                .buttonStyle(.bordered)
                #endif
                .padding()
            }
        }
        .modifier(SheetCaption(is_presented: $is_presented, label: caption_text()))
        #if os(macOS)
        .controlSize(.large)
        .frame(minWidth: 448, idealWidth: 480, maxWidth: 512, minHeight: 448, idealHeight: 480, maxHeight: 512)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .onAppear()
        {
            if get_statistics
            {
                perform_update()
            }
        }
        .onDisappear()
        {
            disable_update()
        }
    }
    
    private func clear_statistics_view()
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
    
    private func caption_text() -> String
    {
        return "Statistics"
    }
    
    private func perform_update(interval: Double = 0.001)
    {
        diagram_updated = true
        
        diagram_update_task = Task
        {
            while diagram_updated
            {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await MainActor.run
                {
                    base_workspace.update_view()
                }
                
                if diagram_update_task == nil
                {
                    return
                }
            }
        }
    }
    
    private func disable_update()
    {
        diagram_updated = false
        diagram_update_task?.cancel()
        diagram_update_task = nil
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

struct UpdateIntervalView: View
{
    @Binding var is_presented: Bool
    @Binding var time_interval: TimeInterval
    
    var body: some View
    {
        HStack
        {
            Text("sec")
            
            TextField("Time", text: Binding(
                get:
                    {
                        String(format: "%.2f", time_interval)
                    },
                set:
                    { newValue in
                        if let value = Double(newValue)
                        {
                            time_interval = value
                        }
                    })
            )
            .frame(minWidth: 64, maxWidth: 96)
            #if os(iOS) || os(visionOS)
                .frame(idealWidth: 96)
                .textFieldStyle(.roundedBorder)
            #endif
            
            Stepper("Time", value: $time_interval, in: 0.01...60, step: 0.01)
                .labelsHidden()
        }
        .padding()
        #if os(iOS)
        .presentationDetents([.height(96)])
        #endif
    }
}

/*public struct StatisticsWindow: Scene
{
    var window_id: String
    let workspace: Workspace
    
    @Binding var is_presented: Bool
    
    @Binding var get_statistics: Bool
    @Binding var charts_data: [WorkspaceObjectChart]?
    @Binding var states_data: [StateItem]?
    @Binding var update_interval: TimeInterval
    @Binding var scope_type: ScopeType
    
    // Picker data for chart view
    @State private var stats_selection = 0
    
    @State private var update_interval_view_presented = false
    
    // View update handling
    @State private var diagram_updated = false
    @State private var diagram_update_task: Task<Void, Never>?
    
    @EnvironmentObject var base_workspace: Workspace
    @EnvironmentObject var app_state: AppState
    
    var clear_chart_data: () -> Void
    var clear_states_data: () -> Void
    var update_file_data: () -> Void
    
    public init(
        window_id: String = String(),
        workspace: Workspace = Workspace(),
        
        is_presented: Binding<Bool>,
        get_statistics: Binding<Bool>,
        charts_data: Binding<[WorkspaceObjectChart]?>,
        states_data: Binding<[StateItem]?>,
        scope_type: Binding<ScopeType>,
        update_interval: Binding<TimeInterval>,
        clear_chart_data: @escaping () -> Void,
        clear_states_data: @escaping () -> Void,
        update_file_data: @escaping () -> Void
    )
    {
        self.window_id = window_id
        self.workspace = workspace
        
        self._is_presented = is_presented
        self._get_statistics = get_statistics
        self._charts_data = charts_data
        self._states_data = states_data
        self._update_interval = update_interval
        self._scope_type = scope_type
        
        self.clear_chart_data = clear_chart_data
        self.clear_states_data = clear_states_data
        self.update_file_data = update_file_data
    }
    
    @SceneBuilder public var body: some Scene
    {
        WindowGroup(id: window_id)
        {
            StatisticsView(
                is_presented: .constant(true),
                get_statistics: $get_statistics,
                charts_data: $charts_data,
                states_data: $states_data,
                scope_type: $scope_type,
                update_interval: $update_interval,
                clear_chart_data: clear_chart_data,
                clear_states_data: clear_states_data,
                update_file_data: update_file_data
            )
        }
        .windowResizability(.contentSize)
    }
}*/

struct StatisticsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        StatisticsView(
            is_presented: .constant(true),
            get_statistics: .constant(true),
            charts_data: .constant([
                    WorkspaceObjectChart(name: "Chart 1", style: .line),
                    WorkspaceObjectChart(name: "Chart 2", style: .line)
            ]),
            states_data: .constant([
                StateItem(name: "Temperature", image: "thermometer", children: [
                    StateItem(name: "Base", value: "70º"), StateItem(name: "Electrode", value: "150º")
                ])
            ]),
            scope_type: .constant(.selected),
            update_interval: .constant(10),
            clear_chart_data: {},
            clear_states_data: {},
            update_file_data: {}
        )
        .environmentObject(Workspace())
        .environmentObject(AppState())
    }
}
