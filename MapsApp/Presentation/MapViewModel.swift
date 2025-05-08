//
//  MapViewModel.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//  Copyright © 2025 Ryan Aditya. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class MapViewModel {
    let coordinates = BehaviorRelay<[Map]>(value: [])
    let currentIndex = BehaviorRelay<Int>(value: 0)
    let isPlaying = BehaviorRelay<Bool>(value: false)

    let locationToRender = PublishSubject<Map>()
    private let disposeBag = DisposeBag()
    private var timer: Disposable?

    private let getMapUseCase: GetMapUseCase

    init(getMapUseCase: GetMapUseCase) {
        self.getMapUseCase = getMapUseCase
        fetchCoordinates()
    }

    private func fetchCoordinates() {
        getMapUseCase.execute()
            .subscribe(onSuccess: { [weak self] data in
                self?.coordinates.accept(data)
            })
            .disposed(by: disposeBag)
    }

    func togglePlay() {
        isPlaying.accept(!isPlaying.value)
        isPlaying.value ? startTimer() : stopTimer()
    }
    
    func moveTo(index: Int) {
        let coords = coordinates.value
        guard index >= 0 && index < coords.count else { return }
        locationToRender.onNext(coords[index])
        currentIndex.accept(index)
    }
    
    private func startTimer() {
        guard timer == nil else { return }
        
        // Set timer dengan interval 1 detik
        timer = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let current = self.currentIndex.value
                let nextIndex = current + 1
                if nextIndex < self.coordinates.value.count {
                    self.moveTo(index: nextIndex)
                } else {
                    self.stopTimer()
                    self.isPlaying.accept(false)
                }
            })
    }

    private func stopTimer() {
        timer?.dispose()
        timer = nil
    }
}
