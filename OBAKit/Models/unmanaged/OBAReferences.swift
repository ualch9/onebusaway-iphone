//
//  OBAReferences.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

public struct OBAReferences: Decodable {
	public let agencies: Set<CD_OBAAgency>
	public let routes: Set<CD_OBARoute>
//	public let situations
	public let stops: Set<CD_OBAStop>
//	public let trips
}
