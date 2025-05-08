//
//  Map.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import Foundation

struct Map {
    let event: String
    let time: Date
    let latitude: Double
    let longitude: Double
    let course: Double
    let speed: Double?
}

extension Map {
    static func from(model: MapResponse) -> Map {
        return Map(
            event: model.event,
            time: ISO8601DateFormatter().date(from: model.time) ?? Date(),
            latitude: model.coordinate[0],
            longitude: model.coordinate[1],
            course: model.course,
            speed: model.speed
        )
    }
}
