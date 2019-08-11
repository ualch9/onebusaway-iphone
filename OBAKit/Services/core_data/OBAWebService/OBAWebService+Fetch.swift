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
	/// - Parameter type: The entity type to cast the response into. Use `endpoint.managedObject` for this parameter.
	@discardableResult public func fetch<E: OBAManagedObject>(_ endpoint: Endpoint, as type: E.Type) -> Promise<[E]> {
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
	
	/// Request a specific OneBusAway entry synchronously. This method handles Core Data. For example, if the stop you
	/// request already exists in the Core Data graph, it will update that stop with the new data from this request
	/// instead of inserting a new entity.
	/// - important: This method blocks the main thread.
	/// - throws: Network errors, decoding errors, core data errors, etc.
	/// - Parameter endpoint: Which endpoint to use.
	/// - Parameter type: The entity type to cast the response into. Use `endpoint.managedObject` for this parameter.
	public func fetchSync<E: OBAManagedObject>(_ endpoint: Endpoint, as type: E.Type) throws -> [E] {
		let dispatch = DispatchGroup()
		var result: Result<[E]>!
		
		self.fetch(endpoint, as: type).then {
			result = .fulfilled($0)
		}.catch {
			result = .rejected($0)
		}.always {
			dispatch.leave()
		}
		dispatch.wait()
		
		switch result! {
		case .fulfilled(let response): return response
		case .rejected(let error): throw error
		}
	}
}
