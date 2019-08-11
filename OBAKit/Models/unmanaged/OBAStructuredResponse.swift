//
//  OBAStructuredResponse.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import Foundation

/// Expected structure:
/// ```
/// {
///   "data": {
///	    "entry": {},
///	    "references": []
///	  }
/// }
struct OBAEntryResponse<O: OBAManagedObject>: Decodable {
	enum CodingKeys: String, CodingKey {
		case entry, references
	}
	
	let entry: O
	let references: OBAReferences
	
	init(from decoder: Decoder) throws {
		let root = try decoder.container(keyedBy: AnyKey.self)
		let data = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: AnyKey(stringValue: "data"))
		
		self.entry = try data.decode(O.self, forKey: .entry)
		self.references = try data.decode(OBAReferences.self, forKey: .references)
	}
}

/// Expected structure:
/// ```
/// {
///   "data": {
///	    "list": [],
///	    "references": []
///	  }
/// }
struct OBAListResponse<O: OBAManagedObject>: Decodable {
	enum CodingKeys: String, CodingKey {
		case entries = "list"
		case references
	}
	
	let entries: [O]
	let references: OBAReferences
	
	init(from decoder: Decoder) throws {
		let root = try decoder.container(keyedBy: AnyKey.self)
		let data = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: AnyKey(stringValue: "data"))
		
		self.entries = try data.decode([O].self, forKey: .entries)
		self.references = try data.decode(OBAReferences.self, forKey: .references)
	}
}
