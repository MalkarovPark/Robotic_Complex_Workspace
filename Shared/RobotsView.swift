//
//  RobotsView.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 21.10.2021.
//

import SwiftUI
import SceneKit

#if os(macOS)
let placement_trailing: ToolbarItemPlacement = .automatic
#else
let placement_trailing: ToolbarItemPlacement = .navigationBarTrailing
#endif

struct RobotsView: View
{
    @State private var display_rv = false
    
    var body: some View
    {
        HStack
        {
            if display_rv == false
            {
                RobotsTableView(display_rv: $display_rv)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    //.transition(AnyTransition.move(edge: .leading)).animation(.default)
            }
            if display_rv == true
            {
                RobotView(display_rv: $display_rv)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    //.transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, idealWidth: 800, minHeight: 480, idealHeight: 600)
        #endif
    }
}

struct RobotsView_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            RobotsView()
            RobotView(display_rv: .constant(true))
            AddRobotView(add_robot_view_presented: .constant(true))
            RobotCardView(card_color: .green, card_title: "Robot Name", card_subtitle: "Fanuc")//, card_index: 0)
        }
    }
}

struct RobotsTableView: View
{
    @Binding var display_rv: Bool
    
    @State private var add_robot_view_presented = false
    //@State private var delete_robot_alert_presented = false
    
    @EnvironmentObject var base_workspace: Workspace
    
    var columns: [GridItem] = [.init(.adaptive(minimum: 160, maximum: 192), spacing: 24)]
    
    var body: some View
    {
        VStack
        {
            if base_workspace.robots_count() > 0
            {
                ScrollView(.vertical, showsIndicators: true)
                {
                    LazyVGrid(columns: columns, spacing: 24)
                    {
                        ForEach(base_workspace.previewed_robots, id: \.self)
                        { robot_item in
                            ZStack
                            {
                                RobotCardView(card_color: robot_item.card_info().color, card_title: robot_item.card_info().title, card_subtitle: robot_item.card_info().subtitle)
                                RobotDeleteButton(robots: $base_workspace.previewed_robots, robot_item: robot_item, on_delete: remove_robots)
                            }
                            .onTapGesture
                            {
                                print("Viewed Robot - " + robot_item.card_info().title)
                                view_robot()
                            }
                        }
                    }
                    .padding(16)
                }
                .animation(.spring(), value: base_workspace.robots_cards_info)
                //.transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
            }
            else
            {
                Text("Press '+' to add new robot")
                    .foregroundColor(.gray)
                    .padding(16)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        
        .toolbar
        {
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    Button("View Robot")
                    {
                        view_robot()
                        //self.display_rv = true
                    }
                    
                    Button (action: { add_robot_view_presented.toggle() })
                    {
                        Label("Robots", systemImage: "plus")
                    }
                    .sheet(isPresented: $add_robot_view_presented)
                    {
                        AddRobotView(add_robot_view_presented: $add_robot_view_presented)
                    }
                }
            }
        }
    }
    
    func view_robot()
    {
        self.display_rv = true
    }
    
    func remove_robots(at offsets: IndexSet)
    {
        withAnimation
        {
            base_workspace.previewed_robots.remove(atOffsets: offsets)
        }
    }
}

struct RobotCardView: View
{
    @State var card_color: Color
    @State var card_title: String
    @State var card_subtitle: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
            VStack(alignment: .leading, spacing: 8.0)
            {
                Rectangle()
                    .foregroundColor(card_color)
                
                VStack(alignment: .leading)
                {
                    Text(card_title)
                        .font(.headline)
                    
                    HStack(spacing: 4.0)
                    {
                        Image(systemName: "arrow.up.doc")
                        Text(card_subtitle)
                    }
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 8)
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
        .frame(height: 160)
        .shadow(radius: 8.0)
        //.transition(AnyTransition.scale.animation(.easeInOut(duration: 0.6)))
        //.transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.6)))
    }
}

struct RobotDeleteButton: View
{
    @Binding var robots: [Robot]
    @State private var delete_robot_alert_presented = false
    
    let robot_item: Robot
    let on_delete: (IndexSet) -> ()
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Spacer()
                Button(action: { delete_robot_alert_presented = true }) //(action: { delete_robot() })
                {
                    Label("Robots", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .padding(4.0)
                }
                    .foregroundColor(.white)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .frame(width: 24.0, height: 24.0)
                    .padding(8.0)
            }
            Spacer()
        }
        .alert(isPresented: $delete_robot_alert_presented)
        {
            Alert(
                title: Text("Delete robot?"),
                message: Text("Do you wand to delete this robot – \(robot_item.card_info().title)"),
                primaryButton: .destructive(Text("Yes"), action: { delete_robot() }),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func delete_robot()
    {
        if let index = robots.firstIndex(of: robot_item)
        {
            self.on_delete(IndexSet(integer: index))
        }
        print("Deleted")
    }
}

struct AddRobotView: View
{
    @Binding var add_robot_view_presented: Bool
    
    @State var new_robot_name = ""
    @State var new_robot_parameters = ["Brand", "Series", "Model"]
    @State var new_robot_parameters_index = [0, 0, 0]
    
    @EnvironmentObject var base_workspace: Workspace
    
    var brands = ["ABB", "Fanuc", "Kuka"]
    var series = ["LR-Mate", "Paint"]
    var models = ["id-4s", "id-20s"]
    
    var body: some View
    {
        #if os(macOS)
        let button_padding = 12.0 //16.0
        
        VStack
        {
            Text("Add Robot")
                .font(.title2)
                .padding([.top, .leading, .trailing])
            
            VStack
            {
                HStack
                {
                    Text("Name")
                        .bold()
                    TextField("None", text: $new_robot_name)
                        //.textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Picker(selection: $new_robot_parameters_index[0], label: Text("Brand")
                        .bold())
                {
                    ForEach(0 ..< brands.count)
                    {
                        Text(brands[$0])
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker(selection: $new_robot_parameters_index[1], label: Text("Series")
                        .bold())
                {
                    ForEach(0 ..< series.count)
                    {
                        Text(series[$0])
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
                
                Picker(selection: $new_robot_parameters_index[2], label: Text("Model")
                        .bold())
                {
                    ForEach(0 ..< models.count)
                    {
                        Text(models[$0])
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 4.0)
            }
            .padding(.horizontal)
            
            Spacer()
            Divider()
            
            HStack
            {
                Spacer()
                
                Button("Cancel", action: { add_robot_view_presented.toggle() })
                    .keyboardShortcut(.cancelAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding - 8.0)
                
                Button("Save", action: { add_robot_in_workspace() })
                    .keyboardShortcut(.defaultAction)
                    .padding(.top, button_padding - 8.0)
                    .padding(.bottom, button_padding)
                    .padding(.trailing, button_padding)
            }
        }
        .controlSize(.regular)
        .frame(minWidth: 160, idealWidth: 240, maxWidth: 320, minHeight: 240, maxHeight: 300)
        #else
        NavigationView
        {
            Form
            {
                Section(header: Text("Name"))
                {
                    TextField(text: $new_robot_name, prompt: Text("None"))
                    {
                        Text("Name")
                    }
                }
                
                Section(header: Text("Parameters"))
                {
                    Picker(selection: $new_robot_parameters_index[0], label: Text("Brand")
                            .bold())
                    {
                        ForEach(0 ..< brands.count)
                        {
                            Text(brands[$0])
                        }
                    }
                    
                    Picker(selection: $new_robot_parameters_index[1], label: Text("Series")
                            .bold())
                    {
                        ForEach(0 ..< series.count)
                        {
                            Text(series[$0])
                        }
                    }
                    
                    Picker(selection: $new_robot_parameters_index[2], label: Text("Model")
                            .bold())
                    {
                        ForEach(0 ..< models.count)
                        {
                            Text(models[$0])
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Add Robot"), displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel", action: { add_robot_view_presented.toggle() }), trailing: Button("Save", action: { add_robot_in_workspace() }))
        }
        #endif
    }
    
    func add_robot_in_workspace()
    {
        base_workspace.add_robot(robot: Robot(name: new_robot_name, manufacturer: brands[new_robot_parameters_index[0]], model: models[new_robot_parameters_index[2]], ip_address: "127.0.0.1"))
        //base_workspace.add_robot(robot: Robot(name: new_robot_name))
        
        add_robot_view_presented.toggle()
    }
}

struct RobotView: View
{
    @Binding var display_rv: Bool
    
    var body: some View
    {
        HStack
        {
            RobotSceneView()
            RobotInspectorView(display_rv: $display_rv)//.frame(width: 80)
        }
        
        .toolbar
        {
            ToolbarItem(placement: placement_trailing)
            {
                HStack(alignment: .center)
                {
                    //Button("Save", action: add_robot)
                    //Spacer()
                    
                    Button(action: { display_rv = false })
                    {
                        Label("Robots", systemImage: "xmark")
                    }
                    Spacer()
                    
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "stop")
                    }
                    Button(action: add_robot)
                    {
                        Label("Robots", systemImage: "playpause")
                    }
                }
            }
        }
    }
    
    func add_robot()
    {
        print("🔮")
    }
}

struct RobotSceneView: View
{
    let robot_scene = SCNScene(named: "Components.scnassets/Workcell.scn")!
    var viewed_scene: SCNScene?
    {
        robot_scene
    }
    
    var camera_node: SCNNode?
    {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        return cameraNode
    }
    
    var body: some View
    {
        SceneView(scene: viewed_scene, pointOfView: camera_node, options: [.allowsCameraControl, .autoenablesDefaultLighting])
        .onAppear
        {
            print("View Loaded")
        }
        #if os(iOS)
        .cornerRadius(8)
        .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 8))//(20)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct RobotInspectorView: View
{
    @Binding var display_rv: Bool
    
    var body: some View
    {
        VStack
        {
            Button("Add Position Program")
            {
                add_position_program()
            }
            .padding()
            Text("Inspector View")
                .padding()
        }
    }
    
    func add_position_program()
    {
        print("🕰")
    }
}
