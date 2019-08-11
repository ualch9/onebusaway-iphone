//
//  OBAWebService+Codable.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

/// For saving state.
//extension OBAWebService: Codable {
//	public enum CodingKeys: String, CodingKey {
//		case region
//	}
//
//	public func encode(to encoder: Encoder) throws {
//		var container = encoder.container(keyedBy: CodingKeys.self)
//
//		if let region = self.currentRegion {
//			try container.encode(self.currentRegion?.identifier, forKey: .region)s
//		}
//	}
//
//	public convenience required init(from decoder: Decoder) throws {
//		let container = try decoder.container(keyedBy: CodingKeys.self)
//		self.init()
//		if let region = try container.decodeIfPresent(String.self, forKey: .region) {
//
//		}
//	}
//}
