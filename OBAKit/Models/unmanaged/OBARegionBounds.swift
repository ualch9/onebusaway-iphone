//
//  OBARegionBounds.swift
//  OBAKit
//
//  Created by Alan Chu on 7/6/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

public struct OBARegionBounds: Codable {
	public enum CodingKeys: String, CodingKey {
		case latitude = "lat"
		case latitudeSpan = "latSpan"
		case longitude = "lon"
		case longitudeSpan = "lonSpan"
	}
	
	public var latitude: Double
	public var latitudeSpan: Double
	public var longitude: Double
	public var longitudeSpan: Double
}
