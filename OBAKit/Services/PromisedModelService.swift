//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import PromiseKit

// swiftlint:disable force_cast

@objc public class PromisedModelService: OBAModelService {

    // MARK: - Arrival and Departure
    @objc public func requestArrivalAndDeparture(_ instance: OBAArrivalAndDepartureInstanceRef) -> PromiseWrapper {
        let tripInstance = instance.tripInstance
        let request = buildRequestForArrivalAndDeparture(stopID: instance.stopId, tripID: tripInstance.tripId, serviceDate: tripInstance.serviceDate, vehicleID: tripInstance.vehicleId, stopSequence: instance.stopSequence)
        let wrapper = PromiseWrapper(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let arrivalAndDeparture = try self.decodeArrivalAndDeparture(json: networkResponse.object)
            return NetworkResponse(object: arrivalAndDeparture, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @objc public func requestArrivalAndDeparture(convertible: OBAArrivalAndDepartureConvertible) -> PromiseWrapper {
        let request = buildRequestForArrivalAndDeparture(stopID: convertible.stopID, tripID: convertible.tripID, serviceDate: convertible.serviceDate, vehicleID: convertible.vehicleID, stopSequence: convertible.stopSequence)
        let wrapper = PromiseWrapper(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let arrivalAndDeparture = try self.decodeArrivalAndDeparture(json: networkResponse.object)
            return NetworkResponse(object: arrivalAndDeparture, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func buildRequestForArrivalAndDeparture(stopID: String, tripID: String, serviceDate: Int64, vehicleID: String?, stopSequence: Int) -> OBAURLRequest {
        var args = [String: Any]()
        args["tripId"] = tripID
        args["serviceDate"] = serviceDate
        if let vehicleID = vehicleID {
            args["vehicleId"] = vehicleID
        }

        if stopSequence >= 0 {
            args["stopSequence"] = stopSequence
        }

        let escapedStopID = OBAURLHelpers.escapePathVariable(stopID)
        let path = "/api/where/arrival-and-departure-for-stop/\(escapedStopID).json"

        return obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: args)
    }

    private func decodeArrivalAndDeparture(json: Any) throws -> OBAArrivalAndDepartureV2 {
        var error: NSError?

        let entry = modelFactory.getArrivalAndDepartureForStopV2(fromJSON: json as! [AnyHashable: Any], error: &error)
        if let error = error {
            throw error
        }

        return entry
    }

    // MARK: - Stop -> OBAArrivalAndDepartureV2

    @objc public func requestStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> PromiseWrapper {
        let request = buildURLRequestForStopArrivalsAndDepartures(withID: stopID, minutesBefore: minutesBefore, minutesAfter: minutesAfter)
        let promiseWrapper = PromiseWrapper(request: request)

        promiseWrapper.promise = promiseWrapper.promise.then { networkResponse -> NetworkResponse in
            let arrivals = try self.decodeStopArrivals(json: networkResponse.object)
            return NetworkResponse(object: arrivals, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return promiseWrapper
    }

    @objc public func buildURLRequestForStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> OBAURLRequest {
        let args = ["minutesBefore": minutesBefore, "minutesAfter": minutesAfter]
        let escapedStopID = OBAURLHelpers.escapePathVariable(stopID)
        let path = String(format: "/api/where/arrivals-and-departures-for-stop/%@.json", escapedStopID)

        return obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: args)
    }

    private func decodeStopArrivals(json: Any) throws -> OBAArrivalsAndDeparturesForStopV2 {
        var error: NSError?

        let modelObjects = modelFactory.getArrivalsAndDeparturesForStopV2(fromJSON: json as! [AnyHashable: Any], error: &error)
        if let error = error {
            throw error
        }

        return modelObjects
    }

    // MARK: - Trip Details

    /// Trip details for the specified OBATripInstanceRef
    ///
    /// - Parameter tripInstance: The trip instance reference
    /// - Returns: A PromiseWrapper that resolves to an instance of OBATripDetailsV2
    @objc public func requestTripDetails(tripInstance: OBATripInstanceRef) -> PromiseWrapper {
        let request = self.buildTripDetailsRequest(tripInstance: tripInstance)
        let wrapper = PromiseWrapper(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let tripDetails = try self.decodeTripDetails(json: networkResponse.object as! [AnyHashable: Any])
            return NetworkResponse(object: tripDetails, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func decodeTripDetails(json: [AnyHashable: Any]) throws -> OBATripDetailsV2 {
        var error: NSError?
        let model = modelFactory.getTripDetailsV2(fromJSON: json, error: &error)

        if let error = error {
            throw error
        }

        let entry = model.entry as! OBATripDetailsV2
        return entry
    }

    private func buildTripDetailsRequest(tripInstance: OBATripInstanceRef) -> OBAURLRequest {
        var args: [String: Any] = [:]
        if tripInstance.serviceDate > 0 {
            args["serviceDate"] = tripInstance.serviceDate
        }

        if tripInstance.vehicleId != nil {
            args["vehicleId"] = tripInstance.vehicleId
        }

        let escapedTripID = OBAURLHelpers.escapePathVariable(tripInstance.tripId)

        return obaJsonDataSource.buildGETRequest(withPath: "/api/where/trip-details/\(escapedTripID).json", queryParameters: args)
    }

    // MARK: - Agencies with Coverage

    @objc public func requestAgenciesWithCoverage() -> PromiseWrapper {
        let request = buildRequest()
        let wrapper = PromiseWrapper(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let agencies = try self.decodeData(json: networkResponse.object as! [AnyHashable: Any])
            return NetworkResponse(object: agencies, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func buildRequest() -> OBAURLRequest {
        return obaJsonDataSource.buildGETRequest(withPath: "/api/where/agencies-with-coverage.json", queryParameters: nil)
    }

    private func decodeData(json: [AnyHashable: Any]) throws -> [OBAAgencyWithCoverageV2] {
        var error: NSError?
        let listWithRange = modelFactory.getAgenciesWithCoverageV2(fromJson: json, error: &error)

        if let error = error {
            throw error
        }

        let entries = listWithRange.values as! [OBAAgencyWithCoverageV2]
        return entries
    }

    // MARK: - Regional Alerts

    public func requestRegionalAlerts() -> Promise<[AgencyAlert]> {
        return requestAgenciesWithCoverage().promise.then { networkResponse -> Promise<[AgencyAlert]> in
            let agencies = networkResponse.object as! [OBAAgencyWithCoverageV2]
            var requests = agencies.map { self.buildRequest(agency: $0) }

            let obacoRequest = self.buildObacoRequest(region: self.modelDAO.currentRegion!)
            requests.append(obacoRequest)

            let promises = requests.map { request -> Promise<[TransitRealtime_FeedEntity]> in
                return CancellablePromise.go(request: request).then { networkResponse -> Promise<[TransitRealtime_FeedEntity]> in
                    let data = networkResponse.object as! Data
                    let message = try TransitRealtime_FeedMessage(serializedData: data)
                    return Promise(value: message.entity)
                }
            }

            return when(fulfilled: promises).then { nestedEntities in
                let allAlerts: [AgencyAlert] = nestedEntities.reduce(into: [], { (acc, entities) in
                    let alerts = entities.filter { (entity) -> Bool in
                        return entity.hasAlert && AgencyAlert.isAgencyWideAlert(alert: entity.alert)
                    }.compactMap { try? AgencyAlert(feedEntity: $0, agencies: agencies) }
                    acc.append(contentsOf: alerts)
                })
                return Promise(value: allAlerts)
            }
        }
    }

    private func buildObacoRequest(region: OBARegionV2) -> OBAURLRequest {
        var params: [String: Any]?
        if OBAApplication.shared().userDefaults.bool(forKey: OBAShowTestAlertsDefaultsKey) {
            params = ["test": "1"]
        }
        let url = obacoJsonDataSource.constructURL(fromPath: "/api/v1/regions/\(region.identifier)/alerts.pb", params: params)
        let obacoRequest = OBAURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        return obacoRequest
    }

    private func buildRequest(agency: OBAAgencyWithCoverageV2) -> OBAURLRequest {
        let encodedID = OBAURLHelpers.escapePathVariable(agency.agencyId)
        let path = "/api/gtfs_realtime/alerts-for-agency/\(encodedID).pb"
        return unparsedDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}
