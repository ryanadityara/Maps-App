//
//  MapDataSource.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import Foundation
import RxSwift

protocol MapDataSourceProtocol {
    func fetchCoordinates() -> Single<[MapResponse]>
}

class MapDataSource: MapDataSourceProtocol {
    func fetchCoordinates() -> Single<[MapResponse]> {
        return Single.create { single in
            guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let coordinates = try? JSONDecoder().decode([MapResponse].self, from: data) else {
                single(.failure(NSError(domain: "DataError", code: 0)))
                return Disposables.create()
            }
            single(.success(coordinates))
            return Disposables.create()
        }
    }
}
