//
//  MapResponse.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

struct MapResponse: Codable {
    let event: String
    let time: String
    let coordinate: [Double]
    let course: Double
    let speed: Double?
}
