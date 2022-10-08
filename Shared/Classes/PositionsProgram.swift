import Foundation
import SceneKit
import SwiftUI

class PositionsProgram: Identifiable, Equatable, ObservableObject
{
    static func == (lhs: PositionsProgram, rhs: PositionsProgram) -> Bool
    {
        return lhs.name == rhs.name //Identity condition by names
    }
    
    public var name: String?
    public var points = [PositionPoint]()
    
    //MARK: - Positions program init functions
    init()
    {
        self.name = "None"
    }
    
    init(name: String?)
    {
        self.name = name ?? "None"
    }
    
    //MARK: - Point manage functions
    public func add_point(_ point: PositionPoint)
    {
        points.append(point)
        visual_build()
    }
    
    public func update_point(number: Int, _ point: PositionPoint)
    {
        if points.indices.contains(number) //Checking for the presence of a point with a given number to update
        {
            points[number] = point
            visual_build()
        }
    }
    
    public func delete_point(number: Int) //Checking for the presence of a point with a given number to delete
    {
        if points.indices.contains(number)
        {
            points.remove(at: number)
            visual_build()
        }
    }
    
    public var points_info: [[Float]]
    {
        var pinfo = [[Float]]()
        if points.count > 0
        {
            var pindex: Float = 1.0
            for point in points
            {
                pinfo.append([point.x, point.y, point.z, point.r, point.p, point.w, pindex])
                pindex += 1
            }
        }
        return pinfo
    }
    
    public var points_count: Int
    {
        return points.count
    }
    
    //MARK: - Visual functions
    public var positions_group = SCNNode()
    public var selected_point_index = -1
    {
        didSet
        {
            visual_build()
        }
    }
    
    //Define colors for path and points of program
    #if os(macOS)
    private let target_point_color = NSColor.systemPurple
    private let target_point_cone_colors = [NSColor.systemBlue, NSColor.systemPink, NSColor.systemTeal]
    private let selected_point_color = NSColor.systemIndigo
    private let target_point_cone_pos = [[0.0, 0.0, 0.8], [0.8, 0.0, 0.0], [0.0, 0.8, 0.0]]
    private let target_point_cone_rot = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = NSColor.white
    #else
    private let target_point_color = UIColor.systemPurple
    private let target_point_cone_colors = [UIColor.systemBlue, UIColor.systemPink, UIColor.systemTeal]
    private let selected_point_color = UIColor.systemIndigo
    private let target_point_cone_pos: [[Float]] = [[0.0, 0.0, 0.8], [0.8, 0.0, 0.0], [0.0, 0.8, 0.0]]
    private let target_point_cone_rot: [[Float]] = [[90.0 * .pi / 180, 0.0, 0.0], [0.0, 0.0, -90 * .pi / 180], [0.0, 0.0, 0.0]]
    private let cylinder_color = UIColor.white
    #endif
    
    //MARK: Build points visual model
    public func visual_build()
    {
        visual_clear()
        
        if points.count > 0
        {
            //MARK: Building cones showing tool rotation at point
            let cone_node = SCNNode()
            
            for i in 0..<3 //Set point conical arrows for points
            {
                let cone = SCNNode()
                cone.geometry = SCNCone(topRadius: 0, bottomRadius: 0.2, height: 0.4)
                cone.geometry?.firstMaterial?.diffuse.contents = target_point_cone_colors[i]
                cone.position = SCNVector3(x: target_point_cone_pos[i][0], y: target_point_cone_pos[i][1], z: target_point_cone_pos[i][2])
                cone.eulerAngles.x = target_point_cone_rot[i][0]
                cone.eulerAngles.y = target_point_cone_rot[i][1]
                cone.eulerAngles.z = target_point_cone_rot[i][2]
                cone_node.addChildNode(cone.copy() as! SCNNode)
            }
            
            //MARK: Build positions points in robot cell
            if points.count > 1
            {
                let internal_cone_node = cone_node.clone()
                var is_first = true
                var pivot_points = [SCNVector3(), SCNVector3()]
                var point_location = SCNVector3()
                var point_index = 0
                
                for point in points
                {
                    let visual_point = SCNNode()
                    visual_point.geometry = SCNSphere(radius: 0.4)
                    
                    #if os(macOS)
                    point_location = SCNVector3(x: CGFloat(point.y) / 10 - 10, y: CGFloat(point.z / 10) - 10, z: CGFloat(point.x / 10) - 10)
                    #else
                    point_location = SCNVector3(x: point.y / 10 - 10, y: point.z / 10 - 10, z: point.x / 10 - 10)
                    #endif
                    
                    visual_point.position = point_location
                    
                    if is_first == true
                    {
                        pivot_points[0] = point_location
                        is_first = false
                    }
                    else
                    {
                        #if os(macOS)
                        pivot_points[1] = SCNVector3(point_location.x + CGFloat.random(in: -0.001..<0.001), point_location.y + CGFloat.random(in: -0.001..<0.001), point_location.z + CGFloat.random(in: -0.001..<0.001))
                        #else
                        pivot_points[1] = SCNVector3(point_location.x + Float.random(in: -0.001..<0.001), point_location.y + Float.random(in: -0.001..<0.001), point_location.z + Float.random(in: -0.001..<0.001))
                        #endif
                        positions_group.addChildNode(build_ptp_line(from: simd_float3(pivot_points[0]), to: simd_float3(pivot_points[1])))
                        pivot_points[0] = pivot_points[1]
                    }
                    
                    #if os(macOS)
                    internal_cone_node.eulerAngles.z = CGFloat(point.r.to_rad)
                    #else
                    internal_cone_node.eulerAngles.z = point.r.to_rad
                    #endif
                    
                    visual_point.addChildNode(internal_cone_node)
                    
                    #if os(macOS)
                    visual_point.eulerAngles.x = CGFloat(point.p.to_rad)
                    visual_point.eulerAngles.y = CGFloat(point.w.to_rad)
                    #else
                    visual_point.eulerAngles.x = point.p.to_rad
                    visual_point.eulerAngles.y = point.w.to_rad
                    #endif
                    
                    if point_index == selected_point_index
                    {
                        visual_point.geometry?.firstMaterial?.diffuse.contents = selected_point_color
                    }
                    else
                    {
                        visual_point.geometry?.firstMaterial?.diffuse.contents = target_point_color
                    }
                    
                    positions_group.addChildNode(visual_point.clone())
                    point_index += 1
                }
            }
            else
            {
                let visual_point = SCNNode()
                visual_point.geometry = SCNSphere(radius: 0.4)
                
                let point = points.first ?? PositionPoint()
                
                #if os(macOS)
                let point_location = SCNVector3(x: CGFloat(point.y) / 10 - 10, y: CGFloat(point.z) / 10 - 10, z: CGFloat(point.x / 10) - 10)
                #else
                let point_location = SCNVector3(x: point.y / 10 - 10, y: point.z / 10 - 10, z: point.x / 10 - 10)
                #endif
                
                visual_point.position = point_location
                
                #if os(macOS)
                cone_node.eulerAngles.z = CGFloat(point.r.to_rad)
                #else
                cone_node.eulerAngles.z = point.r.to_rad
                #endif
                
                visual_point.addChildNode(cone_node)
                
                #if os(macOS)
                visual_point.eulerAngles.x = CGFloat(point.p.to_rad)
                visual_point.eulerAngles.y = CGFloat(point.w.to_rad)
                #else
                visual_point.eulerAngles.x = point.p.to_rad
                visual_point.eulerAngles.y = point.w.to_rad
                #endif
                
                if selected_point_index == 0
                {
                    visual_point.geometry?.firstMaterial?.diffuse.contents = selected_point_color
                }
                else
                {
                    visual_point.geometry?.firstMaterial?.diffuse.contents = target_point_color
                }
                
                positions_group.addChildNode(visual_point)
            }
        }
    }
    
    public func visual_clear() //Remove positions points from cell
    {
        positions_group.enumerateChildNodes
        { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    private func build_ptp_line(from: simd_float3, to: simd_float3) -> SCNNode //Build line between neighboring points
    {
        let vector = to - from
        let height = simd_length(vector)
        
        let cylinder = SCNCylinder(radius: 0.2, height: CGFloat(height))
        
        cylinder.firstMaterial?.diffuse.contents = cylinder_color
        //cylinder.firstMaterial?.transparency = 0.5
        
        let line_node = SCNNode(geometry: cylinder)
        
        let line_axis = simd_float3(0, height/2, 0)
        line_node.simdPosition = from + line_axis

        let vector_cross = simd_cross(line_axis, vector)
        let qw = simd_length(line_axis) * simd_length(vector) + simd_dot(line_axis, vector)
        let q = simd_quatf(ix: vector_cross.x, iy: vector_cross.y, iz: vector_cross.z, r: qw).normalized

        line_node.simdRotate(by: q, aroundTarget: from)
        return line_node
    }
    
    //MARK: - Create moving group for robot
    public func points_moving_group(move_time: TimeInterval) -> (moving: [SCNAction], rotation: [SCNAction])
    {
        var moving_position: SCNVector3
        var moving_rotation: [Float] = [0.0, 0.0, 0.0]
        
        var movings_array = [SCNAction]()
        var movings_array2 = [SCNAction]()
        
        if points.count > 0
        {
            for point in points
            {
                moving_position = SCNVector3(point.y / 10, point.z / 10, point.x / 10)
                
                moving_rotation = [point.p.to_rad, point.w.to_rad, 0]
                movings_array.append(SCNAction.group([SCNAction.move(to: moving_position, duration: move_time), SCNAction.rotateTo(x: CGFloat(moving_rotation[0]), y: CGFloat(moving_rotation[1]), z: CGFloat(moving_rotation[2]), duration: move_time)]))
                movings_array2.append(SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(point.r.to_rad), duration: move_time))
            }
        }
        
        return (movings_array, movings_array2)
    }
    
    //MARK: - Work with file system
    public var file_info: program_struct
    {
        return program_struct(name: name ?? "None", points: self.points)
    }
}

//MARK: - Program structure for workspace preset document handling
struct program_struct: Codable
{
    var name: String
    var points = [PositionPoint()]
}
