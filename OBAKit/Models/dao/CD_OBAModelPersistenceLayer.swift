//
//  CD_OBAModelPersistenceLayer.swift
//  OBAKit
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

public protocol CD_OBAModelPersistenceLayer {
	var hideFutureLocationWarnings: Bool { get set }
	var ungroupedBookmarksOpen: Bool { get set }
	var shareRegionPII: Bool { get set }
	var shareLocationPII: Bool { get set }
	var shareLogsPII: Bool { get set }
	
//	var bookmarks: Set<CD_OBABookmark> { get set }
//	var bookmarkGroups: Set<CD_OBABookmarkGroup> { get set }
	
	var mostRecentStops: [CD_OBAStop] { get set }
	var stopPreferences: NSDictionary { get set } // TODO: idk what this does so far
	var mostRecentLocation: CLLocation? { get set }
	
	// MARK: Service Alerts
//	var situations: Set<CD_OBASituation> { get set }
//	var agencyAlerts: Set<CD_OBAAgencyAlert> { get set }
	
	// MARK: Regions
	var customRegions: [CD_OBARegion] { get set }
	var remoteRegions: [CD_OBARegion] { get }
	var allRegions: [CD_OBARegion] { get }
	
	// MARK: Shared trips/deep linking
	var sharedTrips: Set<OBATripDeepLink> { get set }
	
	// MARK: Alarms
	var alarms: Set<CD_OBAAlarm> { get set }
	func alarm(for key: String) -> CD_OBAAlarm?
}
