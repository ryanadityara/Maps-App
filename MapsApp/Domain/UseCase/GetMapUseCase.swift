//
//  GetMapUseCase.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import RxSwift

class GetMapUseCase {
    private let repository: MapRepository

    init(repository: MapRepository) {
        self.repository = repository
    }

    func execute() -> Single<[Map]> {
        return repository.getCoordinates()
    }
}
