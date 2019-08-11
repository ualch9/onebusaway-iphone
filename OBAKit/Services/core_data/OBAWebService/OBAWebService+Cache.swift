//
//  OBAWebService+Cache.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

extension OBAWebService {
	public class Cache {
		static let dbName = "OneBusAway.sqlite"
		static var sharedAppGroupURL: URL = {
			return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.onebusaway.iphone")!
		}()
		
		let container: NSPersistentContainer
		
		public init() {
			container = NSPersistentContainer(name: "OneBusAway")
			
			// Require the container to load before we proceed.
			let dispatch = DispatchGroup()
			container.loadPersistentStores { (_, error) in
				if let error = error {
					print(error)
					fatalError()
				}
				
				dispatch.leave()
			}
			dispatch.wait()
			
			container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			container.viewContext.automaticallyMergesChangesFromParent = true
		}
	}
}
