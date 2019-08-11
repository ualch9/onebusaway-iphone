//
//  CD_OBAModelDAO.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

public class CD_OBAModelDAO: CD_OBAModelPersistenceLayer {
	public static let shared = CD_OBAModelDAO()
	
	public var hideFutureLocationWarnings: Bool = false
	public var ungroupedBookmarksOpen: Bool = false
	public var shareRegionPII: Bool = false
	public var shareLocationPII: Bool = false
	public var shareLogsPII: Bool = false
	
	// MARK: - Web service and caching
	public var webService = OBAWebService()
	public var viewContext: NSManagedObjectContext { return webService.viewContext }
	
	public var currentRegion: CD_OBARegion? {
		get { return self.webService.currentRegion }
		set { self.webService.currentRegion = newValue }
	}
	
	public var mostRecentLocation: CLLocation? {
		get {
			return nil
		} set {
			_ = newValue
		}
	}
	
	// MARK: - Stops
	public var mostRecentStops: [CD_OBAStop] {
		get {
			return []
		} set {
			_ = newValue
		}
	}
	
	public var stopPreferences: NSDictionary{
		get {
			return [:]
		} set {
			_ = newValue
		}
	}
	
	// MARK: - Regions
	public var customRegions: [CD_OBARegion] {
		get {
			let customRegionRequest = CD_OBARegion.sortedFetchRequest
			customRegionRequest.predicate = NSPredicate(format: "isCustom == YES")
			
			return (try? webService.cache.container.viewContext.fetch(customRegionRequest)) ?? []
		} set {
			_ = newValue
		}
	}
	
	public var remoteRegions: [CD_OBARegion] {
		return (try? webService.fetchSync(.regions, as: CD_OBARegion.self)) ?? []
	}
	
	public var allRegions: [CD_OBARegion] {
		return self.customRegions + self.remoteRegions
	}
	
	public var sharedTrips: Set<OBATripDeepLink> {
		get {
			return []
		} set {
			_ = newValue
		}
	}
	
	// MARK: - Alarms
	
	public var alarms: Set<CD_OBAAlarm> {
		get {
			return []
		} set {
			_ = newValue
		}
	}
	
	public func alarm(for key: String) -> CD_OBAAlarm? {
		return nil
	}
}
