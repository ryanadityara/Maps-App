//
//  MapRepositoryImpl.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import RxSwift

class MapRepositoryImpl: MapRepository {
    private let localDataSource: MapDataSourceProtocol
    
    init(localDataSource: MapDataSourceProtocol) {
        self.localDataSource = localDataSource
    }

    func getCoordinates() -> Single<[Map]> {
        return localDataSource.fetchCoordinates()
            .map { $0.map(Map.from(model:)) }
    }
}
