//
//  PositionsProgram.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 05.12.2021.
//

import Foundation
import SceneKit

class PositionsProgram : Equatable
{
    static func == (lhs: PositionsProgram, rhs: PositionsProgram) -> Bool
    {
        return lhs.program_name == rhs.program_name
    }
    
    private var program_name: String?
    private var points = [SCNNode]()
    private var point_node = SCNNode()
    
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
        point_node.position = SCNVector3(x: pos_x, y: pos_y, z: pos_z)
        point_node.eulerAngles.x = rot_x
        point_node.eulerAngles.y = rot_y
        point_node.eulerAngles.z = rot_z
        
        points.append(point_node)
        
        visual_build()
    }
    
    public func update_point(number: Int, pos_x: CGFloat, pos_y: CGFloat, pos_z: CGFloat, rot_x: CGFloat, rot_y: CGFloat, rot_z: CGFloat)
    {
        if points.indices.contains(number) == true
        {
            point_node.position = SCNVector3(x: pos_x, y: pos_y, z: pos_z)
            point_node.eulerAngles.x = rot_x
            point_node.eulerAngles.y = rot_y
            point_node.eulerAngles.z = rot_z
            
            points[number] = point_node
            
            visual_build()
        }
    }
    
    public func delete_point(number: Int)
    {
        if points.indices.contains(number) == true
        {
            points.remove(at: number)
            visual_build()
        }
    }
    
    //MARK: - Visual functions
    private var positions_group = SCNNode()
    
    #if os(macOS)
    private let target_point_color = NSColor.systemPurple
    #else
    private let target_point_color = UIColor.systemPurple
    #endif
    
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
                            pivot_points[1] = SCNVector3(point.position.x + CGFloat.random(in: -0.001..<0.001), point.position.z + CGFloat.random(in: -0.001..<0.001), point.position.y + CGFloat.random(in: -0.001..<0.001))
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
        cylinder.firstMaterial?.diffuse.contents = NSColor.white
        
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
                movings_array.append(SCNAction.group([SCNAction.move(to: point.position, duration: move_time), SCNAction.rotateTo(x: point.rotation.x, y: point.rotation.y, z: point.rotation.z, duration: move_time)]))
            }
            
            moving_group = SCNAction.sequence(movings_array)
        }
        
        return moving_group
    }
}
