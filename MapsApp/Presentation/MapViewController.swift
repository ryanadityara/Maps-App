//
//  MapViewController.swift
//  MapsApp
//
//  Created by Ryan Aditya on 05/05/25.
//

import UIKit
import RxSwift
import MapKit
import RxCocoa

class MapViewController: UIViewController, MKMapViewDelegate {

    private let mapView = MKMapView()
    private let controlContainer = UIView()
    private let playButton = UIButton(type: .system)
    private let slider = UISlider()
    private let timeLabel = UILabel()
    private let speedLabel = UILabel()
    private let timeIcon = UIImageView(image: UIImage(systemName: "clock"))
    private let speedIcon = UIImageView(image: UIImage(systemName: "speedometer"))

    private let viewModel: MapViewModel
    private let disposeBag = DisposeBag()
    private var marker = MKPointAnnotation()
    private var markerView: MKAnnotationView? // ADDED
    private var previousCoordinate: CLLocationCoordinate2D?
    private var isPlaying = false
    private var polylines: [MKPolyline] = []

    // CADisplayLink animation properties
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var animationDuration: TimeInterval = 1.0
    private var animationStartCoord: CLLocationCoordinate2D = .init()
    private var animationEndCoord: CLLocationCoordinate2D = .init()

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        centerMapOnInitialMarker()
    }

    private func setupUI() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
        mapView.delegate = self
        mapView.addAnnotation(marker)

        controlContainer.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        controlContainer.layer.cornerRadius = 12
        controlContainer.layer.shadowColor = UIColor.black.cgColor
        controlContainer.layer.shadowOpacity = 0.1
        controlContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        controlContainer.layer.shadowRadius = 5
        controlContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlContainer)

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .black

        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isContinuous = true

        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .black
        speedLabel.font = .systemFont(ofSize: 14)
        speedLabel.textColor = .black
        timeIcon.tintColor = .black
        speedIcon.tintColor = .black

        let timeStack = UIStackView(arrangedSubviews: [timeIcon, timeLabel])
        timeStack.axis = .horizontal
        timeStack.spacing = 4

        let speedStack = UIStackView(arrangedSubviews: [speedIcon, speedLabel])
        speedStack.axis = .horizontal
        speedStack.spacing = 4

        let infoStack = UIStackView(arrangedSubviews: [timeStack, UIView(), speedStack])
        infoStack.axis = .horizontal
        infoStack.alignment = .center
        infoStack.distribution = .equalCentering

        let playbackStack = UIStackView(arrangedSubviews: [playButton, slider])
        playbackStack.axis = .horizontal
        playbackStack.spacing = 8
        playbackStack.alignment = .center

        let fullStack = UIStackView(arrangedSubviews: [playbackStack, infoStack])
        fullStack.axis = .vertical
        fullStack.spacing = 12
        fullStack.translatesAutoresizingMaskIntoConstraints = false
        controlContainer.addSubview(fullStack)

        NSLayoutConstraint.activate([
            controlContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlContainer.heightAnchor.constraint(equalToConstant: 100),

            fullStack.leadingAnchor.constraint(equalTo: controlContainer.leadingAnchor, constant: 16),
            fullStack.trailingAnchor.constraint(equalTo: controlContainer.trailingAnchor, constant: -16),
            fullStack.topAnchor.constraint(equalTo: controlContainer.topAnchor, constant: 12),
            fullStack.bottomAnchor.constraint(equalTo: controlContainer.bottomAnchor, constant: -12),
        ])
    }

    private func bindViewModel() {
        playButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.isPlaying.toggle()
                let iconName = self.isPlaying ? "stop.fill" : "play.fill"
                self.playButton.setImage(UIImage(systemName: iconName), for: .normal)
                self.viewModel.togglePlay()
            }
            .disposed(by: disposeBag)

        viewModel.locationToRender
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] coord in
                guard let self = self else { return }
                let currentCoord = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
                self.animateMarker(to: currentCoord)

                if let prev = self.previousCoordinate {
                    let bearing = self.calculateBearing(from: prev, to: currentCoord)
                    self.rotateMarker(to: bearing)
                }

                self.previousCoordinate = currentCoord
                self.timeLabel.text = self.format(date: coord.time)
                self.speedLabel.text = "\(Int(coord.speed ?? 0)) Km/h"

                let total = Float(self.viewModel.coordinates.value.count)
                let currentIndex = Float(self.viewModel.currentIndex.value)
                if total > 0 {
                    self.slider.value = currentIndex / total
                }

                self.updateMarkerColor(for: coord.event)

            })
            .disposed(by: disposeBag)

        slider.rx.value
            .skip(1)
            .distinctUntilChanged()
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                guard let self = self else { return }
                let total = Float(self.viewModel.coordinates.value.count)
                guard total > 0 else { return }

                let index = min(Int(value * total), self.viewModel.coordinates.value.count - 1)
                self.viewModel.moveTo(index: index)
            })
            .disposed(by: disposeBag)
    }

    private func centerMapOnInitialMarker() {
        guard let firstCoord = viewModel.coordinates.value.first else { return }
        let initialCoord = CLLocationCoordinate2D(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        marker.coordinate = initialCoord
        let region = MKCoordinateRegion(center: initialCoord, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: false)
        previousCoordinate = initialCoord
        redrawAllPolylines()
    }

    private func redrawAllPolylines() {
        // Reset yang sebelumnya digambar di peta
        mapView.removeOverlays(polylines)
        polylines.removeAll()
        previousCoordinate = nil

        // Loop untuk dibandingkan dengan indeks sebelumnya
        let coords = viewModel.coordinates.value
        for i in 1..<coords.count {
            let from = CLLocationCoordinate2D(latitude: coords[i - 1].latitude, longitude: coords[i - 1].longitude)
            let to = CLLocationCoordinate2D(latitude: coords[i].latitude, longitude: coords[i].longitude)
            drawLine(from: from, to: to, event: coords[i].event)
        }

        // Recreate draw semua garis dan gunakan koordinat terakhir
        if let last = coords.last {
            previousCoordinate = CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude)
        }
    }

    private func drawLine(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, event: String) {
        let color: UIColor
        switch event.lowercased() {
        case "driving": color = MapsColors.mapsBlue
        case "idling": color = MapsColors.mapsGreen
        case "parking": color = MapsColors.mapsGrey
        default: color = MapsColors.mapsGrey
        }

        let coords = [from, to]
        let polyline = ColorPolyline(coordinates: coords, count: coords.count)
        polyline.color = color
        mapView.addOverlay(polyline)
        polylines.append(polyline)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let colorPolyline = overlay as? ColorPolyline {
            let renderer = MKPolylineRenderer(polyline: colorPolyline)
            renderer.strokeColor = colorPolyline.color
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        let identifier = "VehicleMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            annotationView?.glyphText = "🚗"
            annotationView?.markerTintColor = MapsColors.mapsGrey
        } else {
            annotationView?.annotation = annotation
        }

        self.markerView = annotationView
        return annotationView
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH.mm.ss"
        return formatter.string(from: date)
    }

    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        // Convert derajat ke radian
        let lat1 = start.latitude.degreesToRadians
        let lon1 = start.longitude.degreesToRadians
        let lat2 = end.latitude.degreesToRadians
        let lon2 = end.longitude.degreesToRadians

        // Calculate selisih longitude
        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        var degrees = atan2(y, x).radiansToDegrees
        
        // Convert radian ke derajat
        if degrees < 0 {
            degrees += 360
        }
        return degrees
    }

    private func animateMarker(to coordinate: CLLocationCoordinate2D, duration: TimeInterval = 1.0) {
        displayLink?.invalidate()

        guard mapView.view(for: marker) != nil else {
            marker.coordinate = coordinate
            return
        }

        animationStartTime = CACurrentMediaTime()
        animationDuration = duration
        animationStartCoord = marker.coordinate
        animationEndCoord = coordinate

        displayLink = CADisplayLink(target: self, selector: #selector(updateMarkerPosition))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateMarkerPosition() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let fraction = min(elapsed / animationDuration, 1.0)

        let lat = animationStartCoord.latitude + (animationEndCoord.latitude - animationStartCoord.latitude) * fraction
        let lon = animationStartCoord.longitude + (animationEndCoord.longitude - animationStartCoord.longitude) * fraction
        let interpolatedCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        marker.coordinate = interpolatedCoord
        mapView.setCenter(interpolatedCoord, animated: false)

        if fraction >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    private func rotateMarker(to bearing: Double) {
        guard let annotationView = mapView.view(for: marker) else { return }

        UIView.animate(withDuration: 0.3) {
            annotationView.transform = CGAffineTransform(rotationAngle: CGFloat(bearing.degreesToRadians))
        }
    }

    private func updateMarkerColor(for event: String) {
        let color: UIColor
        switch event.lowercased() {
        case "driving": color = MapsColors.mapsBlue
        case "idling": color = MapsColors.mapsGreen
        case "parking": color = MapsColors.mapsGrey
        default: color = MapsColors.mapsGrey
        }

        (markerView as? MKMarkerAnnotationView)?.markerTintColor = color
    }
}
