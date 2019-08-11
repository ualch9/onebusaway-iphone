//
//  OBAWebService+Endpoints.swift
//  OBAKit
//
//  Created by Alan Chu on 8/10/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import Foundation

extension OBAWebService {
	public enum Endpoint {
		case stop(stopID: String)
		case stopsForLocation(location: CLLocationCoordinate2D)
		case stopsForRegion(region: MKCoordinateRegion)
		
		case route(routeID: String)
		case agency(agencyID: String)
		case regions
		
		/// Returns the URL path for the current case. Except for `regions`, you should cast the returning
		/// string into a URL, relative to the current region's baseURL host. For `regions` only, cast the
		/// returning string into a URL without a `relativeTo` host.
		///
		/// # Example for non-regions
		/// ```
		/// let stopEndpoint: Endpoint = .stop("1_1234")
		/// let url = URL(string: stopEndpoint.urlPath, relativeTo: OBAAPI.shared().baseURL)!
		/// ```
		///
		/// # Example for regions
		///	```
		/// let regionsEndpoint: Endpoint = .regions
		/// let url = URL(string: regionsEndpoint)!
		/// ```
		public var path: String {
			switch self {
			case .stop(let stopID):
				return "/api/where/stop/\(stopID).json"
			case .stopsForLocation(_), .stopsForRegion(_):
				return "/api/where/stops-for-location.json"
			case .route(let routeID):
				return "/api/where/route/\(routeID).json"
			case .agency(let agencyID):
				return "/api/where/agency/\(agencyID).json"
			case .regions:
				return "http://regions.onebusaway.org/regions-v3.json"
			}
		}
		
		public var arguments: [String: String]? {
			switch self {
			case .stopsForLocation(let location):
				return ["lat": "\(location.latitude)",
						"lon": "\(location.longitude)"]
			case .stopsForRegion(let region):
				return ["lat": "\(region.center.latitude)",
						"lon": "\(region.center.longitude)",
						"latSpan": "\(region.span.latitudeDelta)",
						"lonSpan": "\(region.span.longitudeDelta)"]
			default: return nil
			}
		}
		
		/// For handling how to cast data response into an object.
		/// - If `endpointReturnsList` is true, you should cast the response into `OBAListResponse`.
		/// - If `endpointReturnsList` is false, you should cast the response into `OBAEntryResponse`.
		public var endpointReturnsList: Bool {
			switch self {
			case .stop, .stopsForLocation, .stopsForRegion, .route, .agency: return true
			case .regions: return false
			}
		}
	}
}
