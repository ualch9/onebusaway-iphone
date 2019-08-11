//
//  OBAWebService+EndpointsCoreData.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

extension OBAWebService.Endpoint {
	public var identifier: String? {
		switch self {
		case .stop(let id), .agency(let id), .route(let id): return id
		case .regions, .stopsForLocation, .stopsForRegion: return nil
		}
	}
	
	public var managedObject: OBAManagedObject.Type {
		switch self {
		case .stop, .stopsForLocation, .stopsForRegion: return CD_OBAStop.self
		case .route: return CD_OBARoute.self
		case .agency: return CD_OBAAgency.self
		case .regions: return CD_OBARegion.self
		}
	}
	
	public var fetchRequest: NSFetchRequest<NSFetchRequestResult> {
		let fetchRequest = self.managedObject.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
		
		if let identifier = self.identifier {
			fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
		}
		
		return fetchRequest
	}
}
