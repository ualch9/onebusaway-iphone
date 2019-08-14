//
//  RegionBuilderView.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/12/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import SwiftUI
import CoreData

// TODO: This is for prototyping. We need to make a form that's iOS 12 friendly.
@available(iOS 13.0, *)
struct RegionBuilderView: View {
	@EnvironmentObject var region: CD_OBARegion
	@Environment(\.managedObjectContext) var context: NSManagedObjectContext
	
	@Environment(\.presentationMode) private var presentationMode
	
	@State var error: String = "" {
		didSet {
			isError = !error.isEmpty
		}
	}
	@State var isError: Bool = false
    
	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Auto generated identifier")) {
					TextField("Tap SAVE to generate ID", text: $region.identifier)
						.disabled(true)
				}
				
				Section(header: Text("Required Data")) {
					TextField("OBA Base URL", text: $region.obaBaseURL)
						.keyboardType(.URL)
					TextField("Region Name", text: $region.regionName)
				}

				Section(header: Text("Optional Data")) {
					Toggle(isOn: $region.supportsOBARealtimeAPIs) {
						Text("Supports OBA Realtime APIs")
					}

					Toggle(isOn: $region.isActive) {
						Text("Is Active")
					}
					
					TextField("Contact Email", text: $region.contactEmail)
						.keyboardType(.emailAddress)
				}
			}
			.navigationBarTitle("Custom Region")
			.navigationBarItems(trailing: Button(action: {
				self.saveRegion()
			}, label: {
				Text("Save")
			}))
			.alert(isPresented: $isError) {
				Alert(title: Text("Error"), message: Text(verbatim: self.error), dismissButton: .default(Text("OK")))
			}
		}
    }
	
	func saveRegion() {
		self.region.isCustom = true
		
		if !self.region.isInserted {
			self.region.identifier = UUID().uuidString
			self.context.insert(self.region)
		}
		
		do {
			try self.context.save()
			self.error = "This is not an error. Ignore the title. Save successful, please dismiss this modal manually by swiping down."
		} catch {
			self.error = error.localizedDescription
		}
	}
}

#if DEBUG
struct RegionBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        RegionBuilderView()
    }
}
#endif
