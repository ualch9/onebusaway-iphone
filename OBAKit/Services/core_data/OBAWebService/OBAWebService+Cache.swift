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
		static let dbName = "OBAKit.sqlite"
		static var sharedAppGroupURL: URL = {
			return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.onebusaway.iphone")!
		}()
		
		public let container: NSPersistentContainer
		
		init() {
			let mom = NSManagedObjectModel.mergedModel(from: [Bundle(for: OBAWebService.Cache.self)])!
			container = NSPersistentContainer(name: "OBAKit", managedObjectModel: mom)
			
			// Require the container to load before we proceed.
			let dispatch = DispatchGroup()
			dispatch.enter()
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
