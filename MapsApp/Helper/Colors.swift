//
//  Colors.swift
//  MapsApp
//
//  Created by Ryan Aditya on 02/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        
        if hexString.count == 6 {
            let scanner = Scanner(string: hexString)
            var hexInt: UInt64 = 0
            scanner.scanHexInt64(&hexInt)
            
            let red = CGFloat((hexInt >> 16) & 0xFF) / 255.0
            let green = CGFloat((hexInt >> 8) & 0xFF) / 255.0
            let blue = CGFloat(hexInt & 0xFF) / 255.0
            
            self.init(red: red, green: green, blue: blue, alpha: 1.0)
        } else {
            // Default to transparent
            self.init(white: 0.0, alpha: 0.0)
        }
    }
}

class MapsColors {
    static let mapsBlue = UIColor(hex: "#165BAA")
    static let mapsGrey = UIColor(hex: "#D3D3D3")
    static let mapsGreen = UIColor(hex: "#009A46")
}

