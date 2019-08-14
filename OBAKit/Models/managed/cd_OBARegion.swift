//
//  cd_OBARegion.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import CoreData

@objc(CD_OBARegion)
public class CD_OBARegion: NSManagedObject, OBAManagedObject, Decodable {
	public class var entityName: String { return "CD_OBARegion" }
	public enum CodingKeys: String, CodingKey {
		case identifier = "id"
		case regionName
		case obaBaseURL = "obaBaseUrl"
		case regionBounds = "bounds"
		case isActive = "active"
		case isExperimental = "experimental"
		
		case supportsSiriRealtimeAPIs = "supportsSiriRealtimeApis"
		case supportsOBARealtimeAPIs = "supportsObaRealtimeApis"
		case supportsOBADiscoveryAPIs = "supportsObaDiscoveryApis"
		case language
		
		case facebookURL = "facebookUrl"
		case twitterURL = "twitterUrl"
		case contactEmail
		
		case siriBaseURL = "siriBaseUrl"
		case paymentWarningBody, paymentWarningTitle, paymentAppStoreIdentifier
		case paymentAppURLScheme = "paymentAppUrlScheme"
	}
	
	// MARK: Base properties
	@NSManaged public var identifier: String
	@NSManaged public var regionName: String
	@NSManaged public var obaBaseURL: String
	@NSManaged public var regionBounds: Data?		// raw value is a JSON array.
	
	/// Signifies that this was created in the RegionBuilderViewController
	@NSManaged public var isCustom: Bool
	@NSManaged public var isActive: Bool
	@NSManaged public var isExperimental: Bool
	
	// MARK: Supporting extensions
	@NSManaged public var supportsSiriRealtimeAPIs: Bool
	@NSManaged public var supportsOBARealtimeAPIs: Bool
	@NSManaged public var supportsOBADiscoveryAPIs: Bool
	
	@NSManaged public var language: String?
	
	// MARK: Optional contact information
	@NSManaged public var facebookURL: String?
	@NSManaged public var twitterURL: String?
	@NSManaged public var contactEmail: String
	@NSManaged public var siriBaseURL: String?		 	// Service Interface for Real Time (SIRI)
	
	// MARK: Payments
	@NSManaged public var paymentWarningBody: String?
	@NSManaged public var paymentWarningTitle: String?
	@NSManaged public var paymentAppURLScheme: String?
	@NSManaged public var paymentAppStoreIdentifier: String?
	
	// MARK: Relationships
//	@NSManaged public var stops: Set<OBAStop>
//	@NSManaged public var agencies: Set<OBAAgency>
	
	// TODO: Replace force tries.
	public var bounds: [OBARegionBounds] {
		get {
			guard let regionBounds = self.regionBounds else { return [] }
			return try! JSONDecoder().decode([OBARegionBounds].self, from: regionBounds)
		} set {
			self.regionBounds = try! JSONEncoder().encode(newValue)
		}
	}
	
	// MARK: - Region name
	static func cleanUpRegionName(_ dirtyRegionName: String) -> String {
		guard !dirtyRegionName.isEmpty else { return dirtyRegionName }
		
		let regex = try! NSRegularExpression(pattern: "\\s?\\(?beta\\)?", options: .caseInsensitive)
		return regex.stringByReplacingMatches(in: dirtyRegionName, options: [], range: NSRange(location: 0, length: dirtyRegionName.count), withTemplate: "")
	}
	
	// MARK: - Payment App
	public var supportsMobileFarePayment: Bool {
		return self.paymentAppURLScheme != nil
	}
	
	public var paymentAppDoesNotCoverFullRegion: Bool {
		return self.paymentWarningTitle != nil && self.paymentWarningBody != nil
	}
	
	public var paymentAppDeepLinkURL: URL? {
		guard let paymentURLScheme = self.paymentAppURLScheme else { return nil }
		return URL(string: "\(paymentURLScheme)://onebusaway")
	}
	
	// MARK: - Initializers
	public convenience required init(from decoder: Decoder) throws {
		guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
			throw OBAManagedObjectDecodeError.contextNotFound
		}
		
		guard let entity = NSEntityDescription.entity(forEntityName: CD_OBARegion.entityName, in: context) else {
			throw OBAManagedObjectDecodeError.entityNotFound
		}
		
		/// Initialize but don't insert into the context yet. Leave inserting until after decoding keys, in case we throw.
		self.init(entity: entity, insertInto: nil)
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.identifier = "\(try container.decode(Int.self, forKey: .identifier))"
		self.regionName = CD_OBARegion.cleanUpRegionName(try container.decode(String.self, forKey: .regionName))
		self.obaBaseURL = try container.decode(String.self, forKey: .obaBaseURL)
		self.bounds = try container.decode([OBARegionBounds].self, forKey: .regionBounds)
		
		self.isActive = try container.decode(Bool.self, forKey: .isActive)
		self.isExperimental = try container.decode(Bool.self, forKey: .isExperimental)
		
		self.supportsSiriRealtimeAPIs = try container.decode(Bool.self, forKey: .supportsSiriRealtimeAPIs)
		self.supportsOBARealtimeAPIs = try container.decode(Bool.self, forKey: .supportsOBARealtimeAPIs)
		self.supportsOBADiscoveryAPIs = try container.decode(Bool.self, forKey: .supportsOBADiscoveryAPIs)
		
		self.language = try container.decodeIfPresent(String.self, forKey: .language)
		
		self.facebookURL = try container.decodeIfPresent(String.self, forKey: .facebookURL)
		self.twitterURL = try container.decodeIfPresent(String.self, forKey: .twitterURL)
		self.contactEmail = try container.decode(String.self, forKey: .contactEmail)
		self.siriBaseURL = try container.decodeIfPresent(String.self, forKey: .siriBaseURL)
		
		self.paymentWarningBody = try container.decodeIfPresent(String.self, forKey: .paymentWarningBody)
		self.paymentWarningTitle = try container.decodeIfPresent(String.self, forKey: .paymentWarningTitle)
		self.paymentAppURLScheme = try container.decodeIfPresent(String.self, forKey: .paymentAppURLScheme)
		self.paymentAppStoreIdentifier = try container.decodeIfPresent(String.self, forKey: .paymentAppStoreIdentifier)
		
		context.insert(self)
	}
	
	// MARK: - Other Public Methods
	
	/// Tests whether this is a valid region object.
	public var isValidModel: Bool {
		return self.obaBaseURL.hasPrefix("https") && !self.regionName.isEmpty
//		return self.obaBaseURL.scheme == "https" && !self.regionName.isEmpty
	}
	
	// MARK: - Public Location-Related Methods
	public func distance(from location: CLLocation) -> CLLocationDistance {
		var distance: Double = .greatestFiniteMagnitude	// Basically DBL_MAX
		let latitude = location.coordinate.latitude
		let longitude = location.coordinate.longitude
		
		for bound in self.bounds {
			let thisDistance: Double
			
			if 	bound.latitude - bound.latitudeSpan <= latitude && latitude <= bound.latitude + bound.latitudeSpan &&
				bound.longitude - bound.longitudeSpan <= longitude && latitude <= bound.longitude + bound.longitudeSpan {
				thisDistance = 0
			} else {
				let boundLocation = CLLocation(latitude: bound.latitude, longitude: bound.longitude)
				thisDistance = location.distance(from: boundLocation)
			}
			
			if thisDistance < distance { distance = thisDistance }
		}
		
		return distance
	}
	
	public var serviceRect: MKMapRect {
		var minX: Double = .greatestFiniteMagnitude
		var minY: Double = .greatestFiniteMagnitude
		var maxX: Double = .leastNormalMagnitude
		var maxY: Double = .leastNormalMagnitude
		
		for bound in self.bounds {
			let a = MKMapPoint(CLLocationCoordinate2D(latitude: bound.latitude + bound.latitudeSpan / 2,
													  longitude: bound.longitude - bound.longitudeSpan / 2))
			
			let b = MKMapPoint(CLLocationCoordinate2D(latitude: bound.latitude - bound.latitudeSpan / 2,
													  longitude: bound.longitude + bound.longitudeSpan / 2))
			
			minX = .minimum(minX, .minimum(a.x, b.x))
			minY = .minimum(minY, .minimum(a.y, b.y))
			maxX = .maximum(maxX, .maximum(a.x,	b.x))
			maxY = .maximum(maxY, .maximum(a.y, b.y))
		}
		
		return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
	}
	
	/// The location coordinate in the center of the `serviceRect`.
	public var centerCoordinate: CLLocationCoordinate2D {
		let rect = self.serviceRect
		let centerPoint = MKMapPoint(x: rect.midX, y: rect.midY)
		
		return centerPoint.coordinate
	}
}
