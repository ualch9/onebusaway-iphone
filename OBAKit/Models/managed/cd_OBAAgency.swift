//
//  cd_OBAAgency.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

@objc(CD_OBAAgency)
public class CD_OBAAgency: NSManagedObject, OBAManagedObject, Decodable {
	public class var entityName: String { return "CD_OBAAgency" }
	public enum CodingKeys: String, CodingKey {
		case identifier = "id"
		case name, url, disclaimer
	}
	
	@NSManaged public var url: String
	
	/// Equivalent to `agencyID`.
	@NSManaged public var identifier: String
	@NSManaged public var name: String
	
	/// The disclaimer field is an additional field that includes any legal
	/// disclaimer that transit agencies would like displayed to users when
	/// using the agency’s data in an application.
	@NSManaged public var disclaimer: String?
	
//	@NSManaged public var routes: Set<OBARoute>
	
	required convenience public init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
			throw OBAManagedObjectDecodeError.contextNotFound
		}
		
		guard let entity = NSEntityDescription.entity(forEntityName: CD_OBAAgency.entityName, in: context) else {
			throw OBAManagedObjectDecodeError.entityNotFound
		}
		
		self.init(entity: entity, insertInto: nil)
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.url = try container.decode(String.self, forKey: .url)
		self.identifier = try container.decode(String.self, forKey: .identifier)
		self.name = try container.decode(String.self, forKey: .name)
		
		self.disclaimer = try container.decodeIfPresent(String.self, forKey: .disclaimer)
		
		context.insert(self)
	}
}
