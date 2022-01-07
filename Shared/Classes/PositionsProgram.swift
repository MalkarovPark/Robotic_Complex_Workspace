import Foundation
import SceneKit
import SwiftUI

class PositionsProgram: Equatable, ObservableObject
{
    static func == (lhs: PositionsProgram, rhs: PositionsProgram) -> Bool
    {
        return lhs.program_name == rhs.program_name
    }
    
    public var program_name: String?
    private var points = [SCNNode]()
    
    //MARK: - Initialization
    init()
    {
        self.program_name = "None"
    }
    
    init(name: String?)
    {
        self.program_name = name ?? "None"
    }
    
    //MARK: - Point manage functions
    public func add_point(pos_x: CGFloat, pos_y: CGFloat, pos_z: CGFloat, rot_x: CGFloat, rot_y: CGFloat, rot_z: CGFloat)
    {
        var point_node = SCNNode()
        
        #if os(macOS)
        point_node.position = SCNVector3(x: pos_x, y: pos_y, z: pos_z)
        point_node.rotation.x = to_rad(in_angle: rot_x)
        point_node.rotation.y = to_rad(in_angle: rot_y)
        point_node.rotation.z = to_rad(in_angle: rot_z)
        #else
        point_node.position = SCNVector3(x: Float(pos_x), y: Float(pos_y), z: Float(pos_z))
        point_node.rotation.x = Float(to_rad(in_angle: rot_x))
        point_node.rotation.y = Float(to_rad(in_angle: rot_y))
        point_node.rotation.z = Float(to_rad(in_angle: rot_z))
        #endif
        
        points.append(point_node)
        print(points)
        
        visual_build()
    }
    
    public func update_point(number: Int, pos_x: CGFloat, pos_y: CGFloat, pos_z: CGFloat, rot_x: CGFloat, rot_y: CGFloat, rot_z: CGFloat)
    {
        var point_node = SCNNode()
        
        if points.indices.contains(number) == true
        {
            #if os(macOS)
            point_node.position = SCNVector3(x: pos_x, y: pos_y, z: pos_z)
            //point_node.eulerAngles = SCNVector3(x: rot_x, y: rot_y, z: rot_z)
            point_node.rotation.x = to_rad(in_angle: rot_x)
            point_node.rotation.y = to_rad(in_angle: rot_y)
            point_node.rotation.z = to_rad(in_angle: rot_z)
            #else
            point_node.position = SCNVector3(x: Float(pos_x), y: Float(pos_y), z: Float(pos_z))
            //point_node.eulerAngles = SCNVector3(x: Float(rot_x), y: Float(rot_y), z: Float(rot_z))
            point_node.rotation.x = Float(to_rad(in_angle: rot_x))
            point_node.rotation.y = Float(to_rad(in_angle: rot_y))
            point_node.rotation.z = Float(to_rad(in_angle: rot_z))
            #endif
            
            points[number] = point_node
            
            visual_build()
        }
    }
    
    private func to_rad(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * .pi / 180
    }
    
    private func to_deg(in_angle: CGFloat) -> CGFloat
    {
        return in_angle * 180 / .pi
    }
    
    public func delete_point(number: Int)
    {
        if points.indices.contains(number) == true
        {
            points.remove(at: number)
            visual_build()
        }
    }
    
    public var points_info: [[Double]]
    {
        var pinfo = [[Double]]()
        if points.count > 0
        {
            var pindex = 1.0
            for point in points
            {
                pinfo.append([Double(point.position.x), Double(point.position.y), Double(point.position.z), to_deg(in_angle: Double(point.rotation.x)), to_deg(in_angle: Double(point.rotation.y)), to_deg(in_angle: Double(point.rotation.z)), pindex])
                pindex += 1
            }
        }
        //print(pinfo)
        return pinfo
    }
    
    public var points_count: Int
    {
        return points.count
    }
    
    //MARK: - Visual functions
    private var positions_group = SCNNode()
    
    private let target_point_color = Color.purple
    
    public var positions_visible = false
    {
        didSet
        {
            visual_build()
        }
    }
    
    private func visual_build()
    {
        if positions_visible == true
        {
            if points.count > 0
            {
                if points.count > 1
                {
                    var is_first = true
                    var pivot_points = [SCNVector3(), SCNVector3()]
                    
                    for point in points
                    {
                        point.geometry = SCNSphere(radius: 0.4)
                        point.geometry?.firstMaterial?.diffuse.contents = target_point_color
                        
                        if is_first == true
                        {
                            pivot_points[0] = point.position
                            is_first = false
                        }
                        else
                        {
                            #if os(macOS)
                            pivot_points[1] = SCNVector3(point.position.x + CGFloat.random(in: -0.001..<0.001), point.position.z + CGFloat.random(in: -0.001..<0.001), point.position.y + CGFloat.random(in: -0.001..<0.001))
                            #else
                            pivot_points[1] = SCNVector3(point.position.x + Float.random(in: -0.001..<0.001), point.position.z + Float.random(in: -0.001..<0.001), point.position.y + Float.random(in: -0.001..<0.001))
                            #endif
                            positions_group.addChildNode(build_ptp_line(from: simd_float3(pivot_points[0]), to: simd_float3(pivot_points[1])))
                            pivot_points[0] = pivot_points[1]
                        }
                        
                        positions_group.addChildNode(point)
                    }
                }
                else
                {
                    var point = points.first
                    point?.geometry = SCNSphere(radius: 0.4)
                    point?.geometry?.firstMaterial?.diffuse.contents = target_point_color
                    
                    positions_group.addChildNode(point!)
                }
            }
        }
        else
        {
            positions_group = SCNNode()
        }
    }
    
    private func build_ptp_line(from: simd_float3, to: simd_float3) -> SCNNode
    {
        let vector = to - from
        let height = simd_length(vector)
        
        let cylinder = SCNCylinder(radius: 0.2, height: CGFloat(height))
        
        #if os(macOS)
        let cylinder_color = NSColor.white
        #else
        let cylinder_color = UIColor.white
        #endif
        cylinder.firstMaterial?.diffuse.contents = cylinder_color
        
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
    //var moving_actions_group: [SCNAction]?
    
    public func points_moving_group(move_time: TimeInterval) -> SCNAction
    {
        var moving_group = SCNAction()
        if points.count > 0
        {
            var movings_array = [SCNAction]()
            for point in points
            {
                #if os(macOS)
                movings_array.append(SCNAction.group([SCNAction.move(to: point.position, duration: move_time), SCNAction.rotateTo(x: point.rotation.x, y: point.rotation.y, z: point.rotation.z, duration: move_time)]))
                #else
                movings_array.append(SCNAction.group([SCNAction.move(to: point.position, duration: move_time), SCNAction.rotateTo(x: CGFloat(point.rotation.x), y: CGFloat(point.rotation.y), z: CGFloat(point.rotation.z), duration: move_time)]))
                #endif
            }
            
            moving_group = SCNAction.sequence(movings_array)
        }
        
        return moving_group
    }
}
