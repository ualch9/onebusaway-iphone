//
//  OBAArrivalAndDepartureConvertible.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 Defines the common properties exposed by classes like OBAAlarm and OBATripDeepLink
 that can be used to retrieve an OBAArrivalAndDepartureV2 from the server.
 */
@protocol OBAArrivalAndDepartureConvertible<NSObject, NSCopying>
@property(nonatomic,copy,readonly) NSString *stopID;
@property(nonatomic,copy,readonly) NSString *tripID;
@property(nonatomic,assign,readonly) long long serviceDate;
@property(nonatomic,copy,readonly) NSString *vehicleID;
@property(nonatomic,assign,readonly) NSInteger stopSequence;
@end

NS_ASSUME_NONNULL_END
