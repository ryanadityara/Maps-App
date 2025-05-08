//
//  MapRepository.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import RxSwift

protocol MapRepository {
    func getCoordinates() -> Single<[Map]>
}
