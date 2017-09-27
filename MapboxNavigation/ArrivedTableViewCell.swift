//
//  ArrivedTableViewCell.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 9/26/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation


class ArrivedTableViewCell: UITableViewCell, MGLMapViewDelegate {

    @IBOutlet weak var feedbacksAdded: UILabel!
    @IBOutlet weak var mapView: NavigationMapView!
    
    static let mapInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    override func awakeFromNib() {
        mapView.delegate = self
    }
    var route: Route?
    
    var feedbacks: [CoreFeedbackEvent]? {
        didSet {
            guard let feedbacks = feedbacks else { return }
            updateFeedbacks(with: feedbacks)
        }
    }
    
    private func updateMap(with route: Route) {
        mapView.showRoute(route)
        
        if let coordinates = route.coordinates {
            mapView.showRoute(route)
            let polyline = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
            mapView.setVisibleCoordinateBounds(polyline.overlayBounds, edgePadding: ArrivedTableViewCell.mapInsets, animated: false)
        }
    }
    private func updateFeedbacks(with feedbacks: [CoreFeedbackEvent]) {
        feedbacksAdded.text = "\(feedbacks.count) feedbacks added"
    }
    
    //MARK: - MGLMapViewDelegate Methods
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        guard let route = route else { return }
        updateMap(with: route)
    }
}
