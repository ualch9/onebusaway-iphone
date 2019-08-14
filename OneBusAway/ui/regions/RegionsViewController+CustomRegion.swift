//
//  RegionsViewController+CustomRegion.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/12/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import SwiftUI
import CoreData

@available(iOS 13.0, *)
extension RegionsViewController {
	@objc func createCustomRegion() {
		self.editRegion(CD_OBARegion(entity: CD_OBARegion.entity(), insertInto: nil))
	}
	
	@objc func editRegion(_ region: CD_OBARegion) {
		let view = RegionBuilderView()
			.environmentObject(region)
			.environment(\.managedObjectContext, CD_OBAModelDAO.shared.viewContext)
		let host = UIHostingController(rootView: view)
		
		self.navigationController?.present(host, animated: true, completion: nil)
	}
}
