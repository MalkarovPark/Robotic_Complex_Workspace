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
    
    var body: some View
    {
        DisclosureGroup(isExpanded: $is_expanded)
        {
            ForEach(module.paths, id: \.file)
            { paths in
                ProgramComponentItemView(name: paths.file, url: module.url, sockets_paths: [paths.socket], file_paths: [paths.file])
            }
        }
        label:
        {
            ProgramComponentItemView(name: module.name, url: module.url, sockets_paths: module.paths.map { $0.socket }, file_paths: module.paths.map { $0.file })
        }
    }
}

private struct ProgramComponentItemView: View
{
    let name: String
    let url: URL
    let sockets_paths: [String]
    let file_paths: [String]
    
    @State private var control_items_presented = false
    @State private var process_state: ProcessState = .stopped
    @State private var timer: Timer?
    
    var body: some View
    {
        HStack(spacing: 4)
        {
            Text(name)
            
            Spacer()
            
            if control_items_presented
            {
                Button(action: restart_process)
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
                .foregroundColor(process_state.color)
        }
        .onAppear
        {
            update_process_state()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                update_process_state()
            }
        }
        /*.onDisappear
         {
         timer?.invalidate()
         timer = nil
         }*/
        //.onAppear(perform: update_process_state)
        .onChange(of: control_items_presented) { _, _ in update_process_state() }
        .onChange(of: sockets_paths) { _, _ in update_process_state() }
        .onHover
        { hovered in
            withAnimation
            {
                control_items_presented = hovered
            }
        }
    }
    
    private func update_process_state()
    {
        Task
        {
            let statuses = await sockets_paths.concurrentMap
            { path in
                await is_socket_active_async(at: path)
            }
            
            let active_count = statuses.filter { $0 }.count
            
            await MainActor.run
            {
                if active_count == sockets_paths.count
                {
                    process_state = .running
                }
                else if active_count == 0
                {
                    process_state = .stopped
                }
                else
                {
                    process_state = .partially
                }
            }
        }
    }
    
    private func stop_processes()
    {
        for socket_path in sockets_paths
        {
            if is_socket_active(at: socket_path)
            {
                send_via_unix_socket(at: socket_path, command: "stop")
            }
        }
    }
    
    private func start_processes()
    {
        for (socket_path, file_path) in zip(sockets_paths, file_paths)
        {
            if !is_socket_active(at: socket_path)
            {
                perform_terminal_app_sync(at: url.appendingPathComponent(file_path), with: [" > /dev/null 2>&1 &"])
            }
        }
    }
    
    private func restart_process()
    {
        for (socket_path, file_path) in zip(sockets_paths, file_paths)
        {
            if is_socket_active(at: socket_path)
            {
                send_via_unix_socket(at: socket_path, command: "stop")
                {_ in
                    perform_terminal_app_sync(at: url.appendingPathComponent(file_path), with: [" > /dev/null 2>&1 &"])
                }
            }
            else
            {
                perform_terminal_app_sync(at: url.appendingPathComponent(file_path), with: [" > /dev/null 2>&1 &"])
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
                    .gray
            case .running:
                    .green
            case .partially:
                    .yellow
            }
        }
    }
}

private extension Array
{
    func concurrentMap<T>(transform: @escaping (Element) async -> T) async -> [T]
    {
        await withTaskGroup(of: (Int, T).self)
        { group in
            for (index, element) in self.enumerated()
            {
                group.addTask
                {
                    let value = await transform(element)
                    return (index, value)
                }
            }
            var results = Array<T?>(repeating: nil, count: self.count)
            for await (index, value) in group
            {
                results[index] = value
            }
            return results.compactMap { $0 }
        }
    }
}

public func is_socket_active_async(at path: String) async -> Bool
{
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-U", path]
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = Pipe()
    
    do {
        try process.run()
    } catch {
        return false
    }
    
    return await withCheckedContinuation
    { continuation in
        Task
        {
            let outputData = try? outputPipe.fileHandleForReading.readToEnd()
            process.waitUntilExit()
            
            let output = String(data: outputData ?? Data(), encoding: .utf8) ?? ""
            continuation.resume(returning: output.contains(path))
        }
    }
}

enum ModuleType: Hashable
{
    case robot
    case tool
    case part
    case changer
    
    var modules: [
        (
            name: String,
            url: URL,
            paths: [(file: String, socket: String)]
        )
    ]
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
