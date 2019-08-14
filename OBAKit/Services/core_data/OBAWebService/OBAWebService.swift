//
//  OBAWebService.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import Foundation
import CoreData
import os.log

public class OBAWebService {
	// MARK: - Decoders
	internal let decoder: JSONDecoder
	
	// MARK: - API Arguments
	public var currentRegion: CD_OBARegion? = nil {
		didSet {
			os_log("OBAWebService.currentRegion changed to: %@.", self.currentRegion?.regionName ?? "nil")
			Notifications.didChangeRegion.post()
		}
	}
	
	public static let baseURL = URL(string: "http://api.onebusaway.org/api")!
	fileprivate var reachability = OBAReachability.forInternetConnection()
	static let apiKey = "org.onebusaway.iphone"		// TODO: Make this an environment variable instead
	
	// MARK: - Core Data
	public fileprivate(set) var cache: Cache
	
	public fileprivate(set) var workingContext: NSManagedObjectContext
	public var viewContext: NSManagedObjectContext { return self.cache.container.viewContext }
	
	// MARK: - Initializer
	internal init() {
		self.cache = Cache()
		
		self.workingContext = self.cache.container.newBackgroundContext()
		self.workingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		
		self.decoder = JSONDecoder()
		self.decoder.userInfo[.context] = workingContext
		
		reachability.reachableBlock = { _ in
			Notifications.networkConnected.post()
		}
		
		reachability.unreachableBlock = { _ in
			Notifications.networkDisconnected.post()
		}
		
		reachability.startNotifier()
	}
	
	deinit {
		reachability.stopNotifier()
	}
	
	// MARK: - Networking
	/// Make a request to the appropriate OneBusAway service.
	/// - Parameter requestToMake: The API endpoint to call
	/// - Precondition: `self.currentRegion` is not nil (except if `requestToMake` is `.regions`).
 	public func request(_ requestToMake: Endpoint) -> Promise<Data> {
		return Promise<Data>() { fulfill, reject in
			let url: URL
			
			// Don't allow requests to be made to specific regions if no currentRegion
			// has been set. The exception to this rule is if the request is to get
			// a list of available regions.
			switch requestToMake {
			case .agency, .route, .stop, .stopsForLocation, .stopsForRegion:
				guard let currentRegion = self.currentRegion else {
//					reject(Errors.preconditionFailedMissingRegion)
					fatalError("No region.")
//					return
				}
				
				url = URL(string: requestToMake.path, relativeTo: URL(string: currentRegion.obaBaseURL)!)!
			
			case .regions:
				url = URL(string: requestToMake.path)!
			}
			
			var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
			var queryArgs = [URLQueryItem(name: "key", value: OBAWebService.apiKey)]
			
			if let endpointArguments = requestToMake.arguments {
				queryArgs.append(contentsOf: endpointArguments.map { URLQueryItem(name: $0, value: $1) })
			}
			
			components.queryItems = queryArgs

			// In a real life situation, poor connection (e.g. in tunnel) or
			// 2G speeds can slow down requests. However, for development, this
			// is for testing offline situations (via Network Link Conditioner).
			let timeout: TimeInterval
			#if DEBUG
				timeout = 5.0
			#else
				timeout = 30.0
			#endif
			
			// Ignore local cache, data must be from online.
			let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let data = data,
					let response = response as? HTTPURLResponse,
					(200 ..< 300) ~= response.statusCode,			// is status code 2xx
					error == nil else {
						reject(error ?? NSError(domain: "obaapi", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error."]))
						return
				}
				
				fulfill(data)
			}.resume()
		}
	}
}
