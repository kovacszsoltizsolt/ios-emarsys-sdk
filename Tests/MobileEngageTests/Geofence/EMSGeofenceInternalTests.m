//
//  Copyright © 2020 Emarsys. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <CoreLocation/CoreLocation.h>
#import "EMSGeofenceInternal.h"
#import "EMSRequestFactory.h"
#import "EMSRequestManager.h"
#import "EMSGeofenceResponseMapper.h"
#import "EMSResponseModel.h"
#import "NSError+EMSCore.h"
#import "EMSGeofenceResponse.h"
#import "EMSGeofenceGroup.h"
#import "EMSGeofence.h"
#import "EMSGeofenceTrigger.h"

@interface EMSGeofenceInternalTests : XCTestCase

@property(nonatomic, strong) EMSGeofenceInternal *geofenceInternal;
@property(nonatomic, strong) EMSRequestFactory *mockRequestFactory;
@property(nonatomic, strong) EMSRequestManager *mockRequestManager;
@property(nonatomic, strong) EMSGeofenceResponseMapper *mockResponseMapper;
@property(nonatomic, strong) EMSRequestModel *mockRequestModel;
@property(nonatomic, strong) EMSResponseModel *mockResponseModel;
@property(nonatomic, strong) id mockLocationManager;
@property(nonatomic, assign) double refreshRadiusRatio;

@end

@implementation EMSGeofenceInternalTests

- (void)setUp {
    _mockRequestFactory = OCMClassMock([EMSRequestFactory class]);
    _mockRequestManager = OCMClassMock([EMSRequestManager class]);
    _mockRequestModel = OCMClassMock([EMSRequestModel class]);
    _mockResponseModel = OCMClassMock([EMSResponseModel class]);
    _mockResponseMapper = OCMClassMock([EMSGeofenceResponseMapper class]);

    _mockLocationManager = OCMClassMock([CLLocationManager class]);

    OCMStub([self.mockRequestFactory createGeofenceRequestModel]).andReturn(self.mockRequestModel);

    _geofenceInternal = [[EMSGeofenceInternal alloc] initWithRequestFactory:self.mockRequestFactory
                                                             requestManager:self.mockRequestManager
                                                             responseMapper:self.mockResponseMapper
                                                            locationManager:self.mockLocationManager];
    _refreshRadiusRatio = 0.3;
}

- (void)tearDown {
    [self.mockLocationManager stopMocking];
}

- (void)testInit_requestFactory_mustNotBeNil {
    @try {
        [[EMSGeofenceInternal alloc] initWithRequestFactory:nil
                                             requestManager:self.mockRequestManager
                                             responseMapper:self.mockResponseMapper
                                            locationManager:self.mockLocationManager];
        XCTFail(@"Expected Exception when requestFactory is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: requestFactory");
    }
}

- (void)testInit_requestManager_mustNotBeNil {
    @try {
        [[EMSGeofenceInternal alloc] initWithRequestFactory:self.mockRequestFactory
                                             requestManager:nil
                                             responseMapper:self.mockResponseMapper
                                            locationManager:self.mockLocationManager];
        XCTFail(@"Expected Exception when requestManager is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: requestManager");
    }
}

- (void)testInit_responseMapper_mustNotBeNil {
    @try {
        [[EMSGeofenceInternal alloc] initWithRequestFactory:self.mockRequestFactory
                                             requestManager:self.mockRequestManager
                                             responseMapper:nil
                                            locationManager:self.mockLocationManager];
        XCTFail(@"Expected Exception when responseMapper is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: responseMapper");
    }
}

- (void)testInit_locationManager_mustNotBeNil {
    @try {
        [[EMSGeofenceInternal alloc] initWithRequestFactory:self.mockRequestFactory
                                             requestManager:self.mockRequestManager
                                             responseMapper:self.mockResponseMapper
                                            locationManager:nil];
        XCTFail(@"Expected Exception when locationManager is nil!");
    } @catch (NSException *exception) {
        XCTAssertEqualObjects(exception.reason, @"Invalid parameter not satisfying: locationManager");
    }
}

- (void)testFetchGeofence {
    OCMStub([self.mockRequestManager submitRequestModelNow:self.mockRequestModel
                                              successBlock:([OCMArg invokeBlockWithArgs:@"testRequestId",
                                                                                        self.mockResponseModel,
                                                                                        nil])
                                                errorBlock:[OCMArg any]]);

    [self.geofenceInternal fetchGeofences];

    OCMVerify([self.mockRequestManager submitRequestModelNow:self.mockRequestModel
                                                successBlock:[OCMArg any]
                                                  errorBlock:[OCMArg any]]);
    OCMVerify([self.mockResponseMapper mapFromResponseModel:self.mockResponseModel]);
}

- (void)testRequestAlwaysAuthorization {
    [self.geofenceInternal requestAlwaysAuthorization];

    OCMVerify([self.mockLocationManager requestAlwaysAuthorization]);
}

- (void)testGeofenceLimit {
    XCTAssertEqual([self.geofenceInternal geofenceLimit], 20);
}

- (void)testEnable {
    OCMStub([self.mockLocationManager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    [self.geofenceInternal enableWithCompletionBlock:^(NSError *error) {
    }];

    OCMVerify([self.mockLocationManager startUpdatingLocation]);
}

- (void)testEnable_callsCompletionBlockWithError_whenAuthorizationStatusNotAlwaysAuthorized {
    NSError *expectedError = [NSError errorWithCode:1401
                               localizedDescription:@"LocationManager authorization status must be AuthorizedAlways!"];

    OCMStub([self.mockLocationManager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedWhenInUse);
    OCMReject([self.mockLocationManager startUpdatingLocation]);

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"waitForError"];
    __block NSError *returnedError = nil;
    [self.geofenceInternal enableWithCompletionBlock:^(NSError *error) {
        returnedError = error;
        [expectation fulfill];
    }];
    XCTWaiterResult waiterResult = [XCTWaiter waitForExpectations:@[expectation]
                                                          timeout:1];

    XCTAssertEqual(waiterResult, XCTWaiterResultCompleted);
    XCTAssertEqualObjects(returnedError, expectedError);
}

- (void)testEnable_callsCompletionBlockWithNil_whenAuthorizationStatusISAlwaysAuthorized {
    OCMStub([self.mockLocationManager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"waitForError"];
    __block NSError *returnedError = nil;
    [self.geofenceInternal enableWithCompletionBlock:^(NSError *error) {
        returnedError = error;
        [expectation fulfill];
    }];
    XCTWaiterResult waiterResult = [XCTWaiter waitForExpectations:@[expectation]
                                                          timeout:1];

    XCTAssertEqual(waiterResult, XCTWaiterResultCompleted);
    XCTAssertNil(returnedError);
}

- (void)testEnable_shouldNotCrash_whenThereIsNoCompletionBlock {
    OCMStub([self.mockLocationManager authorizationStatus]).andReturn(kCLAuthorizationStatusAuthorizedAlways);

    [self.geofenceInternal enableWithCompletionBlock:nil];
}

- (void)testEnable_delegatesToEnableWithCompletionBlock {
    EMSGeofenceInternal *partialGeofenceInternal = OCMPartialMock(self.geofenceInternal);

    [partialGeofenceInternal enable];

    OCMVerify([partialGeofenceInternal enableWithCompletionBlock:nil]);
}

- (void)testRegisterGeofences_shouldBeCalled_whenLocationUpdated {
    CLLocation *expectedLocation = [[CLLocation alloc] initWithLatitude:12.34
                                                              longitude:56.78];

    EMSGeofenceInternal *partialGeofenceInternal = OCMPartialMock(self.geofenceInternal);

    [partialGeofenceInternal locationManager:self.mockLocationManager
                          didUpdateLocations:@[expectedLocation]];

    OCMVerify([partialGeofenceInternal registerGeofences]);

    XCTAssertEqualObjects(partialGeofenceInternal.currentLocation, expectedLocation);
}

- (void)testRegisterGeofences_shouldBeCalled_afterFetchingSucceeded {
    EMSGeofenceInternal *partialGeofenceInternal = OCMPartialMock(self.geofenceInternal);
    EMSGeofenceResponse *expectedGeofenceResponse = OCMClassMock([EMSGeofenceResponse class]);

    OCMStub([self.mockRequestManager submitRequestModelNow:self.mockRequestModel
                                              successBlock:([OCMArg invokeBlockWithArgs:@"testRequestId",
                                                                                        self.mockResponseModel,
                                                                                        nil])
                                                errorBlock:[OCMArg any]]);
    OCMStub([self.mockResponseMapper mapFromResponseModel:self.mockResponseModel]).andReturn(expectedGeofenceResponse);

    [partialGeofenceInternal fetchGeofences];

    OCMVerify([partialGeofenceInternal registerGeofences]);
    XCTAssertEqualObjects(partialGeofenceInternal.geofenceResponse, expectedGeofenceResponse);
}

- (void)testRegisterGeofences_shouldNotRegister_whenCurrentLocation_andGeofenceResponse_areNotAvailable {
    OCMReject([self.mockLocationManager startMonitoringForRegion:[OCMArg any]]);

    [self.geofenceInternal registerGeofences];
}

- (void)testRegisterGeofences {
    CLLocationCoordinate2D emarsysLocation = CLLocationCoordinate2DMake(47.493160, 19.058355);
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:emarsysLocation.latitude
                                                             longitude:emarsysLocation.longitude];
    CLCircularRegion *region1 = [[CLCircularRegion alloc] initWithCenter:emarsysLocation
                                                                  radius:10
                                                              identifier:@"1"];
    CLCircularRegion *region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.493812, 19.058537)
                                                                  radius:10
                                                              identifier:@"2"];
    CLCircularRegion *region3 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.492292, 19.056440)
                                                                  radius:10
                                                              identifier:@"3"];
    CLCircularRegion *regionArea = [[CLCircularRegion alloc] initWithCenter:emarsysLocation
                                                                     radius:163.598 * self.refreshRadiusRatio
                                                                 identifier:@"EMSRefreshArea"];
    CLCircularRegion *region4 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.493827, 19.060715)
                                                                  radius:10
                                                              identifier:@"4"];
    CLCircularRegion *region5 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.489680, 19.061230)
                                                                  radius:10
                                                              identifier:@"5"];

    OCMReject([self.mockLocationManager startMonitoringForRegion:region4]);
    OCMReject([self.mockLocationManager startMonitoringForRegion:region5]);

    [self.geofenceInternal setCurrentLocation:currentLocation];
    [self.geofenceInternal setGeofenceResponse:[self createExpectedResponse]];
    [self.geofenceInternal setGeofenceLimit:4];

    [self.geofenceInternal registerGeofences];

    OCMVerify([self.mockLocationManager startMonitoringForRegion:region1]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region2]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region3]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:regionArea]);
}

- (void)testRegisterGeofences_whenLimitIsBiggerThanGeofenceCount {
    CLLocationCoordinate2D emarsysLocation = CLLocationCoordinate2DMake(47.493160, 19.058355);
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:emarsysLocation.latitude
                                                             longitude:emarsysLocation.longitude];
    CLCircularRegion *region1 = [[CLCircularRegion alloc] initWithCenter:emarsysLocation
                                                                  radius:10
                                                              identifier:@"1"];
    CLCircularRegion *region2 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.493812, 19.058537)
                                                                  radius:10
                                                              identifier:@"2"];
    CLCircularRegion *region3 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.492292, 19.056440)
                                                                  radius:10
                                                              identifier:@"3"];
    CLCircularRegion *region4 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.493827, 19.060715)
                                                                  radius:10
                                                              identifier:@"4"];
    CLCircularRegion *region5 = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(47.489680, 19.061230)
                                                                  radius:10
                                                              identifier:@"5"];
    CLCircularRegion *regionArea = [[CLCircularRegion alloc] initWithCenter:emarsysLocation
                                                                     radius:433.431 * self.refreshRadiusRatio
                                                                 identifier:@"EMSRefreshArea"];

    [self.geofenceInternal setCurrentLocation:currentLocation];
    [self.geofenceInternal setGeofenceResponse:[self createExpectedResponse]];

    [self.geofenceInternal registerGeofences];

    OCMVerify([self.mockLocationManager startMonitoringForRegion:region1]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region2]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region3]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region4]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:region5]);
    OCMVerify([self.mockLocationManager startMonitoringForRegion:regionArea]);
}

- (EMSGeofenceResponse *)createExpectedResponse {
    return [[EMSGeofenceResponse alloc] initWithGroups:@[
                    [[EMSGeofenceGroup alloc] initWithId:@"geoGroupId1"
                                            waitInterval:20
                                               geofences:@[
                                                       [self createGeofenceWithId:@"1"
                                                                              lat:47.493160
                                                                              lon:19.058355
                                                                                r:10],
                                                       [self createGeofenceWithId:@"2"
                                                                              lat:47.493812
                                                                              lon:19.058537
                                                                                r:10],
                                                       [self createGeofenceWithId:@"4"
                                                                              lat:47.493827
                                                                              lon:19.060715
                                                                                r:10]
                                               ]],
                    [[EMSGeofenceGroup alloc] initWithId:@"geoGroupId2"
                                            waitInterval:20
                                               geofences:@[
                                                       [self createGeofenceWithId:@"5"
                                                                              lat:47.489680
                                                                              lon:19.061230
                                                                                r:10],
                                                       [self createGeofenceWithId:@"3"
                                                                              lat:47.492292
                                                                              lon:19.056440
                                                                                r:10]
                                               ]]]
                                    refreshRadiusRatio:0.3];
}

- (EMSGeofence *)createGeofenceWithId:(NSString *)id
                                  lat:(double)lat
                                  lon:(double)lon
                                    r:(int)r {
    return [[EMSGeofence alloc] initWithId:id
                                       lat:lat
                                       lon:lon
                                         r:r
                              waitInterval:30
                                  triggers:@[[[EMSGeofenceTrigger alloc] initWithId:@"triggerId1"
                                                                               type:@"ENTER"
                                                                     loiteringDelay:7
                                                                             action:@{@"id": @"testActionId1",
                                                                                     @"title": @"Custom event",
                                                                                     @"type": @"MECustomEvent",
                                                                                     @"name": @"nameValue",
                                                                                     @"payload": @{
                                                                                             @"someKey": @"someValue"
                                                                                     }}]
                                  ]];
}

@end