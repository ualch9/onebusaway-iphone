//
//  cd_OBARoute.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

@objc(CD_OBARoute)
public class CD_OBARoute: NSManagedObject, OBAManagedObject, Decodable {
	public class var entityName: String { return "CD_OBARoute" }
	public enum CodingKeys: String, CodingKey {
		// Required
		case identifier = "id"
		case routeType = "type"
		
		// Optional
		case shortName, longName
	}
	
	/// Equivalent to `routeID`.
	@NSManaged public var identifier: String
	@NSManaged public var routeType: CD_OBARouteType
	
	// Agencies are not required to specify both a shortName and longName,
	// thought they must specify at least one. Some will specify one but not
	// the other. Others will include both. Confounding matters even more, some
	// agencies don’t specify a longName but do specify a description that’s
	// effectively a longName. The result is that care must be taken when
	// constructing a route name by using the information that you’re actually
	// given.
	@NSManaged public var shortName: String?
	@NSManaged public var longName: String?
	
//	@NSManaged public var agency: OBAAgency?
//	@NSManaged public var stops: Set<OBAStop>
	
	@available(*, deprecated, renamed: "bestAvailableName")
	public var safeShortName: String { return self.bestAvailableName }
	
	public var bestAvailableName: String {
		return self.shortName ?? self.longName ?? ""
	}
	
	/// An amalgamation of shortName and longName
	public var fullRouteName: String {
		var pieces = [String]()
		
		if let shortName = self.shortName {
			pieces.append(shortName)
		}
		
		if let longName = self.longName {
			pieces.append(longName)
		}
		
		guard pieces.count > 1 else { return pieces.joined() }
		
		return pieces.joined(separator: " - ")
	}
	
	required convenience public init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
			throw OBAManagedObjectDecodeError.contextNotFound
		}
		
		guard let entity = NSEntityDescription.entity(forEntityName: CD_OBARoute.entityName, in: context) else {
			throw OBAManagedObjectDecodeError.entityNotFound
		}
		
		/// Initialize but don't insert into the context yet. Leave inserting until after decoding keys, in case we throw.
		self.init(entity: entity, insertInto: nil)
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.identifier = try container.decode(String.self, forKey: .identifier)
		self.routeType = try container.decode(CD_OBARouteType.self, forKey: .routeType)
		
		self.shortName = try container.decodeIfPresent(String.self, forKey: .shortName)
		self.longName = try container.decodeIfPresent(String.self, forKey: .longName)
		
		context.insert(self)
	}
	
	public func compareUsingName(_ otherStop: CD_OBARoute) -> ComparisonResult {
		return self.bestAvailableName.compare(otherStop.bestAvailableName, options: .numeric)
	}
}

@objc public enum CD_OBARouteType: Int16, Codable {
	case lightRail = 0
	case metro = 1
	case train = 2
	case bus = 3
	case ferry = 4
	case unknown = 999
}

