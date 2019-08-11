//
//  OBAManagedObject.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

public protocol OBAManagedObject: NSManagedObject, Decodable {
	static var entityName: String { get }
	var identifier: String { get }
}

extension OBAManagedObject {
	static var sortedFetchRequest: NSFetchRequest<Self> {
		let request = fetchedRequest
		request.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
		
		return request
	}
	
	static var fetchedRequest: NSFetchRequest<Self> {
		return NSFetchRequest<Self>(entityName: Self.entityName)
	}
	
	var hashValue: Int {
		return self.identifier.hashValue
	}
}

public enum OBAManagedObjectDecodeError: Error {
	/// The `context` value in the Decoder's `userInfo` is invalid.
	case contextNotFound
	
	/// The specified entity could not be found in the context's graph.
	case entityNotFound
}
