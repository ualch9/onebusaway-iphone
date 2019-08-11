//
//  Codable+AnyKey.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

/// Allows us to access an arbitrary value in a Decoder.
/// For example, OBA API responses generally includes metadata about the request in the body, but we are
/// interested in only the resulting data. With this CodingKey, we can dial into the data directly.
/// # Example
/// ```
/// let container = try decoder.container(keyedBy: AnyKey.self)
/// let dataContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: AnyKey(stringValue: "data"))
/// ```
struct AnyKey: CodingKey {
	var stringValue: String
	var intValue: Int?
	
	init(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}
	
	init(intValue: Int) {
		self.stringValue = String(intValue)
		self.intValue = intValue
	}
}
