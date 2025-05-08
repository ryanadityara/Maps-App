//
//  DoubleExt.swift
//  MapsApp
//
//  Created by Ryan Aditya on 07/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
