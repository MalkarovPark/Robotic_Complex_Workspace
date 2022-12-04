//
//  ChartsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 03.12.2022.
//

import SwiftUI
import Charts

struct ChartsView: View
{
    @State private var chart_selection = 0
    @State var charts_data: [WorkspaceObjectChart]
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            if charts_data.count > 1
            {
                Text("Statistics")
                    .font(.title2)
                    .padding([.top, .leading, .trailing])
                
                Picker("Statistics", selection: $chart_selection)
                {
                    ForEach(0..<charts_data.count, id: \.self)
                    { index in
                        Text(charts_data[index].name).tag(index)
                    }
                }
                .controlSize(.regular)
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding()
            }
            else
            {
                Text(charts_data.first?.name ?? "Unnamed")
                    .font(.title2)
                    .padding([.top, .leading, .trailing])
            }
            
            if charts_data.count > 1
            {
                switch charts_data[chart_selection].style
                {
                case .line:
                    Chart
                    {
                        ForEach(charts_data[chart_selection].data)
                        {
                            LineMark(x: .value("Mount", $0.domain), y: .value("Value", $0.codomain))
                            .foregroundStyle(by: .value("Type", $0.name))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                default:
                    //Text("None")
                    Spacer()
                }
            }
            else
            {
                //Text("None")
                Spacer()
            }
            
            /*Chart
            {
                ForEach(charts_data[chart_selection].data)
                {
                    //LineMark(x: .value("Mount", $0.domain), y: .value("Value", $0.codomain))
                    //.foregroundStyle(by: .value("Type", $0.name))
                    
                    switch charts_data[chart_selection].style
                    {
                    case .line:
                        LineMark(
                            x: .value("Mount", $0.domain),
                            y: .value("Value", $0.codomain)
                        )
                        .foregroundStyle(by: .value("Type", $0.name))
                    default:
                        LineMark(
                            x: .value("Mount", $0.domain),
                            y: .value("Value", $0.codomain)
                        )
                        .foregroundStyle(by: .value("Type", $0.name))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()*/
        }
    }
}

struct ChartsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ChartsView(charts_data: [WorkspaceObjectChart(name: "Chart 1", style: .line), WorkspaceObjectChart(name: "Chart 2", style: .line)])
    }
}
