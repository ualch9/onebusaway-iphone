//
//  OBACoreDataDAO.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

public class OBACoreDataDAO: NSObject, OBAModelPersistenceLayer {
	public var hideFutureLocationWarnings: Bool = false
	public var ungroupedBookmarksOpen: Bool = false
	public var shareRegionPII: Bool = false
	public var shareLocationPII: Bool = false
	public var shareLogsPII: Bool = false
	
	public func readBookmarks() -> [Any] {
		fatalError()
	}
	
	public func writeBookmarks(_ source: [Any]) {
		fatalError()
	}
	
	public func readBookmarkGroups() -> [OBABookmarkGroup] {
		fatalError()
	}
	
	public func write(_ source: [OBABookmarkGroup]) {
		fatalError()
	}
	
	public func readMostRecentStops() -> [Any] {
		fatalError()
	}
	
	public func writeMostRecentStops(_ source: [Any]) {
		fatalError()
	}
	
	public func readStopPreferences() -> [AnyHashable : Any] {
		fatalError()
	}
	
	public func writeStopPreferences(_ stopPreferences: [AnyHashable : Any]) {
		fatalError()
	}
	
	public func readMostRecentLocation() -> CLLocation? {
		fatalError()
	}
	
	public func writeMostRecentLocation(_ mostRecentLocation: CLLocation) {
		fatalError()
	}
	
	public func readVisistedSituationIds() -> Set<AnyHashable> {
		fatalError()
	}
	
	public func writeVisistedSituationIds(_ situationIds: Set<AnyHashable>) {
		fatalError()
	}
	
	public func readAgencyAlerts() -> Set<AnyHashable> {
		fatalError()
	}
	
	public func writeAgencyAlerts(_ agencyAlerts: Set<AnyHashable>) {
		fatalError()
	}
	
	public func readOBARegion() -> OBARegionV2? {
		fatalError()
	}
	
	public func writeOBARegion(_ region: OBARegionV2) {
		fatalError()
	}
	
	public func readSetRegionAutomatically() -> Bool {
		fatalError()
	}
	
	public func writeSetRegionAutomatically(_ setRegionAutomatically: Bool) {
		fatalError()
	}
	
	public func customRegions() -> Set<OBARegionV2> {
		fatalError()
	}
	
	public func addCustomRegion(_ region: OBARegionV2) {
		fatalError()
	}
	
	public func removeCustomRegion(_ region: OBARegionV2) {
		fatalError()
	}
	
	public func sharedTrips() -> Set<OBATripDeepLink> {
		fatalError()
	}
	
	public func addSharedTrip(_ sharedTrip: OBATripDeepLink) {
		fatalError()
	}
	
	public func removeSharedTrip(_ sharedTrip: OBATripDeepLink) {
		fatalError()
	}
	
	public func alarms() -> [OBAAlarm] {
		fatalError()
	}
	
	public func alarm(forKey alarmKey: String) -> OBAAlarm {
		fatalError()
	}
	
	public func add(_ alarm: OBAAlarm) {
		fatalError()
	}
	
	public func removeAlarm(withKey alarmKey: String) {
		fatalError()
	}
}
