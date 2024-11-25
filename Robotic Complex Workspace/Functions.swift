//
//  Functions.swift
//  Robotic Complex Workspace
//
//  Created by Artem on 04.10.2023.
//

import Foundation
import IndustrialKit
import SwiftUI

extension Color
{
    /**
     Initializes a `Color` instance from a HEX string.
     
     - Parameters:
        - hex: A string representing the HEX color. Supported formats: `#RRGGBB`, `#RRGGBBAA`, `RRGGBB`, `RRGGBBAA`.
        - alpha: An optional alpha value between 0 and 1. Defaults to `1.0` (fully opaque). If the HEX string includes alpha, this parameter is ignored.
     
     - Returns: A `Color` instance or a fallback to `clear` if the HEX string is invalid.
     */
    init(hex: String, alpha: Double = 1.0)
    {
        // Remove any leading "#" and ensure proper casing
        let sanitizedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
        
        // Convert HEX string to UInt64
        var hexValue: UInt64 = 0
        guard Scanner(string: sanitizedHex).scanHexInt64(&hexValue)
        else
        {
            self = .clear // Fallback to a transparent color if invalid
            return
        }
        
        let red, green, blue, computedAlpha: Double
        
        switch sanitizedHex.count
        {
        case 6: // #RRGGBB
            red = Double((hexValue >> 16) & 0xFF) / 255.0
            green = Double((hexValue >> 8) & 0xFF) / 255.0
            blue = Double(hexValue & 0xFF) / 255.0
            computedAlpha = alpha
        case 8: // #RRGGBBAA
            red = Double((hexValue >> 24) & 0xFF) / 255.0
            green = Double((hexValue >> 16) & 0xFF) / 255.0
            blue = Double((hexValue >> 8) & 0xFF) / 255.0
            computedAlpha = Double(hexValue & 0xFF) / 255.0
        default:
            self = .clear // Fallback for invalid length
            return
        }
        
        self = Color(
            red: red,
            green: green,
            blue: blue,
            opacity: computedAlpha
        )
    }
}
