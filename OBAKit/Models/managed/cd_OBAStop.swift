//
//  cd_OBAStop.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData
import CoreLocation
import MapKit

@objc(CD_OBAStop)
public class CD_OBAStop: NSManagedObject, OBAManagedObject, Decodable {
	public class var entityName: String { return "CD_OBAStop" }
	public enum CodingKeys: String, CodingKey {
		case identifier = "id"
		case name, code, direction
		case latitude = "lat"
		case longitude = "lon"
		case routeIDs = "routeIds"
	}

	/// Equivalent to `stopID`.
	@NSManaged public var identifier: String
	@NSManaged public var name: String
	
	/// The stop number. A unique identifier for the stop
	/// within its transit system. In Puget Sound, e.g.,
	/// these stop numbers are actually written on the bus stops.
	@NSManaged public var code: String?
	@NSManaged public var direction: String?
	
	// TODO: handle wheelchair boarding
	/// Mapped from 3 possible API responses:
	/// - `ACCESSSIBLE` == true
	/// - `NOT_ACCESSIBLE` == false
	/// - `UNKNOWN` == nil
//	@NSManaged public var isWheelchairAccessible: Bool
	
	@NSManaged public var latitude: CLLocationDegrees
	@NSManaged public var longitude: CLLocationDegrees
	
	@NSManaged public var routeIDs: NSArray
	
	public var routes: [CD_OBARoute] {
		let ids = routeIDs.compactMap { $0 as? String }
		
		var predicates: [NSPredicate] = []
		for route in ids {
			predicates.append(NSPredicate(format: "identifier == %@", route))
		}
		
		let fetchRequest = CD_OBARoute.fetchedRequest
		fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CD_OBARoute.identifier, ascending: true)]
		
		// TODO: This requires testing, but in theory, because all the related routes
		// are already inserted into SQL from the references of the request response,
		// there shouldn't be any issues with this.
		return (try? self.managedObjectContext?.fetch(fetchRequest)) ?? []
	}
	
	// MARK: - Public Helpers
	public var firstAvailableRouteTypeForStop: CD_OBARouteType {
		return self.routes.first?.routeType ?? .unknown
	}
	
	public var nameWithDirection: String {
		if let direction = self.direction {
			return "\(self.name) [\(direction)]"
		} else {
			return self.name
		}
	}
	
	public var routeNamesAsString: String {
		let bestAvailableNames = self.routes.map { $0.bestAvailableName as String }
		return bestAvailableNames.joined(separator: ", ")
	}
	
	// MARK: - Initializers
	public convenience required init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
			throw OBAManagedObjectDecodeError.contextNotFound
		}
		
		guard let entity = NSEntityDescription.entity(forEntityName: CD_OBAStop.entityName, in: context) else {
			throw OBAManagedObjectDecodeError.entityNotFound
		}
		
		/// Initialize but don't insert into the context yet. Leave inserting until after decoding keys, in case we throw.
		self.init(entity: entity, insertInto: nil)
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.identifier = try container.decode(String.self, forKey: .identifier)
		
		self.name = try container.decode(String.self, forKey: .name)
		self.code = try container.decodeIfPresent(String.self, forKey: .code)
		self.direction = try container.decodeIfPresent(String.self, forKey: .direction)
		
		self.latitude = try container.decode(Double.self, forKey: .latitude)
		self.longitude = try container.decode(Double.self, forKey: .longitude)
		
		self.routeIDs = try container.decode([String].self, forKey: .routeIDs) as NSArray
		
		context.insert(self)
	}
}

// MARK: - MKAnnotation delegate methods
extension CD_OBAStop: MKAnnotation {
	public var title: String? {
		return self.name
	}
	
	public var subtitle: String? {
		let routes = self.routeNamesAsString
		if let direction = self.direction {
			return String(format: NSLocalizedString("text_bound_and_routes_params", comment: ""), direction, routes)
		} else {
			return String(format: NSLocalizedString("text_only_routes_colon_params", comment: ""), routes)
		}
	}
	
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
	}
	
	public var location: CLLocation {
		return CLLocation(latitude: self.latitude, longitude: self.longitude)
	}
}
