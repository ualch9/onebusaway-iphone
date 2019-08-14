//
//  OBAWebService+Notifications.swift
//  OBAKit
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

extension OBAWebService {
	/// Example usage: `OBAWebService.Notifications.didChangeRegion.name`.
	public enum Notifications {
		case didChangeRegion
		case networkDisconnected
		case networkConnected
		
		public var name: Notification.Name {
			return Notification.Name("OBAWebServiceNotification_\(self)")
		}
		
		public func post(with object: Any? = nil) {
			NotificationCenter.default.post(name: self.name, object: object)
		}
	}
}
