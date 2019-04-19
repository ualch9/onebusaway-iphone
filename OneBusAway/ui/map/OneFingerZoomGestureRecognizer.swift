//
//  OneFingerZoomGestureRecognizer.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 4/4/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import MapKit

enum AGSSingleFingerZoomMode {
    case Google
    case UpOutDownIn(centeredOnTap:Bool)
    case UpInDownOut(centeredOnTap:Bool)

    func translateScaleFactor(factor: Double) -> Double {
        return -factor
    }
}

@objc class OneFingerZoomGestureRecognizer: UIGestureRecognizer {
    var scalePower: Double = 5.0
    var zoomMode: AGSSingleFingerZoomMode = .Google

    private var anchorPoint: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        guard let mapView = self.view as? MKMapView else {
            print("You should only apply \(type(of: self)) to an MKMapView!")
            self.state = .failed
            return
        }

        guard touches.count == 1 else {
            // Single finger only
            self.state = .cancelled
            return
        }

        if let tap = touches.first {
            guard tap.tapCount <= 2 else {
                // Second tap becomes the drag, so no more than 2 taps allowed
                self.state = .cancelled
                return
            }

            if tap.tapCount == 2 {
                // We're doing the drag, so remember where we tapped
                self.anchorPoint = self.location(in: mapView)
                self.state = .began
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard let mapView = self.view as? MKMapView else {
            print("You should only apply \(type(of: self)) to an MKMapView!")
            state = .failed
            return
        }

        guard [.began, .changed].contains(state) else {
            return
        }

        guard touches.count == 1 else {
            state = .cancelled
            return
        }

        guard let touch = touches.first else {
            return
        }

        let prevLoc = touch.previousLocation(in: mapView)
        let thisLoc = touch.location(in: mapView)

        if prevLoc.equalTo(thisLoc) {
            return
        }

        let diff = Double(thisLoc.y - prevLoc.y)

        // Scale ratio is determined by taking a proportion of the screen height we've dragged, and raising by a power.
        let scaleRatio = pow(1 + (diff / Double(mapView.frame.height)), self.scalePower)

        print("ZOOM! Scale Ratio: \(scaleRatio)")

        let ugh = Int(mapView.oba_zoomLevel())
        let currentZoom = Double(ugh)
        let newZoom = currentZoom * scaleRatio
        let clamped = UInt(newZoom)
        print("Zoom to level \(clamped)")

        mapView.oba_setCenter(mapView.centerCoordinate, zoomLevel: clamped, animated: false)

        // Zoom in/out around the tap point
        // mapView.zoomWithFactor(scaleRatio, atAnchorPoint: self.anchorPoint!, animated: false)

        // --or--

        // Zoom in/out around the center of the map view
        // let newScale = mapView.mapScale * scaleRatio
        // mapView.zoomToScale(newScale, animated: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.state = .ended
    }

    override func reset() {
        self.anchorPoint = nil
    }
}
