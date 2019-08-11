//
//  OBAWebService+Fetch.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

extension OBAWebService {
	/// Request a specific OneBusAway entry. This method handles Core Data. For example, if the stop you
	/// request already exists in the Core Data graph, it will update that stop with the new data from this request
	/// instead of inserting a new entity.
	/// - Parameter endpoint: Which endpoint to use.
	/// - Parameter Type: The entity type to cast the response into. Use `endpoint.managedObject` for this parameter.
	public func fetch<E: OBAManagedObject>(endpoint: Endpoint, type: E.Type) -> Promise<[E]> {
		return self.request(endpoint).then { (response) -> Promise<[E]> in
			if endpoint.endpointReturnsList {
				let entryResponse = try self.decoder.decode(OBAEntryResponse<E>.self, from: response)
				
				return Promise<[E]> { fulfill, reject in
					do {
						try self.workingContext.save()
					} catch {
						reject(error)
					}
					fulfill([entryResponse.entry])
				}
			} else {
				let listResponse = try self.decoder.decode(OBAListResponse<E>.self, from: response)
				return Promise<[E]> { fulfill, reject in
					do {
						try self.workingContext.save()
					} catch {
						reject(error)
					}
					fulfill(listResponse.entries)
				}
			}
		}
	}
}
