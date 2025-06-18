//
//  ProgramComponentsManagerView.swift
//  RCWorkspace
//
//  Created by Artem on 18.06.2025.
//

import SwiftUI
import IndustrialKit

struct ProgramComponentsManagerView: View
{
    let module_type: ModuleType
    
    private var restart_all: () -> Void
    private var stop_all: () -> Void
    
    public init(module_type: ModuleType)
    {
        self.module_type = module_type
        
        switch module_type
        {
        case .robot:
            restart_all = {
                Robot.external_modules_servers_stop()
                Robot.external_modules_servers_start()
            }
            stop_all = Robot.external_modules_servers_stop
        case .tool:
            restart_all = {
                Tool.external_modules_servers_stop()
                Tool.external_modules_servers_start()
            }
            stop_all = Tool.external_modules_servers_stop
        case .part:
            restart_all = {}
            stop_all = {}
        case .changer:
            restart_all = {
                Changer.external_modules_servers_stop()
                Changer.external_modules_servers_start()
            }
            
            stop_all = Changer.external_modules_servers_stop
        }
    }
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            List
            {
                ForEach(module_type.modules, id: \.name)
                {
                    ProgramComponentGroupView(module: $0)
                }
            }
            .modifier(ListBorderer())
            .padding(.bottom)
            
            HStack(spacing: 0)
            {
                Spacer()
                
                Button(action: restart_all)
                {
                    Text("Restart All")
                }
                .padding(.trailing)
                
                Button(action: stop_all)
                {
                    Text("Stop All")
                }
            }
        }
        .padding()
    }
}

private struct ProgramComponentGroupView: View
{
    let module: (name: String, url: URL, paths: [(file: String, socket: String)])
    
    @State private var is_expanded = false
    @State private var group_state: ProgramComponentItemView.ProcessState = .stopped
    
    var body: some View
    {
        DisclosureGroup(isExpanded: $is_expanded)
        {
            ForEach(module.paths, id: \.file)
            { paths in
                ProgramComponentItemView(
                    name: paths.file,
                    url: module.url,
                    sockets_paths: [paths.socket],
                    file_paths: [paths.file],
                    onStateChanged: update_group_state
                )
            }
        }
        label:
        {
            ProgramComponentItemView(
                name: module.name,
                url: module.url,
                sockets_paths: module.paths.map { $0.socket },
                file_paths: module.paths.map { $0.file },
                overrideState: group_state
            )
        }
        .task
        {
            await update_group_state()
        }
    }
    
    private func update_group_state() async
    {
        var activeCount = 0
        for path in module.paths.map(\.socket)
        {
            if await is_socket_active_async(at: path)
            {
                activeCount += 1
            }
        }
        if activeCount == module.paths.count
        {
            group_state = .running
        }
        else if activeCount == 0
        {
            group_state = .stopped
        }
        else
        {
            group_state = .partially
        }
    }
    
    private func update_group_state(_ : String, _ : ProgramComponentItemView.ProcessState)
    {
        Task
        {
            await update_group_state()
        }
    }
}

private struct ProgramComponentItemView: View
{
    let name: String
    let url: URL
    let sockets_paths: [String]
    let file_paths: [String]
    
    var overrideState: ProcessState? = nil
    var onStateChanged: ((String, ProcessState) -> Void)? = nil

    @State private var control_items_presented = false
    @State private var process_state: ProcessState = .stopped
    
    var body: some View
    {
        HStack(spacing: 4)
        {
            Text(name)
            
            Spacer()
            
            if control_items_presented
            {
                Button(action:
                {
                    stop_processes()
                    start_processes()
                })
                {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                }
                .buttonStyle(.plain)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                
                Button(action: stop_processes)
                {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
            
            Image(systemName: "circle.fill")
                .foregroundColor((overrideState ?? process_state).color)
        }
        .onHover
        { hovered in
            withAnimation
            {
                control_items_presented = hovered
            }
        }
        .task
        {
            await update_process_state()
        }
    }
    
    private func update_process_state() async
    {
        var activeCount = 0
        for path in sockets_paths
        {
            if await is_socket_active_async(at: path)
            {
                activeCount += 1
            }
        }
        let newState: ProcessState
        if activeCount == sockets_paths.count
        {
            newState = .running
        }
        else if activeCount == 0
        {
            newState = .stopped
        }
        else
        {
            newState = .partially
        }
        DispatchQueue.main.async
        {
            process_state = newState
            onStateChanged?(name, newState)
        }
    }
    
    private func stop_processes()
    {
        for socket_path in sockets_paths
        {
            Task
            {
                if await is_socket_active_async(at: socket_path)
                {
                    send_via_unix_socket(at: socket_path, command: "stop")
                }
                await update_process_state()
            }
        }
    }
    
    private func start_processes()
    {
        for (socket_path, file_path) in zip(sockets_paths, file_paths)
        {
            Task
            {
                if !(await is_socket_active_async(at: socket_path))
                {
                    perform_terminal_app_sync(
                        at: url.appendingPathComponent(file_path),
                        with: [" > /dev/null 2>&1 &"]
                    )
                }
                await update_process_state()
            }
        }
    }
    
    enum ProcessState: String, CaseIterable
    {
        case stopped
        case running
        case partially
        
        var color: Color
        {
            switch self
            {
            case .stopped:
                return .gray
            case .running:
                return .green
            case .partially:
                return .yellow
            }
        }
    }
}

private func is_socket_active_async(at path: String) async -> Bool
{
    await withCheckedContinuation
    { continuation in
        DispatchQueue.global().async
        {
            let result = is_socket_active(at: path)
            continuation.resume(returning: result)
        }
    }
}

enum ModuleType: Hashable
{
    case robot
    case tool
    case part
    case changer
    
    var modules: [(name: String, url: URL, paths: [(file: String, socket: String)])]
    {
        var modules = [(name: String, url: URL, paths: [(file: String, socket: String)])]()
        
        switch self
        {
        case .robot:
            for external_module in Robot.external_modules
            {
                modules.append((name: external_module.name, url: external_module.package_url, paths: external_module.program_components_paths))
            }
        case .tool:
            for external_module in Tool.external_modules
            {
                modules.append((name: external_module.name, url: external_module.package_url, paths: external_module.program_components_paths))
            }
        case .part:
            return modules
        case .changer:
            for external_module in Changer.external_modules
            {
                modules.append((name: external_module.name, url: external_module.package_url, paths: external_module.program_components_paths))
            }
        }
        
        return modules
    }
}

#Preview
{
    ProgramComponentsManagerView(module_type: .robot)
}
