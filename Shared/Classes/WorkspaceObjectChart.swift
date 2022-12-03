//
//  WorkspaceObjectChart.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 03.12.2022.
//

import Foundation

class WorkspaceObjectChart: Identifiable, Codable, Hashable
{
    static func == (lhs: WorkspaceObjectChart, rhs: WorkspaceObjectChart) -> Bool
    {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    var name: String
    var style: ChartStyle
    
    var data = [ChartDataItem]()
    
    init()
    {
        self.name = "None"
        self.style = .line
    }
    
    init(name: String)
    {
        self.name = name
        self.style = .line
    }
    
    init(name: String, style: ChartStyle)
    {
        self.name = name
        self.style = style
    }
}

struct ChartDataItem: Identifiable, Codable
{
    var id = UUID()
    var name: String
    var domain: Float
    var codomain: Float
}

enum ChartStyle: Codable, Equatable, CaseIterable
{
    case area
    case line
    case point
    case rectange
    case rule
    case bar
}
